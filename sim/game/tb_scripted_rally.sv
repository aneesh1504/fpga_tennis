module tb_scripted_rally;
  import protocol_pkg::*;
  import game_types_pkg::*;
  import video_types_pkg::*;

  logic clk_sys = 1'b0;
  logic rst_sys_n = 1'b0;
  logic game_tick;
  logic match_reset;
  logic player_one_sample_valid;
  logic player_one_sample_ready;
  motion_sample_t player_one_sample;
  transport_health_t player_one_health;
  logic player_two_sample_valid;
  logic player_two_sample_ready;
  motion_sample_t player_two_sample;
  transport_health_t player_two_health;
  logic scripted_opponent_enable;
  game_render_state_t render_state;
  logic audio_valid;
  logic audio_ready;
  audio_event_t audio_event;
  integer player_two_hit_count;
  integer tick_count;

  always #5 clk_sys = ~clk_sys;
  game_engine dut (.*);

  always @(posedge clk_sys) begin
    if (audio_valid && audio_ready && (audio_event.kind == AUDIO_EVENT_HIT)
        && audio_event.player_two) begin
      player_two_hit_count <= player_two_hit_count + 1;
    end
  end

  task automatic send_player_one_sample(input integer gy);
    begin
      while (!player_one_sample_ready) @(negedge clk_sys);
      @(negedge clk_sys);
      player_one_sample = '0;
      player_one_sample.valid = 1'b1;
      player_one_sample.gyro_y = gy;
      player_one_sample.accel_z = 16'sd1000;
      player_one_sample_valid = 1'b1;
      @(negedge clk_sys);
      player_one_sample_valid = 1'b0;
    end
  endtask

  task automatic tick_slow;
    begin
      @(negedge clk_sys);
      game_tick = 1'b1;
      @(negedge clk_sys);
      game_tick = 1'b0;
      repeat (8) @(posedge clk_sys);
    end
  endtask

  initial begin
    game_tick = 1'b0;
    match_reset = 1'b0;
    player_one_sample_valid = 1'b0;
    player_one_sample = '0;
    player_one_health = '0;
    player_one_health.connected = 1'b1;
    player_one_health.calibrated = 1'b1;
    player_two_sample_valid = 1'b0;
    player_two_sample = '0;
    player_two_health = '0;
    scripted_opponent_enable = 1'b1;
    audio_ready = 1'b1;
    player_two_hit_count = 0;
    repeat (3) @(negedge clk_sys);
    rst_sys_n = 1'b1;

    send_player_one_sample(1900);
    send_player_one_sample(2600);
    send_player_one_sample(3000);
    send_player_one_sample(2400);
    repeat (3) @(posedge clk_sys);
    tick_slow();
    if (!render_state.ball_visible) $fatal(1, "scripted rally serve did not enter play");

    for (tick_count = 0; (tick_count < 30) && (player_two_hit_count == 0);
         tick_count = tick_count + 1) begin
      tick_slow();
    end
    if (player_two_hit_count != 1) begin
      $fatal(1, "scripted opponent did not return the served ball");
    end
    if ($signed(render_state.ball_y_q8_8) < 16'sh0500) begin
      $fatal(1, "scripted return occurred outside the far-player zone");
    end

    $display("PASS: one-controller serve and scripted-opponent return path");
    $finish;
  end
endmodule
