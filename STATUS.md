# Implementation Status

This file is the compact handoff record. Keep it under roughly 150 lines. Replace placeholders with measured facts; do not guess.

## Current state

- Current phase: Phase 1 — BLE controller bring-up
- Last completed checkpoint: None
- Next checkpoint: C1 — BLE sensor path
- Overall status: Planning complete; implementation not started

## Confirmed project decisions

- Two BLE-equipped Real Digital Boolean Boards are available.
- Both use XC7S50-CSGA324 Spartan-7 FPGAs.
- Phone target is iPhone with Swift/Core Motion/Core Bluetooth.
- RTL target is synthesizable SystemVerilog.
- Board A is authoritative; Board B is a controller gateway.
- Final video target is 1280×720 at 60 Hz.

## Hardware discoveries

Populate during Phase 1 and Phase 2.

| Item | Verified value | Evidence |
|---|---|---|
| Vivado version | Unverified | — |
| Boolean Board XDC source/version | Unverified | — |
| BLE advertised device name | Unverified | — |
| BLE service UUID | Unverified | — |
| Phone-to-board writable characteristic UUID | Unverified | — |
| Board-to-phone notify characteristic UUID | Unverified | — |
| Maximum write-without-response length | Unverified | — |
| Board A Pmod TX/RX/GND positions | Unverified | — |
| Board B Pmod TX/RX/GND positions | Unverified | — |
| HDMI/VGA-to-HDMI IP version | Unverified | — |
| Tested monitor mode | Unverified | — |

## Checkpoint record

| Checkpoint | Status | Evidence summary |
|---|---|---|
| C1 BLE sensor path | Not started | — |
| C2 two-board path | Not started | — |
| C3 video path | Not started | — |
| C4 integrated game | Not started | — |

## Latest test results

None yet.

## Open issues and risks

- Exact BLE services and characteristic behavior must be discovered on hardware.
- Exact Pmod pins must be selected from the official constraints file.
- Sustained 50 Hz BLE delivery has not been measured.

## Next action

Follow `docs/02_phase_ble_controller.md`, beginning with manual BLE discovery and a one-byte UART loop-through test.

