# Transport Track Status

- Owner: Transport implementation owner (`/root/transport_f0_review`)
- State: Software/simulation handoff ready; C1 and C2 remain blocked on physical BLE/board verification
- Track document: `docs/03_track_transport.md`
- Frozen-interface commit: `8255a4c52125101f8c8d033766b490975a36ffa5`
- F0 closure base: `4edbea5d57580ddf9b216e1241018ad0e9605a93`
- Latest merged integration base: `1bac79c119fa5eaa6ca72299434b945218af62ab`
- Latest-main merge tested for this handoff: `ab886ffa1ee18647a6e6c4caa48e501d22bd6978`

## Implementation commits

- `97616d0b444d6cdd0eedb24d19df11c1d9027c74` — serial, reset, tick, CRC, and FIFO primitives
- `ea3677ea3af11d59f88b1847ca5e124469c24e53` — frame unescaping, normative packet decoding, health/stale endpoint, and vector-driven tests
- `a80b3ba511ce295e73c0701847ead10d46178f01` — independent dual-player receive chains and full-duplex Board B forwarding
- `3ad7049d93f4deffe65005349934465502d4f1ad` — isolate FIFO storage from asynchronous reset so Vivado infers distributed RAM

## Implemented

- `rtl/common/reset_sync.sv`: asynchronous assertion and configurable multi-stage synchronous reset deassertion.
- `rtl/common/tick_gen.sv`: accumulator-based fractional periodic tick generation.
- `rtl/common/uart_rx.sv`: parameterized 8-N-1 receiver with two-flop input synchronization, centered sampling, a valid pulse, bad-stop rejection, and a saturating framing-error counter.
- `rtl/common/uart_tx.sv`: parameterized 8-N-1 transmitter with explicit valid/ready and busy behavior.
- `rtl/common/sync_fifo.sv`: parameterized power-of-two FIFO with simultaneous read/write support, level, high-water, overflow, and underflow indications. Storage uses a reset-free write process; reset clears validity/pointers without resetting stale memory bits, allowing RAM inference.
- `rtl/common/crc16_ccitt.sv`: streaming CRC-16/CCITT-FALSE engine matching the frozen polynomial and initialization.
- `rtl/common/frame_unescaper.sv`: strict `0x7d 0x2a`/`0x7d 0x5d` decoding, unescaped `0x0a` termination, raw indexing, overflow discard, timeout recovery, and one error indication per rejected frame.
- `rtl/common/motion_packet_decoder.sv`: exact 32-byte validation, frozen version/type/player/flags enforcement, CRC verification, signed little-endian reconstruction, optional fixed-player filtering, and rejection pulses.
- `rtl/common/motion_transport_rx.sv`: complete UART-to-gameplay endpoint with frame timeout, sequence and saturating health counters, configurable stale/recovery behavior, one-entry valid/ready publication, stable sample/health under backpressure, and blocked-publication overflow accounting.
- `rtl/common/dual_motion_transport_rx.sv`: independent Player 1 and Player 2 endpoints; bytes are never multiplexed between parsers.
- `rtl/bridge/frame_forwarder.sv`: byte-transparent FIFO forwarding with input/output byte counts, received delimiter count, FIFO high-water, and saturating overflow count.
- `rtl/bridge/board_b_top.sv`: symmetric BLE-RX to Pmod-TX and Pmod-RX to BLE-TX paths with independent baud parameters and counters. It intentionally contains no protocol decode/re-encode and no unverified pin assignments.
- `sim/common/`: repeatable WSL/Icarus regression, frozen-JSON-to-RTL vector adapter, and self-checking unit/integration testbenches.

No frozen package, protocol, vector, iOS, video, gameplay/audio, Board A top-level, global status, integration status, hardware manifest, or pin file was changed by the transport implementation commits.

## Tests and evidence

The complete transport regression was rerun after merging `origin/main` at `1bac79c119fa5eaa6ca72299434b945218af62ab` and applying the FIFO inference fix:

- `wsl -e sh sim/common/run_transport_wsl.sh`
  - PASS: reset synchronization, fractional tick generation, UART nominal loopback, approximately 1% independent sender timing mismatch, bad stop-bit rejection/counter, CRC `123456789 = 0x29b1`, and FIFO ordering/high-water/overflow/underflow.
  - PASS: generated six RTL records directly from frozen `sim/vectors/motion_protocol_v1.json`.
  - PASS: all six frozen vectors matched full packed samples and expected accept/reject outcomes.
  - PASS: strict escaping, signed endpoints, CRC failure, truncated/oversized frames, dangling/invalid escapes, wrong header/player, timeout recovery, and valid-frame resynchronization.
  - PASS: modulo sequence wrap `0xffff -> 0x0000`, stale publication/recovery, duplicate gap counting, CRC/framing counters, and valid/sample/health stability under backpressure.
  - PASS: simultaneous independent Player 1 and Player 2 receive chains rejected crossed identities and retained independent counters.
  - PASS: two back-to-back copies of the worst-case escaped vector remained byte-exact through a stalled 128-byte forwarding FIFO; ordering, delimiter count, high-water, and overflow reporting matched expectations.
  - PASS: simultaneous Board B forward and reverse UART traffic remained byte-transparent with zero simulated UART/FIFO errors.
  - Tool/result: Icarus Verilog `12.0 (stable)`, Python `3.12.3`, exit code 0. Icarus emitted only its known informational package-timescale and conservative `always_comb` constant-select messages; no compile or simulation failure occurred.
