# SBShortcutMenuSimulator

`SBShortcutMenuSimulator` is a tweak for the iPhone Simulator that allows you to simulate the new `UIApplicationShortcutItem` API for iPhone with 3D Touch enabled.

## Requirements

- Xcode 7 GM or later, set as your default version of Xcode

## Build

``` sh
git clone https://github.com/PoomSmart/SBShortcutMenuSimulator.git
cd SBShortcutMenuSimulator
make
```

**Note:** If you installed SBShortcutMenuSimulator using the old method, go [here](https://github.com/PoomSmart/SBShortcutMenuSimulator/blob/85c3d73b9e22a20e5c59144fa1b3d19883a68f0e/README.md) and follow the uninstallation directions.

## Usage

First, start SpringBoard with SBShortcutMenuSimulator enabled (run this from the cloned directory):

``` sh
xcrun simctl spawn booted launchctl debug system/com.apple.SpringBoard --environment DYLD_INSERT_LIBRARIES=$PWD/SBShortcutMenuSimulator.dylib
xcrun simctl spawn booted launchctl stop com.apple.SpringBoard
```

You can also run respring script, which does similar things above.

Now, to show an app's quick action menu, send the app's bundle identifier over TCP to port 8000. For example, running this command will show the shortcut menu for Calendar:

``` sh
echo 'com.apple.mobilecal' | nc 127.0.0.1 8000
```

You can also run show script, which shows the quick action menu of an app given the bundle identifier:

``` sh
./show com.apple.mobilecal
```

<img src="https://raw.githubusercontent.com/PoomSmart/SBShortcutMenuSimulator/screenshot/Shortcuts.png" width="326" height="592"></img>

## Bundle identifiers Apple default apps with Quick Actions
Calendar:     com.apple.mobilecal
Contacts:     com.apple.MobileAddressBook
GameCenter:   com.apple.gamecenter
Health:       com.apple.Health
MobileSafari: com.apple.mobilesafari
News:         com.apple.news
Photos:       com.apple.mobileslideshow
Reminders:    com.apple.reminders

## License

SBShortcutMenuSimulator is available under the MIT license. See the LICENSE file for more info.
