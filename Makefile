CLANG_SIMULATOR = xcrun --sdk iphonesimulator clang -Os -miphoneos-version-min=9.0 -isysroot "`xcrun --sdk iphonesimulator --show-sdk-path`" -arch i386 -arch x86_64 -fobjc-arc -fmodules

all: SBShortcutMenuSimulator.dylib

SBShortcutMenuSimulator.dylib: SBShortcutMenuListener.o 
	$(CLANG_SIMULATOR) -dynamiclib -o $@ $^

%.o: %.m
	$(CLANG_SIMULATOR) -c -o $@ $< 

clean:
	rm -f *.o SBShortcutMenuSimulator.dylib
