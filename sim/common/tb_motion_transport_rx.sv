`timescale 1ns/1ps

module tb_motion_transport_rx;
  import protocol_pkg::*;

  localparam int CLOCK_HZ = 1_000_000;
  localparam int BAUD = 100_000;
  localparam int CLKS_PER_BIT = CLOCK_HZ / BAUD;
  localparam int VECTOR_COUNT = 6;
  localparam int VECTOR_STRIDE = 80;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;

  logic serial_rx;
  logic sample_valid;
  logic sample_ready;
  motion_sample_t sample;
  transport_health_t sample_health;
  transport_health_t debug_health;

  logic [7:0] framed_bytes [0:VECTOR_COUNT*VECTOR_STRIDE-1];
  logic [7:0] vector_lengths [0:VECTOR_COUNT-1];

  integer transfer_count;
  motion_sample_t transferred_sample;
  transport_health_t transferred_health;
  motion_sample_t held_sample;
  transport_health_t held_health;
  integer byte_index;
  integer target_count;

  motion_transport_rx #(
    .CLOCK_HZ(CLOCK_HZ),
    .BAUD(BAUD),
    .ACCEPTED_PLAYER_ID(8'h00),
    .FRAME_TIMEOUT_MS(5),
    .STALE_TIMEOUT_MS(50)
  ) dut (
    .clk,
    .rst_n,
    .serial_rx,
    .sample_valid,
    .sample_ready,
    .sample,
    .sample_health,
    .debug_health
  );

  always @(posedge clk) begin
    if (sample_valid && sample_ready) begin
      transfer_count <= transfer_count + 1;
      transferred_sample <= sample;
      transferred_health <= sample_health;
    end
  end

  task automatic send_serial_byte(input logic [7:0] value);
    integer bit_number;
    begin
      @(negedge clk);
      serial_rx = 1'b0;
      repeat (CLKS_PER_BIT) @(negedge clk);
      for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
        serial_rx = value[bit_number];
        repeat (CLKS_PER_BIT) @(negedge clk);
      end
      serial_rx = 1'b1;
      repeat (CLKS_PER_BIT) @(negedge clk);
    end
  endtask

  task automatic send_vector(input integer selected_vector);
    integer offset;
    begin
      offset = selected_vector * VECTOR_STRIDE;
      for (byte_index = 0; byte_index < vector_lengths[selected_vector]; byte_index = byte_index + 1) begin
        send_serial_byte(framed_bytes[offset + byte_index]);
      end
    end
  endtask

  task automatic wait_for_transfer(input integer expected_count);
    integer guard;
    begin
      guard = 0;
      while (transfer_count < expected_count && guard < 100_000) begin
        @(posedge clk);
        guard = guard + 1;
      end
      if (transfer_count != expected_count) $fatal(1, "timed out waiting for transfer %0d", expected_count);
      repeat (2) @(posedge clk);
    end
  endtask

  initial begin
    $readmemh(".build/transport/vectors/framed_bytes.hex", framed_bytes);
    $readmemh(".build/transport/vectors/lengths.hex", vector_lengths);

    serial_rx = 1'b1;
    sample_ready = 1'b1;
    transfer_count = 0;
    transferred_sample = '0;
    transferred_health = '0;

    repeat (5) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;

    send_vector(4);
    wait_for_transfer(1);
    if (transferred_sample.sequence_number != 16'hffff || transferred_sample.stale) begin
      $fatal(1, "sequence-wrap-before decode mismatch");
    end

    send_vector(5);
    wait_for_transfer(2);
    if (transferred_sample.sequence_number != 16'h0000 || transferred_health.sequence_gaps != 0) begin
      $fatal(1, "modulo sequence wrap counted as a gap: seq=%04x gaps=%0d", transferred_sample.sequence_number, transferred_health.sequence_gaps);
    end
    if (debug_health.received_frames != 2) $fatal(1, "received frame count mismatch");

    wait_for_transfer(3);
    if (!transferred_sample.stale || !transferred_health.stale || transferred_health.stale_events != 1) begin
      $fatal(1, "stale transition was not published");
    end

    send_vector(5);
    wait_for_transfer(4);
    if (transferred_sample.stale || transferred_health.stale || transferred_health.sequence_gaps != 1) begin
      $fatal(1, "stale recovery or duplicate-sequence accounting failed");
    end

    target_count = transfer_count;
    send_vector(3);
    repeat (30) @(posedge clk);
    if (transfer_count != target_count || debug_health.crc_errors != 1) begin
      $fatal(1, "bad CRC was not rejected and counted");
    end

    send_serial_byte(8'h7d);
    send_serial_byte(8'h00);
    send_serial_byte(8'h0a);
    repeat (30) @(posedge clk);
    if (debug_health.framing_errors == 0) $fatal(1, "invalid escape was not counted");

    send_serial_byte(8'h01);
    repeat (6_000) @(posedge clk);
    if (debug_health.framing_errors < 2) $fatal(1, "partial-frame timeout was not counted");

    sample_ready = 1'b0;
    send_vector(0);
    wait (sample_valid);
    repeat (2) @(posedge clk);
    held_sample = sample;
    held_health = sample_health;
    send_vector(0);
    repeat (30) @(posedge clk);
    if (!sample_valid || sample !== held_sample || sample_health !== held_health) begin
      $fatal(1, "valid/sample/health changed under backpressure");
    end
    if (debug_health.fifo_overflows != 1) $fatal(1, "blocked sample overflow was not counted");
    sample_ready = 1'b1;
    wait_for_transfer(5);

    $display("PASS: UART-to-motion endpoint sequence, stale, recovery, rejection, timeout, and backpressure");
    $finish;
  end
endmodule
