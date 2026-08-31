`timescale 1ns/1ps

module tb_motion_decoder;
  import protocol_pkg::*;

  localparam int VECTOR_COUNT = 6;
  localparam int VECTOR_STRIDE = 80;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;

  logic byte_valid;
  logic [7:0] byte_data;
  logic timeout;
  logic raw_valid;
  logic [7:0] raw_data;
  logic [4:0] raw_index;
  logic frame_end;
  logic [5:0] frame_length;
  logic frame_error;
  logic frame_active;

  logic motion_valid;
  motion_sample_t motion_sample;
  logic calibrated;
  logic crc_error;
  logic length_error;
  logic header_error;

  logic p1_motion_valid;
  motion_sample_t p1_motion_sample;
  logic p1_calibrated;
  logic p1_crc_error;
  logic p1_length_error;
  logic p1_header_error;

  logic [7:0] framed_bytes [0:VECTOR_COUNT*VECTOR_STRIDE-1];
  logic [7:0] vector_lengths [0:VECTOR_COUNT-1];
  logic vector_accepted [0:VECTOR_COUNT-1];
  motion_sample_t expected_samples [0:VECTOR_COUNT-1];
  logic expected_calibrated [0:VECTOR_COUNT-1];

  integer motion_count;
  integer crc_error_count;
  integer length_error_count;
  integer header_error_count;
  integer frame_error_count;
  integer p1_motion_count;
  integer p1_header_error_count;
  motion_sample_t last_motion;
  logic last_calibrated;
  integer vector_index;
  integer byte_index;
  integer before_count;

  frame_unescaper unescaper (
    .clk, .rst_n, .byte_valid, .byte_data, .timeout,
    .raw_valid, .raw_data, .raw_index, .frame_end, .frame_length,
    .frame_error, .frame_active
  );

  motion_packet_decoder decoder (
    .clk, .rst_n, .raw_valid, .raw_data, .raw_index, .frame_end,
    .frame_length, .frame_error, .motion_valid, .motion_sample,
    .calibrated, .crc_error, .length_error, .header_error
  );

  motion_packet_decoder #(.ACCEPTED_PLAYER_ID(PLAYER_1_ID)) p1_decoder (
    .clk, .rst_n, .raw_valid, .raw_data, .raw_index, .frame_end,
    .frame_length, .frame_error, .motion_valid(p1_motion_valid),
    .motion_sample(p1_motion_sample), .calibrated(p1_calibrated),
    .crc_error(p1_crc_error), .length_error(p1_length_error),
    .header_error(p1_header_error)
  );

  always @(posedge clk) begin
    if (motion_valid) begin
      motion_count <= motion_count + 1;
      last_motion <= motion_sample;
      last_calibrated <= calibrated;
    end
    if (crc_error) crc_error_count <= crc_error_count + 1;
    if (length_error) length_error_count <= length_error_count + 1;
    if (header_error) header_error_count <= header_error_count + 1;
    if (frame_error) frame_error_count <= frame_error_count + 1;
    if (p1_motion_valid) p1_motion_count <= p1_motion_count + 1;
    if (p1_header_error) p1_header_error_count <= p1_header_error_count + 1;
  end

  task automatic send_byte(input logic [7:0] value);
    begin
      @(negedge clk);
      byte_data = value;
      byte_valid = 1'b1;
      @(negedge clk);
      byte_valid = 1'b0;
    end
  endtask

  task automatic send_vector(input integer selected_vector);
    integer offset;
    begin
      offset = selected_vector * VECTOR_STRIDE;
      for (byte_index = 0; byte_index < vector_lengths[selected_vector]; byte_index = byte_index + 1) begin
        send_byte(framed_bytes[offset + byte_index]);
      end
      repeat (5) @(posedge clk);
    end
  endtask

  initial begin
    $readmemh(".build/transport/vectors/framed_bytes.hex", framed_bytes);
    $readmemh(".build/transport/vectors/lengths.hex", vector_lengths);
    $readmemh(".build/transport/vectors/accepted.hex", vector_accepted);
    $readmemh(".build/transport/vectors/samples.hex", expected_samples);
    $readmemh(".build/transport/vectors/calibrated.hex", expected_calibrated);

    byte_valid = 1'b0;
    byte_data = '0;
    timeout = 1'b0;
    motion_count = 0;
    crc_error_count = 0;
    length_error_count = 0;
    header_error_count = 0;
    frame_error_count = 0;
    p1_motion_count = 0;
    p1_header_error_count = 0;
    last_motion = '0;
    last_calibrated = 1'b0;

    repeat (4) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;

    for (vector_index = 0; vector_index < VECTOR_COUNT; vector_index = vector_index + 1) begin
      before_count = motion_count;
      send_vector(vector_index);
      if (vector_accepted[vector_index]) begin
        if (motion_count != before_count + 1) $fatal(1, "vector %0d was not accepted", vector_index);
        if (last_motion !== expected_samples[vector_index]) $fatal(1, "vector %0d sample mismatch", vector_index);
        if (last_calibrated !== expected_calibrated[vector_index]) $fatal(1, "vector %0d calibrated mismatch", vector_index);
      end else if (motion_count != before_count) begin
        $fatal(1, "vector %0d was unexpectedly accepted", vector_index);
      end
    end
    if (motion_count != 5 || crc_error_count != 1) $fatal(1, "golden vector outcome counts mismatch");
    if (p1_motion_count != 2 || p1_header_error_count != 3) $fatal(1, "player filtering counts mismatch");

    before_count = length_error_count;
    send_byte(8'h01);
    send_byte(8'h01);
    send_byte(8'h01);
    send_byte(8'h0a);
    repeat (4) @(posedge clk);
    if (length_error_count != before_count + 1) $fatal(1, "truncated frame not rejected");

    before_count = frame_error_count;
    send_byte(8'h7d);
    send_byte(8'h00);
    send_byte(8'h0a);
    repeat (3) @(posedge clk);
    if (frame_error_count != before_count + 1) $fatal(1, "invalid escape error count mismatch");

    before_count = frame_error_count;
    send_byte(8'h7d);
    send_byte(8'h0a);
    repeat (3) @(posedge clk);
    if (frame_error_count != before_count + 1) $fatal(1, "dangling escape not rejected");

    before_count = frame_error_count;
    for (byte_index = 0; byte_index < 33; byte_index = byte_index + 1) send_byte(8'h55);
    send_byte(8'h0a);
    repeat (3) @(posedge clk);
    if (frame_error_count != before_count + 1) $fatal(1, "oversized frame error count mismatch");

    before_count = frame_error_count;
    send_byte(8'h01);
    send_byte(8'h02);
    @(negedge clk);
    timeout = 1'b1;
    @(negedge clk);
    timeout = 1'b0;
    repeat (3) @(posedge clk);
    if (frame_error_count != before_count + 1 || frame_active) $fatal(1, "timeout did not reset parser");

    before_count = motion_count;
    send_vector(0);
    if (motion_count != before_count + 1) $fatal(1, "valid frame did not resynchronize after errors");

    $display("PASS: all frozen vectors, rejection cases, player filtering, and parser resynchronization");
    $finish;
  end
endmodule
