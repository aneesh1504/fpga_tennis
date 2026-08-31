module tb_rally_judge;
  logic clk_sys = 1'b0;
  logic rst_sys_n = 1'b0;
  logic reset_rally;
  logic last_hitter_two;
  logic net_fault_pulse;
  logic out_of_bounds_pulse;
  logic stopped_pulse;
  logic bounce_pulse;
  logic bounce_in_bounds;
  logic bounce_seen;
  logic point_valid;
  logic point_winner_two;
  logic point_was_fault;

  always #5 clk_sys = ~clk_sys;
  rally_judge dut (.*);

  task automatic pulse_bounce;
    begin
      @(negedge clk_sys);
      bounce_in_bounds = 1'b1;
      bounce_pulse = 1'b1;
      @(negedge clk_sys);
      bounce_pulse = 1'b0;
      #1;
    end
  endtask

  initial begin
    reset_rally = 1'b0;
    last_hitter_two = 1'b0;
    net_fault_pulse = 1'b0;
    out_of_bounds_pulse = 1'b0;
    stopped_pulse = 1'b0;
    bounce_pulse = 1'b0;
    bounce_in_bounds = 1'b0;
    repeat (2) @(negedge clk_sys);
    rst_sys_n = 1'b1;

    pulse_bounce();
    if (!bounce_seen || point_valid) $fatal(1, "first bounce was not counted");
    pulse_bounce();
    if (!point_valid || point_winner_two || bounce_seen) begin
      $fatal(1, "double bounce did not award last hitter");
    end

    @(negedge clk_sys);
    reset_rally = 1'b1;
    @(negedge clk_sys);
    reset_rally = 1'b0;
    last_hitter_two = 1'b1;
    net_fault_pulse = 1'b1;
    @(negedge clk_sys);
    net_fault_pulse = 1'b0;
    #1;
    if (!point_valid || point_winner_two || !point_was_fault) begin
      $fatal(1, "net fault winner/reason failed");
    end

    $display("PASS: first/double bounce and fault point adjudication");
    $finish;
  end
endmodule
