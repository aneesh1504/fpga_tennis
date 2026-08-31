module tb_interface_smoke;
  import protocol_pkg::*;
  import game_types_pkg::*;
  import video_types_pkg::*;

  logic clk_sys = 1'b0;
  logic clk_pix = 1'b0;
  logic rst_sys_n = 1'b0;
  logic rst_pix_n = 1'b0;
  always #5 clk_sys = ~clk_sys;
  always #7 clk_pix = ~clk_pix;

  logic transport_valid;
  logic transport_ready;
  motion_sample_t transport_sample;
  transport_health_t transport_health;
  logic gameplay_valid;
  logic gameplay_ready;
  motion_sample_t gameplay_sample;
  transport_health_t gameplay_health;

  logic gameplay_audio_valid;
  logic gameplay_audio_ready;
  audio_event_t gameplay_audio_event;
  logic audio_valid;
  logic audio_ready;
  audio_event_t audio_event;

  game_render_state_t render_state_sys;
  logic vblank_request_toggle;
  logic snapshot_ready_toggle;
  logic pixel_state_valid;
  game_render_state_t render_state_pix;

  logic top_gameplay_ready;
  logic top_gameplay_valid;
  motion_sample_t top_gameplay_sample;
  transport_health_t top_gameplay_health;
  logic top_video_valid;
  game_render_state_t top_video_state;
  logic top_gameplay_audio_ready;
  logic top_audio_valid;
  audio_event_t top_audio_event;

  transport_gameplay_stub transport_gameplay (
    .clk_sys, .rst_sys_n, .transport_valid, .transport_ready,
    .transport_sample, .transport_health, .gameplay_valid,
    .gameplay_ready, .gameplay_sample, .gameplay_health
  );

  gameplay_audio_stub gameplay_audio (
    .clk_sys, .rst_sys_n, .gameplay_valid(gameplay_audio_valid),
    .gameplay_ready(gameplay_audio_ready), .gameplay_event(gameplay_audio_event),
    .audio_valid, .audio_ready, .audio_event
  );

  gameplay_video_stub gameplay_video (
    .clk_sys, .rst_sys_n, .render_state_sys, .clk_pix, .rst_pix_n,
    .vblank_request_toggle, .snapshot_ready_toggle,
    .pixel_state_valid, .render_state_pix
  );

  board_a_top top_level_seam (
    .transport_p1_valid(transport_valid),
    .gameplay_p1_ready(top_gameplay_ready),
    .transport_p1_sample(transport_sample),
    .transport_p1_health(transport_health),
    .gameplay_p1_valid(top_gameplay_valid),
    .gameplay_p1_sample(top_gameplay_sample),
    .gameplay_p1_health(top_gameplay_health),
    .gameplay_render_valid(render_state_sys.valid),
    .gameplay_render_state(render_state_sys),
    .video_render_valid(top_video_valid),
    .video_render_state(top_video_state),
    .gameplay_audio_valid(gameplay_audio_valid),
    .gameplay_audio_ready(top_gameplay_audio_ready),
    .gameplay_audio_event(gameplay_audio_event),
    .audio_event_valid(top_audio_valid),
    .audio_event_ready(audio_ready),
    .audio_event(top_audio_event)
  );

  initial begin
    transport_valid       = 1'b0;
    transport_sample      = '0;
    transport_health      = '0;
    gameplay_ready        = 1'b0;
    gameplay_audio_valid  = 1'b0;
    gameplay_audio_event  = '0;
    audio_ready           = 1'b0;
    render_state_sys      = '0;
    vblank_request_toggle = 1'b0;

    #18;
    rst_sys_n = 1'b1;
    rst_pix_n = 1'b1;

    @(negedge clk_sys);
    transport_sample.valid = 1'b1;
    transport_sample.sequence_number = 16'h55aa;
    transport_health.connected = 1'b1;
    transport_valid = 1'b1;
    @(negedge clk_sys);
    transport_valid = 1'b0;
    repeat (2) @(negedge clk_sys);
    if (!gameplay_valid || gameplay_sample.sequence_number != 16'h55aa) $fatal(1, "transport to gameplay payload");
    gameplay_ready = 1'b1;
    @(negedge clk_sys);
    gameplay_ready = 1'b0;

    gameplay_audio_event.valid = 1'b1;
    gameplay_audio_event.kind = AUDIO_EVENT_HIT;
    gameplay_audio_event.strength = 16'hc000;
    gameplay_audio_valid = 1'b1;
    @(negedge clk_sys);
    gameplay_audio_valid = 1'b0;
    repeat (2) @(negedge clk_sys);
    if (!audio_valid || audio_event.kind != AUDIO_EVENT_HIT) $fatal(1, "gameplay to audio payload");
    audio_ready = 1'b1;
    @(negedge clk_sys);

    render_state_sys.valid = 1'b1;
    render_state_sys.ball_x_q8_8 = 16'sh1234;
    @(negedge clk_pix);
    vblank_request_toggle = ~vblank_request_toggle;
    wait (pixel_state_valid);
    if (!render_state_pix.valid || render_state_pix.ball_x_q8_8 != 16'sh1234) $fatal(1, "gameplay to video snapshot");

    transport_valid = 1'b1;
    transport_sample.sequence_number = 16'hcafe;
    gameplay_audio_valid = 1'b1;
    gameplay_audio_event.kind = AUDIO_EVENT_SCORE;
    #1;
    if (!top_gameplay_ready || !top_gameplay_valid || top_gameplay_sample.sequence_number != 16'hcafe) $fatal(1, "top transport seam");
    if (!top_video_valid || top_video_state.ball_x_q8_8 != 16'sh1234) $fatal(1, "top video seam");
    if (!top_gameplay_audio_ready || !top_audio_valid || top_audio_event.kind != AUDIO_EVENT_SCORE) $fatal(1, "top audio seam");

    $display("PASS: transport->gameplay valid/ready interface");
    $display("PASS: gameplay->video atomic snapshot interface");
    $display("PASS: gameplay->audio valid/ready interface");
    $display("PASS: subsystem->top structural interface");
    $finish;
  end
endmodule
