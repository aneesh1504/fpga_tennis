# iOS Controller

The native SwiftUI controller samples processed Core Motion data at 50 Hz and sends protocol-v1 motion frames over a selected BLE writable characteristic.

The stock Boolean Board BLE interface was physically verified on 2026-09-01. The app filters the observed `RD_BOOL_` advertised-name prefix, discovers service `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`, and automatically selects writable characteristic `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`. Discovery-mode configuration remains available for diagnostic scans and future hardware revisions.

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
