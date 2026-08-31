# Track — Transport RTL and Board Link

## Objective

Implement and verify the complete byte path: BLE-side UART reception, frame unescaping, CRC and motion decoding, health tracking, and Board B forwarding to Board A. Prove C1 jointly with the iOS track and then prove stable simultaneous transport at C2.

This track may start as soon as F0 passes. Develop against frozen golden vectors and UART testbenches while BLE discovery and the iOS app proceed in parallel.

## Required inputs and ownership

Read `plan.md`, `STATUS.md`, `status/transport.md`, `docs/01_architecture.md`, and this document. Gate F0 must be marked passed.

This track exclusively owns `rtl/common/`, `rtl/bridge/`, `sim/common/`, transport-specific build files, and `status/transport.md`. It consumes but does not edit frozen packages or vectors. It does not edit Board A top-level integration, `STATUS.md`, or shared hardware records; place verified pins, Vivado facts, counters, and evidence in `status/transport.md` for the integration owner.

## BLE receive and decode path

Implement in this order:

1. `uart_rx.sv`: parameterized `CLOCK_HZ` and `BAUD`; valid pulse plus byte output; framing-error counter.
2. `uart_tx.sv`: matching parameterization with explicit busy/ready behavior.
3. `frame_unescaper.sv`: recognize `0x7D`, XOR the following byte with `0x20`, detect unescaped newline, enforce a maximum raw length, and recover after errors.
4. `crc16_ccitt.sv`: streaming or bounded-block implementation matching the frozen golden vectors.
5. `motion_packet_decoder.sv`: enforce exact 32-byte length, version, type, player ID, and CRC before pulsing `sample_valid`.
6. Controller health logic: count frames, CRC failures, length failures, invalid type/version/player, sequence gaps, and age/stale state.

Keep the last valid `motion_sample_t` stable until a new valid frame arrives. Invalid frames must never partially update controller state.

### Receive-path simulation

- UART reception at nominal baud and modest independent-clock mismatch.
- Back-to-back frames and every payload byte value that needs escaping.
- Signed little-endian reconstruction and all frozen golden vectors.
- Truncated/oversized frames, unexpected terminal escape, extra byte, bad CRC, wrong version, and wrong player ID.
- Invalid bytes followed by a valid frame to prove resynchronization.
- Sequence wrap from `65535` to `0`.
- Stale transition after the configured timeout and recovery on the next valid frame.

## Joint checkpoint C1

Coordinate the physical BLE runs described in `docs/02_track_ios_controller.md`. C1 passes only when both the app and this receive path meet the master checkpoint criteria on both phone/board pairs. Record RTL counters, tests, hardware evidence, and the tested app commit in `status/transport.md`.

## Physical wiring

The installed Pmod/Pmod+ sockets are female, so use male-to-male 0.1-inch jumper wires.

| Board A | Board B | Purpose |
|---|---|---|
| Selected Pmod `RX` GPIO | Selected Pmod `TX` GPIO | Player 2 motion toward Board A |
| Selected Pmod `TX` GPIO | Selected Pmod `RX` GPIO | Feedback/status toward Board B |
| Pmod `GND` | Pmod `GND` | Common signal reference |

Safety rules:

- Do not connect the boards' `3V3`, `5V`, or USB power rails.
- Power each board normally by USB.
- Select exact signal and ground positions from the official XDC/schematic.
- Record connector name, header position, FPGA package pin, I/O bank, and I/O standard in `docs/hardware-manifest.md`.
- Configure GPIO as `LVCMOS33` only after confirming the board design uses 3.3 V on that connector.
- Cross TX and RX. Never configure both ends of one wire as outputs.

## Board B forwarding design

Board B should remain simple and byte-transparent:

```mermaid
flowchart LR
    BLE["BLE UART RX"] --> RX["uart_rx"]
    RX --> FIFO["small byte FIFO"]
    FIFO --> TX["Pmod uart_tx"]
    TX --> A["Board A"]
```

- Forward the complete escaped wire frame, including its terminating newline.
- Do not decode and re-encode ordinary Player 2 motion frames on Board B.
- Use a small FIFO, initially 128 bytes or greater, between the two UARTs.
- Count input bytes, output bytes, complete frames, FIFO high-water mark, and overflow.
- A malformed frame may still be forwarded; Board A is the authoritative validator. Board B may count delimiters for debug visibility.
- Both serial links start at 115,200 baud. Keep baud parameters independent so later changes do not require module rewrites.

For the reverse direction, implement the symmetrical Pmod-RX → FIFO → BLE-UART-TX path. It need not carry gameplay feedback until integration, but proving the electrical/full-duplex path now reduces integration risk.

## Board A receive integration

Board A has two independent receive chains:

- BLE UART parser configured to accept Player ID 1.
- Pmod UART parser configured to accept Player ID 2.

Do not multiplex bytes from both sources into one parser. Independent parsers eliminate interleaving and preserve per-link error counters. Their validated `motion_sample_t` outputs update separate controller-state registers.

Add a compact debug/status register bank containing:

- Valid-frame counts per player.
- Last sequence per player.
- Sequence gaps per player.
- CRC/framing/length failures per input.
- Stale flags and time since last valid sample.
- Board B FIFO overflow/high-water information if returned through a debug event.

## Bring-up sequence

1. Program Board A with a Pmod UART receiver that displays a received test counter.
2. Program Board B with a local repeating test-frame generator feeding Pmod UART.
3. Connect only `Board B TX → Board A RX` and common ground.
4. Confirm reliable one-way traffic before connecting the reverse wire.
5. Connect the reverse UART and verify Board A can send a test event back to Board B.
6. Replace Board B's test generator with BLE-frame forwarding.
7. Connect Phone 2 to Board B and verify decoded Player 2 motion on Board A.
8. Connect Phone 1 to Board A and stream both phones simultaneously.

This staged sequence isolates pin mapping and UART electrical errors from BLE/application errors.

## Simulation requirements

- FIFO preserves byte order under small rate mismatch and bursty input.
- FIFO never reads empty or writes full without setting the expected status.
- Back-to-back worst-case escaped frames pass intact.
- UART endpoints tolerate independent local clocks within expected oscillator tolerance.
- Board A's two parsers update only their assigned player.
- Sequence/stale counters remain independent.
- Reverse feedback traffic does not block forward motion traffic because it uses a separate wire/UART direction.

## Checkpoint C2 — pass criteria

1. Connect Phone 1 to Board A and Phone 2 to Board B.
2. Stream both at 50 Hz for five continuous minutes.
3. Move the phones independently and verify that Board A never swaps player identity.
4. Temporarily disconnect or stop one phone and verify only that controller becomes stale within 250 ms.
5. Reconnect and verify automatic recovery without reprogramming either FPGA.
6. Record frame counts, sequence gaps, CRC errors, UART framing errors, FIFO high-water mark, and FIFO overflow.

C2 passes when:

- Board A continuously holds fresh, independent motion state for both players.
- Each player retains at least 99.5% observed frame delivery during the stable portion of the run.
- There are no FIFO overflows or persistent framing failures.
- Stale/recovery behavior works independently.
- Full-duplex test traffic succeeds.
- Exact wiring and XDC assignments are documented.

After C2, record the transport commit and evidence in `status/transport.md` and hand the tested interfaces to integration. The motion wire protocol was already frozen at F0; any demonstrated change still follows the versioned cross-track change process.
