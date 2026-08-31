module game_engine (
  input  logic                            clk_sys,
  input  logic                            rst_sys_n,
  input  logic                            game_tick,
  input  logic                            match_reset,
  input  logic                            player_one_sample_valid,
  output logic                            player_one_sample_ready,
  input  protocol_pkg::motion_sample_t    player_one_sample,
  input  protocol_pkg::transport_health_t player_one_health,
  input  logic                            player_two_sample_valid,
  output logic                            player_two_sample_ready,
  input  protocol_pkg::motion_sample_t    player_two_sample,
  input  protocol_pkg::transport_health_t player_two_health,
  input  logic                            scripted_opponent_enable,
  output video_types_pkg::game_render_state_t render_state,
  output logic                            audio_valid,
  input  logic                            audio_ready,
  output game_types_pkg::audio_event_t    audio_event
);
  import protocol_pkg::*;
  import game_types_pkg::*;
  import video_types_pkg::*;
  import gameplay_tuning_pkg::*;

  typedef enum logic {GAME_WAIT_SERVE, GAME_RALLY} game_state_t;

  game_state_t game_state_q;
  swing_event_t player_one_swing;
  swing_event_t player_two_swing;
  swing_event_t player_one_pending_q;
  swing_event_t player_two_pending_q;
  logic player_one_swing_valid;
  logic player_two_swing_valid;
  logic player_one_swing_ready;
  logic player_two_swing_ready;
  logic player_two_effective_valid;
  logic player_two_effective_ready;
  motion_sample_t player_two_effective_sample;
  transport_health_t player_two_effective_health;
  logic scripted_sample_valid;
  logic scripted_sample_ready;
  motion_sample_t scripted_sample;
  transport_health_t scripted_health;
  logic player_one_pending_valid_q;
  logic player_two_pending_valid_q;

  logic physics_load_q;
  logic physics_load_active_q;
  logic signed [31:0] physics_load_x_q;
  logic signed [31:0] physics_load_y_q;
  logic signed [31:0] physics_load_z_q;
  logic signed [31:0] physics_load_vx_q;
  logic signed [31:0] physics_load_vy_q;
  logic signed [31:0] physics_load_vz_q;
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

  logic point_valid;
  logic point_winner_two;
  logic point_was_fault;
  logic last_hitter_two_q;
  logic reset_rally_q;
  logic bounce_seen;
  logic player_two_serves;
  logic [1:0] player_one_points;
  logic [1:0] player_two_points;
  logic [3:0] player_one_games;
  logic [3:0] player_two_games;
  logic [1:0] player_one_sets;
  logic [1:0] player_two_sets;
  logic advantage_valid;
  logic advantage_player_two;
  logic game_won_pulse;
  logic set_won_pulse;

  audio_event_t audio_event_q;
  logic [15:0] player_one_meter_q;
  logic [15:0] player_two_meter_q;
  logic player_one_contact;
  logic player_two_contact;
  logic signed [31:0] timing_error;
  logic signed [31:0] player_one_shot_vx;
  logic signed [31:0] player_one_shot_vy;
  logic signed [31:0] player_one_shot_vz;
  logic signed [31:0] player_two_shot_vx;
  logic signed [31:0] player_two_shot_vy;
  logic signed [31:0] player_two_shot_vz;

  function automatic logic signed [15:0] q16_to_q8_8(input logic signed [31:0] value);
    logic signed [31:0] shifted;
    begin
      shifted = value >>> 8;
      if (shifted > 32'sd32767) begin
        q16_to_q8_8 = 16'sh7fff;
      end else if (shifted < -32'sd32768) begin
        q16_to_q8_8 = -16'sh8000;
      end else begin
        q16_to_q8_8 = shifted[15:0];
      end
    end
  endfunction

  swing_detector player_one_detector (
    .clk_sys,
    .rst_sys_n,
    .sample_valid(player_one_sample_valid),
    .sample_ready(player_one_sample_ready),
    .sample(player_one_sample),
    .health(player_one_health),
    .swing_valid(player_one_swing_valid),
    .swing_ready(player_one_swing_ready),
    .swing_event(player_one_swing)
  );

  scripted_opponent opponent (
    .clk_sys,
    .rst_sys_n,
    .enable(scripted_opponent_enable),
    .game_tick,
    .render_state,
    .sample_valid(scripted_sample_valid),
    .sample_ready(scripted_sample_ready),
    .sample(scripted_sample),
    .health(scripted_health)
  );

  assign player_two_effective_valid = scripted_opponent_enable
                                    ? scripted_sample_valid : player_two_sample_valid;
  assign player_two_effective_sample = scripted_opponent_enable
                                     ? scripted_sample : player_two_sample;
  assign player_two_effective_health = scripted_opponent_enable
                                     ? scripted_health : player_two_health;
  assign player_two_sample_ready = !scripted_opponent_enable && player_two_effective_ready;
  assign scripted_sample_ready = scripted_opponent_enable && player_two_effective_ready;

  swing_detector player_two_detector (
    .clk_sys,
    .rst_sys_n,
    .sample_valid(player_two_effective_valid),
    .sample_ready(player_two_effective_ready),
    .sample(player_two_effective_sample),
    .health(player_two_effective_health),
    .swing_valid(player_two_swing_valid),
    .swing_ready(player_two_swing_ready),
    .swing_event(player_two_swing)
  );

  assign player_one_swing_ready = !player_one_pending_valid_q;
  assign player_two_swing_ready = !player_two_pending_valid_q;

  shot_mapper player_one_mapper (
    .toward_player_two(1'b1),
    .strength(player_one_pending_q.strength),
    .aim_x(player_one_pending_q.aim_x),
    .lift(player_one_pending_q.lift),
    .timing_error_q16((game_state_q == GAME_RALLY)
                      ? (ball_y_q16 + 32'sh0006_8000) : 32'sd0),
    .velocity_x_q16(player_one_shot_vx),
    .velocity_y_q16(player_one_shot_vy),
    .velocity_z_q16(player_one_shot_vz)
  );

  shot_mapper player_two_mapper (
    .toward_player_two(1'b0),
    .strength(player_two_pending_q.strength),
    .aim_x(player_two_pending_q.aim_x),
    .lift(player_two_pending_q.lift),
    .timing_error_q16((game_state_q == GAME_RALLY)
                      ? (ball_y_q16 - 32'sh0006_8000) : 32'sd0),
    .velocity_x_q16(player_two_shot_vx),
    .velocity_y_q16(player_two_shot_vy),
    .velocity_z_q16(player_two_shot_vz)
  );

  ball_physics physics (
    .clk_sys,
    .rst_sys_n,
    .game_tick,
    .state_load(physics_load_q),
    .load_active(physics_load_active_q),
    .load_x_q16(physics_load_x_q),
    .load_y_q16(physics_load_y_q),
    .load_z_q16(physics_load_z_q),
    .load_vx_q16(physics_load_vx_q),
    .load_vy_q16(physics_load_vy_q),
    .load_vz_q16(physics_load_vz_q),
    .ball_active,
    .ball_x_q16,
    .ball_y_q16,
    .ball_z_q16,
    .ball_vx_q16,
    .ball_vy_q16,
    .ball_vz_q16,
    .net_cross_pulse,
    .net_fault_pulse,
    .bounce_pulse,
    .bounce_in_bounds,
    .out_of_bounds_pulse,
    .stopped_pulse
  );

  tennis_rules rules (
    .clk_sys,
    .rst_sys_n,
    .match_reset,
    .point_valid,
    .point_winner_two,
    .player_two_serves,
    .player_one_points,
    .player_two_points,
    .player_one_games,
    .player_two_games,
    .player_one_sets,
    .player_two_sets,
    .advantage_valid,
    .advantage_player_two,
    .game_won_pulse,
    .set_won_pulse
  );

  rally_judge judge (
    .clk_sys,
    .rst_sys_n,
    .reset_rally(reset_rally_q),
    .last_hitter_two(last_hitter_two_q),
    .net_fault_pulse,
    .out_of_bounds_pulse,
    .stopped_pulse,
    .bounce_pulse,
    .bounce_in_bounds,
    .bounce_seen,
    .point_valid,
    .point_winner_two,
    .point_was_fault
  );

  assign player_one_contact = ball_active
                           && ($signed(ball_vy_q16) < 0)
                           && ($signed(ball_y_q16) >= -32'sh0008_0000)
                           && ($signed(ball_y_q16) <= -32'sh0005_0000)
                           && ($signed(ball_z_q16) <= 32'sh0003_0000);
  assign player_two_contact = ball_active
                           && ($signed(ball_vy_q16) > 0)
                           && ($signed(ball_y_q16) >= 32'sh0005_0000)
                           && ($signed(ball_y_q16) <= 32'sh0008_0000)
                           && ($signed(ball_z_q16) <= 32'sh0003_0000);

  assign audio_valid = audio_event_q.valid;
  assign audio_event = audio_event_q;

  assign render_state.valid = 1'b1;
  assign render_state.player_one_connected = player_one_health.connected && !player_one_health.stale;
  assign render_state.player_two_connected = player_two_effective_health.connected
                                           && !player_two_effective_health.stale;
  assign render_state.player_two_serves = player_two_serves;
  assign render_state.player_one_x_q8_8 = -16'sh0180;
  assign render_state.player_one_y_q8_8 = -16'sh0700;
  assign render_state.player_two_x_q8_8 = 16'sh0180;
  assign render_state.player_two_y_q8_8 = 16'sh0700;
  assign render_state.player_one_anim = player_one_pending_valid_q ? 4'd1 : 4'd0;
  assign render_state.player_two_anim = player_two_pending_valid_q ? 4'd1 : 4'd0;
  assign render_state.ball_visible = ball_active;
  assign render_state.ball_x_q8_8 = q16_to_q8_8(ball_x_q16);
  assign render_state.ball_y_q8_8 = q16_to_q8_8(ball_y_q16);
  assign render_state.ball_z_q8_8 = q16_to_q8_8(ball_z_q16);
  assign render_state.player_one_points = player_one_points;
  assign render_state.player_two_points = player_two_points;
  assign render_state.player_one_games = player_one_games;
  assign render_state.player_two_games = player_two_games;
  assign render_state.player_one_sets = player_one_sets;
  assign render_state.player_two_sets = player_two_sets;
  assign render_state.player_one_swing_meter = player_one_meter_q;
  assign render_state.player_two_swing_meter = player_two_meter_q;

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      game_state_q <= GAME_WAIT_SERVE;
      player_one_pending_q <= '0;
      player_two_pending_q <= '0;
      player_one_pending_valid_q <= 1'b0;
      player_two_pending_valid_q <= 1'b0;
      physics_load_q <= 1'b0;
      physics_load_active_q <= 1'b0;
      physics_load_x_q <= '0;
      physics_load_y_q <= '0;
      physics_load_z_q <= '0;
      physics_load_vx_q <= '0;
      physics_load_vy_q <= '0;
      physics_load_vz_q <= '0;
      last_hitter_two_q <= 1'b0;
      reset_rally_q <= 1'b0;
      audio_event_q <= '0;
      player_one_meter_q <= '0;
      player_two_meter_q <= '0;
      timing_error <= '0;
    end else begin
      physics_load_q <= 1'b0;
      reset_rally_q <= 1'b0;

      if (audio_event_q.valid && audio_ready) begin
        audio_event_q.valid <= 1'b0;
      end

      if (player_one_swing_valid && player_one_swing_ready) begin
        player_one_pending_q <= player_one_swing;
        player_one_pending_valid_q <= 1'b1;
        player_one_meter_q <= player_one_swing.strength;
      end
      if (player_two_swing_valid && player_two_swing_ready) begin
        player_two_pending_q <= player_two_swing;
        player_two_pending_valid_q <= 1'b1;
        player_two_meter_q <= player_two_swing.strength;
      end

      if (match_reset) begin
        game_state_q <= GAME_WAIT_SERVE;
        player_one_pending_valid_q <= 1'b0;
        player_two_pending_valid_q <= 1'b0;
        physics_load_q <= 1'b1;
        physics_load_active_q <= 1'b0;
        audio_event_q.valid <= 1'b0;
        player_one_meter_q <= '0;
        player_two_meter_q <= '0;
      end else begin
        if (point_valid) begin
          game_state_q <= GAME_WAIT_SERVE;
          physics_load_q <= 1'b1;
          physics_load_active_q <= 1'b0;
          audio_event_q.valid <= 1'b1;
          audio_event_q.kind <= point_was_fault ? AUDIO_EVENT_FAULT : AUDIO_EVENT_SCORE;
          audio_event_q.player_two <= point_winner_two;
          audio_event_q.strength <= point_was_fault ? 16'h9000 : 16'hc000;
        end else if (bounce_pulse) begin
          audio_event_q.kind <= AUDIO_EVENT_BOUNCE;
          audio_event_q.player_two <= last_hitter_two_q;
          audio_event_q.strength <= 16'h7000;
          audio_event_q.valid <= 1'b1;
        end

        if (game_tick) begin
          if (player_one_meter_q > 16'h0100) begin
            player_one_meter_q <= player_one_meter_q - 16'h0100;
          end else begin
            player_one_meter_q <= '0;
          end
          if (player_two_meter_q > 16'h0100) begin
            player_two_meter_q <= player_two_meter_q - 16'h0100;
          end else begin
            player_two_meter_q <= '0;
          end

          if (game_state_q == GAME_WAIT_SERVE) begin
            if ((!player_two_serves && player_one_pending_valid_q)
                || (player_two_serves && player_two_pending_valid_q)) begin
              physics_load_q <= 1'b1;
              physics_load_active_q <= 1'b1;
              physics_load_x_q <= '0;
              physics_load_y_q <= player_two_serves ? 32'sh0007_0000 : -32'sh0007_0000;
              physics_load_z_q <= 32'sh0001_8000;
              if (player_two_serves) begin
                physics_load_vx_q <= player_two_shot_vx;
                physics_load_vy_q <= player_two_shot_vy;
                physics_load_vz_q <= player_two_shot_vz;
                player_two_pending_valid_q <= 1'b0;
              end else begin
                physics_load_vx_q <= player_one_shot_vx;
                physics_load_vy_q <= player_one_shot_vy;
                physics_load_vz_q <= player_one_shot_vz;
                player_one_pending_valid_q <= 1'b0;
              end
              last_hitter_two_q <= player_two_serves;
              reset_rally_q <= 1'b1;
              game_state_q <= GAME_RALLY;
              audio_event_q.valid <= 1'b1;
              audio_event_q.kind <= AUDIO_EVENT_HIT;
              audio_event_q.player_two <= player_two_serves;
              audio_event_q.strength <= player_two_serves
                                      ? player_two_pending_q.strength
                                      : player_one_pending_q.strength;
            end
          end else begin
            if (player_one_pending_valid_q) begin
              player_one_pending_valid_q <= 1'b0;
              if (player_one_contact) begin
                timing_error <= ball_y_q16 + 32'sh0006_8000;
                physics_load_q <= 1'b1;
                physics_load_active_q <= 1'b1;
                physics_load_x_q <= ball_x_q16;
                physics_load_y_q <= ball_y_q16;
                physics_load_z_q <= ball_z_q16;
                physics_load_vx_q <= player_one_shot_vx;
                physics_load_vy_q <= player_one_shot_vy;
                physics_load_vz_q <= player_one_shot_vz;
                last_hitter_two_q <= 1'b0;
                reset_rally_q <= 1'b1;
                audio_event_q.valid <= 1'b1;
                audio_event_q.kind <= AUDIO_EVENT_HIT;
                audio_event_q.player_two <= 1'b0;
                audio_event_q.strength <= player_one_pending_q.strength;
              end
            end
            if (player_two_pending_valid_q) begin
              player_two_pending_valid_q <= 1'b0;
              if (player_two_contact) begin
                timing_error <= ball_y_q16 - 32'sh0006_8000;
                physics_load_q <= 1'b1;
                physics_load_active_q <= 1'b1;
                physics_load_x_q <= ball_x_q16;
                physics_load_y_q <= ball_y_q16;
                physics_load_z_q <= ball_z_q16;
                physics_load_vx_q <= player_two_shot_vx;
                physics_load_vy_q <= player_two_shot_vy;
                physics_load_vz_q <= player_two_shot_vz;
                last_hitter_two_q <= 1'b1;
                reset_rally_q <= 1'b1;
                audio_event_q.valid <= 1'b1;
                audio_event_q.kind <= AUDIO_EVENT_HIT;
                audio_event_q.player_two <= 1'b1;
                audio_event_q.strength <= player_two_pending_q.strength;
              end
            end
          end
        end
      end
    end
  end
endmodule
