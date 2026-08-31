module tb_ball_physics;
  logic clk_sys = 1'b0;
  logic rst_sys_n = 1'b0;
  logic game_tick;
  logic state_load;
  logic load_active;
  logic signed [31:0] load_x_q16;
  logic signed [31:0] load_y_q16;
  logic signed [31:0] load_z_q16;
  logic signed [31:0] load_vx_q16;
  logic signed [31:0] load_vy_q16;
  logic signed [31:0] load_vz_q16;
  logic ball_active;
  logic signed [31:0] ball_x_q16;
  logic signed [31:0] ball_y_q16;
  logic signed [31:0] ball_z_q16;
  logic signed [31:0] ball_vx_q16;
  logic signed [31:0] ball_vy_q16;
  logic signed [31:0] ball_vz_q16;
  logic net_cross_pulse;
  logic net_fault_pulse;
  logic bounce_pulse;
  logic bounce_in_bounds;
  logic out_of_bounds_pulse;
  logic stopped_pulse;

  always #5 clk_sys = ~clk_sys;
  ball_physics dut (.*);

  task automatic load_ball(
    input logic signed [31:0] x,
    input logic signed [31:0] y,
    input logic signed [31:0] z,
    input logic signed [31:0] vx,
    input logic signed [31:0] vy,
    input logic signed [31:0] vz
  );
    begin
      @(negedge clk_sys);
      load_active = 1'b1;
      load_x_q16 = x;
      load_y_q16 = y;
      load_z_q16 = z;
      load_vx_q16 = vx;
      load_vy_q16 = vy;
      load_vz_q16 = vz;
      state_load = 1'b1;
      @(negedge clk_sys);
      state_load = 1'b0;
    end
  endtask

  task automatic tick;
    begin
      @(negedge clk_sys);
      game_tick = 1'b1;
      @(negedge clk_sys);
      game_tick = 1'b0;
      #1;
    end
  endtask

  initial begin
    game_tick = 1'b0;
    state_load = 1'b0;
    load_active = 1'b0;
    load_x_q16 = '0;
    load_y_q16 = '0;
    load_z_q16 = '0;
    load_vx_q16 = '0;
    load_vy_q16 = '0;
    load_vz_q16 = '0;
    repeat (2) @(negedge clk_sys);
    rst_sys_n = 1'b1;

    load_ball(0, -32'sd32768, 32'sd65792, 0, 32'sd32768, 0);
    tick();
    if (!net_cross_pulse || net_fault_pulse || !ball_active) begin
      $fatal(1, "ball at net-height boundary did not clear");
    end

    load_ball(0, -32'sd32768, 32'sd65536, 0, 32'sd32768, 0);
    tick();
    if (!net_cross_pulse || !net_fault_pulse || ball_active) begin
      $fatal(1, "ball below net-height boundary did not fault");
    end

    load_ball(0, 32'sh0002_0000, 32'sd100, 0, 0, -32'sd1000);
    tick();
    if (!bounce_pulse || !bounce_in_bounds || !ball_active
        || (ball_z_q16 != 0) || (ball_vz_q16 <= 0)) begin
      $fatal(1, "in-bounds bounce failed");
    end

    load_ball(32'sh0004_8000, 32'sh0002_0000, 32'sd100, 0, 0, -32'sd1000);
    tick();
    if (!bounce_pulse || bounce_in_bounds || !out_of_bounds_pulse || ball_active) begin
      $fatal(1, "out-of-bounds bounce failed");
    end

    load_ball(32'sh7fff_fff0, 32'sh0002_0000, 32'sh0002_0000,
              32'sh7fff_fff0, 0, 0);
    tick();
    if (ball_x_q16 != 32'sh7fff_ffff) $fatal(1, "positive Q16.16 saturation wrapped");

    $display("PASS: Q16.16 physics, net boundary, bounce, bounds, and saturation");
    $finish;
  end
endmodule
