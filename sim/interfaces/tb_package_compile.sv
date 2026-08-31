module tb_package_compile;
  import protocol_pkg::*;
  import game_types_pkg::*;
  import video_types_pkg::*;

  motion_sample_t      motion;
  transport_health_t   health;
  swing_event_t        swing;
  audio_event_t        audio;
  game_render_state_t  render;

  initial begin
    motion = '0;
    health = '0;
    swing  = '0;
    audio  = '0;
    render = '0;

    if (PROTOCOL_INTERFACE_VERSION != 16'h0100) $fatal(1, "protocol interface version");
    if (GAME_INTERFACE_VERSION != 16'h0100) $fatal(1, "game interface version");
    if (VIDEO_INTERFACE_VERSION != 16'h0100) $fatal(1, "video interface version");
    if ($bits(motion_sample_t) != 210) $fatal(1, "motion_sample_t width");
    if ($bits(swing_event_t) != 51) $fatal(1, "swing_event_t width");
    if (MOTION_PAYLOAD_BYTES != 32) $fatal(1, "motion payload length");
    $display("PASS: shared packages compile and elaborate");
    $finish;
  end
endmodule
