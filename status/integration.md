# Integration Status

- Owner: Codex orchestration/integration owner (current task)
- State: F0 artifact/test work complete; consumer reviews pending; integration waiting for C2, C3, and G1
- Track document: `docs/06_integration.md`
- Integration commit: This F0 commit; exact resulting SHA is recorded in the push receipt/final handoff because a commit cannot embed its own SHA

## Accepted handoffs

| Track/gate | Commit | Evidence reviewed | Accepted |
|---|---|---|---|
| F0 interface freeze | This commit; exact SHA in push receipt | Packages/vectors/stubs/tests reviewed by integration owner; four track-owner acknowledgements pending | No |
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
| `ios-track-owner` | `ios-controller/`, iOS tests, `status/ios.md` |
| `transport-track-owner` | `rtl/common/`, `rtl/bridge/`, `sim/common/`, transport build files, `status/transport.md` |
| `video-track-owner` | `rtl/video/`, `assets/`, `scripts/build_assets.py`, `sim/video/`, `status/video.md` |
| `gameplay-track-owner` | `rtl/game/`, `rtl/audio/`, `sim/game/`, `status/gameplay.md` |
| `orchestration-integration-owner` (Codex current task) | `rtl/board_a_top.sv`, board/project build scripts, `config/`, hardware/bring-up docs, `STATUS.md`, this file |

## Review record

| Reviewer/consumer | Result |
|---|---|
| Interface-freeze owner | Complete 2026-08-30 |
| Integration/top-level owner | Complete 2026-08-30; structural seam passes |
| iOS owner | Pending; no acknowledgement supplied |
| Transport owner | Pending; no acknowledgement supplied |
| Video owner | Pending; no acknowledgement supplied |
| Gameplay/audio owner | Pending; no acknowledgement supplied |

## Regression tests and evidence — 2026-08-30

| Exact command | Result |
|---|---|
| `git fetch origin main` | Pass; fetched `origin/main` at `b8f0578` |
| `git merge-base --is-ancestor b8f0578 origin/main` | Pass; exit 0 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_smoke.ps1` | Pass with Icarus Verilog 12.0: 6 protocol vectors; local links in 21 Markdown files; shared packages compile/elaborate; transport-to-gameplay, gameplay-to-video, gameplay-to-audio, and subsystem-to-top smoke tests pass |
| `git diff --check` | Pass; no output |

No hardware was used, programmed, wired, or measured.

## Open cross-track requests

- Each of `ios-track-owner`, `transport-track-owner`, `video-track-owner`, and `gameplay-track-owner` must review and acknowledge protocol `1.0`, package interfaces `0x0100`, its consumed seam, and the relevant golden vectors.
- Any requested change must use the versioned frozen-contract process; do not patch around the contract in `rtl/board_a_top.sv`.

## Risks/blockers

- F0 cannot pass until the four required track-owner reviews are recorded.
- Exact BLE UUIDs, writable/notify characteristics, payload limits, XDC source/pins, Pmod positions, Vivado/IP versions, board revisions, monitor mode, and all measurements are unverified.
- Full integration remains blocked on accepted C2, C3, and G1 handoffs even after F0 review closes.

## Next action

Obtain and record all four F0 consumer acknowledgements. Keep every implementation track waiting until orchestration records a passed F0 in a subsequent commit.
