module tb_game_engine;
  import protocol_pkg::*;
  import game_types_pkg::*;
  import video_types_pkg::*;

  logic clk_sys = 1'b0;
  logic rst_sys_n = 1'b0;
  logic game_tick;
  logic match_reset;
  logic player_one_sample_valid;
  logic player_one_sample_ready_a;
  motion_sample_t player_one_sample;
  transport_health_t player_one_health;
  logic player_two_sample_valid;
  logic player_two_sample_ready_a;
  motion_sample_t player_two_sample;
  transport_health_t player_two_health;
  game_render_state_t render_state_a;
  logic audio_valid_a;
  logic audio_ready;
  audio_event_t audio_event_a;
  logic signed [15:0] held_ball_y;
  audio_event_t held_audio;
  game_render_state_t first_serve_state;
  game_render_state_t first_tick_state;
  audio_event_t first_audio_event;

  always #5 clk_sys = ~clk_sys;

  game_engine engine_a (
    .clk_sys,
    .rst_sys_n,
    .game_tick,
    .match_reset,
    .player_one_sample_valid,
    .player_one_sample_ready(player_one_sample_ready_a),
    .player_one_sample,
    .player_one_health,
    .player_two_sample_valid,
    .player_two_sample_ready(player_two_sample_ready_a),
    .player_two_sample,
    .player_two_health,
    .render_state(render_state_a),
    .audio_valid(audio_valid_a),
    .audio_ready,
    .audio_event(audio_event_a)
  );

  task automatic send_player_one_sample(input integer gy, input integer az);
    begin
      while (!player_one_sample_ready_a) @(negedge clk_sys);
      @(negedge clk_sys);
      player_one_sample = '0;
      player_one_sample.valid = 1'b1;
      player_one_sample.gyro_y = gy;
      player_one_sample.accel_z = az;
      player_one_sample.quat_y = 16'sd600;
      player_one_sample_valid = 1'b1;
      @(negedge clk_sys);
      player_one_sample_valid = 1'b0;
    end
  endtask

  task automatic pulse_game_tick;
    begin
      @(negedge clk_sys);
      game_tick = 1'b1;
      @(negedge clk_sys);
      game_tick = 1'b0;
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
    player_two_health.connected = 1'b1;
    player_two_health.calibrated = 1'b1;
    audio_ready = 1'b0;
    repeat (3) @(negedge clk_sys);
    rst_sys_n = 1'b1;

    send_player_one_sample(1900, 1000);
    send_player_one_sample(2600, 1000);
    send_player_one_sample(3000, 1000);
    send_player_one_sample(2400, 1000);
    repeat (3) @(negedge clk_sys);
    if (!engine_a.player_one_pending_valid_q) $fatal(1, "swing did not reach game-engine pending queue");
    pulse_game_tick();
    repeat (4) @(posedge clk_sys);
    if (!render_state_a.ball_visible || !audio_valid_a) begin
      $fatal(1, "serve did not become visible with an audio event");
    end
    if ((audio_event_a.kind != AUDIO_EVENT_HIT) || !render_state_a.valid) begin
      $fatal(1, "serve did not publish hit audio/render state");
    end
    first_serve_state = render_state_a;
    first_audio_event = audio_event_a;

    held_audio = audio_event_a;
    repeat (4) @(posedge clk_sys);
    if (!audio_valid_a || (audio_event_a !== held_audio)) begin
      $fatal(1, "audio event was not stable under backpressure");
    end
    audio_ready = 1'b1;
    @(posedge clk_sys);
    audio_ready = 1'b0;

    held_ball_y = render_state_a.ball_y_q8_8;
    repeat (5) @(posedge clk_sys);
    if (render_state_a.ball_y_q8_8 != held_ball_y) begin
      $fatal(1, "physics changed without game_tick enable");
    end
    pulse_game_tick();
    repeat (2) @(posedge clk_sys);
    if (render_state_a.ball_y_q8_8 == held_ball_y) begin
      $fatal(1, "physics did not advance on game_tick");
    end
    first_tick_state = render_state_a;

    if (!render_state_a.player_one_connected || !render_state_a.player_two_connected) begin
      $fatal(1, "controller health did not publish to render state");
    end

    @(negedge clk_sys);
    match_reset = 1'b1;
    @(negedge clk_sys);
    match_reset = 1'b0;
    repeat (10) send_player_one_sample(50, 0);
    send_player_one_sample(1900, 1000);
    send_player_one_sample(2600, 1000);
    send_player_one_sample(3000, 1000);
    send_player_one_sample(2400, 1000);
    repeat (3) @(negedge clk_sys);
    pulse_game_tick();
    repeat (4) @(posedge clk_sys);
    if ((render_state_a !== first_serve_state) || !audio_valid_a
        || (audio_event_a !== first_audio_event)) begin
      $fatal(1, "identical replay diverged at serve publication");
    end
    audio_ready = 1'b1;
    @(posedge clk_sys);
    audio_ready = 1'b0;
    pulse_game_tick();
    repeat (2) @(posedge clk_sys);
    if (render_state_a !== first_tick_state) begin
      $fatal(1, "identical replay diverged after physics tick");
    end

    $display("PASS: identical game traces, serve, tick, render, and audio backpressure");
    $finish;
  end
endmodule
