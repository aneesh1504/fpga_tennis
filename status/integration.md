# Integration Status

- Owner: Codex orchestration/integration owner (current task)
- State: First-pair iOS BLE evidence is merged; the timing-clean Board A diagnostic is programmed and configuration/reset indicators pass; live FPGA counters and the second pair still block C1
- Track document: `docs/06_integration.md`
- Structural integration commit: This commit; exact resulting SHA is recorded in the push receipt/final handoff because a commit cannot embed its own SHA

## Accepted handoffs

| Track/gate | Commit | Evidence reviewed | Accepted |
|---|---|---|---|
| F0 interface freeze | Freeze `8255a4c`; reviews `9e62763`, `7d10743`, `0c6f9cd`, `f27b234`; merged `2083519` | All four consumers accepted without changes; complete merged smoke suite passed | Yes |
| iOS/C1 | Software `3aaf1fb`; device `d4adcac`; BLE evidence `c0d7c6e`, `1c1404c` | Physical build/install/launch, Core Motion calibration, verified GATT, acknowledged write, and 120.007-second 6,033-frame phone-to-BLE run passed with zero local drops; FPGA receipt and second pair pending | First-pair phone/BLE accepted; C1 No |
| Transport/C2 | Software handoff `1b72824` | Complete transport regression passed after merge: frozen vectors/rejections, sequence/stale/backpressure, dual-player RX, forwarding FIFO, and Board B simultaneous full-duplex; physical BLE/boards, XDC, Vivado/timing, and five-minute counters pending | Software accepted; C2 No |
| Video/C3 | Software handoff `48890d9` | Deterministic assets, timing/components/atomic-snapshot tests, and complete 720p active-frame scene passed after merge; Vivado/HDMI/XDC/clocks/timing/utilization/monitor and five-minute stability evidence pending | Software accepted; C3 No |
| Gameplay/G1 | Software handoff `5cfb1df` | 10/10 deterministic simulations passed after merge: swing/shot/physics/rules, replay, scripted opponent rally, mailbox, and audio; recorded phone traces and real one-phone FPGA rally pending | Software accepted; G1 No |
| iOS physical device | `d4adcac` | Signed physical iPhone 17 build, installation, launch, real Core Motion sampling, and neutral calibration passed; 14/14 physical tests passed | Device motion accepted; BLE/C1 No |

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
| `orchestration-integration-owner` (Codex current task) | `rtl/board_a_top.sv`, `rtl/board_a_system.sv`, `sim/integration/`, board/project build scripts, `config/`, hardware/bring-up docs, `STATUS.md`, this file |

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
| `git merge --no-edit origin/work/transport` | Pass; software handoff `1b72824` fast-forwarded onto main |
| `wsl -e sh sim/common/run_transport_wsl.sh` after transport handoff | Pass with Icarus 12.0/Python 3.12.3: all transport primitive, decoder, health, dual-player, forwarder, and full-duplex tests passed |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_smoke.ps1` after transport handoff | Pass: 6 vectors; 22 Markdown files; packages compile/elaborate; all four frozen seams pass |
| `git merge --no-edit origin/work/video` | Pass; software handoff `48890d9` merged without ownership conflicts |
| `powershell -NoProfile -ExecutionPolicy Bypass -File sim/video/run_video_tests.ps1` after video handoff | Pass with Icarus 12.0: nominal frame timing, layer/component priority, atomic old/new snapshots, and full procedural scene passed |
| Transport regression and `scripts/run_smoke.ps1` after video handoff | Pass: transport suite remained green; root smoke validated 6 vectors, 23 Markdown files, packages, and all frozen seams |
| `git merge --no-edit origin/work/gameplay` | Pass; software handoff `5cfb1df` merged without ownership conflicts |
| `powershell -NoProfile -ExecutionPolicy Bypass -File sim/game/run_game_tests.ps1` after gameplay handoff | Pass with Icarus 12.0: all 10 deterministic gameplay/audio simulations passed |
| Transport + video + gameplay + root smoke after gameplay handoff | Pass together on merged `0d3df40`; all accepted software remained green |
| `powershell -NoProfile -ExecutionPolicy Bypass -File sim/integration/run_integration_tests.ps1` | Pass 2026-08-31; four calibrated protocol-v1 UART frames traversed transport and gameplay and produced atomic pixel snapshot, active video, 60 Hz game tick, and audio evidence |
| Concurrent transport + video + gameplay + root smoke launch | Video and gameplay passed; transport and root smoke failed only because both first-use WSL runners extracted the same local Icarus files concurrently. No RTL compilation/assertion failure was reported |
| `wsl -e sh sim/common/run_transport_wsl.sh` (sequential rerun) | Pass 2026-08-31; complete transport suite passed |
| `powershell -NoProfile -ExecutionPolicy Bypass -File sim/video/run_video_tests.ps1` | Pass 2026-08-31; all video elaboration and behavioral regressions passed |
| `powershell -NoProfile -ExecutionPolicy Bypass -File sim/game/run_game_tests.ps1` | Pass 2026-08-31; all 10 gameplay/audio simulations passed |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_smoke.ps1` (sequential rerun) | Pass 2026-08-31; vectors, local Markdown links, packages, and four interface seams passed |
| `git merge --no-edit origin/work/ios` | Pass; physical-device commit `d4adcac` merged and ancestry verified |
| `C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat -mode batch -nolog -nojournal -notrace -source scripts/build_board_a_transport_bringup.tcl` | Pass from build commit `d457063`; routed timing WNS `4.487 ns`, TNS `0`, WHS `0.116 ns`, THS `0`; DRC 0 errors/critical warnings; bitstream SHA-256 `193a255ecb25f3ad97c225c2a05859670558067e189e8aae8be314dcf59254a1` |
| `C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat -mode batch -nolog -nojournal -notrace -source scripts/program_board_a_transport_bringup.tcl` | Pass; exactly one target `887235230329A`, device `xc7s50_0`, startup status HIGH |

