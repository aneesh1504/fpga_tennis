`timescale 1ns/1ps

module reset_sync #(
  parameter int unsigned STAGES = 2
) (
  input  logic clk,
  input  logic async_rst_n,
  output logic sync_rst_n
);
  logic [STAGES-1:0] sync_q;

  initial begin
    if (STAGES < 2) $fatal(1, "reset_sync STAGES must be at least 2");
  end

  always_ff @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      sync_q <= '0;
    end else begin
      sync_q <= {sync_q[STAGES-2:0], 1'b1};
    end
  end

  assign sync_rst_n = sync_q[STAGES-1];
endmodule
