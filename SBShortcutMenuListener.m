#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include <arpa/inet.h>

// Many interfaces here, obviously a tough research
@interface SBUIForceTouchGestureRecognizer : UIGestureRecognizer
@end

@interface SBApplication : NSObject
@end

@interface SBIcon : NSObject
- (SBApplication *)application;
@end

@interface SBIconView : UIView
- (SBIcon *)icon;
- (SBUIForceTouchGestureRecognizer *)appIconForceTouchGestureRecognizer;
@end

@interface SBIconModel : NSObject
- (SBIcon *)applicationIconForBundleIdentifier:(NSString *)bundleIdentifier;
@end

@interface SBIconViewMap : NSObject
+ (instancetype)homescreenMap;
- (SBIconView *)mappedIconViewForIcon:(SBIcon *)icon;
- (SBIconView *)iconViewForIcon:(SBIcon *)icon;
- (SBIconView *)_iconViewForIcon:(SBIcon *)icon;
@end

@interface SBIconAccessoryViewMap : SBIconViewMap
@end

@interface SBUIAction : NSObject
@end

@interface SBSApplicationShortcutItem : NSObject
@end

@interface SBUIAppIconForceTouchShortcutViewController : UIViewController
- (SBUIAction *)_actionFromApplicationShortcutItem:(SBSApplicationShortcutItem *)item;
@end

@interface SBUIIconForceTouchController : NSObject
- (void)_setupWithGestureRecognizer:(SBUIForceTouchGestureRecognizer *)recognizer;
- (void)_presentAnimated:(BOOL)animated withCompletionHandler:(id)handler;
@end

@interface SBUIAppIconForceTouchController : NSObject {
	SBUIIconForceTouchController *_iconForceTouchController;
}
- (void)_setupWithGestureRecognizer:(SBUIForceTouchGestureRecognizer *)recognizer;
- (void)_peekAnimated:(BOOL)animated withRelativeTouchForce:(double)force allowSmoothing:(BOOL)smooth;
- (void)presentAnimated:(BOOL)animated withCompletionHandler:(id)handler;
- (void)appIconForceTouchShortcutViewController:(SBUIAppIconForceTouchShortcutViewController *)controller activateApplicationShortcutItem:(SBSApplicationShortcutItem *)item;
@end

@interface SBIconController : UIViewController {
	SBUIAppIconForceTouchController *_appIconForceTouchController;
}
@property (nonatomic, readonly, strong) SBIconModel *model;
+ (instancetype)sharedInstance;
- (SBIconViewMap *)homescreenIconViewMap;
- (void)scrollToIconListContainingIcon:(SBIcon *)icon animate:(BOOL)animate;
- (void)_revealMenuForIconView:(SBIconView *)iconView presentImmediately:(BOOL)presentImmediately;
- (void)appIconForceTouchController:(SBUIAppIconForceTouchController *)controller willPresentForGestureRecognizer:(SBUIForceTouchGestureRecognizer *)recognizer;
- (void)_runAppIconForceTouchTest:(NSString *)test withOptions:(NSDictionary *)options;
@end

// These hacks are required in iOS 10
@implementation UITraitCollection (Hack)

