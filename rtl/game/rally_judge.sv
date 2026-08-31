module rally_judge (
  input  logic clk_sys,
  input  logic rst_sys_n,
  input  logic reset_rally,
  input  logic last_hitter_two,
  input  logic net_fault_pulse,
  input  logic out_of_bounds_pulse,
  input  logic stopped_pulse,
  input  logic bounce_pulse,
  input  logic bounce_in_bounds,
  output logic bounce_seen,
  output logic point_valid,
  output logic point_winner_two,
  output logic point_was_fault
);
  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      bounce_seen <= 1'b0;
      point_valid <= 1'b0;
      point_winner_two <= 1'b0;
      point_was_fault <= 1'b0;
    end else begin
      point_valid <= 1'b0;
      point_was_fault <= 1'b0;
      if (reset_rally) begin
        bounce_seen <= 1'b0;
      end else if (net_fault_pulse || out_of_bounds_pulse) begin
        point_valid <= 1'b1;
        point_winner_two <= !last_hitter_two;
        point_was_fault <= net_fault_pulse;
        bounce_seen <= 1'b0;
      end else if (stopped_pulse) begin
        point_valid <= 1'b1;
        point_winner_two <= last_hitter_two;
        point_was_fault <= 1'b0;
        bounce_seen <= 1'b0;
      end else if (bounce_pulse && bounce_in_bounds) begin
        if (bounce_seen) begin
          point_valid <= 1'b1;
          point_winner_two <= last_hitter_two;
          point_was_fault <= 1'b0;
          bounce_seen <= 1'b0;
        end else begin
          bounce_seen <= 1'b1;
        end
      end
    end
  end
endmodule
