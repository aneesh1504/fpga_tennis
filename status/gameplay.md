# Gameplay Track Status

- Owner: Gameplay/audio implementation owner (`/root/gameplay_f0_review`)
- State: G1 software/simulation handoff ready; recorded-motion and hardware playability evidence pending
- Track document: `docs/05_track_gameplay.md`
- Reviewed base commit: `7dce568348d7b30cda9063822534ab7c3d6ddf2a`
- Frozen-interface commit: `8255a4c52125101f8c8d033766b490975a36ffa5`
- Implementation commits: `4699b3e04a90cd2dcb812fba0049cd8035b2b1ed`, `4df88da7d89c553a8965a2ee26c697dca9924e21`
- Current integration base merged: `origin/main` at `b419052becfc8d5e615aa4e0dc558ba2a38e417b` by merge commit `d4dc520`

## Implemented

- Centralized gameplay tuning and saturating fixed-point helpers in `gameplay_tuning_pkg`.
- Deterministic hysteretic swing detector with explicit idle/armed/tracking/emit/cooldown states, valid/ready backpressure, stale/un-calibrated cancellation, forehand/backhand and upward classification, bounded strength, aim, and lift.
- Bounded shot mapper with deterministic early/good/late timing influence and direction, strength, aim, and lift mapping.
- Q16.16 ball integration with explicit 60 Hz enable, gravity, net-plane boundary checks, in/out bounce handling, restitution, stop events, and saturating arithmetic.
- Rally judge for net faults, out balls, stopped balls, first/double bounce, and deterministic point ownership.
- Conventional point/game/set rules including deuce, advantage, service rotation, win-by-two games, and 7-6 set completion.
- Game engine consuming both frozen motion/health streams and publishing frozen render/audio types. Physics advances only on `game_tick`; audio payloads remain stable under backpressure.
- Synthesizable scripted Player-2 motion opponent, selectable inside the gameplay engine, for one-controller rally integration.
- Atomic toggle-based render-state mailbox with a stable system-domain shadow bank.
- Event-driven hit/bounce/fault/score tone voice, saturating mixer, fractional-rate audio tick generator, PCM output, and one-bit PWM stage.
- Ten deterministic self-checking simulations and repeatable PowerShell/WSL runners under `sim/game/`.

## Tests and evidence

- `powershell -NoProfile -ExecutionPolicy Bypass -File sim/game/run_game_tests.ps1`
  - PASS on implementation commit `4df88da` after merging `origin/main` at `b419052`.
  - PASS: deterministic swing traces cover idle/noise, slow repositioning, forehand, backhand, cooldown separation, stale/un-calibrated suppression, exact threshold, and signed saturation.
  - PASS: early/good/late shot timing maps and maximum/minimum shot values remain bounded.
  - PASS: Q16.16 physics covers net clear/fail boundary heights, in/out bounce, and saturation without wrap.
  - PASS: rally adjudication covers first bounce, double bounce, and net-fault winner.
  - PASS: score progresses through points, deuce, advantage, game, serve rotation, and set.
  - PASS: identical replayed input traces produce bit-identical render/audio state; serve, 60 Hz enable behavior, health publication, and audio backpressure pass.
  - PASS: scripted opponent hit-window, single-trigger, re-arm, and full one-controller serve/return path pass.
  - PASS: atomic render snapshot publication passes.
  - PASS: tone event/duration, mixer saturation, and zero-level PWM density pass.
  - Result: 10 of 10 self-checking Icarus Verilog 12.0 simulations passed.
- `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_smoke.ps1`
  - PASS on the merged implementation: 6 protocol vectors, 22 Markdown files, shared package compile/elaboration, and all four frozen interface seams.
- `git diff --check`
  - PASS: exit code 0 with no output after this status update.

Trace provenance: every gameplay trace in this handoff is deterministic and synthetic, authored in `sim/game/`; no phone recording or hardware measurement is represented as evidence.

## Interface requests

Accepted without changes:

- Motion protocol 1.0 / wire version `0x01`.
- Protocol package revision `0x0100`.
- Game package revision `0x0100`.
- Video package revision `0x0100`.
- Transport-to-gameplay, gameplay-to-video, gameplay-to-audio, and subsystem-to-top cross-track seam version 1.0.

No versioned change request. Frozen-contract changes still require a versioned request and affected-owner acknowledgement.

## Risks/blockers

- Integration must instantiate/wire `game_engine`, `render_state_mailbox`, and `audio_engine`, supply the one-cycle 60 Hz `game_tick`, decide how `scripted_opponent_enable` is selected, and route the frozen render/audio seams. Those edits belong to the integration owner.
- Swing thresholds and shot/physics constants are simulation-safe initial values, not human-factors tuning. They require recorded intentional forehand/backhand/serve/repositioning traces from multiple users.
- The required one-phone rally is proven only with synthetic motion in simulation. It still requires a real phone, transport path, FPGA build, and playable hardware observation.
- No synthesis, timing closure, board programming, HDMI observation, audio-pin measurement, or physical control-latency test has been run by this track.
- G1 is not claimed passed until orchestration accepts the software handoff and the track document's recorded-motion and hardware playability evidence exists.

## Next action

Orchestration may accept and merge the G1 software/simulation handoff. Integration should wire the modules against the frozen seams, then collect recorded phone traces and run the single-player hardware rally before marking G1 fully passed or proceeding to C4 tuning.
