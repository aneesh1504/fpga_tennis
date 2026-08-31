module board_a_system #(
  parameter int unsigned CLOCK_HZ = 100_000_000,
  parameter int unsigned PLAYER_1_BAUD = 115_200,
  parameter int unsigned PLAYER_2_BAUD = 115_200,
  parameter int unsigned FRAME_TIMEOUT_MS = 20,
  parameter int unsigned STALE_TIMEOUT_MS = 250
) (
  input  logic                                clk_sys,
  input  logic                                clk_pix,
  input  logic                                async_rst_n,
  input  logic                                player_1_serial_rx,
  input  logic                                player_2_serial_rx,
  input  logic                                match_reset,
  input  logic                                scripted_opponent_enable,
  output protocol_pkg::transport_health_t     player_1_debug_health,
  output protocol_pkg::transport_health_t     player_2_debug_health,
  output video_types_pkg::game_render_state_t render_state_sys_debug,
  output video_types_pkg::game_render_state_t render_state_pix_debug,
  output logic                                game_tick_debug,
  output logic                                pixel_state_valid_debug,
  output logic                                snapshot_pending,
  output logic [11:0]                         pixel_x,
  output logic [10:0]                         pixel_y,
  output logic                                hsync,
  output logic                                vsync,
  output logic                                video_data_enable,
  output logic                                start_of_line,
  output logic                                start_of_frame,
  output logic [7:0]                          red,
  output logic [7:0]                          green,
  output logic [7:0]                          blue,
  output logic signed [15:0]                  audio_pcm,
  output logic                                audio_pwm,
  output logic                                audio_voice_active
);
  import protocol_pkg::*;
  import game_types_pkg::*;
  import video_types_pkg::*;

  logic rst_sys_n;
  logic rst_pix_n;
  logic game_tick;

  logic player_1_valid;
  logic player_1_ready;
  motion_sample_t player_1_sample;
  transport_health_t player_1_health;
  logic player_2_valid;
  logic player_2_ready;
  motion_sample_t player_2_sample;
  transport_health_t player_2_health;

  game_render_state_t render_state_sys;
  game_render_state_t render_state_pix;
  logic game_audio_valid;
  logic game_audio_ready;
  audio_event_t game_audio_event;

  logic vblank_request_toggle;
  logic snapshot_ready_toggle;
  logic pixel_state_valid;

  reset_sync sys_reset (
    .clk(clk_sys),
    .async_rst_n,
    .sync_rst_n(rst_sys_n)
  );

  reset_sync pixel_reset (
    .clk(clk_pix),
    .async_rst_n,
    .sync_rst_n(rst_pix_n)
  );

  tick_gen #(
    .CLOCK_HZ(CLOCK_HZ),
    .TICK_HZ(60)
  ) game_tick_generator (
    .clk(clk_sys),
    .rst_n(rst_sys_n),
    .tick(game_tick)
  );

  dual_motion_transport_rx #(
    .CLOCK_HZ(CLOCK_HZ),
    .PLAYER_1_BAUD(PLAYER_1_BAUD),
    .PLAYER_2_BAUD(PLAYER_2_BAUD),
    .FRAME_TIMEOUT_MS(FRAME_TIMEOUT_MS),
    .STALE_TIMEOUT_MS(STALE_TIMEOUT_MS)
  ) transport (
    .clk(clk_sys),
    .rst_n(rst_sys_n),
    .player_1_serial_rx,
    .player_1_valid,
    .player_1_ready,
    .player_1_sample,
    .player_1_health,
    .player_1_debug_health,
    .player_2_serial_rx,
    .player_2_valid,
    .player_2_ready,
    .player_2_sample,
    .player_2_health,
    .player_2_debug_health
  );

  game_engine game (
    .clk_sys,
    .rst_sys_n,
    .game_tick,
    .match_reset,
    .player_one_sample_valid(player_1_valid),
    .player_one_sample_ready(player_1_ready),
    .player_one_sample(player_1_sample),
    .player_one_health(player_1_health),
    .player_two_sample_valid(player_2_valid),
    .player_two_sample_ready(player_2_ready),
    .player_two_sample(player_2_sample),
    .player_two_health(player_2_health),
    .scripted_opponent_enable,
    .render_state(render_state_sys),
    .audio_valid(game_audio_valid),
    .audio_ready(game_audio_ready),
    .audio_event(game_audio_event)
  );

  render_state_mailbox render_mailbox (
    .clk_sys,
    .rst_sys_n,
    .render_state_sys,
    .clk_pix,
    .rst_pix_n,
    .vblank_request_toggle,
    .snapshot_ready_toggle,
    .pixel_state_valid,
    .render_state_pix
  );

  video_pipeline video (
    .clk_pix,
    .rst_pix_n,
    .render_state_pix,
    .pixel_state_valid,
    .vblank_request_toggle,
    .snapshot_pending,
    .pixel_x,
    .pixel_y,
    .hsync,
    .vsync,
    .video_data_enable,
    .start_of_line,
    .start_of_frame,
    .red,
    .green,
    .blue
  );

  audio_engine #(
    .CLOCK_HZ(CLOCK_HZ),
    .SAMPLE_HZ(48_000)
  ) audio (
    .clk_sys,
    .rst_sys_n,
    .event_valid(game_audio_valid),
    .event_ready(game_audio_ready),
    .event_data(game_audio_event),
    .pcm_sample(audio_pcm),
    .audio_pwm,
    .voice_active(audio_voice_active)
  );

  assign render_state_sys_debug = render_state_sys;
  assign render_state_pix_debug = render_state_pix;
  assign game_tick_debug = game_tick;
  assign pixel_state_valid_debug = pixel_state_valid;
endmodule
