module tb_video_snapshot_atomic;
  import video_types_pkg::*;

  logic clk_sys = 1'b0;
  logic clk_pix = 1'b0;
  logic rst_sys_n = 1'b0;
  logic rst_pix_n = 1'b0;
  game_render_state_t render_state_sys;
  logic vblank_request_toggle;
  logic snapshot_ready_toggle;
  logic pixel_state_valid;
  game_render_state_t render_state_pix;
  game_render_state_t state_a;
  game_render_state_t state_b;
  logic ready_before;

  always #5 clk_sys = ~clk_sys;
  always #7 clk_pix = ~clk_pix;

  gameplay_video_stub dut (.*);

  initial begin
    state_a = '0;
    state_a.valid = 1'b1;
    state_a.player_one_connected = 1'b1;
    state_a.player_one_x_q8_8 = -16'sd40 <<< 8;
    state_a.player_one_y_q8_8 = 16'sd4 <<< 8;
    state_a.player_one_anim = 4'd1;
    state_a.ball_visible = 1'b1;
    state_a.ball_x_q8_8 = 16'sd12 <<< 8;
    state_a.ball_y_q8_8 = 16'sd50 <<< 8;
    state_a.ball_z_q8_8 = 16'sd20 <<< 8;
    state_a.player_one_points = 2'd1;
    state_a.player_two_points = 2'd2;
    state_a.player_one_swing_meter = 16'h1234;

    state_b = '0;
    state_b.valid = 1'b1;
    state_b.player_two_connected = 1'b1;
    state_b.player_two_serves = 1'b1;
    state_b.player_two_x_q8_8 = 16'sd55 <<< 8;
    state_b.player_two_y_q8_8 = 16'sd100 <<< 8;
    state_b.player_two_anim = 4'd3;
    state_b.ball_visible = 1'b1;
    state_b.ball_x_q8_8 = -16'sd25 <<< 8;
    state_b.ball_y_q8_8 = 16'sd80 <<< 8;
    state_b.ball_z_q8_8 = 16'sd5 <<< 8;
    state_b.player_one_games = 4'd6;
    state_b.player_two_games = 4'd7;
    state_b.player_two_swing_meter = 16'hfedc;

    render_state_sys = state_a;
    vblank_request_toggle = 1'b0;
    repeat (3) @(negedge clk_sys);
    rst_sys_n = 1'b1;
    rst_pix_n = 1'b1;

    @(negedge clk_pix);
    ready_before = snapshot_ready_toggle;
    vblank_request_toggle = ~vblank_request_toggle;
    wait (snapshot_ready_toggle != ready_before);
    // Change every semantic group immediately after the system-domain capture,
    // while the ready toggle and old shadow bank are still crossing to pixels.
    render_state_sys = state_b;
    wait (pixel_state_valid);
    if (render_state_pix !== state_a) $fatal(1, "first snapshot was torn");

    wait (!pixel_state_valid);
    @(negedge clk_pix);
    ready_before = snapshot_ready_toggle;
    vblank_request_toggle = ~vblank_request_toggle;
    wait (snapshot_ready_toggle != ready_before);
    wait (pixel_state_valid);
    if (render_state_pix !== state_b) $fatal(1, "second snapshot was torn");

    rst_sys_n = 1'b0;
    rst_pix_n = 1'b0;
    #1;
    if (snapshot_ready_toggle || pixel_state_valid || render_state_pix !== '0) $fatal(1, "snapshot reset state");
    $display("PASS: near-boundary state change produced complete old/new snapshots and clean reset");
    $finish;
  end
endmodule
