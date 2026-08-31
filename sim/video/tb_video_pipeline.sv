module tb_video_pipeline;
  import video_types_pkg::*;

  logic clk_pix = 1'b0;
  logic rst_pix_n = 1'b0;
  game_render_state_t render_state;
  logic snapshot_ready_toggle;
  logic vblank_request_toggle;
  logic snapshot_pending;
  logic [11:0] pixel_x;
  logic [10:0] pixel_y;
  logic hsync;
  logic vsync;
  logic video_data_enable;
  logic start_of_line;
  logic start_of_frame;
  logic [7:0] red;
  logic [7:0] green;
  logic [7:0] blue;

  integer active_count;
  integer blank_count;
  integer court_count;
  integer surround_count;
  integer crowd_count;
  integer line_count;
  integer ball_count;
  integer player_count;
  integer p1_meter_count;
  integer p2_meter_count;
  integer request_count;
  logic request_seen;
  logic [23:0] rgb;

  always #1 clk_pix = ~clk_pix;
  assign rgb = {red, green, blue};

  video_pipeline dut (.*);

  initial begin
    render_state = '0;
    render_state.valid = 1'b1;
    render_state.player_one_connected = 1'b1;
    render_state.player_two_connected = 1'b1;
    render_state.player_one_x_q8_8 = -16'sd40 <<< 8;
    render_state.player_one_y_q8_8 = 16'sd0;
    render_state.player_two_x_q8_8 = 16'sd30 <<< 8;
    render_state.player_two_y_q8_8 = 16'sd100 <<< 8;
    render_state.player_one_anim = 4'd1;
    render_state.player_two_anim = 4'd2;
    render_state.ball_visible = 1'b1;
    render_state.ball_x_q8_8 = 16'sd0;
    render_state.ball_y_q8_8 = 16'sd64 <<< 8;
    render_state.ball_z_q8_8 = 16'sd30 <<< 8;
    render_state.player_one_points = 2'd2;
    render_state.player_two_points = 2'd3;
    render_state.player_one_swing_meter = 16'h8000;
    render_state.player_two_swing_meter = 16'h4000;
    snapshot_ready_toggle = 1'b0;
    request_seen = 1'b0;
    request_count = 0;
    repeat (4) @(negedge clk_pix);
    rst_pix_n = 1'b1;

    @(negedge clk_pix);
    while (!start_of_frame) @(negedge clk_pix);
    active_count = 0;
    blank_count = 0;
    court_count = 0;
    surround_count = 0;
    crowd_count = 0;
    line_count = 0;
    ball_count = 0;
    player_count = 0;
    p1_meter_count = 0;
    p2_meter_count = 0;

    do begin
      if (video_data_enable) begin
        active_count = active_count + 1;
        if (pixel_x >= 1280 || pixel_y >= 720) $fatal(1, "pipeline VDE/coordinate misalignment");
        case (rgb)
          24'h1769aa: court_count = court_count + 1;
          24'h176b52: surround_count = surround_count + 1;
          24'h29324f, 24'h3b4669: crowd_count = crowd_count + 1;
          24'hf4f1dc, 24'hfff7dc: line_count = line_count + 1;
          24'hfff36a: ball_count = ball_count + 1;
          24'hf04b5a: player_count = player_count + 1;
          24'h52d6ff: p1_meter_count = p1_meter_count + 1;
          24'hffb84a: p2_meter_count = p2_meter_count + 1;
          default: begin end
        endcase
      end else begin
        blank_count = blank_count + 1;
        if (rgb != 24'h000000) $fatal(1, "non-black RGB during blanking at %0d,%0d", pixel_x, pixel_y);
      end

      if (vblank_request_toggle != request_seen) begin
        request_seen = vblank_request_toggle;
        request_count = request_count + 1;
        snapshot_ready_toggle = request_seen;
      end
      @(negedge clk_pix);
    end while (!start_of_frame);

    if (active_count != 1280 * 720) $fatal(1, "pipeline active count %0d", active_count);
    if (court_count < 200000) $fatal(1, "court not substantially rendered: %0d", court_count);
    if (surround_count < 100000) $fatal(1, "surround not substantially rendered: %0d", surround_count);
    if (crowd_count < 100000) $fatal(1, "crowd not substantially rendered: %0d", crowd_count);
    if (line_count < 1000) $fatal(1, "lines/UI not rendered: %0d", line_count);
    if (ball_count < 40) $fatal(1, "ball not rendered: %0d", ball_count);
    if (player_count < 40) $fatal(1, "sprites not rendered: %0d", player_count);
    if (p1_meter_count != 128 * 12) $fatal(1, "P1 meter width: %0d", p1_meter_count);
    if (p2_meter_count != 64 * 12) $fatal(1, "P2 meter width: %0d", p2_meter_count);
    if (request_count != 1) $fatal(1, "snapshot request count: %0d", request_count);
    repeat (3) @(negedge clk_pix);
    if (snapshot_pending) $fatal(1, "snapshot acknowledgement did not clear pending");

    $display("PASS: full 1280x720 procedural scene, aligned controls, dynamic sprites/ball/UI, and snapshot handshake");
    $display("INFO: active=%0d blank=%0d court=%0d surround=%0d crowd=%0d line_ui=%0d ball=%0d player=%0d", active_count, blank_count, court_count, surround_count, crowd_count, line_count, ball_count, player_count);
    $finish;
  end
endmodule
