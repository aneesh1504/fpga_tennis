# iOS Track Status

- Owner: `ios-track-owner` (Codex macOS task)
- State: Software implementation and physical iPhone/Core Motion verification complete; physical BLE/FPGA verification pending
- Track document: `docs/02_track_ios_controller.md`
- Handoff commit: `3aaf1fb`

## Implemented

- Added a generated Xcode project and native SwiftUI controller app.
- Added processed Core Motion sampling at 50 Hz with explicit neutral-grip calibration and relative attitude quaternion.
- Added protocol-v1 encoding with saturation, ties-away-from-zero rounding, CRC-16/CCITT-FALSE, byte escaping, and sequence/timestamp handling.
- Added BLE discovery without invented UUIDs, explicit writable-characteristic selection, verified-UUID configuration seams, chunking, write-without-response flow control, newest-sample backpressure policy, and automatic reconnect state.
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

A physical iPhone was connected; the signed app was installed, launched, and used for automated Core Motion evidence. No BLE peripheral or FPGA was used in this review.

## Verified BLE discoveries

None. Record advertised name, UUIDs, characteristic properties, write length, source/evidence, and discovery date here for integration to consolidate.

## Interface requests

None. The iOS owner accepts protocol document/API `1.0`, wire version `0x01`, shared interface revision `0x0100`, and `sim/vectors/motion_protocol_v1.json` without changes. Swift can implement the specified ties-away-from-zero rounding, saturation, little-endian encoding, CRC, and escaping directly.

### `IOS-REQ-001` — physical GATT discovery and C1 coordination

- State: Open — physical hardware pending.
- Request observed: `origin/main` commit `a9d7101`.
- Action taken: refreshed `origin/main` and `origin/work/transport`, inspected the integration request and transport handoff, queried CoreDevice with `devicectl`, and listed Xcode destinations.
- Result: iOS software commit `3aaf1fb` and test/status commit `973d63e` are accepted on `main`; readiness evidence is recorded at `3297905`. Transport software handoff `1b72824`, all gameplay/video software, and Board A structural integration are accepted on `main`. The new iPhone is paired, Developer Mode is enabled, signed device compilation passes, the app installs and launches, and physical Core Motion sampling/calibration passes. No programmed-board bitstream exists and BLE GATT values remain unknown. Therefore no advertised name, service/characteristic UUID, characteristic property, notify UUID, maximum write length, one-byte UART result, or 50 Hz BLE counter result can yet be measured truthfully.
- Tests: the physical iPhone suite passes 14/14, including real Core Motion sampling and calibration; the simulator regression passes all 13 software tests. These do not constitute BLE/C1 evidence.
- Remaining prerequisites: make a programmed Boolean Board and transport bring-up bitstream available; then perform GATT discovery, the `41 0A` one-byte check, and both two-minute 50 Hz C1 runs.

## Risks/blockers

- The active developer directory is Command Line Tools rather than full Xcode; builds can use the verified `DEVELOPER_DIR` override without changing global machine state.
- BLE names, UUIDs, characteristic properties, maximum write length, discovery/streaming, reconnect behavior, and 50 Hz BLE delivery remain unverified pending a programmed Boolean Board.
- Physical iPhone build, signing, installation, launch, Core Motion availability, sample delivery, and neutral calibration are verified.

## Next action

Make a programmed Boolean Board and transport bring-up bitstream available, then discover and record its verified GATT interface. Coordinate with the transport owner for the one-byte UART check and two-board C1 runs. Do not mark C1 passed from simulator or device-only evidence.