Hardware evidence is limited to the explicitly recorded sessions. The earlier transport image and the current diagnostic image were programmed successfully; live LED/seven-segment observations remain pending.

## C1 FPGA diagnostic — 2026-09-01

- Current integration diagnostic source/build commit: `52c815053e0942e1279bb52a4c49c7db39f209a1`; supersedes initial diagnostic build `03c53cc` by latching receipt of probe byte `0x41` independently of the following `0x0A` terminator.
- Top/constraints: `board_a_transport_diagnostic_top` and `config/board_a_transport_diagnostic.xdc`; only vendor-recorded clock, BTN0, BLE RX, switches, discrete LEDs, and onboard seven-segment pins are applied. No Pmod mapping or BLE UUID is encoded in the FPGA image.
- Reset review: `reset_sync` accepts an asynchronous active-low reset and synchronously releases it after two clock edges. The top supplies `~btn_reset`; vendor documentation says the pushbutton is normally low/high when pressed, so release deasserts reset. This source/constraint review is internally consistent but is not a substitute for a live observation.
- LED review: vendor documentation identifies the discrete LEDs as active high; LED 0 is constrained to package pin `G1`. LED 15 is driven constantly high as a configuration/polarity witness independent of reset. A powered, programmed board is required to distinguish lost volatile configuration from reset or observation faults.
- Build command: `C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat -mode batch -nolog -nojournal -notrace -source scripts/build_board_a_transport_diagnostic.tcl`.
- Current build result: pass; DRC 0 errors and 0 critical warnings, timing closed at WNS `3.356 ns` and WHS `0.159 ns`; utilization 504 Slice LUTs, 482 Slice registers, 0 BRAM, and 0 DSP.
- Current bitstream: `%LOCALAPPDATA%\fpga_tennis_vivado\board_a_transport_diagnostic\board_a_transport_diagnostic.bit`; SHA-256 `ac3d2952b688aae4f9983038abcd706e380ff171fd5b72de97dd7192e2dfc67f`.
- Programming command: `C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat -mode batch -nolog -nojournal -notrace -source scripts/program_board_a_transport_diagnostic.tcl`.
- Initial programming attempt: blocked before programming because no target was enumerated.
- Programming retry at 2026-09-01 14:40 local time: pass. Windows enumerated FTDI serial `887235230329` and `COM4`; Vivado selected exactly `localhost:3121/xilinx_tcf/Xilinx/887235230329A` and `xc7s50_0`, reported `End of startup status: HIGH`, and emitted `DIAGNOSTIC_PROGRAM_PASS`. The interfaces remained enumerated after programming, establishing that the board was powered at that observation instant. Continuous power and the LED/seven-segment path require visual confirmation.
- Physical observation after programming: LED15 and LED0 were both illuminated. This accepts the constant configuration/active-high witness and reset-deasserted indicator; no BTN0 intervention was required. Raw UART and decoded-frame observations remain pending.
- Corrected diagnostic programming at 2026-09-01 14:51 local time: pass on exactly `887235230329A`/`xc7s50_0`, startup status HIGH. Configuration/reset indicators must be re-observed because reprogramming resets their state.
- Windows BLE probe command: set `PYTHONPATH` to the isolated directory populated by `python -m pip install --target %LOCALAPPDATA%\fpga_tennis_tools\bleak -r scripts/requirements-ble-diagnostic.txt`, then run `python scripts/run_ble_diagnostic_probe.py`. The first scan found zero `RD_BOOL_88723523033D` advertisements, so no GATT connection or write occurred. This is consistent with the peripheral being connected or non-advertising but does not establish which; retry when it advertises.
- Post-build regressions: `wsl -e sh sim/common/run_transport_wsl.sh`, `powershell -NoProfile -ExecutionPolicy Bypass -File sim/integration/run_integration_tests.ps1`, and `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_smoke.ps1` all passed on sequential rerun. The root smoke run also validated all local Markdown links in 23 files. An initial concurrent transport/root-smoke launch hit the already-recorded shared Icarus extraction race and was not an HDL failure.

