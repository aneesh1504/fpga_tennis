# Global Implementation Status

This is the orchestration index, not a shared scratchpad. Only the orchestration/integration owner edits it. Track owners update their files under `status/`. Never replace unknowns with guesses.

## Current state

- Execution mode: Four parallel implementation tracks after F0
- Current gate: C1/C2/C3/G1 development in parallel
- Last completed gate/checkpoint: F0 interface freeze
- Overall status: All four software handoffs accepted and merged; integration scaffolding is next; C1/C2/C3/G1 hardware/recorded-motion evidence remains open
- Integration owner: Codex orchestration/integration owner (current task)
- Freeze base: `origin/main` at `b8f0578`; ancestry check passed 2026-08-30
- Freeze implementation commit: `8255a4c52125101f8c8d033766b490975a36ffa5`
- Reviewed merge before closure: `2083519`; closure commit is this commit and its exact SHA is recorded in the push receipt/final handoff

## Dependency board

| Work | State | Depends on | Detailed status |
|---|---|---|---|
| Interface freeze | Passed | All deliverables, reviews, and merged smoke tests passed | This file and `docs/00_interface_freeze.md` |
| iOS controller | Software complete; hardware pending | Physical iPhone/BLE/FPGA evidence | `status/ios.md` |
| Transport RTL | Software complete; hardware pending | C1/C2 physical evidence and Vivado implementation | `status/transport.md` |
| Video | Software complete; hardware pending | C3 Vivado/HDMI/monitor evidence | `status/video.md` |
| Gameplay | Software complete; validation pending | Recorded phone traces and one-phone FPGA rally for G1 | `status/gameplay.md` |
| Integration | Scaffolding ready | Formal C2 + C3 + G1 still gate full integration claims | `status/integration.md` |

## Frozen interface record

| Item | Version | State |
|---|---|---|
| Motion wire protocol | Wire `0x01`; document/API `1.0` | Frozen and accepted by all consumers |
| SystemVerilog shared packages | `protocol/game/video` interface `0x0100` | Frozen; merged compile/elaboration passed |
| Golden protocol vectors | Format `1`, protocol `1`, six vectors | Frozen; independent Swift and merged validator checks passed |
| Cross-track module interfaces/stubs | Interface `1.0` | Frozen; all four merged smoke checks passed |
| File owners | Ownership table below | Exclusive roles assigned and all F0 consumer reviews recorded |

## Exclusive ownership assignments

| Owner identifier | Exclusive paths |
|---|---|
| `interface-freeze-owner` (Codex current task through F0) | `rtl/packages/`, `docs/protocol.md`, initial `sim/vectors/`, F0-only `sim/interfaces/`, repository skeleton |
| `ios-track-owner` (Codex macOS task) | `ios-controller/`, iOS-side tests, `status/ios.md` |
| `transport-track-owner` (`/root/transport_f0_review`) | `rtl/common/`, `rtl/bridge/`, `sim/common/`, transport build files, `status/transport.md` |
| `video-track-owner` (`/root/video_f0_review`) | `rtl/video/`, `assets/`, `scripts/build_assets.py`, `sim/video/`, `status/video.md` |
| `gameplay-track-owner` (`/root/gameplay_f0_review`) | `rtl/game/`, `rtl/audio/`, `sim/game/`, `status/gameplay.md` |
| `orchestration-integration-owner` (Codex current task) | `rtl/board_a_top.sv`, board/project build scripts, `config/`, `docs/hardware-manifest.md`, `docs/bringup-log.md`, `STATUS.md`, `status/integration.md` |

Role assignment is exclusive. Future implementation work must preserve these ownership boundaries.

## F0 review acknowledgements

