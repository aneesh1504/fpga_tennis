#!/usr/bin/env sh
set -eu

REPO_DIR=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
cd "$REPO_DIR"
BUILD_DIR=.build/integration
mkdir -p "$BUILD_DIR"

if command -v iverilog >/dev/null 2>&1 && command -v vvp >/dev/null 2>&1; then
  IVERILOG_BIN=iverilog
  VVP_BIN=vvp
  IVL_BASE=
else
  TOOL_ROOT=.build/tools/iverilog/root
  if [ ! -x "$TOOL_ROOT/usr/bin/iverilog" ]; then
    scripts/run_sim_wsl.sh >/dev/null
  fi
  IVERILOG_BIN="$REPO_DIR/$TOOL_ROOT/usr/bin/iverilog"
  VVP_BIN="$REPO_DIR/$TOOL_ROOT/usr/bin/vvp"
  IVL_BASE="$REPO_DIR/$TOOL_ROOT/usr/lib/x86_64-linux-gnu/ivl"
  PATH="$REPO_DIR/$TOOL_ROOT/usr/bin:$PATH"
  export PATH
fi

if [ -n "$IVL_BASE" ]; then
  "$IVERILOG_BIN" -B "$IVL_BASE" -g2012 -Wall -Wimplicit -s tb_board_a_system \
    -o "$BUILD_DIR/board_a_system.vvp" \
    rtl/packages/protocol_pkg.sv \
    rtl/packages/game_types_pkg.sv \
    rtl/packages/video_types_pkg.sv \
    rtl/common/reset_sync.sv \
    rtl/common/tick_gen.sv \
    rtl/common/uart_rx.sv \
    rtl/common/crc16_ccitt.sv \
    rtl/common/frame_unescaper.sv \
    rtl/common/motion_packet_decoder.sv \
    rtl/common/motion_transport_rx.sv \
    rtl/common/dual_motion_transport_rx.sv \
    rtl/game/gameplay_tuning_pkg.sv \
    rtl/game/swing_detector.sv \
    rtl/game/scripted_opponent.sv \
    rtl/game/shot_mapper.sv \
    rtl/game/ball_physics.sv \
    rtl/game/tennis_rules.sv \
    rtl/game/rally_judge.sv \
    rtl/game/game_engine.sv \
    rtl/game/render_state_mailbox.sv \
    rtl/audio/tone_voice.sv \
    rtl/audio/pwm_audio_out.sv \
    rtl/audio/audio_engine.sv \
    rtl/video/video_timing_720p.sv \
    rtl/video/perspective_projector.sv \
    rtl/video/court_renderer.sv \
    rtl/video/net_renderer.sv \
    rtl/video/sprite_renderer.sv \
    rtl/video/font_rom.sv \
    rtl/video/ui_renderer.sv \
    rtl/video/pixel_compositor.sv \
    rtl/video/video_pipeline.sv \
    rtl/board_a_system.sv \
    sim/integration/tb_board_a_system.sv
else
  "$IVERILOG_BIN" -g2012 -Wall -Wimplicit -s tb_board_a_system \
    -o "$BUILD_DIR/board_a_system.vvp" \
    rtl/packages/protocol_pkg.sv \
    rtl/packages/game_types_pkg.sv \
    rtl/packages/video_types_pkg.sv \
    rtl/common/reset_sync.sv \
    rtl/common/tick_gen.sv \
    rtl/common/uart_rx.sv \
    rtl/common/crc16_ccitt.sv \
    rtl/common/frame_unescaper.sv \
    rtl/common/motion_packet_decoder.sv \
    rtl/common/motion_transport_rx.sv \
    rtl/common/dual_motion_transport_rx.sv \
    rtl/game/gameplay_tuning_pkg.sv \
    rtl/game/swing_detector.sv \
    rtl/game/scripted_opponent.sv \
    rtl/game/shot_mapper.sv \
    rtl/game/ball_physics.sv \
    rtl/game/tennis_rules.sv \
    rtl/game/rally_judge.sv \
    rtl/game/game_engine.sv \
    rtl/game/render_state_mailbox.sv \
    rtl/audio/tone_voice.sv \
    rtl/audio/pwm_audio_out.sv \
    rtl/audio/audio_engine.sv \
    rtl/video/video_timing_720p.sv \
    rtl/video/perspective_projector.sv \
    rtl/video/court_renderer.sv \
    rtl/video/net_renderer.sv \
    rtl/video/sprite_renderer.sv \
    rtl/video/font_rom.sv \
    rtl/video/ui_renderer.sv \
    rtl/video/pixel_compositor.sv \
    rtl/video/video_pipeline.sv \
    rtl/board_a_system.sv \
    sim/integration/tb_board_a_system.sv
fi

"$VVP_BIN" "$BUILD_DIR/board_a_system.vvp"
echo "PASS: Board A structural integration regression"
