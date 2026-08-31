#!/usr/bin/env sh
set -eu

REPO_DIR=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
cd "$REPO_DIR"
BUILD_DIR=.build/video
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

compile() {
  output=$1
  top=$2
  shift 2
  if [ -n "$IVL_BASE" ]; then
    "$IVERILOG_BIN" -B "$IVL_BASE" -g2012 -Wall -Wimplicit -s "$top" -o "$BUILD_DIR/$output" "$@"
  else
    "$IVERILOG_BIN" -g2012 -Wall -Wimplicit -s "$top" -o "$BUILD_DIR/$output" "$@"
  fi
}

compile timing.vvp tb_video_timing_720p \
  rtl/video/video_timing_720p.sv \
  sim/video/tb_video_timing_720p.sv
"$VVP_BIN" "$BUILD_DIR/timing.vvp"

compile components.vvp tb_video_components \
  rtl/packages/video_types_pkg.sv \
  rtl/video/perspective_projector.sv \
  rtl/video/court_renderer.sv \
  rtl/video/net_renderer.sv \
  rtl/video/sprite_renderer.sv \
  rtl/video/font_rom.sv \
  rtl/video/ui_renderer.sv \
  rtl/video/pixel_compositor.sv \
  sim/video/tb_video_components.sv
"$VVP_BIN" "$BUILD_DIR/components.vvp"

compile snapshot_atomic.vvp tb_video_snapshot_atomic \
  rtl/packages/video_types_pkg.sv \
  sim/interfaces/gameplay_video_stub.sv \
  sim/video/tb_video_snapshot_atomic.sv
"$VVP_BIN" "$BUILD_DIR/snapshot_atomic.vvp"

compile pipeline.vvp tb_video_pipeline \
  rtl/packages/video_types_pkg.sv \
  rtl/video/video_timing_720p.sv \
  rtl/video/perspective_projector.sv \
  rtl/video/court_renderer.sv \
  rtl/video/net_renderer.sv \
  rtl/video/sprite_renderer.sv \
  rtl/video/font_rom.sv \
  rtl/video/ui_renderer.sv \
  rtl/video/pixel_compositor.sv \
  rtl/video/video_pipeline.sv \
  sim/video/tb_video_pipeline.sv
"$VVP_BIN" "$BUILD_DIR/pipeline.vvp"

echo "PASS: all video elaboration and behavioral regressions"
