# Track — 720p Procedural Video Pipeline

## Objective

Produce a stable 1280×720/60 Hz HDMI signal and render the complete visual vocabulary of the game without a full framebuffer. Establish timing and BRAM feasibility before complex gameplay is attached.

This track starts after F0 and does not wait for BLE or board-link checkpoints. Drive the renderer with frozen `game_render_state_t` test fixtures until gameplay integration.

## Ownership and handoff

This track owns `rtl/video/`, `assets/`, `scripts/build_assets.py`, `sim/video/`, and `status/video.md`. It consumes `video_types_pkg.sv` without editing it and does not edit top-level Board A integration or shared Vivado project files. Send required clock/IP/top-level changes to the integration owner through `status/video.md`.

## Design position

The FPGA does not build an image in memory. It receives the current raster coordinate and emits one pixel per `clk_pix` cycle. Court/background geometry is computed procedurally; only compact fonts, palettes, and player animation frames live in BRAM.

Nominal 720p60 timing uses a 74.25 MHz pixel clock. Use the timing parameters required by the verified Real Digital VGA-to-HDMI reference/IP; do not substitute remembered values when the installed core's requirements are available.

## Implementation sequence

### 1. Vendor-supported HDMI bring-up

- Import or regenerate the Real Digital VGA-to-HDMI IP/reference path using the documented Vivado version.
- Generate the required pixel and high-speed clocks with supported clocking primitives.
- Drive color bars and confirm the monitor reports 1280×720 at 60 Hz.
- Record IP version, clock configuration, and monitor mode in the hardware manifest.
- Preserve a minimal known-good video top/test bitstream for regression.

### 2. Timing generator and pipeline contract

`video_timing_720p.sv` produces pipelined:

- Horizontal and vertical pixel coordinates.
- Horizontal sync, vertical sync, and video-data-enable.
- Start-of-line, start-of-frame, and vertical-blank indications.

Define a documented pipeline latency from input coordinate to output RGB/sync/VDE. Delay control signals by exactly the same latency as the layer data.

### 3. Static procedural court

Implement flat layers first:

- Stadium/crowd background using repeated patterns or simple ROM rows.
- Green outside court.
- Blue trapezoidal court.
- White perspective boundary/service/center lines.
- Net posts, band, and repeated mesh pattern.

Avoid general division in the pixel path. Use constant-coefficient comparisons, line inequalities, scanline boundary accumulation, lookup tables, or pipelined fixed-point multiplication.

### 4. Sprites and font

- Start with colored placeholder rectangles to validate priority and coordinates.
- Use palette-indexed sprite ROMs with one reserved transparent index.
- Generate `.mem` assets with a deterministic script checked into `scripts/`.
- Use nearest-neighbor integer scaling only if needed; prefer separate near/far assets to arbitrary scaling hardware.
- Implement a compact bitmap font for score, player labels, connection status, and swing power.
- Limit animation initially to idle, forehand, backhand, and serve poses.

### 5. Dynamic ball/UI scene

Before gameplay exists, animate deterministic test values:

- A ball following a scripted arc.
- A projected shadow following the court surface.
- Near/far player animation cycling.
- Scoreboard values.
- Player connection dots and stale indication.
- Swing-power bar.

This ensures the renderer is fully exercised without coupling failures to physics.

## Recommended rendering model

Game state uses logical court coordinates. A fixed perspective projector maps them to screen coordinates:

- Court width narrows toward a fixed horizon.
- World height moves a sprite/ball upward independently of its court shadow.
- Near and far players use fixed-size sprite sets; optional small discrete size variants are preferable to arbitrary resampling.

The exact visual target is:

- Behind-the-near-player camera.
- Blue hard court with green surround.
- Strong trapezoidal perspective and centered net.
- Small far-player sprite and larger near-player sprite.
- Flat colors, hard edges, minimal palette, no per-pixel lighting.
- Crisp scoreboard and status UI.

## BRAM and throughput budget

- Do not allocate a full-screen framebuffer or large line-buffer unless a measured requirement justifies it.
- Budget sprite/font/palette storage before creating final art.
- Keep total BRAM below approximately 70% through the MVP to preserve room for FIFOs, optional animation, and debug IP.
- Use transparent color-key composition rather than alpha blending.
- Each rendering stage must accept one pixel per cycle after pipeline fill.
- Pipeline expensive comparisons/multiplies rather than lowering the pixel rate.

An example conservative asset budget is up to roughly 160 KB for all sprite frames and fonts, but the implementation agent must report actual inferred BRAM and adjust asset sizes based on synthesis.

## Clock-domain crossing

Use the render-state mailbox in `docs/01_architecture.md`.

- The game domain publishes a coherent snapshot once per vertical blank.
- The pixel domain uses that snapshot for the entire active frame.
- Do not synchronize coordinates, scores, or animation fields independently.
- Simulate a state change near the frame boundary and prove only complete old/new snapshots appear.

## Simulation and static verification

- Verify total pixels per line/frame, sync polarity/width, and VDE region against the chosen timing standard/IP.
- Assert coordinates stay within defined ranges.
- Verify all layer latencies align at the compositor.
- Test court predicate boundaries and symmetry at representative scanlines.
- Test sprite transparency, clipping at all screen edges, and ROM-address bounds.
- Test font glyph selection and score values.
- Confirm no inferred latches and no unintended asynchronous RAM behavior.

## Checkpoint C3 — pass criteria

1. Program Board A with the scripted complete test scene.
2. Confirm the monitor identifies 1280×720 at 60 Hz.
3. Run for five minutes with no blanking, resynchronization, or visible instability.
4. Inspect court lines, net, sprites, ball/shadow, score, and UI for correct clipping and priority.
5. Run synthesis and implementation with all production video layers enabled.

C3 passes when:

- Output is stable at the required resolution/refresh.
- The scene visually represents the intended 2.5D game.
- Worst setup slack is non-negative in the implemented design.
- There are no unresolved critical warnings.
- BRAM/LUT/FF/DSP utilization and clock configuration are recorded.
- The video test scene can be rebuilt reproducibly from source and asset scripts.

Record the implementation commit, timing/resource evidence, monitor test, and exact handoff ports in `status/video.md`. Integration may consume the track only after C3 is recorded as passed.
