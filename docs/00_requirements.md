# Product Requirements and Constraints

## Experience brief

The game should feel like a simple living-room motion tennis game rather than an FPGA technology demo. Two players hold iPhones as rackets, calibrate, and swing. The game interprets intentional gestures and automatically positions each avatar so players focus on timing and shot selection.

The display uses a behind-the-near-player perspective. It is technically 2D but presents depth through a trapezoidal court, a horizon, different sprite sizes, ball height/shadow separation, and perspective projection. The intended finish is comparable to a polished retro/early-arcade sports title, not modern textured 3D.

## Functional requirements

### Controller

- Sample processed iPhone motion at 50 Hz initially.
- Send gravity-removed acceleration, rotation rate, attitude quaternion, sequence number, timestamp, role, and status.
- Provide explicit Player 1/Player 2 selection and calibration.
- Show connection, calibration, and streaming state.
- Detect and report BLE backpressure or disconnection.
- Later receive hit/miss/score events for local haptic feedback.

### Gameplay

- Support serve, rally, miss, point, game, and match states.
- Distinguish at minimum left/right or forehand/backhand swing direction.
- Derive shot strength from a bounded motion window.
- Use swing timing and orientation to influence aim and ball height.
- Handle bounce, net, in/out, and basic tennis scoring.
- Automatically position player sprites; absolute controller location is unnecessary.

### Video and audio

- Output 1280×720 at 60 Hz.
- Render a perspective court, net, two players, racket, ball, ball shadow/trail, scoreboard, connection indicators, and swing meter.
- Use compact sprite animation and a bitmap font.
- Produce basic stereo-compatible PWM/PDM tones for serve, hit, bounce, fault, and score.

## Hardware inventory

Required:

- Two Real Digital Boolean Boards with populated BLE modules and Pmod connectors.
- Two iPhones that support Core Motion and BLE.
- One Mac for Xcode and the established Vivado/programming workflow.
- One HDMI cable and a 720p-capable monitor/TV.
- Three male-to-male 0.1-inch jumper wires for board UART (`TX`, `RX`, `GND`).
- One USB cable/power connection per board.
- Powered speakers or headphones appropriate for the board's 3.5 mm output.
- Two secure phone wrist straps for motion testing.

Useful during development:

- nRF Connect or LightBlue for BLE inspection only; neither is part of the final game.
- Vivado Integrated Logic Analyzer.
- A USB logic analyzer or oscilloscope if UART wiring is difficult to debug.

## Known board capabilities

- Spartan-7 XC7S50-CSGA324.
- 100 MHz onboard oscillator.
- Approximately 337 KB of FPGA block RAM and 120 DSP blocks.
- Stock BLE-to-FPGA UART at 115,200 baud, with newline-triggered packet forwarding.
- HDMI source supported through the Real Digital VGA-to-HDMI design flow.
- Stereo analog output intended for PWM/PDM-style audio.
- Female Pmod/Pmod+ expansion sockets exposing FPGA GPIO.

Treat the official board manual, schematic, XDC, and installed Vivado IP as authoritative if any planning value conflicts with the actual hardware.

## Engineering constraints

### No full framebuffer

A 24-bit 1280×720 framebuffer needs about 2.76 MB, far beyond internal BRAM. The renderer must produce pixels as the raster scans. Store only fonts, palettes, small sprites, and limited animation frames.

### No absolute position from acceleration

Double-integrating consumer-phone acceleration drifts quickly. The controller is a gesture device, not a tracked 3D object. Use acceleration, gyro, attitude, thresholds, and short windows to classify a swing.

### Fixed-point datapaths

Gameplay and projection should use fixed-point arithmetic. Floating-point IP is unnecessary. Prefer bounded ranges, explicit saturation, and documented Q formats.

### One authoritative game state

Only Board A advances physics and scoring. Board B forwards controller traffic and returns feedback. Do not run replicated simulations that require board synchronization.

## Quality targets

- Input: sustained 50 Hz per player with at least 99.5% observed frame delivery during checkpoint tests.
- Video: stable 720p60, no visible tearing, non-negative implementation slack.
- Responsiveness: no deliberate multi-frame buffering; tune for a perceived response under roughly 100 ms on a Game Mode display.
- Reliability: stale-controller state within 250 ms of missing frames; clean recovery after reconnect.
- Resource margin: target less than 70% BRAM and less than 60% LUT/FF utilization until measured needs justify a change.

