# Video Track Status

- Owner: Codex video implementation owner `/root/video_f0_review`
- State: Software-simulation handoff ready; C3 hardware/synthesis checkpoint pending
- Track document: `docs/04_track_video.md`
- Reviewed base commit: `7dce568348d7b30cda9063822534ab7c3d6ddf2a`
- Frozen-interface commit: `8255a4c52125101f8c8d033766b490975a36ffa5`
- Merged implementation baseline: `origin/main` `b419052becfc8d5e615aa4e0dc558ba2a38e417b`, merged by `c8aa3d4135c647f6a88c16db00d5152e086eacf6`
- Video implementation commits: `86982c7eedefb4e0b280e22734c4cea1545a629d`, `df1f7dc2b9fc2be166ea8ca32cf8be595f3583bb`

## Implemented

- `video_timing_720p.sv`: parameterized one-pixel-per-clock raster timing. The software baseline uses nominal 1280 active pixels, 110 front porch, 40 positive sync, 220 back porch, 720 active lines, 5 front porch, 5 positive sync, and 20 back porch, totaling 1650 by 750. Vendor-reference confirmation remains pending.
- `perspective_projector.sv`: signed Q8.8 logical-court projection with fixed horizon, depth narrowing, height lift, and saturated signed screen outputs.
- `court_renderer.sv` and `net_renderer.sv`: framebuffer-free stadium/crowd, green surround, blue trapezoidal court, perspective lines, center/service/baseline markings, net mesh/band/posts, and foreground/background net separation.
- `sprite_renderer.sv`, `font_rom.sv`, and `ui_renderer.sv`: synchronous palette-indexed ROM reads, transparent sprites, clipping, integer scaling, four player poses, 8-by-8 text, score, connection indicators, and two swing-strength meters.
- `pixel_compositor.sv`: deterministic frozen priority order from background through court/net/players/ball to UI.
- `video_pipeline.sv`: complete procedural scene with ball/shadow, near/far players, UI, aligned RGB/sync/VDE/coordinates, and two registered raster-to-output stages. It issues one vblank request at a time and clears pending only on the mailbox's pixel-domain atomic-capture pulse.
- `scripts/build_assets.py`: deterministic generator/checker for four checked-in memory files. The logical asset payload is 2400 sprite bytes, 768 font bytes, and 48 RGB palette bytes (3216 bytes total), well below the provisional 160 KB budget; synthesis must establish actual BRAM inference.
- Self-checking timing, component, atomic snapshot, and complete-frame regressions under `sim/video/`, with repeatable PowerShell and POSIX shell entry points.

No HDMI serializer, vendor IP wrapper, clock primitive, XDC, Board A top-level integration, or hardware-specific value was implemented or guessed.

## Software handoff contract

`video_pipeline` consumes the frozen `game_render_state_t` after the gameplay/video mailbox has atomically captured it into the pixel domain:

- Inputs: `clk_pix`, active-low `rst_pix_n`, `render_state_pix`, and the one-cycle pixel-domain `pixel_state_valid` completion pulse.
- Snapshot outputs: `vblank_request_toggle` and diagnostic `snapshot_pending`.
- Raster outputs: aligned `pixel_x[11:0]`, `pixel_y[10:0]`, `hsync`, `vsync`, `video_data_enable`, `start_of_line`, `start_of_frame`, and RGB888 `red`, `green`, `blue`.
- Pipeline contract: layer/ROM sampling followed by registered composition; coordinates, sync, VDE, and frame/line flags are delayed through the same two register stages as RGB.
- Reset contract: asynchronous assertion is supported; integration must synchronously deassert reset in `clk_pix` as required by the frozen contract.

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

Commands were run from the repository root on 2026-08-31 (America/New_York), after merging `origin/main` `b419052becfc8d5e615aa4e0dc558ba2a38e417b`:

- `python scripts/build_assets.py` -- PASS: generated 4 deterministic video memories with 3184 addressable entries.
- `python scripts/build_assets.py --check` -- PASS: all 4 checked-in memories exactly matched regenerated content.
- `& .\sim\video\run_video_tests.ps1` -- PASS using Icarus Verilog 12.0:
  - nominal 720p frame length `1,237,500`, active count `921,600`, positive sync widths, VDE region, coordinate bounds, and vertical blank passed;
  - projection depth/height and symmetry, court predicates/symmetry, net layers, font row and score glyph selection, sprite ROM addressing/transparency/edge clipping, and every compositor priority passed;
  - a state change after the system-domain snapshot but before pixel capture produced exactly the complete old snapshot followed by the complete new snapshot, then reset cleanly;
  - the complete frame contained `329,135` court pixels, `348,987` surround pixels, `204,308` crowd pixels, `19,685` line/UI pixels, `81` ball pixels, and `300` player-shirt pixels; both swing-meter widths were exact; RGB was black throughout blanking; one request was issued and acknowledged;
  - all video elaboration and behavioral regressions passed.
- `& .\scripts\run_smoke.ps1` -- PASS: 6 normative protocol vectors, local links in 23 Markdown files, shared-package compile/elaboration, and all 4 cross-track interface smoke tests passed.
- `node scripts/check_markdown_links.mjs` -- PASS after this status update: local links validated in 23 Markdown files.
- `git diff --check` -- PASS with exit code 0 after this status update; Git emitted only the working-tree LF-to-CRLF conversion notice for `status/video.md`, with no whitespace-error diagnostics.

Icarus emitted its non-fatal conservative sensitivity diagnostic (`constant selects in always_* processes ... all bits will be included`) for several combinational blocks. It did not affect elaboration or simulation results; Vivado lint/synthesis remains required to establish production-tool behavior.

## Interface requests

None. Video consumes package revision `0x0100`, the gameplay-to-video seam `1.0`, and the atomic snapshot contract without a frozen-interface change. The pixel pipeline connects to the existing mailbox's `render_state_pix` and `pixel_state_valid` outputs.

## Risks/blockers

- C3 is not passed. No Vivado synthesis, implementation, timing analysis, bitstream, physical Board A output, monitor identification, or five-minute stability run has occurred.
- The exact Real Digital VGA-to-HDMI reference/IP version and interface, supported Vivado version, 74.25 MHz/high-speed clock configuration, sync/polarity expectations, XDC source/pins, and monitor mode remain unverified.
- BRAM/LUT/FF/DSP utilization, inferred ROM implementation, worst setup slack, critical warnings, and physical image quality remain unmeasured.
- Nominal software timing parameters must be checked against the selected vendor-supported HDMI path before top-level integration. Any mismatch is an integration/configuration issue unless it changes the frozen gameplay/video contract.

## Next action

The orchestration owner may accept this branch as a software-simulation video handoff. To claim C3, integration/hardware work must select and document the vendor HDMI path and Vivado version, generate verified clocks, connect authoritative XDC constraints, run synthesis/implementation with non-negative worst setup slack and no unresolved critical warnings, record utilization, program Board A, verify the monitor reports 1280 by 720 at 60 Hz, visually inspect every scene layer and priority, and complete the required five-minute stability run.
