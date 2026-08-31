# Track — iPhone Motion Controller

## Objective

Build the native iPhone controller and prove it emits the frozen motion protocol through the Boolean Board's stock BLE module at a sustained 50 Hz. Coordinate C1 hardware runs with the transport owner, but keep all app implementation and app tests independent.

This track may start as soon as F0 passes. Use a BLE diagnostic app or a mock peripheral until the transport RTL is ready. Repeat the final joint test independently with the second phone/board before declaring C1 complete.

## Required inputs

- `plan.md`, `STATUS.md`, `status/ios.md`, and `docs/01_architecture.md`.
- Gate F0 marked passed and frozen protocol vectors available.
- Official Boolean Board manual, schematic, and XDC matching the physical board revision.
- Xcode on the Mac and the already working Vivado/programming flow.
- nRF Connect or LightBlue as a temporary diagnostic tool.

## Deliverables

- Swift controller app skeleton with Player ID selection.
- Verified BLE service/characteristic information in `docs/hardware-manifest.md`.
- Swift golden-vector tests that consume the frozen vectors without rewriting them.
- Hardware demonstration satisfying C1.

## Ownership and handoff

This track exclusively owns `ios-controller/`, its app-side tests, and `status/ios.md`. It does not edit `rtl/`, shared protocol packages/vectors, top-level modules, `STATUS.md`, or the hardware manifest. Record discovered BLE values and supporting evidence in `status/ios.md`; the integration owner copies verified shared facts into the manifest.

If the app reveals a frozen-protocol defect, stop depending on the changed behavior and file a versioned interface-change request in `status/ios.md`. Do not silently fork the Swift encoding from the SystemVerilog contract.

## Workstream A — discover the BLE interface

1. Coordinate with the transport owner to program a minimal FPGA design with a working BLE-side UART receiver and visible byte/debug counters.
2. Press `BLE RST`, scan from nRF Connect, and record the advertised name.
3. Discover and record:
   - Service UUID.
   - Phone-to-board writable characteristic UUID.
   - Board-to-phone readable/notifiable characteristic UUID, if present.
   - Whether the characteristic supports write without response.
   - The phone-reported maximum write-without-response length.
4. Manually send `41 0A` (`A` plus newline) and verify the FPGA receives `0x41`.
5. If data does not arrive, inspect characteristic properties, pairing state, module reset behavior, UART direction, baud rate, and XDC pins. Do not proceed by guessing UUIDs or pin names.

The diagnostic app is not part of the final product. Its only purpose is to reveal and verify the stock BLE GATT interface.

## Workstream B — Swift controller app

### Components

`BLEManager.swift`

- Owns `CBCentralManager`, scanning, connection, service discovery, characteristic discovery, writes, notifications, and reconnect state.
- Filters for the verified service UUID after discovery is known.
- Uses `.withoutResponse` when supported.
- Checks `canSendWriteWithoutResponse` and resumes on `peripheralIsReady(toSendWriteWithoutResponse:)` instead of creating an unbounded queue.
- Splits an encoded frame into chunks no larger than `maximumWriteValueLength(for: .withoutResponse)` while preserving order.

`MotionSampler.swift`

- Owns one `CMMotionManager`.
- Uses processed device motion rather than raw acceleration.
- Begins at `deviceMotionUpdateInterval = 1.0 / 50.0`.
- Collects `userAcceleration`, `rotationRate`, and attitude quaternion.
- Applies only minimal phone-side conditioning: calibration transform, bounds checking, saturation, and conversion to the protocol units. Swing recognition remains on Board A.

`MotionPacket.swift`

- Implements the exact 32-byte payload in `docs/01_architecture.md`.
- Implements CRC-16/CCITT-FALSE.
- Escapes `0x0A` and `0x7D`, then appends `0x0A`.
- Provides golden-vector tests for normal values, negative values, saturation, reserved bytes, both escaped values, and a known CRC.

`ControllerViewModel.swift` and UI

- Select Player 1 or Player 2 before streaming.
- Show disconnected, scanning, connected, calibrating, streaming, backpressured, and stale/error states.
- Require an explicit calibration action while the phone is held in the intended neutral grip.
- Display sample rate, last sequence, and dropped/backpressured sample count for bring-up.

### Permissions

Add the required Bluetooth and motion usage descriptions to the iOS project. Verify behavior on a physical iPhone; the simulator is not sufficient for the final sensor/BLE test.

### Sampling and overload behavior

- Sample at 50 Hz, but do not accumulate an ever-growing transmission backlog.
- If BLE is temporarily unable to write, retain only the newest unsent motion sample and increment a local dropped-sample counter.
- Sequence numbers increase per generated sample, not per successful transmission, so the FPGA can observe losses.
- Never batch multiple old motion samples after congestion; fresh control input matters more than perfect delivery.

## Simulation requirements

App-side tests must cover:

- Negative `int16` values and little-endian reconstruction.
- Every raw payload byte value that needs escaping.
- Frozen ordinary and boundary golden vectors.
- CRC, wrong version, and both player IDs.
- Sequence wrap from `65535` to `0`.
- Backpressure behavior: retain only the newest unsent sample and count drops.
- Reconnect, role selection, calibration, and interrupted streaming state transitions.

Use checked-in frozen golden byte vectors, not only vectors produced by the Swift encoder itself.

## Joint hardware debug presentation

During bring-up, ask the transport owner to map useful signals to LEDs/seven-segment/ILA:

- BLE paired/connected status if observable.
- Heartbeat toggled on every valid frame.
- CRC/framing error indicator.
- Low bits of sequence number.
- Selectable acceleration or gyro axis.

This temporary visibility may be removed or placed behind a debug parameter later.

## Joint checkpoint C1 — pass criteria

Run on each phone/board pair:

1. Connect and calibrate the app.
2. Stream at 50 Hz for two continuous minutes.
3. Move and rotate the phone through each axis.
4. Confirm decoded values change with correct sign and return near neutral.
5. Record generated, received, sequence-gap, CRC, length, framing, and overflow counters.

C1 passes jointly with the transport track when:

- At least 99.5% of generated sequence numbers are observed by the FPGA.
- No parser failure requires FPGA reset or BLE reconnect to recover framing.
- No FIFO or parser overflow occurs during normal streaming.
- Both board/phone pairs pass independently.
- Verified UUIDs, characteristic behavior, write size, Vivado version, and evidence are recorded in the relevant track status files and consolidated by the integration owner.

The iOS owner records its C1 evidence and commit hash in `status/ios.md`, then hands the tested app build to integration. C1 gates live board-to-board BLE testing but does not gate video or gameplay work.
