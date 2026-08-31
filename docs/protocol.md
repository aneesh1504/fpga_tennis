# Motion Wire Protocol

This document is the normative specification for motion frames exchanged between an iPhone and a board and between Board B and Board A. Version 1.0 is frozen by `MOTION_PROTOCOL_VERSION = 0x01`; the shared SystemVerilog interface revision is `0x0100`. If this document and a summary elsewhere disagree, this document wins.

## Raw payload

Every decoded motion message is exactly 32 bytes. All multibyte integers are little-endian two's-complement values where signed.

| Offset | Bytes | Field | Encoding and legal wire range |
|---:|---:|---|---|
| 0 | 1 | Protocol version | Exactly `0x01` |
| 1 | 1 | Message type | Exactly `0x01` for motion |
| 2 | 1 | Player ID | Exactly `0x01` or `0x02` |
| 3 | 1 | Flags | Bit 0 is calibrated; bits 7:1 must be transmitted as zero and ignored on receipt in version 1 |
| 4 | 2 | Sequence | Unsigned modulo-65536 counter |
| 6 | 4 | Phone timestamp | Unsigned milliseconds modulo 2^32 |
| 10 | 2 | Acceleration X | Signed int16, g multiplied by 4096 |
| 12 | 2 | Acceleration Y | Signed int16, g multiplied by 4096 |
| 14 | 2 | Acceleration Z | Signed int16, g multiplied by 4096 |
| 16 | 2 | Gyroscope X | Signed int16, rad/s multiplied by 512 |
| 18 | 2 | Gyroscope Y | Signed int16, rad/s multiplied by 512 |
| 20 | 2 | Gyroscope Z | Signed int16, rad/s multiplied by 512 |
| 22 | 2 | Quaternion W | Signed int16, unitless value multiplied by 32767 |
| 24 | 2 | Quaternion X | Signed int16, unitless value multiplied by 32767 |
| 26 | 2 | Quaternion Y | Signed int16, unitless value multiplied by 32767 |
| 28 | 2 | Quaternion Z | Signed int16, unitless value multiplied by 32767 |
| 30 | 2 | CRC | CRC-16/CCITT-FALSE over raw bytes 0 through 29, stored low byte then high byte |

Producers round to the nearest integer, with ties away from zero, then saturate rather than wrap. Acceleration therefore encodes -8.0 through 7.999755859375 g; gyroscope encodes -64.0 through 63.998046875 rad/s. A producer clamps quaternion inputs to [-1, 1], mapping -1 to -32767 and +1 to +32767. Receivers accept and preserve every signed int16 wire value, including -32768, so malformed-but-CRC-valid sensor extremes remain observable for health and test logic.

Sequence arithmetic is modulo 65536. After `0xffff`, `0x0000` is the next in-order value. A receiver establishes its baseline from the first valid frame; duplicate or out-of-order policy belongs to transport, but neither case changes the wire decoding rules.

## CRC

CRC-16/CCITT-FALSE has width 16, polynomial `0x1021`, initial value `0xffff`, no input or output reflection, and final XOR `0x0000`. The check value for ASCII `123456789` is `0x29b1`. Only the 30 raw bytes preceding the CRC participate. Escapes and the terminator never participate. The computed 16-bit value is appended little-endian.

## Framing and escaping

Encode the complete 32-byte raw payload, including its CRC, as follows:

1. Replace each raw `0x0a` with `0x7d 0x2a`.
2. Replace each raw `0x7d` with `0x7d 0x5d`.
3. Copy every other byte unchanged.
4. Append one unescaped `0x0a` terminator.

Equivalently, an escaped byte is `0x7d` followed by the original byte XOR `0x20`. The receiver accepts only `0x2a` or `0x5d` after an escape. It rejects dangling/invalid escapes, decoded lengths other than 32, unsupported version/type, invalid player ID, reserved flag bits set, and CRC mismatch. A terminator, overflow, timeout, or framing error returns the parser to the empty, unescaped state; the error-causing frame is not published.

## Shared RTL contracts

The packed types and version constants live in `rtl/packages/`. `motion_sample_t.sequence_number` represents the wire Sequence field; the suffix avoids the reserved SystemVerilog keyword `sequence`. `motion_sample_t` values retain the wire-scale signed integers; no implicit unit conversion occurs at a module boundary. Each controller has a distinct interface instance, so player identity is not duplicated in `motion_sample_t`. `transport_health_t.calibrated` carries flag bit 0 for that controller.

All `valid`/`ready` streams use a single-clock transfer on a rising edge where both are high. A producer may assert `valid` independently of `ready` and must hold `valid` and the entire payload stable until transfer. A consumer may apply backpressure. Counters saturate at all ones. `stale` becomes true when the transport owner's versioned timeout expires and remains true until a new valid sample transfers; the initial timeout constant is owned by transport and is not a wire-protocol value.

Resets are active-low. Assertion may be asynchronous, but reset deassertion presented to an interface module must be synchronized to that module's clock. No cross-domain payload may be sampled without the documented handshake.

### Transport to gameplay

For each player, transport supplies `motion_sample_t`, `transport_health_t`, `valid`, and accepts `ready`. The payload and health record are stable under backpressure. Gameplay must not infer player identity from sequence or timestamp.

### Gameplay to video

Gameplay publishes one packed `game_render_state_t`. Coordinates ending in `_q8_8` are signed pixels or projection-space units with 8 fractional bits, legal raw range -32768 through 32767, and saturation at that range. Scores and animation selectors are unsigned display values; gameplay saturates any value that exceeds its field.

Video toggles `vblank_request` once per frame. The system domain synchronizes that toggle, copies the entire state to a shadow bank, then toggles `snapshot_ready`. The shadow bank remains unchanged until the next request. The pixel domain synchronizes `snapshot_ready` and captures the entire stable bank atomically before active video. Toggle comparisons, not pulse widths, signal events. Neither domain may issue a second request until the previous ready toggle is observed.

### Gameplay to audio

Gameplay supplies `audio_event_t` over `valid`/`ready` in `clk_sys`. `strength` is unsigned Q0.16 intensity (`0x0000` silent/minimum through `0xffff` maximum). Events are discrete and remain stable under backpressure.

### Subsystems to top level

Top-level RTL is structural. It wires the typed streams, clock/reset inputs, and snapshot handshake without recreating protocol, gameplay, audio, or video logic. The F0 top-level scaffold is a compile-time test double, not a pin-accurate hardware top.

## Golden vectors and compatibility

`sim/vectors/motion_protocol_v1.json` is normative test data. Hex strings are byte order on the wire from left to right. `raw_hex` is the decoded 32-byte payload; `framed_hex` includes escaping and the final terminator. `accepted` describes the expected decoder decision. The vectors cover normal values, every signed endpoint, both escaped byte values, an intentionally bad CRC, and sequence wrap.

A frozen-contract change requires a new interface revision, updated documentation/vectors/tests, and acknowledgement by every affected track owner before merge. Unknown BLE UUIDs and physical transport characteristics are hardware-manifest facts, not protocol constants.
