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
