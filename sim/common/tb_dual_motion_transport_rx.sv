`timescale 1ns/1ps

module tb_dual_motion_transport_rx;
  import protocol_pkg::*;

  localparam int CLOCK_HZ = 1_000_000;
  localparam int BAUD = 100_000;
  localparam int CLKS_PER_BIT = CLOCK_HZ / BAUD;
  localparam int VECTOR_STRIDE = 80;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;

  logic player_1_serial_rx;
  logic player_1_valid;
  logic player_1_ready;
  motion_sample_t player_1_sample;
  transport_health_t player_1_health;
  transport_health_t player_1_debug_health;
  logic player_2_serial_rx;
  logic player_2_valid;
  logic player_2_ready;
  motion_sample_t player_2_sample;
  transport_health_t player_2_health;
  transport_health_t player_2_debug_health;

  logic [7:0] framed_bytes [0:6*VECTOR_STRIDE-1];
  logic [7:0] vector_lengths [0:5];
  integer player_1_count;
  integer player_2_count;
  motion_sample_t player_1_last;
  motion_sample_t player_2_last;

  dual_motion_transport_rx #(
    .CLOCK_HZ(CLOCK_HZ),
    .PLAYER_1_BAUD(BAUD),
    .PLAYER_2_BAUD(BAUD),
    .STALE_TIMEOUT_MS(250)
  ) dut (
    .clk, .rst_n, .player_1_serial_rx, .player_1_valid,
    .player_1_ready, .player_1_sample, .player_1_health,
    .player_1_debug_health, .player_2_serial_rx, .player_2_valid,
    .player_2_ready, .player_2_sample, .player_2_health,
    .player_2_debug_health
  );

  always @(posedge clk) begin
    if (player_1_valid && player_1_ready) begin
      player_1_count <= player_1_count + 1;
      player_1_last <= player_1_sample;
    end
    if (player_2_valid && player_2_ready) begin
      player_2_count <= player_2_count + 1;
      player_2_last <= player_2_sample;
    end
  end

  task automatic drive_player_1_byte(input logic [7:0] value);
    integer bit_number;
    begin
      @(negedge clk);
      player_1_serial_rx = 1'b0;
      repeat (CLKS_PER_BIT) @(negedge clk);
      for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
        player_1_serial_rx = value[bit_number];
        repeat (CLKS_PER_BIT) @(negedge clk);
      end
      player_1_serial_rx = 1'b1;
      repeat (CLKS_PER_BIT) @(negedge clk);
    end
  endtask

  task automatic drive_player_2_byte(input logic [7:0] value);
    integer bit_number;
    begin
      @(negedge clk);
      player_2_serial_rx = 1'b0;
      repeat (CLKS_PER_BIT) @(negedge clk);
      for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
        player_2_serial_rx = value[bit_number];
        repeat (CLKS_PER_BIT) @(negedge clk);
      end
      player_2_serial_rx = 1'b1;
      repeat (CLKS_PER_BIT) @(negedge clk);
    end
  endtask

  task automatic send_player_1_vector(input integer vector_index);
    integer index;
    begin
      for (index = 0; index < vector_lengths[vector_index]; index = index + 1) begin
        drive_player_1_byte(framed_bytes[vector_index*VECTOR_STRIDE + index]);
      end
    end
  endtask

  task automatic send_player_2_vector(input integer vector_index);
    integer index;
    begin
      for (index = 0; index < vector_lengths[vector_index]; index = index + 1) begin
        drive_player_2_byte(framed_bytes[vector_index*VECTOR_STRIDE + index]);
      end
    end
  endtask

  initial begin
    $readmemh(".build/transport/vectors/framed_bytes.hex", framed_bytes);
    $readmemh(".build/transport/vectors/lengths.hex", vector_lengths);
    player_1_serial_rx = 1'b1;
    player_2_serial_rx = 1'b1;
    player_1_ready = 1'b1;
    player_2_ready = 1'b1;
    player_1_count = 0;
    player_2_count = 0;
    player_1_last = '0;
    player_2_last = '0;
    repeat (5) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;

    fork
      send_player_1_vector(0);
      send_player_2_vector(1);
    join
    wait (player_1_count == 1 && player_2_count == 1);
    repeat (3) @(posedge clk);
    if (player_1_last.sequence_number != 16'h1234 || player_2_last.sequence_number != 16'habcd) begin
      $fatal(1, "independent player parser data mismatch");
    end

    fork
      send_player_1_vector(1);
      send_player_2_vector(0);
    join
    repeat (20) @(posedge clk);
    if (player_1_count != 1 || player_2_count != 1) $fatal(1, "crossed player identities were accepted");
    if (player_1_debug_health.framing_errors != 1 || player_2_debug_health.framing_errors != 1) begin
      $fatal(1, "crossed player identity errors were not independently counted");
    end
    if (player_1_debug_health.received_frames != 1 || player_2_debug_health.received_frames != 1) begin
      $fatal(1, "player receive counters were not independent");
    end

    $display("PASS: independent simultaneous Player 1 and Player 2 receive chains");
    $finish;
  end
endmodule
