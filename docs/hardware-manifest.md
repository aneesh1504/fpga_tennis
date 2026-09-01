# Hardware Manifest

This manifest intentionally contains no inferred hardware values. An item moves from **Unverified** only when its authoritative source or observed evidence is recorded.

| Item | Value | Verification state | Evidence |
|---|---|---|---|
| Board model | Real Digital Boolean Board | Project decision; physical revision unverified | `plan.md` |
| FPGA part/design target | `xc7s50csga324-1` | Vendor documentation verified; installed part not physically rechecked | [Real Digital first-project guide](https://www.realdigital.org/doc/c4ceeb20d229e5f3d4e32f3a74e343e9) |
| Connected board cable identifier | FTDI/JTAG target `887235230329A`; Windows FTDI serial `887235230329`; UART `COM4` | Observed on one connected board 2026-08-31; board PCB revision and role as Board A/B unverified | Vivado Hardware Manager and Windows PnP enumeration |
| Board A identifier/serial | Unassigned | One physical board detected, but its eventual A/B role and PCB revision remain unverified | — |
| Board B identifier/serial | Unverified | Unverified | — |
| Vivado version | 2026.1, SW build 6511674, IP build 6504888 | Verified on this Windows host 2026-08-31 | `scripts/run_vivado_validation.ps1 -Mode Probe` |
| Boolean Board XDC source | Real Digital download `8d5c167add28c014173edcf51db78bb9.txt`; SHA-256 `4ad1c2f9a5f08219b03914ae65b44e4f0382c0aa8c0f35bd4a0513b8e1c2a6d3` | Vendor-source file verified 2026-08-31; physical-board revision compatibility unverified | [Real Digital Boolean constraints file](https://www.realdigital.org/downloads/8d5c167add28c014173edcf51db78bb9.txt) |
| BLE advertised device name | `RD_BOOL_88723523033D` | Verified on first physical pair 2026-09-01 | iOS evidence `1c1404c` |
| BLE service UUID | `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` | Verified on first physical pair 2026-09-01 | iOS evidence `1c1404c` |
| Phone-to-board writable characteristic UUID | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`; `writeWithoutResponse`, `write` | Verified on first physical pair 2026-09-01 | iOS evidence `1c1404c` |
| Board-to-phone notify characteristic UUID | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`; `notify` | Verified on first physical pair 2026-09-01 | iOS evidence `1c1404c` |
| Maximum BLE write length reported by iOS | 244 bytes without response; 512 bytes with response | Verified on first physical pair 2026-09-01 | iOS evidence `1c1404c` |
| Board A Pmod TX/RX/GND pins and connector positions | Unverified | Unverified | — |
| Board B Pmod TX/RX/GND pins and connector positions | Unverified | Unverified | — |
| Onboard BLE-to-FPGA UART | 115,200 baud; newline-terminated module packets up to 256 bytes | Vendor documentation verified; physical operation unverified | [Real Digital reference manual](https://www.realdigital.org/doc/02013cd17602c8af749f00561f88ae21) |
| UART electrical standard | `LVCMOS33` for vendor-constrained onboard BLE pins | Vendor XDC verified; physical voltage measurement and Pmod selection unverified | Real Digital constraints file above |
| VGA-to-HDMI board/path revision | Unverified | Unverified | — |
| Clocking Wizard configuration/version | Unverified | Unverified | — |
| HDMI/vendor IP upstream source | `realdigital.org:realdigital:hdmi_tx:1.1`, RealDigitalOrg/VivadoIP commit `4e11eaa2e049959d3da1ca34acaec6d25af54e99` | Upstream source identity verified 2026-08-31; installed/generated IP and Vivado compatibility unverified | [Real Digital Vivado IP repository](https://github.com/RealDigitalOrg/VivadoIP) |
| Audio output circuit | Two AC-coupled amplifier/filter channels, documented 50 Hz–5 kHz for square/PWM/PDM signals | Vendor documentation verified; physical response/level unmeasured | [Real Digital reference manual](https://www.realdigital.org/doc/02013cd17602c8af749f00561f88ae21) |
| Tested monitor and accepted mode | Unverified | Unverified | — |
| Measured pixel clock | Unverified | Unverified | — |
| Measured BLE delivery rate/loss | Phone handed 6,033/6,033 frames to CoreBluetooth in 120.007 s at 50.272 Hz, 0 local drops; FPGA receipt unverified | First-pair phone/BLE boundary verified 2026-09-01; not an FPGA-path measurement | iOS evidence `1c1404c` |
| Measured board-to-board error rate | Unverified | Unverified | — |

## Programmed bring-up configuration — 2026-08-31

| Item | Verified value | Evidence |
|---|---|---|
| Logical role for this session | Board A BLE/transport bring-up | `docs/bringup-log.md` |
| Build commit | `d457063a5d73834767cd37fd96dc79568fa8ee6a` | Clean committed source used by Vivado |
| Top | `board_a_transport_bringup_top` | `rtl/board_a_transport_bringup_top.sv` |
| FPGA target | `xc7s50csga324-1`; JTAG reported `xc7s50_0` | Vivado 2026.1 build and Hardware Manager |
| Applied constraints | `config/board_a_transport_bringup.xdc`; clock `F14`, reset button `J2`, BLE RX `F5`, LEDs `G1/G2/F1/F2/E1/E2/E3/E5/E6/C3/B2/A2/B3/A3/B4/A4` | Real Digital XDC source recorded above |
| Bitstream SHA-256 | `193a255ecb25f3ad97c225c2a05859670558067e189e8aae8be314dcf59254a1` | Local generated bitstream |
| Implementation timing | WNS `4.487 ns`; TNS `0`; WHS `0.116 ns`; THS `0` | Vivado timing summary |
| Utilization | 290 Slice LUTs; 357 Slice registers; 0 BRAM; 0 DSP | Vivado utilization report |
| Programming result | Pass; startup status HIGH | Vivado Hardware Manager |

The PCB revision is not exposed by the JTAG device record and was not visually confirmed. The first-pair GATT interface and phone-to-BLE delivery are verified at `1c1404c`; BLE-to-FPGA UART receipt remains unverified.

## Board A diagnostic configuration — 2026-09-01

| Item | Verified value | Evidence |
|---|---|---|
| Build commit | `03c53ccbb0a8a005daf6c142ca1514fcbbc23edd` | Clean committed diagnostic source used by Vivado |
| Top | `board_a_transport_diagnostic_top` | `rtl/board_a_transport_diagnostic_top.sv` |
| FPGA target | `xc7s50csga324-1` | Vivado implementation target; no live JTAG device was present for programming |
| Applied constraints | `config/board_a_transport_diagnostic.xdc`; vendor-recorded clock, BTN0, BLE RX, switches, LEDs, and seven-segment pins only | Constraint file and recorded Real Digital source |
| Bitstream SHA-256 | `2b5e19b4e7b8ef81901b300152943d32b5e0e43db9a6b473f9f046c8d7a7d12b` | Local generated bitstream |
| Implementation timing | WNS `3.355 ns`; WHS `0.156 ns`; timing closed | Vivado timing summary |
| Utilization | 504 Slice LUTs; 481 Slice registers; 0 BRAM; 0 DSP | Vivado utilization report |
| Programming result | Not programmed; no matching JTAG target on `localhost` | Vivado Hardware Manager attempt 2026-09-01 |

The diagnostic image does not verify the physical PCB revision. It encodes no Pmod connector mapping and no BLE UUID. Its LEDs and seven-segment path remain unverified until the board is reconnected, programmed, and observed.

## Vendor-source pin record

These are board-fixed package pins copied from the vendor constraints source. They are not proof of the revision installed on either physical board, and they do not select a Pmod connector.

| Function | FPGA package pin(s) | I/O standard | Verification boundary |
|---|---|---|---|
| 100 MHz oscillator input | `F14` | `LVCMOS33` | Pin from vendor XDC; frequency from vendor reference manual; physical clock unmeasured |
| BLE UART FPGA output / module RX | `G5` (`ble_uart_tx`) | `LVCMOS33` | Vendor XDC only |
| BLE UART FPGA input / module TX | `F5` (`ble_uart_rx`) | `LVCMOS33` | Vendor XDC only |
| BLE UART RTS / CTS | `H6` / `G6` | `LVCMOS33` | Vendor XDC only; required flow-control behavior unverified |
| HDMI clock N/P | `T14` / `R14` | `TMDS_33` | Vendor XDC only |
| HDMI data N `[0:2]` | `T15`, `R17`, `P16` | `TMDS_33` | Vendor XDC only |
| HDMI data P `[0:2]` | `R15`, `R16`, `N15` | `TMDS_33` | Vendor XDC only |
| Left/right audio | `N13` / `N14` | `LVCMOS33` | Vendor XDC only; physical polarity/level unmeasured |

The intended board-to-board logical connection is UART TX to RX, RX to TX, and common ground. Exact Pmod connector locations, header positions, pins, and physical orientation remain unverified; do not wire hardware from this document. Do not connect supply rails between independently powered boards.