+ (void)load
{
	static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = object_getClass((id)self);
        SEL originalSelector = @selector(traitCollectionWithForceTouchCapability:);
        SEL swizzledSelector = @selector(hax_traitCollectionWithForceTouchCapability:);
        Method originalMethod = class_getClassMethod(class, originalSelector);
        Method swizzledMethod = class_getClassMethod(class, swizzledSelector);
        BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        if (didAddMethod)
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        else
            method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

- (int)forceTouchCapability
{
	return 2;
}

+ (UITraitCollection *)hax_traitCollectionWithForceTouchCapability:(int)capability
{
	return [self hax_traitCollectionWithForceTouchCapability:2];
}

@end

@implementation UIDevice (Override)

- (BOOL)_supportsForceTouch
{
	return YES;
}

@end

@implementation UIScreen (Override)

- (int)_forceTouchCapability
{
	return 2;
}

@end

static dispatch_source_t server = nil;

__attribute__((constructor))
static void SBShortcutMenuListenerInitialize() {
    NSLog(@"SBShortcutMenuListener: Injecting into SpringBoard");

    struct sockaddr_in server_addr = {};
    server_addr.sin_len = sizeof(server_addr);
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(8000);
    server_addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    
    int sock;
    if ((sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)) == -1)
        return;
    
    if (bind(sock, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
        return;
    
    if (listen(sock, 1) == -1)
        return;
    
    server = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, sock, 0, dispatch_get_main_queue());
    
    dispatch_source_set_event_handler(server, ^{
        int client_sock;
        struct sockaddr_in client_addr;
        socklen_t size = sizeof(client_addr);
        if ((client_sock = accept(sock, (struct sockaddr *)&client_addr, &size)) == -1)
            return;
        
        dispatch_io_t channel = dispatch_io_create(DISPATCH_IO_STREAM, client_sock, dispatch_get_main_queue(), ^(int error) {
            close(client_sock);
        });
        dispatch_io_set_low_water(channel, 1);
        dispatch_io_read(channel, 0, SIZE_MAX, dispatch_get_main_queue(), ^(bool done, dispatch_data_t data, int error) {
            if (done && data == dispatch_data_empty)
                return dispatch_io_close(channel, DISPATCH_IO_STOP);
            
            if (data && dispatch_data_get_size(data) > 0) {
                size_t length = 0;
                const void *bytes = NULL;
                dispatch_data_t mapped __attribute__((unused, objc_precise_lifetime)) = dispatch_data_create_map(data, &bytes, &length);

                NSString *bundleIdentifier = [[NSString alloc] initWithBytes:bytes length:length encoding:NSUTF8StringEncoding];
                bundleIdentifier = [bundleIdentifier stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

                SBIconController *controller = [NSClassFromString(@"SBIconController") sharedInstance];
                SBIcon *icon = [controller.model applicationIconForBundleIdentifier:bundleIdentifier];
                if (icon == nil) {
                	NSLog(@"Application not found: %@", bundleIdentifier);
                	return;
                }
                [controller scrollToIconListContainingIcon:icon animate:NO];
				
				if ([UIDevice.currentDevice.systemVersion floatValue] >= 10) {
					
					// There exists SpringBoard test for App icon Force Touch, but I don't know how to get it working yet
					/*NSDictionary *options = @{ @"testApplication" : [icon retain] };
                	[controller _runAppIconForceTouchTest:@"AppIconForceTouchPeek" withOptions:options];
                	[controller _runAppIconForceTouchTest:@"AppIconForceTouchPresent" withOptions:options];*/
                	
                	SBIconView *iconView = [[controller homescreenIconViewMap] mappedIconViewForIcon:icon];
                	SBUIForceTouchGestureRecognizer *recognizer = [iconView appIconForceTouchGestureRecognizer];
                	SBUIAppIconForceTouchController *forceTouch;
                	object_getInstanceVariable(controller, "_appIconForceTouchController", (void **)&forceTouch);
                	SBUIIconForceTouchController *ftController;
                	object_getInstanceVariable(forceTouch, "_iconForceTouchController", (void **)&ftController);
                	[forceTouch _setupWithGestureRecognizer:recognizer];
                	// or [ftController _setupWithGestureRecognizer:recognizer];
                	[ftController _presentAnimated:YES withCompletionHandler:nil];
				} else {
					SBIconView *iconView = [[NSClassFromString(@"SBIconViewMap") homescreenMap] iconViewForIcon:icon];
					[controller _revealMenuForIconView:iconView presentImmediately:YES];
				}
                
            }
        });
    });
    dispatch_source_set_cancel_handler(server, ^{
        close(sock);
    });
    dispatch_resume(server);
}
