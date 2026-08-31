# Interface Freeze — Parallel-Work Prerequisite

## Objective

Create the smallest compiling repository skeleton and lock every contract needed for the iOS, transport, video, and gameplay tracks to work independently. This is a short coordination stage, not an implementation track.

## Required decisions

Freeze and document:

- The 32-byte motion payload, byte order, scaling, CRC-16/CCITT-FALSE parameters, escaping, terminator, version, and player IDs.
- `motion_sample_t`, `swing_event_t`, `game_render_state_t`, transport health/status, and audio-event types with units and signedness.
- Module port contracts at transport-to-gameplay, gameplay-to-video, gameplay-to-audio, and subsystem-to-top-level seams.
- Clock, reset, valid/ready, stale, and snapshot-handshake semantics.
- Exclusive directory ownership and the process for requesting cross-owner changes.
- Test-vector format, simulator entry points, and minimum checks run by each track before handoff.

Do not guess hardware-specific UUIDs, pins, connector positions, or vendor IP versions. Those remain explicit unknowns in the hardware manifest until measured or verified from an authoritative source.

## Deliverables

1. Create the repository directories in `docs/01_architecture.md`, including per-track status files.
2. Create `docs/protocol.md` as the normative wire specification; keep `docs/01_architecture.md` as a summary that links to it.
3. Add `rtl/packages/protocol_pkg.sv`, `game_types_pkg.sv`, and `video_types_pkg.sv` with compiling packed types and constants.
4. Add checked-in golden vectors covering ordinary values, signed limits, both escaped bytes, bad CRC, and sequence wrap.
5. Add compiling stubs or test doubles for each cross-track interface.
6. Record exact path ownership and name one integration owner.
7. Run package elaboration and at least one consumer smoke test for each interface.

## Review checklist

- Swift and SystemVerilog interpretations of every packet byte agree.
- CRC input range, initialization, polynomial, reflection behavior, final XOR, and stored byte order are explicit.
- All fixed-point fields have units, scale, legal range, and saturation behavior.
- `valid`, backpressure, stale, reset, and CDC behavior are unambiguous.
- Video receives an atomic state snapshot rather than independently synchronized fields.
- Tests can use synthetic motion and render state without BLE or physical boards.
- No two active tracks own the same writable path.

## Gate F0 — pass criteria

F0 passes when all deliverables exist, compile/smoke tests pass, and the four track owners plus integration owner have reviewed the contracts they consume. Record the commit hash and review result in `STATUS.md`.

After F0, changes to frozen packages, protocol documents, or golden vectors require a versioned proposal, affected-owner acknowledgement, updated vectors/tests, and an entry in each affected status file. Hardware discoveries may fill previously marked unknown values without reopening unrelated contracts.
