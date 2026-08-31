# Global Implementation Status

This is the orchestration index, not a shared scratchpad. Only the orchestration/integration owner edits it. Track owners update their files under `status/`. Never replace unknowns with guesses.

## Current state

- Execution mode: Interface freeze, then four parallel tracks
- Current gate: F0 — artifacts and executable checks complete; required consumer reviews pending
- Last completed gate/checkpoint: None
- Overall status: F0 is **not passed** because four track-owner acknowledgements are not recorded
- Integration owner: Codex orchestration/integration owner (current task)
- Freeze base: `origin/main` at `b8f0578`; ancestry check passed 2026-08-30
- Freeze implementation commit: This commit; its exact SHA is available only after commit creation and is recorded in the push receipt/final handoff

## Dependency board

| Work | State | Depends on | Detailed status |
|---|---|---|---|
| Interface freeze | Review pending | iOS, transport, video, and gameplay owner acknowledgements | This file and `docs/00_interface_freeze.md` |
| iOS controller | Waiting | F0 | `status/ios.md` |
| Transport RTL | Waiting | F0 | `status/transport.md` |
| Video | Waiting | F0 | `status/video.md` |
| Gameplay | Waiting | F0 | `status/gameplay.md` |
| Integration | Waiting | C2 + C3 + G1 | `status/integration.md` |

## Frozen interface record

| Item | Version | State |
|---|---|---|
| Motion wire protocol | Wire `0x01`; document/API `1.0` | Candidate frozen; tests pass, reviews pending |
| SystemVerilog shared packages | `protocol/game/video` interface `0x0100` | Compile/elaboration pass; reviews pending |
| Golden protocol vectors | Format `1`, protocol `1`, six vectors | Validator pass; reviews pending |
| Cross-track module interfaces/stubs | Interface `1.0` | Four smoke checks pass; reviews pending |
| File owners | Ownership table below | Exclusive roles assigned; consumer roles not yet staffed/reviewed |

## Exclusive ownership assignments

| Owner identifier | Exclusive paths |
|---|---|
| `interface-freeze-owner` (Codex current task through F0) | `rtl/packages/`, `docs/protocol.md`, initial `sim/vectors/`, F0-only `sim/interfaces/`, repository skeleton |
| `ios-track-owner` | `ios-controller/`, iOS-side tests, `status/ios.md` |
| `transport-track-owner` | `rtl/common/`, `rtl/bridge/`, `sim/common/`, transport build files, `status/transport.md` |
| `video-track-owner` | `rtl/video/`, `assets/`, `scripts/build_assets.py`, `sim/video/`, `status/video.md` |
| `gameplay-track-owner` | `rtl/game/`, `rtl/audio/`, `sim/game/`, `status/gameplay.md` |
| `orchestration-integration-owner` (Codex current task) | `rtl/board_a_top.sv`, board/project build scripts, `config/`, `docs/hardware-manifest.md`, `docs/bringup-log.md`, `STATUS.md`, `status/integration.md` |

Role assignment is exclusive. A future agent or person must explicitly assume one unstaffed track-owner identifier before editing its paths.

## F0 review acknowledgements

| Consumer | Owner | Review | Evidence |
|---|---|---|---|
| Interface freeze | Codex current task | Complete | Protocol, types, vectors, stubs, ownership, and tests checked 2026-08-30 |
| Integration/top level | Codex current task | Complete | Structural top seam compiled and simulated 2026-08-30 |
| Swift/iOS encoder | `ios-track-owner` | Pending | No owner acknowledgement supplied |
| Transport RTL | `transport-track-owner` | Pending | No owner acknowledgement supplied |
| Video RTL | `video-track-owner` | Pending | No owner acknowledgement supplied |
| Gameplay/audio RTL | `gameplay-track-owner` | Pending | No owner acknowledgement supplied |

## Hardware discoveries

The complete placeholder inventory is in `docs/hardware-manifest.md`; all values below remain unverified.

| Item | Verified value | Evidence |
|---|---|---|
| Vivado and vendor IP versions | Unverified | — |
| Boolean Board XDC source/version and pins | Unverified | — |
| BLE names, UUIDs, and payload limits | Unverified | — |
| Board-to-board Pmod positions/wiring | Unverified | — |
| Monitor mode, clocks, delivery rates, and error measurements | Unverified | — |

## Gate and checkpoint record

| Gate/checkpoint | Status | Evidence summary |
|---|---|---|
| F0 interface freeze | **Not passed — review pending** | All files and executable checks pass; four required track-owner reviews absent |
| C1 BLE sensor path | Not started | — |
| C2 two-board path | Not started | — |
| C3 video path | Not started | — |
| G1 gameplay simulation | Not started | — |
| C4 integrated game | Not started | — |

## F0 commands and results — 2026-08-30

| Exact command | Result |
|---|---|
| `git fetch origin main` | Pass; `origin/main` fetched at `b8f0578` |
| `git merge-base --is-ancestor b8f0578 origin/main` | Pass; exit 0 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_smoke.ps1` | Pass; 6 vectors, 21 Markdown files, package elaboration, and all 4 interface seams passed using Icarus Verilog 12.0 |
| `git diff --check` | Pass; no whitespace errors |

## Open issues and risks

- Required iOS, transport, video, and gameplay owner reviews are absent, so F0 remains closed and implementation tracks must not start.
- The wire field is named `sequence_number` in SystemVerilog because `sequence` is a reserved keyword; consumers must use the frozen name.
- No hardware was used. UUIDs, pins, board revisions, IP/tool versions, connector orientation, timing, delivery rates, and measurements remain unverified.
- A commit cannot contain its own resulting SHA without changing that SHA. The exact pushed SHA is therefore recorded in the external push receipt/final handoff; the repository record identifies it as the commit containing this status and the requested subject.

## Next action

Staff the four track-owner roles and record their reviews of protocol `1.0` and interface revision `0x0100`. If all acknowledge without changes, update F0 to passed in a later orchestration commit; otherwise use the versioned contract-change process. Do not dispatch implementation before that review commit.