| Consumer | Owner | Review | Evidence |
|---|---|---|---|
| Interface freeze | Codex current task | Complete | Protocol, types, vectors, stubs, ownership, and tests checked 2026-08-30 |
| Integration/top level | Codex current task | Complete | Structural top seam compiled and simulated 2026-08-30 |
| Swift/iOS encoder | `ios-track-owner` (Codex macOS task) | Complete | Commit `9e62763`; independent Swift 6.2.1 vector interpretation passed |
| Transport RTL | `/root/transport_f0_review` | Complete | Commit `7d10743`; accepted protocol `1.0`, package `0x0100`, vectors, and seam `1.0` without changes |
| Video RTL | `/root/video_f0_review` | Complete | Commit `0c6f9cd`; accepted video package `0x0100`, seam `1.0`, and snapshot contract without changes |
| Gameplay/audio RTL | `/root/gameplay_f0_review` | Complete | Commit `f27b234`; accepted protocol `1.0`, all packages `0x0100`, and seams `1.0` without changes |

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
| F0 interface freeze | **Passed** | Four consumer acceptances recorded; complete suite passed on merged review commit `2083519` |
| C1 BLE sensor path | Software complete; hardware pending | iOS `3aaf1fb` and transport `1b72824` accepted; physical two-minute run pending |
| C2 two-board path | Software complete; hardware pending | Transport `1b72824` accepted; physical two-board five-minute run pending |
| C3 video path | Software complete; hardware pending | Video `48890d9` accepted; Vivado timing and five-minute physical display run pending |
| G1 gameplay simulation | Software suite complete; validation pending | Gameplay `5cfb1df` accepted with 10/10 simulations; recorded motion and one-phone FPGA rally pending |
| C4 integrated game | Not started | — |

## F0 commands and results — 2026-08-30

| Exact command | Result |
|---|---|
| `git merge --no-edit origin/work/ios` | Pass; review commit `9e62763` already present |
| `git merge --no-edit origin/work/transport` | Pass; review commit `7d10743` merged |
| `git merge --no-edit origin/work/video` | Pass; review commit `0c6f9cd` merged |
| `git merge --no-edit origin/work/gameplay` | Pass; review commit `f27b234` merged |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_smoke.ps1` | Pass on merged `2083519`; 6 vectors, 21 Markdown files, package elaboration, and all 4 interface seams passed using Icarus Verilog 12.0 |
| `git diff --check` and `git diff origin/main..HEAD --check` | Pass; no whitespace errors |
| `git merge --ff-only origin/work/ios` | Pass; software implementation `3aaf1fb` and status `973d63e` merged |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_smoke.ps1` after iOS merge | Pass; 6 vectors, 22 Markdown files, package elaboration, and all 4 interface seams passed |
| `git merge --no-edit origin/work/transport` | Pass; transport software handoff `1b72824` fast-forwarded onto main |
| `wsl -e sh sim/common/run_transport_wsl.sh` after transport merge | Pass; UART/FIFO/CRC, all frozen vectors and rejection/recovery cases, health/stale/backpressure, dual-player RX, forwarding FIFO, and Board B full-duplex suites passed |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_smoke.ps1` after transport merge | Pass; 6 vectors, 22 Markdown files, package elaboration, and all 4 interface seams passed |
| `git merge --no-edit origin/work/video` | Pass; video software handoff `48890d9` merged |
| `powershell -NoProfile -ExecutionPolicy Bypass -File sim/video/run_video_tests.ps1` after video merge | Pass; 720p timing, components/priorities/ROMs, atomic snapshots, and complete 921,600-active-pixel scene passed |
| Transport regression plus `scripts/run_smoke.ps1` after video merge | Pass; prior transport handoff remained green and root smoke validated 6 vectors, 23 Markdown files, packages, and 4 seams |
| `git merge --no-edit origin/work/gameplay` | Pass; gameplay/audio software handoff `5cfb1df` merged |
| `powershell -NoProfile -ExecutionPolicy Bypass -File sim/game/run_game_tests.ps1` after gameplay merge | Pass; 10/10 swing, shot, physics, rally, scoring, deterministic engine, scripted opponent, mailbox, and audio simulations passed |
| Transport, video, gameplay, and root smoke regressions after gameplay merge | Pass together on merged `0d3df40`; no cross-track regression detected |

## Open issues and risks

- The wire field is named `sequence_number` in SystemVerilog because `sequence` is a reserved keyword; consumers must use the frozen name.
- No hardware was used. UUIDs, pins, board revisions, IP/tool versions, connector orientation, timing, delivery rates, and measurements remain unverified.
- Frozen-contract changes now require a versioned proposal, updated vectors/tests, and every affected-owner acknowledgement.
- C1 requires physical iPhone, BLE peripheral, and programmed-board evidence; simulator results do not satisfy it.

## Next action

Build structural Board A integration and reproducible simulation around transport `1b72824`, video `48890d9`, and gameplay `5cfb1df` without guessing hardware values. Keep C1/C2/C3/G1 open until their physical/recorded evidence is collected.
