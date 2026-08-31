#!/usr/bin/env sh
set -eu

IVERILOG_BIN="${IVERILOG:-iverilog}"
BUILD_DIR="${BUILD_DIR:-.build/transport}"
mkdir -p "$BUILD_DIR"

compile_and_run() {
  top="$1"
  shift
  "$IVERILOG_BIN" -g2012 -Wall -s "$top" -o "$BUILD_DIR/$top.vvp" "$@"
  vvp "$BUILD_DIR/$top.vvp"
}

compile_and_run tb_common_primitives \
  rtl/common/reset_sync.sv \
  rtl/common/tick_gen.sv \
  rtl/common/uart_rx.sv \
  rtl/common/uart_tx.sv \
  rtl/common/sync_fifo.sv \
  rtl/common/crc16_ccitt.sv \
  sim/common/tb_common_primitives.sv

python3 sim/common/make_transport_vectors.py sim/vectors/motion_protocol_v1.json "$BUILD_DIR/vectors"

compile_and_run tb_motion_decoder \
  rtl/packages/protocol_pkg.sv \
  rtl/common/crc16_ccitt.sv \
  rtl/common/frame_unescaper.sv \
  rtl/common/motion_packet_decoder.sv \
  sim/common/tb_motion_decoder.sv

compile_and_run tb_motion_transport_rx \
  rtl/packages/protocol_pkg.sv \
  rtl/common/tick_gen.sv \
  rtl/common/uart_rx.sv \
  rtl/common/crc16_ccitt.sv \
  rtl/common/frame_unescaper.sv \
  rtl/common/motion_packet_decoder.sv \
  rtl/common/motion_transport_rx.sv \
  sim/common/tb_motion_transport_rx.sv

compile_and_run tb_dual_motion_transport_rx \
  rtl/packages/protocol_pkg.sv \
  rtl/common/tick_gen.sv \
  rtl/common/uart_rx.sv \
  rtl/common/crc16_ccitt.sv \
  rtl/common/frame_unescaper.sv \
  rtl/common/motion_packet_decoder.sv \
  rtl/common/motion_transport_rx.sv \
  rtl/common/dual_motion_transport_rx.sv \
  sim/common/tb_dual_motion_transport_rx.sv

compile_and_run tb_frame_forwarder \
  rtl/common/sync_fifo.sv \
  rtl/bridge/frame_forwarder.sv \
  sim/common/tb_frame_forwarder.sv

compile_and_run tb_board_b_top \
  rtl/common/uart_rx.sv \
  rtl/common/uart_tx.sv \
  rtl/common/sync_fifo.sv \
  rtl/bridge/frame_forwarder.sv \
  rtl/bridge/board_b_top.sv \
  sim/common/tb_board_b_top.sv
