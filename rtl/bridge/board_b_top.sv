`timescale 1ns/1ps

module board_b_top #(
  parameter int unsigned CLOCK_HZ = 100_000_000,
  parameter int unsigned BLE_BAUD = 115_200,
  parameter int unsigned PMOD_BAUD = 115_200,
  parameter int unsigned FIFO_DEPTH = 128
) (
  input  logic                         clk,
  input  logic                         rst_n,
  input  logic                         ble_uart_rx,
  output logic                         ble_uart_tx,
  input  logic                         pmod_uart_rx,
  output logic                         pmod_uart_tx,
  output logic [31:0]                  forward_input_bytes,
  output logic [31:0]                  forward_output_bytes,
  output logic [31:0]                  forward_complete_frames,
  output logic [31:0]                  forward_fifo_overflows,
  output logic [$clog2(FIFO_DEPTH):0]  forward_fifo_high_water,
  output logic [31:0]                  reverse_input_bytes,
  output logic [31:0]                  reverse_output_bytes,
  output logic [31:0]                  reverse_complete_frames,
  output logic [31:0]                  reverse_fifo_overflows,
  output logic [$clog2(FIFO_DEPTH):0]  reverse_fifo_high_water,
  output logic [31:0]                  ble_rx_framing_errors,
  output logic [31:0]                  pmod_rx_framing_errors
);
  logic ble_rx_valid;
  logic [7:0] ble_rx_data;
  logic ble_rx_error_unused;
  logic pmod_rx_valid;
  logic [7:0] pmod_rx_data;
  logic pmod_rx_error_unused;

  logic forward_ready_unused;
  logic forward_valid;
  logic forward_tx_ready;
  logic [7:0] forward_data;
  logic forward_tx_busy_unused;
  logic [$clog2(FIFO_DEPTH):0] forward_level_unused;

  logic reverse_ready_unused;
  logic reverse_valid;
  logic reverse_tx_ready;
  logic [7:0] reverse_data;
  logic reverse_tx_busy_unused;
  logic [$clog2(FIFO_DEPTH):0] reverse_level_unused;

  uart_rx #(.CLOCK_HZ(CLOCK_HZ), .BAUD(BLE_BAUD)) ble_receiver (
    .clk, .rst_n, .serial_rx(ble_uart_rx), .data_valid(ble_rx_valid),
    .data(ble_rx_data), .framing_error(ble_rx_error_unused),
    .framing_error_count(ble_rx_framing_errors)
  );

  frame_forwarder #(.FIFO_DEPTH(FIFO_DEPTH)) forward_path (
    .clk, .rst_n, .in_byte_valid(ble_rx_valid),
    .in_byte_ready(forward_ready_unused), .in_byte(ble_rx_data),
    .out_byte_valid(forward_valid), .out_byte_ready(forward_tx_ready),
    .out_byte(forward_data), .input_bytes(forward_input_bytes),
    .output_bytes(forward_output_bytes),
    .complete_frames(forward_complete_frames),
    .fifo_overflows(forward_fifo_overflows),
    .fifo_level(forward_level_unused),
    .fifo_high_water(forward_fifo_high_water)
  );

  uart_tx #(.CLOCK_HZ(CLOCK_HZ), .BAUD(PMOD_BAUD)) pmod_transmitter (
    .clk, .rst_n, .data_valid(forward_valid),
    .data_ready(forward_tx_ready), .data(forward_data),
    .serial_tx(pmod_uart_tx), .busy(forward_tx_busy_unused)
  );

  uart_rx #(.CLOCK_HZ(CLOCK_HZ), .BAUD(PMOD_BAUD)) pmod_receiver (
    .clk, .rst_n, .serial_rx(pmod_uart_rx), .data_valid(pmod_rx_valid),
    .data(pmod_rx_data), .framing_error(pmod_rx_error_unused),
    .framing_error_count(pmod_rx_framing_errors)
  );

  frame_forwarder #(.FIFO_DEPTH(FIFO_DEPTH)) reverse_path (
    .clk, .rst_n, .in_byte_valid(pmod_rx_valid),
    .in_byte_ready(reverse_ready_unused), .in_byte(pmod_rx_data),
    .out_byte_valid(reverse_valid), .out_byte_ready(reverse_tx_ready),
    .out_byte(reverse_data), .input_bytes(reverse_input_bytes),
    .output_bytes(reverse_output_bytes),
    .complete_frames(reverse_complete_frames),
    .fifo_overflows(reverse_fifo_overflows),
    .fifo_level(reverse_level_unused),
    .fifo_high_water(reverse_fifo_high_water)
  );

  uart_tx #(.CLOCK_HZ(CLOCK_HZ), .BAUD(BLE_BAUD)) ble_transmitter (
    .clk, .rst_n, .data_valid(reverse_valid),
    .data_ready(reverse_tx_ready), .data(reverse_data),
    .serial_tx(ble_uart_tx), .busy(reverse_tx_busy_unused)
  );
endmodule
