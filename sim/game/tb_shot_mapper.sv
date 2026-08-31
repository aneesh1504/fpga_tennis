module tb_shot_mapper;
  logic toward_player_two;
  logic [15:0] strength;
  logic signed [15:0] aim_x;
  logic signed [15:0] lift;
  logic signed [31:0] timing_error_q16;
  logic signed [31:0] velocity_x_q16;
  logic signed [31:0] velocity_y_q16;
  logic signed [31:0] velocity_z_q16;

  shot_mapper dut (.*);

  initial begin
    toward_player_two = 1'b1;
    strength = 16'h4000;
    aim_x = 16'sd0;
    lift = 16'sd0;

    timing_error_q16 = -32'sh0001_0000;
    #1;
    if (velocity_x_q16 != -32'sd16384) $fatal(1, "early timing map failed");
    timing_error_q16 = 32'sd0;
    #1;
    if (velocity_x_q16 != 0) $fatal(1, "good timing map failed");
    timing_error_q16 = 32'sh0001_0000;
    #1;
    if (velocity_x_q16 != 32'sd16384) $fatal(1, "late timing map failed");

    strength = 16'hffff;
    lift = 16'sh7fff;
    aim_x = 16'sh7fff;
    timing_error_q16 = 32'sh7fff_ffff;
    #1;
    if ((velocity_y_q16 <= 0) || (velocity_z_q16 != 32'sd12288)
        || (velocity_x_q16 < 0)) begin
      $fatal(1, "maximum shot did not remain bounded");
    end

    toward_player_two = 1'b0;
    lift = -16'sd32768;
    #1;
    if ((velocity_y_q16 >= 0) || (velocity_z_q16 != 32'sd2048)) begin
      $fatal(1, "reverse/minimum shot mapping failed");
    end

    $display("PASS: early/good/late shot mapping and bounded extremes");
    $finish;
  end
endmodule
