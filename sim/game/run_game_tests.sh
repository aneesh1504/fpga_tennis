#!/usr/bin/env sh
set -eu

REPO_DIR=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
cd "$REPO_DIR"

if command -v iverilog >/dev/null 2>&1 && command -v vvp >/dev/null 2>&1; then
  IVERILOG_BIN=iverilog
  VVP_BIN=vvp
  IVERILOG_BASE=
else
  if [ ! -x .build/tools/iverilog/root/usr/bin/iverilog ]; then
    sh scripts/run_sim_wsl.sh
  fi
  IVERILOG_BIN=.build/tools/iverilog/root/usr/bin/iverilog
  VVP_BIN=.build/tools/iverilog/root/usr/bin/vvp
  IVERILOG_BASE=.build/tools/iverilog/root/usr/lib/x86_64-linux-gnu/ivl
fi

BUILD_DIR=.build/gameplay
mkdir -p "$BUILD_DIR"

compile_and_run() {
  name=$1
  top=$2
  testbench=$3
  shift 3
  if [ -n "$IVERILOG_BASE" ]; then
    "$IVERILOG_BIN" -B "$IVERILOG_BASE" -g2012 -Wall -s "$top" \
      -o "$BUILD_DIR/$name.vvp" "$@" "$testbench"
  else
    "$IVERILOG_BIN" -g2012 -Wall -s "$top" \
      -o "$BUILD_DIR/$name.vvp" "$@" "$testbench"
  fi
  "$VVP_BIN" "$BUILD_DIR/$name.vvp"
}

PACKAGES="rtl/packages/protocol_pkg.sv rtl/packages/game_types_pkg.sv rtl/packages/video_types_pkg.sv rtl/game/gameplay_tuning_pkg.sv"
GAME_RTL="rtl/game/swing_detector.sv rtl/game/shot_mapper.sv rtl/game/ball_physics.sv rtl/game/rally_judge.sv rtl/game/tennis_rules.sv rtl/game/scripted_opponent.sv rtl/game/game_engine.sv rtl/game/render_state_mailbox.sv"
AUDIO_RTL="rtl/audio/tone_voice.sv rtl/audio/audio_mixer.sv rtl/audio/pwm_audio_out.sv rtl/audio/audio_engine.sv"

# Word splitting is intentional for these repository-relative source lists.
# shellcheck disable=SC2086
compile_and_run swing_detector tb_swing_detector sim/game/tb_swing_detector.sv $PACKAGES $GAME_RTL
# shellcheck disable=SC2086
compile_and_run shot_mapper tb_shot_mapper sim/game/tb_shot_mapper.sv $PACKAGES $GAME_RTL
# shellcheck disable=SC2086
compile_and_run ball_physics tb_ball_physics sim/game/tb_ball_physics.sv $PACKAGES $GAME_RTL
# shellcheck disable=SC2086
compile_and_run rally_judge tb_rally_judge sim/game/tb_rally_judge.sv $PACKAGES $GAME_RTL
# shellcheck disable=SC2086
compile_and_run tennis_rules tb_tennis_rules sim/game/tb_tennis_rules.sv $PACKAGES $GAME_RTL
# shellcheck disable=SC2086
compile_and_run game_engine tb_game_engine sim/game/tb_game_engine.sv $PACKAGES $GAME_RTL
# shellcheck disable=SC2086
compile_and_run scripted_opponent tb_scripted_opponent sim/game/tb_scripted_opponent.sv $PACKAGES $GAME_RTL
# shellcheck disable=SC2086
compile_and_run scripted_rally tb_scripted_rally sim/game/tb_scripted_rally.sv $PACKAGES $GAME_RTL
# shellcheck disable=SC2086
compile_and_run render_mailbox tb_render_state_mailbox sim/game/tb_render_state_mailbox.sv $PACKAGES $GAME_RTL
# shellcheck disable=SC2086
compile_and_run audio tb_audio sim/game/tb_audio.sv $PACKAGES $AUDIO_RTL

echo "PASS: gameplay/audio regression (10 self-checking simulations)"
