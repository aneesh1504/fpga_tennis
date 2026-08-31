# Integration Status

- Owner: Codex orchestration/integration owner (current task)
- State: F0 passed; iOS software accepted; transport/video/gameplay active; full integration waiting for C2, C3, and G1
- Track document: `docs/06_integration.md`
- Integration commit: This F0 commit; exact resulting SHA is recorded in the push receipt/final handoff because a commit cannot embed its own SHA

## Accepted handoffs

| Track/gate | Commit | Evidence reviewed | Accepted |
|---|---|---|---|
| F0 interface freeze | Freeze `8255a4c`; reviews `9e62763`, `7d10743`, `0c6f9cd`, `f27b234`; merged `2083519` | All four consumers accepted without changes; complete merged smoke suite passed | Yes |
| iOS/C1 | Software `3aaf1fb`; status `973d63e` | Xcode build-for-testing passed; simulator suite 13 passed, 0 failed/skipped; physical BLE/iPhone/FPGA evidence explicitly pending | Software accepted; C1 No |
| Transport/C2 | — | — | No |
| Video/C3 | — | — | No |
| Gameplay/G1 | — | — | No |

## F0 interface versions

| Contract | Version |
|---|---|
| Motion wire byte version | `0x01` |
| Normative protocol document | `1.0` |
| Shared protocol package | `0x0100` |
| Shared gameplay package | `0x0100` |
| Shared video package | `0x0100` |
| Golden vector format/protocol | `1` / `1` |
| Cross-track seams | `1.0` |

## Ownership assignments

| Owner | Paths |
|---|---|
| `interface-freeze-owner` (Codex current task through F0) | `rtl/packages/`, `docs/protocol.md`, initial `sim/vectors/`, F0-only `sim/interfaces/`, repository skeleton |
| `ios-track-owner` (Codex macOS task) | `ios-controller/`, iOS tests, `status/ios.md` |
| `transport-track-owner` (`/root/transport_f0_review`) | `rtl/common/`, `rtl/bridge/`, `sim/common/`, transport build files, `status/transport.md` |
| `video-track-owner` (`/root/video_f0_review`) | `rtl/video/`, `assets/`, `scripts/build_assets.py`, `sim/video/`, `status/video.md` |
| `gameplay-track-owner` (`/root/gameplay_f0_review`) | `rtl/game/`, `rtl/audio/`, `sim/game/`, `status/gameplay.md` |
| `orchestration-integration-owner` (Codex current task) | `rtl/board_a_top.sv`, board/project build scripts, `config/`, hardware/bring-up docs, `STATUS.md`, this file |

## Review record

| Reviewer/consumer | Result |
|---|---|
| Interface-freeze owner | Complete 2026-08-30 |
| Integration/top-level owner | Complete 2026-08-30; structural seam passes |
| iOS owner | Complete at `9e62763`; Swift 6.2.1 independently validated all six vectors |
| Transport owner | Complete at `7d10743`; accepted without changes; smoke passed |
| Video owner | Complete at `0c6f9cd`; accepted without changes; smoke passed |
| Gameplay/audio owner | Complete at `f27b234`; accepted without changes; smoke passed |

## Regression tests and evidence — 2026-08-30

| Exact command | Result |
|---|---|
| `git merge --no-edit origin/work/ios` | Pass; `9e62763` already present |
| `git merge --no-edit origin/work/transport` | Pass; `7d10743` merged |
| `git merge --no-edit origin/work/video` | Pass; `0c6f9cd` merged |
| `git merge --no-edit origin/work/gameplay` | Pass; `f27b234` merged |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_smoke.ps1` | Pass on merged `2083519` with Icarus Verilog 12.0: 6 protocol vectors; local links in 21 Markdown files; shared packages compile/elaborate; all four interface seams pass |
| `git diff --check` and `git diff origin/main..HEAD --check` | Pass; no output |
| `git merge --ff-only origin/work/ios` | Pass; commits `406f2a6`, `3aaf1fb`, and `973d63e` fast-forwarded onto main |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_smoke.ps1` after iOS handoff | Pass: 6 vectors; local links in 22 Markdown files; packages compile/elaborate; all four interface seams pass |

No hardware was used, programmed, wired, or measured.

## Open cross-track requests

| Request | Target | Requested action | Relevant commit/interface | Gate impact | State |
|---|---|---|---|---|---|
| `IOS-REQ-001` | `ios-track-owner` on `origin/work/ios` | On a physical iPhone and programmed Boolean Board, record the advertised name, service UUID, writable characteristic UUID/properties, notify UUID/properties if present, maximum write-without-response length, device/iOS/app build, and observed discovery/connection result. Then coordinate a one-byte UART check and 50 Hz protocol-v1 stream once transport supplies the hardware build. Respond only in `status/ios.md`; do not infer absent values. | iOS `3aaf1fb`; protocol `1.0` / wire `0x01`; response `44d0f79`; transport build pending | Blocks C1; does not block C2 simulation, C3, or G1 | Acknowledged; waiting for connected/unlocked/trusted iPhone and programmed transport build |

Any future contract change must use the versioned frozen-contract process; do not patch around the contract in `rtl/board_a_top.sv`.

## Risks/blockers

- Exact BLE UUIDs, writable/notify characteristics, payload limits, XDC source/pins, Pmod positions, Vivado/IP versions, board revisions, monitor mode, and all measurements are unverified.
- Full integration remains blocked on accepted C2, C3, and G1 handoffs.
- `IOS-REQ-001` requires physical hardware and remains open; iOS simulator evidence is accepted only as a software handoff.
- The registered iPhone 13 was unavailable to Xcode during readiness check `3297905`; no GATT or delivery evidence could be collected.

## Next action

Poll `origin/work/ios:status/ios.md` for `IOS-REQ-001`, continue independent transport/video/gameplay work, and accept each software handoff only with exact commit, tests/results, and remaining hardware requirements.
