`timescale 1ns/1ps

module uart_tx #(
  parameter int unsigned CLOCK_HZ = 100_000_000,
  parameter int unsigned BAUD     = 115_200
) (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       data_valid,
  output logic       data_ready,
  input  logic [7:0] data,
  output logic       serial_tx,
  output logic       busy
);
  localparam int unsigned CLKS_PER_BIT = (CLOCK_HZ + (BAUD / 2)) / BAUD;
  localparam int unsigned COUNT_WIDTH  = (CLKS_PER_BIT <= 2) ? 1 : $clog2(CLKS_PER_BIT);

  logic [9:0] shift_q;
  logic [3:0] bit_index_q;
  logic [COUNT_WIDTH-1:0] count_q;

  initial begin
    if (BAUD == 0 || CLKS_PER_BIT < 4) begin
      $fatal(1, "uart_tx requires at least four clocks per bit");
    end
  end

  assign data_ready = !busy;
  assign serial_tx  = busy ? shift_q[0] : 1'b1;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_q     <= 10'h3ff;
      bit_index_q <= '0;
      count_q     <= '0;
      busy        <= 1'b0;
    end else if (!busy) begin
      if (data_valid) begin
        shift_q     <= {1'b1, data, 1'b0};
        bit_index_q <= '0;
        count_q     <= CLKS_PER_BIT - 1;
        busy        <= 1'b1;
      end
    end else if (count_q != 0) begin
      count_q <= count_q - 1'b1;
    end else if (bit_index_q == 4'd9) begin
      busy <= 1'b0;
    end else begin
      shift_q     <= {1'b1, shift_q[9:1]};
      bit_index_q <= bit_index_q + 1'b1;
      count_q     <= CLKS_PER_BIT - 1;
    end
  end
endmodule
