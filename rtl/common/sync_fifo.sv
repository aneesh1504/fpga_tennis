`timescale 1ns/1ps

module sync_fifo #(
  parameter int unsigned WIDTH = 8,
  parameter int unsigned DEPTH = 128
) (
  input  logic                   clk,
  input  logic                   rst_n,
  input  logic                   in_valid,
  output logic                   in_ready,
  input  logic [WIDTH-1:0]       in_data,
  output logic                   out_valid,
  input  logic                   out_ready,
  output logic [WIDTH-1:0]       out_data,
  output logic [$clog2(DEPTH):0] level,
  output logic [$clog2(DEPTH):0] high_water,
  output logic                   overflow,
  output logic                   underflow
);
  localparam int unsigned PTR_WIDTH = (DEPTH <= 2) ? 1 : $clog2(DEPTH);

  logic [WIDTH-1:0] memory [0:DEPTH-1];
  logic [PTR_WIDTH-1:0] write_ptr_q;
  logic [PTR_WIDTH-1:0] read_ptr_q;
  logic write_fire;
  logic read_fire;

  initial begin
    if (DEPTH < 2 || (DEPTH & (DEPTH - 1)) != 0) begin
      $fatal(1, "sync_fifo DEPTH must be a power of two >= 2");
    end
  end

  assign out_valid = (level != 0);
  assign out_data  = memory[read_ptr_q];
  assign in_ready  = (level != DEPTH) || (out_valid && out_ready);
  assign write_fire = in_valid && in_ready;
  assign read_fire  = out_valid && out_ready;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      write_ptr_q <= '0;
      read_ptr_q  <= '0;
      level       <= '0;
      high_water  <= '0;
      overflow    <= 1'b0;
      underflow   <= 1'b0;
    end else begin
      overflow  <= in_valid && !in_ready;
      underflow <= out_ready && !out_valid;

      if (write_fire) begin
        memory[write_ptr_q] <= in_data;
        write_ptr_q <= write_ptr_q + 1'b1;
      end
      if (read_fire) begin
        read_ptr_q <= read_ptr_q + 1'b1;
      end

      case ({write_fire, read_fire})
        2'b10: level <= level + 1'b1;
        2'b01: level <= level - 1'b1;
        default: level <= level;
      endcase

      if (write_fire && !read_fire && (level + 1'b1 > high_water)) begin
        high_water <= level + 1'b1;
      end
    end
  end
endmodule
