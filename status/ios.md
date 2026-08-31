# iOS Track Status

- Owner: `ios-track-owner` (Codex macOS task)
- State: F0 consumer review complete; waiting for orchestration to close F0
- Track document: `docs/02_track_ios_controller.md`
- Handoff commit: None

## Implemented

No app implementation started; F0 remains open. Reviewed motion protocol `1.0`, shared protocol interface `0x0100`, the transport-to-gameplay boundary as it affects emitted samples, and all six frozen vectors at F0 commit `8255a4c`.

## Tests and evidence

- `node scripts/check_protocol_vectors.mjs` — pass: all six vectors validated.
- `swift - sim/vectors/motion_protocol_v1.json` with an independent, ephemeral Swift reviewer — pass: CRC-16/CCITT-FALSE, little-endian sequence values, escaping, framing, and accepted/rejected CRC behavior matched all six vectors.
- `swift --version` — Apple Swift 6.2.1 targeting arm64 macOS.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -version` — Xcode 26.4.1, build 17E202.

No physical iPhone, BLE peripheral, or FPGA was used in this review.

## Verified BLE discoveries

None. Record advertised name, UUIDs, characteristic properties, write length, source/evidence, and discovery date here for integration to consolidate.

## Interface requests

None. The iOS owner accepts protocol document/API `1.0`, wire version `0x01`, shared interface revision `0x0100`, and `sim/vectors/motion_protocol_v1.json` without changes. Swift can implement the specified ties-away-from-zero rounding, saturation, little-endian encoding, CRC, and escaping directly.

## Risks/blockers

- F0 has not passed until orchestration records all four consumer acknowledgements.
- The active developer directory is Command Line Tools rather than full Xcode; builds can use the verified `DEVELOPER_DIR` override without changing global machine state.
- BLE names, UUIDs, characteristic properties, maximum write length, and physical-device behavior remain unverified.

## Next action

Have orchestration merge this acknowledgement with the other consumer reviews and mark F0 passed. Then implement the minimal Swift encoder and permanent golden-vector tests before BLE streaming.
