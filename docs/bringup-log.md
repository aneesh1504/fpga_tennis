# Hardware Bring-up Log

## 2026-08-30 — F0 interface freeze

- Operator: Codex orchestration/interface-freeze owner.
- Hardware used: None.
- Hardware programmed: No.
- Physical wiring performed: No.
- Measurements collected: None.
- Result: Repository contracts and simulation scaffolding prepared; hardware claims remain unverified.

### Required future evidence

- Record the authoritative Boolean Board XDC source before entering pin assignments.
- Record BLE service and characteristic UUID observations from the physical module; do not infer them from similar products.
- Record the installed Vivado, Clocking Wizard, and HDMI/vendor IP versions.
- Record board revisions, Pmod connector/pin mapping, crossing, ground, and a pre-power continuity check.
- Record measured BLE payload limit, sustained delivery, UART link error counts, video mode/timing, and audio behavior with dates and commands/instruments.

## 2026-08-31 — Authoritative source inventory

- Operator: Codex orchestration/integration owner.
- Hardware used/programmed/wired: None.
- Installed Vivado: Not found on `PATH`; version remains unverified.
- Reviewed the Real Digital Boolean Board product page, reference manual, first-project guide, official constraints download, and the RealDigitalOrg Vivado IP repository.
- Recorded the documented design target `xc7s50csga324-1`, 100 MHz oscillator on `F14`, onboard BLE UART pin/baud facts, HDMI pins, audio pins/circuit description, and upstream HDMI core identity in `docs/hardware-manifest.md`.
- Computed SHA-256 `4ad1c2f9a5f08219b03914ae65b44e4f0382c0aa8c0f35bd4a0513b8e1c2a6d3` over the downloaded official constraints bytes.
- Did not select Pmod pins, infer connector orientation, populate project XDC files, generate IP, synthesize, implement, program hardware, or collect measurements.
- Result: Board-fixed vendor facts are source-verified; physical revision compatibility and all physical gates remain open.

## 2026-08-31 — Single-board JTAG and Vivado validation

- Exactly one physical board was connected; no two-board test was attempted.
- Windows enumerated FTDI serial `887235230329` and USB UART `COM4`.
- Vivado 2026.1 Hardware Manager discovered one target, `887235230329A`, containing one `xc7s50` device; the probe did not program or reset it.
- Board B out-of-context synthesis exposed and then cleared a FIFO RAM-inference warning through transport-owner fix `3ad7049`; final handoff `ec86e08` reported 0 errors/critical warnings/warnings and positive preliminary 100 MHz slack.
- Board A out-of-context synthesis exposed and then cleared an enum typing error through gameplay-owner fix `4a17360`; final handoff `5921501` synthesized with 0 errors and 0 critical warnings.
- Board A preliminary out-of-context timing is not closed: WNS `-14.368 ns`, TNS `-677.425 ns`. This is a failure requiring further constraint/path analysis; it is not C3 evidence.
- No XDC was applied, no IP generated, no bitstream built or programmed, and no physical BLE/video/audio measurement was taken.

## 2026-08-31 — Board A BLE transport image build and programming

- Exactly one connected board was used and assigned the logical Board A role for this bring-up only; PCB revision remains visually unverified.
- Accepted iOS physical-device handoff `d4adcac`: signed build, installation, launch, Core Motion sample delivery, calibration, and 14/14 physical tests passed. No BLE evidence was included.
- Build commit: `d457063a5d73834767cd37fd96dc79568fa8ee6a`.
- Exact build command: `C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat -mode batch -nolog -nojournal -notrace -source scripts/build_board_a_transport_bringup.tcl`.
- Configuration: `board_a_transport_bringup_top`, target `xc7s50csga324-1`, 100 MHz clock, 115,200-baud Player 1 BLE UART receiver, button reset, and LED health/gyro display. No Pmod pins or UUIDs are present.
- Constraint source: `config/board_a_transport_bringup.xdc`, copied from the recorded official Real Digital constraint source.
- Implementation passed with DRC 0 errors, 0 critical warnings, WNS `4.487 ns`, TNS `0`, WHS `0.116 ns`, THS `0`; utilization 290 LUTs, 357 registers, 0 BRAM, 0 DSP.
- Generated bitstream SHA-256: `193a255ecb25f3ad97c225c2a05859670558067e189e8aae8be314dcf59254a1`.
- Exact programming command: `C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat -mode batch -nolog -nojournal -notrace -source scripts/program_board_a_transport_bringup.tcl`.
- Programming passed on target `887235230329A`, device `xc7s50_0`; Vivado reported startup status HIGH.
- Remaining: visually verify PCB revision, discover GATT UUIDs/properties, observe LED behavior, and run the one-byte and two-minute BLE delivery tests. C1 is not passed.

## 2026-09-01 — First-pair BLE run and FPGA diagnostic build

- Accepted iOS evidence through `1c1404c`: the physical iPhone verified the advertised name and GATT characteristics, acknowledged `41 0A`, and handed 6,033/6,033 frames to CoreBluetooth over 120.007 seconds at 50.272 Hz with zero local drops. The BLE module activity LED responded, but no FPGA LED was observed; this does not prove FPGA receipt.
- Reverified the prior transport image at `%LOCALAPPDATA%\fpga_tennis_vivado\board_a_transport_bringup\board_a_transport_bringup.bit`; SHA-256 remained `193a255ecb25f3ad97c225c2a05859670558067e189e8aae8be314dcf59254a1`.
- The attempt to reprogram that image was blocked before programming because Vivado found no hardware target on `localhost`; `887235230329A` was not enumerated.
- Source review found reset and LED polarity internally consistent with the vendor documentation and applied constraints: BTN0 is inverted into the active-low synchronizer reset, released reset is synchronized for two clocks, and the discrete LEDs are active high. A live board is required to establish whether the prior no-LED observation resulted from lost volatile programming, power, reset, or another physical condition.
- Diagnostic source/build commit: `03c53ccbb0a8a005daf6c142ca1514fcbbc23edd`; top `board_a_transport_diagnostic_top`; target `xc7s50csga324-1`.
- Exact build command: `C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat -mode batch -nolog -nojournal -notrace -source scripts/build_board_a_transport_diagnostic.tcl`.
- Build passed with DRC 0 errors/critical warnings and closed timing: WNS `3.355 ns`, WHS `0.156 ns`; utilization 504 LUTs, 481 registers, 0 BRAM, 0 DSP.
- Diagnostic bitstream: `%LOCALAPPDATA%\fpga_tennis_vivado\board_a_transport_diagnostic\board_a_transport_diagnostic.bit`; SHA-256 `2b5e19b4e7b8ef81901b300152943d32b5e0e43db9a6b473f9f046c8d7a7d12b`.
- Exact programming command: `C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat -mode batch -nolog -nojournal -notrace -source scripts/program_board_a_transport_diagnostic.tcl`.
- Programming was blocked before touching a device: Vivado reported no matching targets. Startup HIGH, continuous FPGA power, PCB revision, LED behavior, and the diagnostic observation path remain physically unverified.
- C1 is not passed. Required next physical evidence is specified exactly in `status/integration.md`, followed by an independent second phone/board pair.
