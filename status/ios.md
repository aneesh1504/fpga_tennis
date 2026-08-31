# iOS Track Status

- Owner: `ios-track-owner` (Codex macOS task)
- State: Software implementation complete; physical BLE/iPhone/FPGA verification pending
- Track document: `docs/02_track_ios_controller.md`
- Handoff commit: `3aaf1fb`

## Implemented

- Added a generated Xcode project and native SwiftUI controller app.
- Added processed Core Motion sampling at 50 Hz with explicit neutral-grip calibration and relative attitude quaternion.
- Added protocol-v1 encoding with saturation, ties-away-from-zero rounding, CRC-16/CCITT-FALSE, byte escaping, and sequence/timestamp handling.
- Added BLE discovery without invented UUIDs, explicit writable-characteristic selection, verified-UUID configuration seams, chunking, write-without-response flow control, newest-sample backpressure policy, and automatic reconnect state.
- Added Player 1/Player 2 selection, connection/calibration/streaming diagnostics, sample rate, sequence, and drop counters.
- Added unit tests consuming the frozen golden vectors plus state-machine, reconnect, chunk-order, and backpressure tests.

## Tests and evidence

- `node scripts/check_protocol_vectors.mjs` — pass: all six vectors validated.
- `swift - sim/vectors/motion_protocol_v1.json` with an independent, ephemeral Swift reviewer — pass: CRC-16/CCITT-FALSE, little-endian sequence values, escaping, framing, and accepted/rejected CRC behavior matched all six vectors.
- `swift --version` — Apple Swift 6.2.1 targeting arm64 macOS.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -version` — Xcode 26.4.1, build 17E202.
- `xcodegen generate --spec ios-controller/project.yml` — pass; reproducible project generated.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios-controller/MotionTennisController.xcodeproj -scheme MotionTennisController -destination 'generic/platform=iOS Simulator' build-for-testing CODE_SIGNING_ALLOWED=NO` — pass.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios-controller/MotionTennisController.xcodeproj -scheme MotionTennisController -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test CODE_SIGNING_ALLOWED=NO -quiet` — pass on iOS Simulator 26.4.1: 13 tests, 0 failures, 0 skipped.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun devicectl list devices` and `xcodebuild ... -showdestinations` — registered iPhone 13 detected as unavailable; no physical iOS destination was available for building or testing.

No physical iPhone, BLE peripheral, or FPGA was used in this review.

## Verified BLE discoveries

None. Record advertised name, UUIDs, characteristic properties, write length, source/evidence, and discovery date here for integration to consolidate.

## Interface requests

None. The iOS owner accepts protocol document/API `1.0`, wire version `0x01`, shared interface revision `0x0100`, and `sim/vectors/motion_protocol_v1.json` without changes. Swift can implement the specified ties-away-from-zero rounding, saturation, little-endian encoding, CRC, and escaping directly.

## Risks/blockers

- The active developer directory is Command Line Tools rather than full Xcode; builds can use the verified `DEVELOPER_DIR` override without changing global machine state.
- BLE names, UUIDs, characteristic properties, maximum write length, and physical-device behavior remain unverified.
- Core Motion availability, signing, BLE discovery/streaming, reconnect behavior, and 50 Hz delivery still require a physical iPhone and programmed Boolean Board.
- The registered iPhone 13 was unavailable to Xcode during the 2026-08-31 readiness check; connect/unlock/trust it before the device build can proceed.

## Next action

Install on a physical iPhone, discover and record the verified Boolean Board GATT interface, select/configure its write characteristic, and coordinate with the transport owner for the one-byte UART check and two-board C1 runs. Do not mark C1 passed from simulator evidence.
