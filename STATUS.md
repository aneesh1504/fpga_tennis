# Global Implementation Status

This is the orchestration index, not a shared scratchpad. Only the orchestration/integration owner edits it. Track owners update their files under `status/`. Never replace unknowns with guesses.

## Current state

- Execution mode: Four parallel implementation tracks after F0
- Current gate: C1/C2/C3/G1 development in parallel
- Last completed gate/checkpoint: F0 interface freeze
- Overall status: All four software handoffs and first-pair iOS BLE evidence are merged; the Board A diagnostic image is programmed with startup HIGH, but live FPGA observations and the second pair still leave C1/C2/C3/G1 open
- Integration owner: Codex orchestration/integration owner (current task)
- Freeze base: `origin/main` at `b8f0578`; ancestry check passed 2026-08-30
- Freeze implementation commit: `8255a4c52125101f8c8d033766b490975a36ffa5`
- Reviewed merge before closure: `2083519`; closure commit is this commit and its exact SHA is recorded in the push receipt/final handoff

## Dependency board

| Work | State | Depends on | Detailed status |
|---|---|---|---|
| Interface freeze | Passed | All deliverables, reviews, and merged smoke tests passed | This file and `docs/00_interface_freeze.md` |
| iOS controller | First-pair phone/BLE path passed through CoreBluetooth | FPGA diagnostic counters and second phone/board pair | `status/ios.md` |
| Transport RTL | Software complete; hardware pending | C1/C2 physical evidence and Vivado implementation | `status/transport.md` |
| Video | Software complete; hardware pending | C3 Vivado/HDMI/monitor evidence | `status/video.md` |
| Gameplay | Software complete; validation pending | Recorded phone traces and one-phone FPGA rally for G1 | `status/gameplay.md` |
| Integration | Structural simulation passed | Formal C2 + C3 + G1 still gate full integration claims | `status/integration.md` |

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
| Vivado and locally generated IP versions | Vivado 2026.1 verified; generated project IP still unverified | Single-board probe 2026-08-31; `docs/hardware-manifest.md` |
| Boolean Board XDC source and board-fixed pins | Vendor source and clock/BLE/HDMI/audio pins recorded; physical revision compatibility unverified | `docs/hardware-manifest.md` |
| BLE names, UUIDs, and payload limits | First physical pair verified; exact values recorded in the hardware manifest | iOS physical evidence `1c1404c` |
| Board-to-board Pmod positions/wiring | Unverified | — |
| Monitor mode, clocks, delivery rates, and error measurements | Unverified | — |

## Gate and checkpoint record

| Gate/checkpoint | Status | Evidence summary |
|---|---|---|
| F0 interface freeze | **Passed** | Four consumer acceptances recorded; complete suite passed on merged review commit `2083519` |
| C1 BLE sensor path | **Not passed**; first-pair iPhone-to-BLE stream passed and diagnostic is programmed, FPGA receipt unverified | iOS through `1c1404c`; diagnostic build `03c53cc`; target `887235230329A` startup HIGH; observations and second pair pending |
| C2 two-board path | Software complete; hardware pending | Transport `1b72824` accepted; physical two-board five-minute run pending |
| C3 video path | Software complete; hardware pending | Video `48890d9` accepted; Vivado timing and five-minute physical display run pending |
| G1 gameplay simulation | Software suite complete; validation pending | Gameplay `5cfb1df` accepted with 10/10 simulations; recorded motion and one-phone FPGA rally pending |
| C4 integrated game | Structural software path passed; gate not passed | Serial transport-to-gameplay-to-video/audio simulation passed; hardware integration depends on C1/C2/C3/G1 evidence |

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

## Structural integration commands and results — 2026-08-31

