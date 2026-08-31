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
