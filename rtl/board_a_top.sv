module board_a_top (
  input  logic                                transport_p1_valid,
  output logic                                gameplay_p1_ready,
  input  protocol_pkg::motion_sample_t        transport_p1_sample,
  input  protocol_pkg::transport_health_t     transport_p1_health,
  output logic                                gameplay_p1_valid,
  output protocol_pkg::motion_sample_t        gameplay_p1_sample,
  output protocol_pkg::transport_health_t     gameplay_p1_health,
  input  logic                                gameplay_render_valid,
  input  video_types_pkg::game_render_state_t gameplay_render_state,
  output logic                                video_render_valid,
  output video_types_pkg::game_render_state_t video_render_state,
  input  logic                                gameplay_audio_valid,
  output logic                                gameplay_audio_ready,
  input  game_types_pkg::audio_event_t         gameplay_audio_event,
  output logic                                audio_event_valid,
  input  logic                                audio_event_ready,
  output game_types_pkg::audio_event_t         audio_event
);
  assign gameplay_p1_ready   = 1'b1;
  assign gameplay_p1_valid   = transport_p1_valid;
  assign gameplay_p1_sample  = transport_p1_sample;
  assign gameplay_p1_health  = transport_p1_health;
  assign video_render_valid  = gameplay_render_valid;
  assign video_render_state  = gameplay_render_state;
  assign gameplay_audio_ready = audio_event_ready;
  assign audio_event_valid   = gameplay_audio_valid;
  assign audio_event         = gameplay_audio_event;
endmodule