| Exact command | Result |
|---|---|
| `powershell -NoProfile -ExecutionPolicy Bypass -File sim/integration/run_integration_tests.ps1` | Pass; serial protocol-v1 frames traversed UART transport and gameplay, then produced an atomic pixel-domain render snapshot, a non-black active video pixel, and audio activity |
| Concurrent launch of transport, video, gameplay, and root smoke commands | Transport and root smoke runners failed while both attempted to bootstrap the same local Icarus extraction; video and gameplay passed. This was a runner-resource race, not an HDL assertion or compilation failure |
| `wsl -e sh sim/common/run_transport_wsl.sh` (sequential rerun) | Pass; primitives, vectors/rejections, endpoint health/backpressure, dual receive chains, forwarding, and Board B full-duplex passed |
| `powershell -NoProfile -ExecutionPolicy Bypass -File sim/video/run_video_tests.ps1` | Pass; deterministic memories, timing, components, snapshots, and full 1280x720 scene passed |
| `powershell -NoProfile -ExecutionPolicy Bypass -File sim/game/run_game_tests.ps1` | Pass; 10/10 self-checking gameplay/audio simulations passed |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_smoke.ps1` (sequential rerun) | Pass; 6 vectors, local links in 23 Markdown files, shared packages, and all four frozen seams passed |

## C1 diagnostic commands and results — 2026-09-01

| Exact command | Result |
|---|---|
| `git fetch --all --prune` followed by ancestry checks | Pass; `origin/work/ios` through `1c1404c878c2db6fcfbe2e743f86acef1fe6a710` is merged into `main`; no later iOS rerun commit was present |
| `Get-FileHash -Algorithm SHA256 $env:LOCALAPPDATA\fpga_tennis_vivado\board_a_transport_bringup\board_a_transport_bringup.bit` | Pass; `193a255ecb25f3ad97c225c2a05859670558067e189e8aae8be314dcf59254a1` |
| `C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat -mode batch -nolog -nojournal -notrace -source scripts/program_board_a_transport_bringup.tcl` | Blocked before programming; Vivado reported no matching hardware targets on `localhost` |
| `C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat -mode batch -nolog -nojournal -notrace -source scripts/build_board_a_transport_diagnostic.tcl` | Pass from build commit `03c53ccbb0a8a005daf6c142ca1514fcbbc23edd`; DRC 0 errors/critical warnings; timing closed at WNS `3.355 ns`, WHS `0.156 ns`; 504 LUTs, 481 registers, 0 BRAM, 0 DSP; bitstream SHA-256 `2b5e19b4e7b8ef81901b300152943d32b5e0e43db9a6b473f9f046c8d7a7d12b` |
| `C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat -mode batch -nolog -nojournal -notrace -source scripts/program_board_a_transport_diagnostic.tcl` | Blocked before programming; Vivado reported no matching hardware targets on `localhost`; no startup or LED observation was possible |
| Same diagnostic programming command, retried at 2026-09-01 14:40 local time after reconnect | Pass; selected exactly `localhost:3121/xilinx_tcf/Xilinx/887235230329A` and `xc7s50_0`; Vivado reported startup status HIGH and `DIAGNOSTIC_PROGRAM_PASS` |
| `wsl -e sh sim/common/run_transport_wsl.sh` (sequential rerun after a known concurrent bootstrap race) | Pass; UART/FIFO/CRC primitives, all vectors and rejection/recovery behavior, health/backpressure, dual receive, forwarding, and Board B full-duplex passed |
| `powershell -NoProfile -ExecutionPolicy Bypass -File sim/integration/run_integration_tests.ps1` | Pass; serial transport-to-gameplay-to-video/audio structural integration passed |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_smoke.ps1` (sequential rerun) | Pass; 6 vectors, links in 23 Markdown files, shared packages, and all four frozen seams passed |

## Open issues and risks

- The wire field is named `sequence_number` in SystemVerilog because `sequence` is a reserved keyword; consumers must use the frozen name.
- First-pair iPhone/BLE GATT and phone-side delivery are verified at `1c1404c`; FPGA receipt, PCB revision, and the second pair remain unverified.
- Frozen-contract changes now require a versioned proposal, updated vectors/tests, and every affected-owner acknowledgement.
- C1 requires physical iPhone, BLE peripheral, and programmed-board evidence; simulator results do not satisfy it.
- The shared local Icarus bootstrap is not safe for first-use concurrent test launches; initialize it once or run WSL-backed suites sequentially.
- `board_a_system` is a simulation-verified structural integration module. It is not a board bitstream top and contains no guessed clock, reset, UART, HDMI, audio, or connector pin assignments.
- The official constraints source does not select this project's board-to-board Pmod ports; connector choice, header position, pin mapping, orientation, and continuity must be verified before wiring.
- One connected `xc7s50` was discovered over JTAG without programming. Board B OOC synthesis is clean after transport fix `3ad7049`; Board A synthesis is clean after gameplay fix `4a17360`, but preliminary Board A OOC timing fails with WNS `-14.368 ns`, so no timing or hardware gate is passed.
- A constrained transport-only Board A bitstream from `d457063` implemented with WNS `4.487 ns`, DRC 0 errors/critical warnings, and programmed successfully. This is bring-up evidence only; it does not close C1 or supersede the failing full-system preliminary timing result.
- The integration diagnostic image from `03c53cc` closes timing and exposes reset, raw UART, decoded frames, sequence, calibration/stale state, and all required error counters. It was programmed successfully on target `887235230329A` with startup HIGH after the target was reconnected; its LED/seven-segment observation path and live counters still require physical observation.

## Next action

Keep target `887235230329A` continuously powered, execute the exact observation procedure in `status/integration.md`, and commit the resulting FPGA counters on `origin/work/ios`. Then repeat on the required second phone/board pair. Keep C1 open until both requirements pass.