- `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_smoke.ps1`
  - PASS: six protocol vectors, local links in 23 Markdown files, shared-package elaboration, and all four frozen interface smoke tests.
  - Tool/result: Node `v24.11.1`, Icarus Verilog `12.0`, exit code 0.
- `git diff --check`
  - PASS: no whitespace errors.
- `git diff origin/main...HEAD --check`
  - PASS: no whitespace errors in the transport branch delta.
- `& 'C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat' -mode batch -nolog -nojournal -notrace -source 'C:/Users/troym/OneDrive/Documents/GitHub/fpga_tennis/scripts/synth_board_b_top_ooc.tcl'`
  - PASS: Vivado `2026.1` build `6511674` synthesized `board_b_top` out of context for `xc7s50csga324-1`; 0 errors and 0 critical warnings.
  - PASS: the previous `[Synth 8-7137]` same-priority set/reset and `[Synth 8-4767]` asynchronous-reset RAM warnings are absent. Synthesis itself completed with 0 warnings.
  - PASS: both 128x8 FIFO stores inferred as distributed RAM (`12 RAM64M`, 48 LUTs as memory), with 581 total Slice LUTs, 498 Slice Registers, and 0 block RAM. The pre-fix run used 1371 LUTs and 2552 registers with the stores flattened into registers.
  - PASS: preliminary 100 MHz OOC timing has WNS `5.275 ns`, TNS `0.000 ns`, WHS `0.195 ns`, and no unconstrained internal endpoints or unclocked registers.
  - Expected OOC limitation: `[Timing 38-242]` reports that `HD.CLK_SRC` is unset, and top-level serial/reset/status ports have no input/output delays. Pin/clock placement and external delays remain integration constraints for full implementation.

## Software handoff

The transport RTL is ready for orchestration integration as a software-simulated and OOC-synthesized implementation of the frozen protocol and seams. The handoff consists of the implementation commits listed above plus the tested latest-main merge. It is not a C1 or C2 hardware pass.

Integration should instantiate `dual_motion_transport_rx` for Board A's independent Player 1/Player 2 serial inputs and connect each held valid/ready sample plus health record to the frozen gameplay seam. Board B integration should wrap `board_b_top` with a separately synchronized reset and verified physical pins.

## Verified hardware discoveries

No physical hardware discovery was performed. Vivado 2026.1 OOC synthesis verified the transport hierarchy against part `xc7s50csga324-1`, but no BLE module, programmed Boolean Board, Pmod wiring, oscilloscope/ILA capture, or physical measurement was used.

## Interface requests

None. The implementation accepts motion protocol 1.0 / wire `0x01`, protocol package `0x0100`, all frozen vectors, and seam 1.0 without changes.

## Risks/blockers and required hardware work

- Discover and record the actual BLE service/characteristic UUIDs, write mode, notification behavior, MTU/payload limit, module UART behavior, and sustained 50 Hz delivery. Do not derive these from the RTL.
- Verify the authoritative Boolean Board XDC, exact BLE UART and Pmod signal/ground positions, FPGA pins, I/O banks, voltage, I/O standard, and board revision before generating a bitstream or wiring boards.
- Confirm the actual board clock and oscillator tolerance, then select `CLOCK_HZ`, `BLE_BAUD`, and `PMOD_BAUD`; the default baud is 115,200 but no physical clock/pin value was guessed.
- Run Vivado synthesis, implementation, timing, CDC review, and critical-warning review with the verified tool/IP version. Icarus elaboration is not a substitute for FPGA implementation.
- C1 still requires the two-minute iPhone-to-board run with changing decoded fields and at least 99.5% observed frame delivery.
- C2 still requires verified crossed TX/RX plus common ground, independent two-phone streaming for five minutes, stale/reconnect testing, full-duplex traffic, at least 99.5% delivery per player, no FIFO overflow, and recorded counters/high-water/timing evidence.
- Icarus 12.0 reports conservative `always_comb` constant-select sensitivity messages for packed health fields; behavior is covered by simulation, but Vivado lint/synthesis must independently confirm the intended combinational logic.

## Next action

Integration owner may merge the software handoff. Then verify hardware facts and create the board project/pin wrappers before attempting C1 or C2; do not claim either checkpoint from simulation evidence.
