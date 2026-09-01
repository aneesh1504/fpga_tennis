# iOS Track Status

- Owner: `ios-track-owner` (Codex macOS task)
- State: Software, physical iPhone/Core Motion, BLE GATT, and two-minute phone-side streaming verified; FPGA receipt counters and second pair still pending for C1
- Track document: `docs/02_track_ios_controller.md`
- Handoff commit: `3aaf1fb`

## Implemented

- Added a generated Xcode project and native SwiftUI controller app.
- Added processed Core Motion sampling at 50 Hz with explicit neutral-grip calibration and relative attitude quaternion.
- Added protocol-v1 encoding with saturation, ties-away-from-zero rounding, CRC-16/CCITT-FALSE, byte escaping, and sequence/timestamp handling.
- Added BLE discovery without invented UUIDs, explicit writable-characteristic selection, verified-UUID configuration seams, chunking, write-without-response flow control, newest-sample backpressure policy, and automatic reconnect state.
- Added the physically verified Boolean Board advertised-name prefix and GATT service/write UUIDs, automatic verified-characteristic selection, and peripheral retention throughout asynchronous connection setup.
- Added Player 1/Player 2 selection, connection/calibration/streaming diagnostics, sample rate, sequence, and drop counters.
- Added unit tests consuming the frozen golden vectors plus state-machine, reconnect, chunk-order, backpressure, and physical-device Core Motion calibration tests.

## Tests and evidence

- `node scripts/check_protocol_vectors.mjs` — pass: all six vectors validated.
- `swift - sim/vectors/motion_protocol_v1.json` with an independent, ephemeral Swift reviewer — pass: CRC-16/CCITT-FALSE, little-endian sequence values, escaping, framing, and accepted/rejected CRC behavior matched all six vectors.
- `swift --version` — Apple Swift 6.2.1 targeting arm64 macOS.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -version` — Xcode 26.4.1, build 17E202.
- `xcodegen generate --spec ios-controller/project.yml` — pass; reproducible project generated.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios-controller/MotionTennisController.xcodeproj -scheme MotionTennisController -destination 'generic/platform=iOS Simulator' build-for-testing CODE_SIGNING_ALLOWED=NO` — pass.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios-controller/MotionTennisController.xcodeproj -scheme MotionTennisController -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test CODE_SIGNING_ALLOWED=NO -quiet` — pass on iOS Simulator 26.4.1: 13 tests, 0 failures, 0 skipped.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun devicectl list devices` and `xcodebuild ... -showdestinations` — registered iPhone 13 detected as unavailable; no physical iOS destination was available for building or testing.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xctrace list devices` plus `system_profiler SPUSBDataType` — registered iPhone 13 running iOS 26.0.1 is offline, and no iPhone is present on USB. `xcodebuild -checkFirstLaunchStatus` passes, so Xcode first-launch setup is complete.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios-controller/MotionTennisController.xcodeproj -scheme MotionTennisController -sdk iphoneos -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO -quiet` — pass after synchronizing the complete accepted software stack at `9176fba`; device-SDK/arm64 compilation succeeds without signing.
- Simulator regression after synchronizing `9176fba` — pass on iOS Simulator 26.4.1: 13 tests, 0 failures, 0 skipped.
- 2026-08-31 physical-device validation: CoreDevice reports the new iPhone 17 (iPhone18,3, iOS 26.6.1) as available and paired with Developer Mode enabled. A physical arm64 Debug build succeeds with automatic Personal Team provisioning; `devicectl` installs and launches `com.fpga-tennis.MotionTennisController`, and the process remains active.
- Physical iPhone test suite — pass: 14 tests, 0 failures, 0 skipped. `MotionSamplerDeviceTests.testPhysicalDeviceProducesMotionAndCalibrates` received a real processed Core Motion sample and successfully calibrated the neutral quaternion.
- Simulator regression after adding the physical-device diagnostic — pass on iOS Simulator 26.4.1: the 13 software tests pass with 0 failures.
- 2026-09-01 BLE advertisement scan — pass: physical iPhone observed `RD_BOOL_88723523033D` at -54 dBm while the programmed board was powered.
- Physical GATT enumeration — pass: service `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`; write characteristic `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` with write-with-response and write-without-response; notify characteristic `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`; maximum values 244 bytes without response and 512 bytes with response.
- `41 0A` probe — the BLE peripheral acknowledged an explicit write-with-response. The programmed FPGA top does not expose a raw-byte counter, so this alone is not claimed as FPGA receipt of `0x41`.
- Two-minute physical phone-to-BLE run — app-side pass: 120.007 seconds, 6,033 generated frames, 6,033 handed to CoreBluetooth, 0 dropped/backpressured, 50.272 Hz average, delivery ratio 1.000000, last sequence 6032. The board's orange BLE data indicator showed activity, but the user observed no FPGA LEDs, so decoded FPGA receipt is not established and C1 remains open.
- Post-GATT simulator regression — pass on iOS Simulator 26.4.1: 13 software tests passed, 5 physical-only tests skipped, 0 failures.