### Ready-for-iOS procedure

1. Keep the currently programmed board whose JTAG target is `887235230329A` continuously powered through the entire run; do not unplug or power-cycle it.
2. Programming already passed with exactly `887235230329A`, `xc7s50_0`, and startup HIGH. If power is interrupted, rerun the diagnostic programming command above and require the same result before proceeding.
3. Before BLE traffic, record LED 15 and LED 0. Both must be on. If LED 15 is off, stop because configuration/power/active-high observation is not established. If LED 15 is on and LED 0 is off, press and release BTN0 once and record both states; stop if LED 0 does not illuminate after release.
4. Set `SW[2:0]=001`. Send the acknowledged probe bytes `41 0A`. Record LED 1 changing state, LED 2 latched on to confirm receipt of `0x41`, and seven-segment last-byte value `0000000A`. Then set `SW[2:0]=000` and record a nonzero raw-byte count. These observations establish the BLE-to-FPGA UART path; a BLE-module activity LED alone does not.
5. Select Player 1, calibrate, and run the same 50 Hz protocol-v1 stream for at least 120 seconds without power-cycling. Record LEDs 3 through 13 and photograph/transcribe each seven-segment selection: `000` raw byte count, `010` decoded frame count, `011` last sequence, `100` CRC errors, `101` framing errors, `110` sequence gaps, and `111` FIFO overflows.
6. Acceptance for this rerun requires decoded frame count to advance throughout the run, last sequence to track the phone, calibrated asserted, stale deasserted while streaming, and CRC/framing/sequence-gap/overflow counters all zero. Record exact values and duration in `status/ios.md` on `origin/work/ios`; do not summarize them as merely “working.”
7. Repeat the complete procedure on the required second independently identified phone/board pair. C1 remains open until both pairs satisfy the checkpoint.

## Open cross-track requests

| Request | Target | Requested action | Relevant commit/interface | Gate impact | State |
|---|---|---|---|---|---|
| `IOS-REQ-001` | `ios-track-owner` on `origin/work/ios` | Execute the exact diagnostic procedure above and record the first-pair FPGA counters, then repeat on the required second phone/board pair. Respond only in `status/ios.md`; do not infer absent values. | iOS through `1c1404c`; diagnostic `52c8150`; protocol `1.0` / wire `0x01` | Blocks C1; does not block C3 or G1 | GATT and first-pair phone-to-BLE delivery complete; FPGA counters and second pair pending |

Any future contract change must use the versioned frozen-contract process; do not patch around the contract in `rtl/board_a_top.sv`.

## Risks/blockers

- First-pair BLE UUIDs, writable/notify properties, payload limits, and phone-side delivery are verified. FPGA receipt, physical PCB revision, Pmod positions, generated video IP, monitor mode, and the second pair remain unverified.
- Full integration remains blocked on accepted C2, C3, and G1 handoffs.
- `IOS-REQ-001` remains open specifically for live FPGA counters and the required second pair; the first-pair iPhone/BLE evidence is accepted.
- The registered iPhone 13 was unavailable to Xcode during readiness check `3297905`; no GATT or delivery evidence could be collected.
- Video software timing uses nominal 1650-by-750 totals; vendor HDMI reference compatibility, actual clocks, timing closure, and monitor behavior remain unverified.
- Gameplay thresholds/constants use synthetic traces; recorded multi-user motion classification and a real one-phone FPGA rally remain required before G1.
- The local Icarus first-use bootstrap races if multiple WSL-backed suites launch concurrently; initialize once or run those commands sequentially.
- The integrated structural module has no board pin, PLL/MMCM, HDMI vendor IP, or project constraints because those facts remain unverified; it is not yet a bitstream-ready top.
- Vendor-source review recorded the design target and fixed clock/BLE/HDMI/audio pins, but not physical board revision compatibility or any Pmod selection. Vivado is installed outside `PATH` at `C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat`.
- Update 2026-08-31: Vivado 2026.1 was located and one connected JTAG target `887235230329A` with one `xc7s50` was read-only probed. Transport handoff `ec86e08` and gameplay handoff `5921501` clear their Vivado synthesis defects. Board A preliminary OOC timing remains failing at WNS `-14.368 ns`; no bitstream or hardware gate is claimed.
- Physical iPhone handoff `d4adcac` accepted: build, installation, launch, Core Motion sampling, calibration, and 14/14 physical tests passed; BLE remains unverified.
- Transport bring-up build `d457063` used the official clock/button/BLE-RX/LED constraints only. Implementation passed at WNS `4.487 ns` with no DRC errors or critical warnings, and programming target `887235230329A`/`xc7s50_0` passed. PCB revision, UUIDs, BLE reception, and C1 remain unverified.

## Next action

Keep target `887235230329A` powered and execute the exact ready-for-iOS observation procedure above. Poll `origin/work/ios:status/ios.md` after that rerun and merge only measured evidence. Do not pass C1 until the FPGA counters and second pair meet the checkpoint.
