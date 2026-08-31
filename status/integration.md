# Integration Status

- Owner: Codex orchestration/integration owner (current task)
- State: F0 passed; integration waiting for C2, C3, and G1
- Track document: `docs/06_integration.md`
- Integration commit: This F0 commit; exact resulting SHA is recorded in the push receipt/final handoff because a commit cannot embed its own SHA

## Accepted handoffs

| Track/gate | Commit | Evidence reviewed | Accepted |
|---|---|---|---|
| F0 interface freeze | Freeze `8255a4c`; reviews `9e62763`, `7d10743`, `0c6f9cd`, `f27b234`; merged `2083519` | All four consumers accepted without changes; complete merged smoke suite passed | Yes |
| iOS/C1 | — | — | No |
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

No hardware was used, programmed, wired, or measured.

## Open cross-track requests

None. Any future contract change must use the versioned frozen-contract process; do not patch around the contract in `rtl/board_a_top.sv`.

## Risks/blockers

- Exact BLE UUIDs, writable/notify characteristics, payload limits, XDC source/pins, Pmod positions, Vivado/IP versions, board revisions, monitor mode, and all measurements are unverified.
- Full integration remains blocked on accepted C2, C3, and G1 handoffs.

## Next action

F0 is closed. Keep full integration waiting for accepted C2, C3, and G1 handoffs; subsystem implementation was not started during this closure.
