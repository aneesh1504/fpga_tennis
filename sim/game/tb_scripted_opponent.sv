module tb_scripted_opponent;
  import protocol_pkg::*;
  import video_types_pkg::*;

  logic clk_sys = 1'b0;
  logic rst_sys_n = 1'b0;
  logic enable;
  logic game_tick;
  game_render_state_t render_state;
  logic sample_valid;
  logic sample_ready;
  motion_sample_t sample;
  transport_health_t health;
  integer sample_count;
  logic signed [15:0] observed_gyro [0:7];

  always #5 clk_sys = ~clk_sys;
  scripted_opponent dut (.*);

  always @(posedge clk_sys) begin
    if (sample_valid && sample_ready) begin
      observed_gyro[sample_count] <= sample.gyro_y;
      sample_count <= sample_count + 1;
    end
  end

  task automatic tick;
    begin
      @(negedge clk_sys);
      game_tick = 1'b1;
      @(negedge clk_sys);
      game_tick = 1'b0;
    end
  endtask

  initial begin
    enable = 1'b0;
    game_tick = 1'b0;
    render_state = '0;
    sample_ready = 1'b1;
    sample_count = 0;
    repeat (2) @(negedge clk_sys);
    rst_sys_n = 1'b1;
    enable = 1'b1;

    render_state.ball_visible = 1'b1;
    render_state.ball_y_q8_8 = 16'sh057f;
    tick();
    repeat (4) @(posedge clk_sys);
    if (sample_count != 0) $fatal(1, "opponent triggered before its hit window");

    render_state.ball_y_q8_8 = 16'sh0580;
    tick();
    wait (sample_count == 4);
    if ((observed_gyro[0] != -16'sd1900)
        || (observed_gyro[1] != -16'sd2600)
        || (observed_gyro[2] != -16'sd3000)
        || (observed_gyro[3] != -16'sd2400)) begin
      $fatal(1, "scripted swing trace mismatch");
    end
    if (!health.connected || !health.calibrated) $fatal(1, "scripted health mismatch");

    repeat (3) tick();
    if (sample_count != 4) $fatal(1, "opponent double-triggered on one approach");

    render_state.ball_y_q8_8 = -16'sh0100;
    tick();
    render_state.ball_y_q8_8 = 16'sh0600;
    tick();
    wait (sample_count == 8);
    if (sample.sequence_number != 16'd7) $fatal(1, "scripted sequence progression failed");

    $display("PASS: scripted opponent hit window, single trigger, and re-arm");
    $finish;
  end
endmodule
