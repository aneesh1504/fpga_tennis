# Hardware Manifest

This manifest intentionally contains no inferred hardware values. An item moves from **Unverified** only when its authoritative source or observed evidence is recorded.

| Item | Value | Verification state | Evidence |
|---|---|---|---|
| Board model | Real Digital Boolean Board | Project decision; physical revision unverified | `plan.md` |
| FPGA part | XC7S50-CSGA324 | Project decision; installed part not physically rechecked | `plan.md` |
| Board A identifier/serial | Unverified | Unverified | — |
| Board B identifier/serial | Unverified | Unverified | — |
| Vivado version | Unverified | Unverified | — |
| Boolean Board XDC source and revision | Unverified | Unverified | — |
| BLE advertised device name | Unverified | Unverified | — |
| BLE service UUID | Unverified | Unverified | — |
| Phone-to-board writable characteristic UUID | Unverified | Unverified | — |
| Board-to-phone notify characteristic UUID | Unverified | Unverified | — |
| Maximum BLE write-without-response length | Unverified | Unverified | — |
| Board A Pmod TX/RX/GND pins and connector positions | Unverified | Unverified | — |
| Board B Pmod TX/RX/GND pins and connector positions | Unverified | Unverified | — |
| UART electrical level | Unverified | Unverified | — |
| VGA-to-HDMI board/path revision | Unverified | Unverified | — |
| Clocking Wizard configuration/version | Unverified | Unverified | — |
| HDMI/vendor IP name and version | Unverified | Unverified | — |
| Audio output pins and electrical path | Unverified | Unverified | — |
| Tested monitor and accepted mode | Unverified | Unverified | — |
| Measured pixel clock | Unverified | Unverified | — |
| Measured BLE delivery rate/loss | Unverified | Unverified | — |
| Measured board-to-board error rate | Unverified | Unverified | — |

The intended board-to-board logical connection is UART TX to RX, RX to TX, and common ground. Exact connector locations and pins remain unverified; do not wire hardware from this document until the official constraints and board documentation are reviewed. Do not connect supply rails between independently powered boards.
