# iOS Controller

The native SwiftUI controller samples processed Core Motion data at 50 Hz and sends protocol-v1 motion frames over a selected BLE writable characteristic.

BLE UUIDs are intentionally not hard-coded. Until the Boolean Board interface is verified, the app scans nearby peripherals, discovers writable characteristics, and requires an explicit selection. Verified UUID filtering can then be supplied through `BLEConfiguration` without changing the wire encoder.

## Generate and test

```sh
xcodegen generate --spec ios-controller/project.yml
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ios-controller/MotionTennisController.xcodeproj \
  -scheme MotionTennisController \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test CODE_SIGNING_ALLOWED=NO
```

Run the application on a physical iPhone for Core Motion and BLE checkpoint evidence. Simulator tests prove only software behavior.
