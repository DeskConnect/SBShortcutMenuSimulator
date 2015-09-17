#import <UIKit/UIKit.h>

#include <arpa/inet.h>

@interface SBIcon : NSObject
@end

@interface SBIconView : UIView
@end

@interface SBIconModel : NSObject
- (SBIcon *)applicationIconForBundleIdentifier:(NSString *)bundleIdentifier;
@end

@interface SBIconViewMap : NSObject
+ (instancetype)homescreenMap;
- (SBIconView *)iconViewForIcon:(SBIcon *)icon;
@end

@interface SBIconController : UIViewController
@property (nonatomic, readonly, strong) SBIconModel *model;
+ (instancetype)sharedInstance;
- (void)_revealMenuForIconView:(SBIconView *)iconView presentImmediately:(BOOL)presentImmediately;
- (void)scrollToIconListContainingIcon:(SBIcon *)icon animate:(BOOL)animate;
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
                [controller scrollToIconListContainingIcon:icon animate:NO];

                SBIconView *iconView = [[NSClassFromString(@"SBIconViewMap") homescreenMap] iconViewForIcon:icon];
                [controller _revealMenuForIconView:iconView presentImmediately:YES];
            }
        });
    });
    dispatch_source_set_cancel_handler(server, ^{
        close(sock);
    });
    dispatch_resume(server);
}
