# Global Implementation Status

This is the orchestration index, not a shared scratchpad. Only the orchestration/integration owner edits it. Track owners update their files under `status/`. Keep this file under roughly 150 lines and never replace unknowns with guesses.

## Current state

- Execution mode: Interface freeze, then four parallel tracks
- Current gate: F0 — interface freeze
- Last completed gate/checkpoint: None
- Overall status: Parallel plan complete; implementation not started
- Integration owner: Unassigned

## Dependency board

| Work | State | Depends on | Detailed status |
|---|---|---|---|
| Interface freeze | Ready | Planning complete | This file and `docs/00_interface_freeze.md` |
| iOS controller | Waiting | F0 | `status/ios.md` |
| Transport RTL | Waiting | F0 | `status/transport.md` |
| Video | Waiting | F0 | `status/video.md` |
| Gameplay | Waiting | F0 | `status/gameplay.md` |
| Integration | Waiting | C2 + C3 + G1 | `status/integration.md` |

## Frozen interface record

| Item | Version/commit | State |
|---|---|---|
| Motion wire protocol | Not created | Pending F0 |
| SystemVerilog shared packages | Not created | Pending F0 |
| Golden protocol vectors | Not created | Pending F0 |
| Cross-track module interfaces/stubs | Not created | Pending F0 |
| File owners/review acknowledgements | Defined in plan; people unassigned | Pending F0 |

## Confirmed project decisions

- Two BLE-equipped Real Digital Boolean Boards are available.
- Both use XC7S50-CSGA324 Spartan-7 FPGAs.
- Phone target is iPhone with Swift/Core Motion/Core Bluetooth.
- RTL target is synthesizable SystemVerilog.
- Board A is authoritative; Board B is a controller gateway.
- Final video target is 1280×720 at 60 Hz.

## Hardware discoveries

Populate from verified iOS, transport, video, and integration evidence.

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

## Gate and checkpoint record

| Gate/checkpoint | Status | Evidence summary |
|---|---|---|
| F0 interface freeze | Not started | — |
| C1 BLE sensor path | Not started | — |
| C2 two-board path | Not started | — |
| C3 video path | Not started | — |
| G1 gameplay simulation | Not started | — |
| C4 integrated game | Not started | — |

## Latest integration test results

None. Track-local results belong in the matching status files until their gate is accepted.

## Open issues and risks

- Exact BLE services and characteristic behavior must be discovered on hardware.
- Exact Pmod pins must be selected from the official constraints file.
- Sustained 50 Hz BLE delivery has not been measured.
- F0 contracts, vectors, stubs, and human/agent owners have not been created or reviewed.

## Next action

Assign the orchestration/integration owner and execute `docs/00_interface_freeze.md`. Do not start implementation tracks until F0 passes.
