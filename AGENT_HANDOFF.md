# Coding-Agent Handoff

Use the following instruction when handing this project to an implementation agent:

> Implement the FPGA Motion Tennis project phase by phase. Begin by reading `plan.md`, `STATUS.md`, `docs/01_architecture.md`, and only the document for the current phase. Work only on that phase until its exit criteria or formal checkpoint pass. Run the specified simulations and hardware checks; never claim hardware evidence you did not collect. Do not guess BLE UUIDs, XDC pins, connector positions, Vivado IP versions, or measured limits. Record discovered values and evidence in `STATUS.md` and `docs/hardware-manifest.md`. Keep Board A authoritative, Board B transport-only, preserve the versioned escaped wire protocol, and maintain subsystem boundaries. At each phase boundary, update `STATUS.md` with exact tests, results, discoveries, unresolved issues, and the next action before loading the next phase document.

## First task

Execute Phase 1 from `docs/02_phase_ble_controller.md`:

1. Create the repository skeleton from `docs/01_architecture.md`.
2. Create `docs/hardware-manifest.md` and `docs/bringup-log.md`.
3. Discover and record the stock BLE GATT interface.
4. Prove one manually transmitted byte reaches a minimal FPGA UART receiver.
5. Implement and test the Swift packet encoder plus SystemVerilog frame decoder.
6. Complete checkpoint C1 on both independent phone/board pairs.

Stop and report a blocker rather than silently changing the architecture if the stock BLE firmware cannot sustain writes, has no writable characteristic, or behaves differently from the official documentation.

