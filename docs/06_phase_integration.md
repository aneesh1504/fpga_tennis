# Phase 5 — Integration, Tuning, and Final Handoff

## Objective

Combine the proven BLE, two-board UART, video, swing, and game subsystems into a dependable two-player experience. Add limited polish only after the integrated MVP is stable.

## Integration order

1. Board A receives both controller states while displaying the stable scripted video scene.
2. Replace scripted ball/player values with frame-consistent `game_render_state_t` snapshots.
3. Enable swing detection for Player 1 only; verify no effect from Player 2.
4. Enable Player 2 and verify identity, court side, and scoring ownership.
5. Enable audio events.
6. Enable Board A → Board B → Phone 2 feedback, then Board A → Phone 1 feedback if supported.
7. Add final sprites/animation and UI polish within measured timing/BRAM margin.

At every step, rerun the relevant transport/video simulations and inspect hardware counters. Do not debug all subsystems simultaneously.

## Audio design

Use a small event-driven synthesizer rather than stored PCM:

- Independent simple tone/noise voices for racket hit, bounce, net/fault, and score.
- Phase accumulators or counters feeding square/PWM/PDM waveforms.
- Saturating mixer with conservative level.
- Map the same mono mix to both channels initially; optional stereo positioning can come later.
- Respect the board output circuit's limited audio bandwidth.

Audio must not create a new clock domain if a system-clock PWM/PDM implementation is sufficient.

## Phone feedback

If the verified BLE characteristic supports board-to-phone notifications:

- Define a versioned compact event frame for connected, hit, miss, serve, point, and reconnect state.
- Board A sends Player 2 events over reverse Pmod UART to Board B, which forwards bytes unchanged to its BLE UART.
- The Swift app triggers local haptics; do not wait for haptics before advancing game state.
- Rate-limit repeated status events and keep feedback lower priority than fresh motion.

Haptics are desirable but not allowed to block C4 if stock BLE firmware cannot provide a reliable return characteristic. Document that limitation if discovered.

## Performance and correctness review

### Transport

- Confirm both streams remain at 50 Hz under full rendering/audio load.
- Confirm no new UART/FIFO/CRC/sequence errors.
- Confirm controller stale and reconnect behavior.

### Timing and resources

- Run full Vivado synthesis and implementation for both tops.
- Record LUT, FF, BRAM, DSP, clock-buffer utilization, worst setup slack, and worst hold slack.
- Resolve critical warnings.
- Confirm no debug core consumes unacceptable resources in release bitstreams.

### Gameplay

- Test serve, rally, net, in/out, miss, double bounce, score, game reset, and reconnect during play.
- Test left/right-handed or grip-orientation assumptions with at least two users; provide a calibration/orientation setting if necessary.
- Clamp all strength/aim values to prevent unstable shots.

### Video/audio

- Verify no tearing during rapid motion and score changes.
- Verify sprites clip safely and never address ROM out of bounds.
- Verify audio level and event timing without harsh sustained DC output.

## Final checkpoint C4

Conduct a ten-minute two-player session with a monitor/TV in Game Mode.

Collect:

- Generated/received/sequence-gap/CRC/framing/FIFO counters per player.
- Controller stale/reconnect events.
- Full Board A timing/resource report summary.
- Observed gameplay failures with timestamps or reproduction steps.
- Short video or human-observed checklist showing serve, rally, score, audio, and both players.

C4 passes when:

- Two players can connect, calibrate, serve, rally, score, and restart without developer intervention.
- Each phone controls only its assigned player.
- There are no recurring input stalls, double-trigger storms, parser lockups, FIFO overflows, or video instability.
- Disconnect/stale behavior is safe and recovery does not require reprogramming.
- Match state and scoring remain correct throughout the session.
- Full design meets timing with no unresolved critical warnings.

## Final artifacts

The implementation agent must deliver:

- Source-controlled SystemVerilog and tests.
- Reproducible Board A and Board B Vivado projects/scripts.
- Board A and Board B release bitstreams with build identifiers.
- Swift/Xcode project and physical-iPhone run instructions.
- Official/verified XDC-derived pin assignments.
- BLE UUID and characteristic manifest.
- Pmod wiring table and photo/diagram.
- Protocol specification and golden vectors.
- Resource/timing summary.
- Bring-up and troubleshooting guide.
- Known limitations and deferred improvements.

## Optional improvements after C4

Only after the MVP passes:

- More animation frames and sprite polish.
- Spin/slice classification.
- Difficulty-adjustable AI for solo play.
- Local haptic feedback and richer sound.
- Replay trail or slow-motion point recap.
- A more capable external BLE radio allowing both phones to connect to one board.
- Higher sensor rate if measurements prove it improves control without increasing loss/latency.

These are not required for the initial success criterion.

