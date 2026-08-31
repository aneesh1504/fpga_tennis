# Hardware Manifest

This manifest intentionally contains no inferred hardware values. An item moves from **Unverified** only when its authoritative source or observed evidence is recorded.

| Item | Value | Verification state | Evidence |
|---|---|---|---|
| Board model | Real Digital Boolean Board | Project decision; physical revision unverified | `plan.md` |
| FPGA part/design target | `xc7s50csga324-1` | Vendor documentation verified; installed part not physically rechecked | [Real Digital first-project guide](https://www.realdigital.org/doc/c4ceeb20d229e5f3d4e32f3a74e343e9) |
| Board A identifier/serial | Unverified | Unverified | — |
| Board B identifier/serial | Unverified | Unverified | — |
| Vivado version | Unverified | Unverified | — |
| Boolean Board XDC source | Real Digital download `8d5c167add28c014173edcf51db78bb9.txt`; SHA-256 `4ad1c2f9a5f08219b03914ae65b44e4f0382c0aa8c0f35bd4a0513b8e1c2a6d3` | Vendor-source file verified 2026-08-31; physical-board revision compatibility unverified | [Real Digital Boolean constraints file](https://www.realdigital.org/downloads/8d5c167add28c014173edcf51db78bb9.txt) |
| BLE advertised device name | Unverified | Unverified | — |
| BLE service UUID | Unverified | Unverified | — |
| Phone-to-board writable characteristic UUID | Unverified | Unverified | — |
| Board-to-phone notify characteristic UUID | Unverified | Unverified | — |
| Maximum BLE write-without-response length | Unverified | Unverified | — |
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
| Measured BLE delivery rate/loss | Unverified | Unverified | — |
| Measured board-to-board error rate | Unverified | Unverified | — |

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
