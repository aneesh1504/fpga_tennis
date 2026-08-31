# Video Track Status

- Owner: Codex video review agent `/root/video_f0_review`
- State: F0 consumer review accepted; waiting for integrated F0 closure
- Track document: `docs/04_track_video.md`
- Reviewed base commit: `7dce568348d7b30cda9063822534ab7c3d6ddf2a`
- Frozen-interface commit: `8255a4c52125101f8c8d033766b490975a36ffa5`

## Implemented

No video subsystem implementation was started. This branch contains only the F0 consumer review record.

## F0 consumer review

Reviewed `rtl/packages/video_types_pkg.sv`, `sim/interfaces/gameplay_video_stub.sv`, the gameplay-to-video contract in `docs/protocol.md`, `sim/interfaces/tb_interface_smoke.sv`, `sim/interfaces/tb_package_compile.sv`, and the smoke scripts.

The video owner accepts, without changes:

- video package interface revision `0x0100`;
- cross-track gameplay-to-video seam version `1.0`;
- the toggle-based atomic snapshot contract.

Review findings:

- `game_render_state_t` is a 173-bit packed state record. All four player coordinates and all three ball coordinates are signed 16-bit Q8.8 values. Animation selectors, score fields, connection/visibility flags, and swing meters are unsigned fields of the documented widths.
- Gameplay owns saturation before publication: Q8.8 coordinates clamp to raw `-32768` through `32767`, and unsigned display values clamp to their field maxima. Video consumes the frozen values without reinterpretation.
- The pixel-domain request toggle is double-synchronized into `clk_sys`; a newly observed request atomically copies the complete render state into `shadow_sys` and toggles the ready response. The shadow bank changes only on a new accepted request.
- The ready toggle is double-synchronized into `clk_pix`; a newly observed response atomically captures the stable shadow bank and pulses `pixel_state_valid`. Event detection depends on toggle comparisons, not pulse width.
- The requester must not toggle a second request until the corresponding ready-toggle transition is observed. This preserves shadow-bank stability across the multi-bit CDC.
- Active-low reset clears synchronizer history, observed toggles, the shadow and pixel banks, and `pixel_state_valid`. The shared contract requires reset deassertion to be synchronized separately in each receiving clock domain.
- The stub is synthetically testable through independent system/pixel clocks, resets, an arbitrary packed render-state input, and explicit request/ready toggles.

No versioned change request is required.

## Tests and evidence

- `& .\scripts\run_smoke.ps1` -- PASS on 2026-08-30 (America/New_York): 6 protocol vectors validated; local links validated in 21 Markdown files; shared packages compiled/elaborated with Icarus Verilog 12.0; transport-to-gameplay, gameplay-to-video atomic snapshot, gameplay-to-audio, and subsystem-to-top smoke tests all passed.
- `git diff --check` -- PASS with exit code 0; Git emitted only the working-tree line-ending notice that LF will be converted to CRLF when it next touches `status/video.md`, with no whitespace-error diagnostics.
- Gameplay-to-video test evidence: `sim/interfaces/tb_interface_smoke.sv` published a valid synthetic state containing `ball_x_q8_8 = 16'sh1234`, issued a pixel-domain request toggle, observed `pixel_state_valid`, and verified the captured valid bit and coordinate.

## Interface requests

None. Video accepts the frozen contracts listed above without changes. Future changes require a new interface revision and affected-owner acknowledgement.

## Risks/blockers

- F0 remains open until the integration owner merges all four consumer acknowledgements and the complete suite passes on the merged result.
- BLE UUIDs, board pins, IP versions, timing/resource results, monitor mode, and physical measurements remain explicitly unverified and are not part of this interface acceptance.

## Next action

Wait for integrated F0 closure. After F0 passes, drive the frozen render state with a synthetic scene and establish timing-generator tests.
