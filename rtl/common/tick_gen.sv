`timescale 1ns/1ps

module tick_gen #(
  parameter int unsigned CLOCK_HZ = 100_000_000,
  parameter int unsigned TICK_HZ  = 1_000
) (
  input  logic clk,
  input  logic rst_n,
  output logic tick
);
  localparam int unsigned ACC_WIDTH = $clog2(CLOCK_HZ + TICK_HZ) + 1;

  logic [ACC_WIDTH-1:0] accumulator_q;

  initial begin
    if (CLOCK_HZ == 0 || TICK_HZ == 0 || TICK_HZ > CLOCK_HZ) begin
      $fatal(1, "tick_gen requires 0 < TICK_HZ <= CLOCK_HZ");
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      accumulator_q <= '0;
      tick          <= 1'b0;
    end else if (accumulator_q >= CLOCK_HZ - TICK_HZ) begin
      accumulator_q <= accumulator_q - CLOCK_HZ + TICK_HZ;
      tick          <= 1'b1;
    end else begin
      accumulator_q <= accumulator_q + TICK_HZ;
      tick          <= 1'b0;
    end
  end
endmodule
