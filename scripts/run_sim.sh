#!/usr/bin/env sh
set -eu

IVERILOG_BIN="${IVERILOG:-iverilog}"
BUILD_DIR="${BUILD_DIR:-.build/smoke}"
mkdir -p "$BUILD_DIR"

"$IVERILOG_BIN" -g2012 -s tb_package_compile -o "$BUILD_DIR/package_compile.vvp" \
  rtl/packages/protocol_pkg.sv \
  rtl/packages/game_types_pkg.sv \
  rtl/packages/video_types_pkg.sv \
  sim/interfaces/tb_package_compile.sv
vvp "$BUILD_DIR/package_compile.vvp"

"$IVERILOG_BIN" -g2012 -s tb_interface_smoke -o "$BUILD_DIR/interface_smoke.vvp" \
  rtl/packages/protocol_pkg.sv \
  rtl/packages/game_types_pkg.sv \
  rtl/packages/video_types_pkg.sv \
  sim/interfaces/transport_gameplay_stub.sv \
  sim/interfaces/gameplay_video_stub.sv \
  sim/interfaces/gameplay_audio_stub.sv \
  rtl/board_a_top.sv \
  sim/interfaces/tb_interface_smoke.sv
vvp "$BUILD_DIR/interface_smoke.vvp"