A physical iPhone and the programmed Boolean Board BLE peripheral were used for advertisement, GATT, acknowledged-write, and two-minute phone-side streaming evidence. FPGA-side decoded receipt was not observed.

## Verified BLE discoveries

- Date/device: 2026-09-01, physical iPhone 17 (iPhone18,3) running iOS 26.6.1.
- Advertised name: `RD_BOOL_88723523033D`.
- Service UUID: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`.
- Phone-to-board characteristic: `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`; properties `writeWithoutResponse`, `write`.
- Board-to-phone characteristic: `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`; property `notify`.
- Maximum write length reported by iOS: 244 bytes without response; 512 bytes with response.
- Evidence: self-checking physical XCTest advertisement, GATT enumeration, acknowledged probe, and two-minute stream runs against the board programmed from integration build `d457063`.

## Interface requests

None. The iOS owner accepts protocol document/API `1.0`, wire version `0x01`, shared interface revision `0x0100`, and `sim/vectors/motion_protocol_v1.json` without changes. Swift can implement the specified ties-away-from-zero rounding, saturation, little-endian encoding, CRC, and escaping directly.

### `IOS-REQ-001` — physical GATT discovery and C1 coordination

- State: Open — iPhone/BLE-module evidence complete for the first pair; FPGA receipt counters and second pair pending.
- Request observed: `origin/main` commit `a9d7101`.
- Action taken: synchronized accepted integration commit `30a1791`, ran physical advertisement/GATT/write/stream diagnostics, configured the verified interface in the app, and fixed peripheral lifetime during asynchronous connection setup.
- Result: the iPhone is paired, Developer Mode is enabled, signed device compilation/install/launch pass, Core Motion sampling/calibration pass, the programmed board is discovered and connected, all requested GATT facts are recorded above, and the app completes a two-minute 50.272 Hz stream with zero local loss. The BLE module acknowledges `41 0A` and its orange data indicator shows activity. The user observed no FPGA LEDs during the stream, so raw/decoded FPGA receipt and transport counters remain unverified.
- Tests: physical software suite passes 14/14; advertisement, GATT, acknowledged-write, and two-minute stream diagnostics pass; simulator software regression passes. C1 is not passed because the FPGA received/gap/error/overflow counters and the required second phone/board pair are absent.
- Remaining prerequisites: confirm the board retained/reloaded the programmed bitstream and is not held in reset; expose/read FPGA receive counters or ILA; repeat the run and capture decoded-value/counter evidence; then repeat independently on the second phone/board pair.

## Risks/blockers

- The active developer directory is Command Line Tools rather than full Xcode; builds can use the verified `DEVELOPER_DIR` override without changing global machine state.
- The observed board's BLE name, UUIDs, characteristic properties, payload limits, connection, acknowledged write, and two-minute app-to-BLE delivery are verified.
- Physical iPhone build, signing, installation, launch, Core Motion availability, sample delivery, and neutral calibration are verified.
- FPGA receipt remains unverified: no FPGA LEDs illuminated during the two-minute run even though the BLE module's orange data LED showed traffic. The bitstream may have been lost after power removal, reset may be asserted, or the BLE-UART/FPGA path may require transport-side diagnosis.

## Next action

Reprogram or confirm the `d457063` transport bring-up image without removing board power, verify LED 0/reset state, and add/read an observable raw-byte and decoded-frame counter. Then repeat the two-minute run and record FPGA received/gap/CRC/framing/overflow counters before testing the second pair. Do not mark C1 passed from the clean phone-side counters alone.
