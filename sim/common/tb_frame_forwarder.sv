`timescale 1ns/1ps

module tb_frame_forwarder;
  localparam int FIFO_DEPTH = 128;
  localparam int VECTOR_STRIDE = 80;
  localparam int ESCAPE_VECTOR = 2;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;

  logic in_valid;
  logic in_ready;
  logic [7:0] in_data;
  logic out_valid;
  logic out_ready;
  logic [7:0] out_data;
  logic [31:0] input_bytes;
  logic [31:0] output_bytes;
  logic [31:0] complete_frames;
  logic [31:0] fifo_overflows;
  logic [7:0] fifo_level;
  logic [7:0] fifo_high_water;

  logic [7:0] framed_bytes [0:6*VECTOR_STRIDE-1];
  logic [7:0] vector_lengths [0:5];
  logic [7:0] expected [0:FIFO_DEPTH-1];
  integer expected_length;
  integer read_index;
  integer byte_index;
  integer copy_index;

  frame_forwarder #(.FIFO_DEPTH(FIFO_DEPTH)) dut (
    .clk, .rst_n, .in_byte_valid(in_valid), .in_byte_ready(in_ready),
    .in_byte(in_data), .out_byte_valid(out_valid),
    .out_byte_ready(out_ready), .out_byte(out_data),
    .input_bytes, .output_bytes, .complete_frames,
    .fifo_overflows, .fifo_level, .fifo_high_water
  );

  task automatic push_byte(input logic [7:0] value);
    begin
      @(negedge clk);
      in_data = value;
      in_valid = 1'b1;
      @(negedge clk);
      in_valid = 1'b0;
    end
  endtask

  initial begin
    $readmemh(".build/transport/vectors/framed_bytes.hex", framed_bytes);
    $readmemh(".build/transport/vectors/lengths.hex", vector_lengths);
    in_valid = 1'b0;
    in_data = '0;
    out_ready = 1'b0;
    expected_length = 0;
    read_index = 0;

    repeat (4) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;

    for (copy_index = 0; copy_index < 2; copy_index = copy_index + 1) begin
      for (byte_index = 0; byte_index < vector_lengths[ESCAPE_VECTOR]; byte_index = byte_index + 1) begin
        expected[expected_length] = framed_bytes[ESCAPE_VECTOR*VECTOR_STRIDE + byte_index];
        expected_length = expected_length + 1;
        push_byte(framed_bytes[ESCAPE_VECTOR*VECTOR_STRIDE + byte_index]);
      end
    end
    if (fifo_level != expected_length || fifo_high_water != expected_length) begin
      $fatal(1, "forwarder fill/high-water mismatch");
    end
    if (complete_frames != 2) $fatal(1, "forwarder delimiter count mismatch");

    while (read_index < expected_length) begin
      @(negedge clk);
      if (!out_valid || out_data !== expected[read_index]) begin
        $fatal(1, "forwarded byte mismatch at %0d", read_index);
      end
      out_ready = 1'b1;
      @(negedge clk);
      out_ready = 1'b0;
      read_index = read_index + 1;
    end
    repeat (2) @(posedge clk);
    if (fifo_level != 0 || output_bytes != expected_length) $fatal(1, "forwarder drain mismatch");

    for (byte_index = 0; byte_index < FIFO_DEPTH; byte_index = byte_index + 1) push_byte(byte_index[7:0]);
    push_byte(8'hee);
    repeat (3) @(posedge clk);
    if (fifo_overflows != 1 || fifo_level != FIFO_DEPTH) $fatal(1, "forwarder overflow accounting mismatch");

    $display("PASS: byte-transparent forwarding, worst-case escaping, burst ordering, and overflow counters");
    $finish;
  end
endmodule
