# SBShortcutMenuSimulator

`SBShortcutMenuSimulator` is a tweak for the iPhone simulator that allows you to simulate the new `UIApplicationShortcutItem` API for iPhones with 3D touch enabled.

This was released before the iPhone 6s was released to the public.

## Requirements

- Xcode 7 GM or later, set as your default version of Xcode

## Installation

``` sh
git clone https://github.com/DeskConnect/SBShortcutMenuSimulator.git
cd SBShortcutMenuSimulator
make
plutil -replace EnvironmentVariables -json "{\"DYLD_INSERT_LIBRARIES\": \"${PWD}/SBShortcutMenuSimulator.dylib\"}" "$(xcrun --sdk iphonesimulator --show-sdk-path)/System/Library/LaunchDaemons/com.apple.SpringBoard.plist"
killall SpringBoard
```

## Usage

``` sh
echo 'com.apple.mobilecal' | ncat 127.0.0.1 8000
```

## Uninstallation

``` sh
plutil -remove EnvironmentVariables "$(xcrun --sdk iphonesimulator --show-sdk-path)/System/Library/LaunchDaemons/com.apple.SpringBoard.plist"
killall SpringBoard
```

## License

SBShortcutMenuSimulator is available under the MIT license. See the LICENSE file for more info.
