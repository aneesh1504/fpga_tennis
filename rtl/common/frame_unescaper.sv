`timescale 1ns/1ps

module frame_unescaper #(
  parameter int unsigned MAX_RAW_BYTES = 32
) (
  input  logic                                      clk,
  input  logic                                      rst_n,
  input  logic                                      byte_valid,
  input  logic [7:0]                                byte_data,
  input  logic                                      timeout,
  output logic                                      raw_valid,
  output logic [7:0]                                raw_data,
  output logic [$clog2(MAX_RAW_BYTES)-1:0]          raw_index,
  output logic                                      frame_end,
  output logic [$clog2(MAX_RAW_BYTES+1)-1:0]        frame_length,
  output logic                                      frame_error,
  output logic                                      frame_active
);
  localparam int unsigned LENGTH_WIDTH = $clog2(MAX_RAW_BYTES + 1);

  logic escape_q;
  logic discard_q;
  logic [LENGTH_WIDTH-1:0] length_q;
  logic [7:0] decoded_byte;

  assign frame_active = escape_q || discard_q || (length_q != 0);
  assign decoded_byte = byte_data ^ 8'h20;

  initial begin
    if (MAX_RAW_BYTES < 2) $fatal(1, "frame_unescaper MAX_RAW_BYTES must be at least 2");
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      escape_q    <= 1'b0;
      discard_q   <= 1'b0;
      length_q    <= '0;
      raw_valid   <= 1'b0;
      raw_data    <= '0;
      raw_index   <= '0;
      frame_end   <= 1'b0;
      frame_length <= '0;
      frame_error <= 1'b0;
    end else begin
      raw_valid   <= 1'b0;
      frame_end   <= 1'b0;
      frame_error <= 1'b0;

      if (timeout) begin
        if (frame_active && !discard_q) frame_error <= 1'b1;
        escape_q  <= 1'b0;
        discard_q <= 1'b0;
        length_q  <= '0;
      end else if (byte_valid) begin
        if (byte_data == 8'h0a) begin
          if (escape_q) begin
            frame_error <= 1'b1;
          end else if (!discard_q) begin
            frame_end    <= 1'b1;
            frame_length <= length_q;
          end
          escape_q  <= 1'b0;
          discard_q <= 1'b0;
          length_q  <= '0;
        end else if (discard_q) begin
          discard_q <= 1'b1;
        end else if (escape_q) begin
          escape_q <= 1'b0;
          if (byte_data != 8'h2a && byte_data != 8'h5d) begin
            frame_error <= 1'b1;
            discard_q   <= 1'b1;
            length_q    <= '0;
          end else if (length_q == MAX_RAW_BYTES) begin
            frame_error <= 1'b1;
            discard_q   <= 1'b1;
            length_q    <= '0;
          end else begin
            raw_valid <= 1'b1;
            raw_data  <= decoded_byte;
            raw_index <= length_q[$clog2(MAX_RAW_BYTES)-1:0];
            length_q  <= length_q + 1'b1;
          end
        end else if (byte_data == 8'h7d) begin
          escape_q <= 1'b1;
        end else if (length_q == MAX_RAW_BYTES) begin
          frame_error <= 1'b1;
          discard_q   <= 1'b1;
          length_q    <= '0;
        end else begin
          raw_valid <= 1'b1;
          raw_data  <= byte_data;
          raw_index <= length_q[$clog2(MAX_RAW_BYTES)-1:0];
          length_q  <= length_q + 1'b1;
        end
      end
    end
  end
endmodule
