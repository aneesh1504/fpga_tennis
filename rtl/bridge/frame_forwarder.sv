`timescale 1ns/1ps

module frame_forwarder #(
  parameter int unsigned FIFO_DEPTH = 128
) (
  input  logic                         clk,
  input  logic                         rst_n,
  input  logic                         in_byte_valid,
  output logic                         in_byte_ready,
  input  logic [7:0]                   in_byte,
  output logic                         out_byte_valid,
  input  logic                         out_byte_ready,
  output logic [7:0]                   out_byte,
  output logic [31:0]                  input_bytes,
  output logic [31:0]                  output_bytes,
  output logic [31:0]                  complete_frames,
  output logic [31:0]                  fifo_overflows,
  output logic [$clog2(FIFO_DEPTH):0]  fifo_level,
  output logic [$clog2(FIFO_DEPTH):0]  fifo_high_water
);
  logic fifo_overflow;
  logic fifo_underflow_unused;
  logic fifo_read_ready;

  function automatic logic [31:0] sat_inc(input logic [31:0] value);
    if (value == 32'hffff_ffff) sat_inc = value;
    else                        sat_inc = value + 1'b1;
  endfunction

  assign fifo_read_ready = out_byte_ready && out_byte_valid;

  sync_fifo #(.WIDTH(8), .DEPTH(FIFO_DEPTH)) fifo (
    .clk,
    .rst_n,
    .in_valid(in_byte_valid),
    .in_ready(in_byte_ready),
    .in_data(in_byte),
    .out_valid(out_byte_valid),
    .out_ready(fifo_read_ready),
    .out_data(out_byte),
    .level(fifo_level),
    .high_water(fifo_high_water),
    .overflow(fifo_overflow),
    .underflow(fifo_underflow_unused)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      input_bytes     <= '0;
      output_bytes    <= '0;
      complete_frames <= '0;
      fifo_overflows  <= '0;
    end else begin
      if (in_byte_valid) begin
        input_bytes <= sat_inc(input_bytes);
        if (in_byte == 8'h0a) complete_frames <= sat_inc(complete_frames);
      end
      if (out_byte_valid && out_byte_ready) output_bytes <= sat_inc(output_bytes);
      if (fifo_overflow) fifo_overflows <= sat_inc(fifo_overflows);
    end
  end
endmodule
