module video_pipeline (
  input  logic                                clk_pix,
  input  logic                                rst_pix_n,
  input  video_types_pkg::game_render_state_t render_state,
  input  logic                                snapshot_ready_toggle,
  output logic                                vblank_request_toggle,
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
  output logic [7:0]                          blue
);
  logic [11:0] raw_x;
  logic [10:0] raw_y;
  logic raw_hsync;
  logic raw_vsync;
  logic raw_vde;
  logic raw_start_of_line;
  logic raw_start_of_frame;
  logic raw_vertical_blank;

  logic signed [12:0] player_one_screen_x;
  logic signed [12:0] player_one_screen_y;
  logic signed [12:0] player_two_screen_x;
  logic signed [12:0] player_two_screen_y;
  logic signed [12:0] ball_screen_x;
  logic signed [12:0] ball_screen_y;
  logic signed [12:0] shadow_screen_x;
  logic signed [12:0] shadow_screen_y;
  logic [9:0] unused_width_p1;
  logic [9:0] unused_width_p2;
  logic [9:0] unused_width_ball;
  logic [9:0] unused_width_shadow;

  logic [23:0] background_rgb_raw;
  logic court_valid_raw;
  logic [23:0] court_rgb_raw;
  logic line_valid_raw;
  logic [23:0] line_rgb_raw;
  logic net_background_valid_raw;
  logic [23:0] net_background_rgb_raw;
  logic net_foreground_valid_raw;
  logic [23:0] net_foreground_rgb_raw;

  logic near_player_valid_d1;
  logic [23:0] near_player_rgb_d1;
  logic far_player_valid_d1;
  logic [23:0] far_player_rgb_d1;
  logic ui_valid_d1;
  logic [23:0] ui_rgb_d1;

  logic ball_valid_raw;
  logic [23:0] ball_rgb_raw;
  integer ball_dx;
  integer ball_dy;
  integer shadow_dx;
  integer shadow_dy;

  logic [23:0] background_rgb_d1;
  logic court_valid_d1;
  logic [23:0] court_rgb_d1;
  logic line_valid_d1;
  logic [23:0] line_rgb_d1;
  logic net_background_valid_d1;
  logic [23:0] net_background_rgb_d1;
  logic net_foreground_valid_d1;
  logic [23:0] net_foreground_rgb_d1;
  logic ball_valid_d1;
  logic [23:0] ball_rgb_d1;
  logic [23:0] composed_rgb;

  logic [11:0] pixel_x_d1;
  logic [11:0] pixel_x_d2;
  logic [10:0] pixel_y_d1;
  logic [10:0] pixel_y_d2;
  logic hsync_d1;
  logic hsync_d2;
  logic vsync_d1;
  logic vsync_d2;
  logic video_data_enable_d1;
  logic video_data_enable_d2;
  logic start_of_line_d1;
  logic start_of_line_d2;
  logic start_of_frame_d1;
  logic start_of_frame_d2;

  logic vertical_blank_d;
  logic ready_seen;
  logic ready_changed;

  video_timing_720p timing (
    .clk_pix,
    .rst_pix_n,
    .pixel_x(raw_x),
    .pixel_y(raw_y),
    .hsync(raw_hsync),
    .vsync(raw_vsync),
    .video_data_enable(raw_vde),
    .start_of_line(raw_start_of_line),
    .start_of_frame(raw_start_of_frame),
    .vertical_blank(raw_vertical_blank)
  );

  perspective_projector project_player_one (
    .court_x_q8_8(render_state.player_one_x_q8_8),
    .court_y_q8_8(render_state.player_one_y_q8_8),
    .height_q8_8(16'sd0),
    .screen_x(player_one_screen_x),
    .screen_y(player_one_screen_y),
    .perspective_width(unused_width_p1)
  );

  perspective_projector project_player_two (
    .court_x_q8_8(render_state.player_two_x_q8_8),
    .court_y_q8_8(render_state.player_two_y_q8_8),
    .height_q8_8(16'sd0),
    .screen_x(player_two_screen_x),
    .screen_y(player_two_screen_y),
    .perspective_width(unused_width_p2)
  );

  perspective_projector project_ball (
    .court_x_q8_8(render_state.ball_x_q8_8),
    .court_y_q8_8(render_state.ball_y_q8_8),
    .height_q8_8(render_state.ball_z_q8_8),
    .screen_x(ball_screen_x),
    .screen_y(ball_screen_y),
    .perspective_width(unused_width_ball)
  );

  perspective_projector project_shadow (
    .court_x_q8_8(render_state.ball_x_q8_8),
    .court_y_q8_8(render_state.ball_y_q8_8),
    .height_q8_8(16'sd0),
    .screen_x(shadow_screen_x),
    .screen_y(shadow_screen_y),
    .perspective_width(unused_width_shadow)
  );

  court_renderer court (
    .pixel_x(raw_x),
    .pixel_y(raw_y),
    .video_data_enable(raw_vde),
    .background_rgb(background_rgb_raw),
    .court_valid(court_valid_raw),
    .court_rgb(court_rgb_raw),
    .line_valid(line_valid_raw),
    .line_rgb(line_rgb_raw)
  );

  net_renderer net (
    .pixel_x(raw_x),
    .pixel_y(raw_y),
    .video_data_enable(raw_vde),
    .net_background_valid(net_background_valid_raw),
    .net_background_rgb(net_background_rgb_raw),
    .net_foreground_valid(net_foreground_valid_raw),
    .net_foreground_rgb(net_foreground_rgb_raw)
  );

  sprite_renderer #(
    .SPRITE_WIDTH(16),
    .SPRITE_HEIGHT(24),
    .FRAME_COUNT(4),
    .SCALE(2),
    .MEM_FILE("assets/generated_mem/player_near.mem")
  ) near_player (
    .clk_pix,
    .rst_pix_n,
    .pixel_x(raw_x),
    .pixel_y(raw_y),
    .video_data_enable(raw_vde),
    .sprite_enable(render_state.valid && render_state.player_one_connected),
    .center_x(player_one_screen_x),
    .bottom_y(player_one_screen_y),
    .pose(render_state.player_one_anim),
    .mirror(1'b0),
    .sprite_valid(near_player_valid_d1),
    .sprite_rgb(near_player_rgb_d1)
  );

  sprite_renderer #(
    .SPRITE_WIDTH(12),
    .SPRITE_HEIGHT(18),
    .FRAME_COUNT(4),
    .SCALE(1),
    .MEM_FILE("assets/generated_mem/player_far.mem")
  ) far_player (
    .clk_pix,
    .rst_pix_n,
    .pixel_x(raw_x),
    .pixel_y(raw_y),
    .video_data_enable(raw_vde),
    .sprite_enable(render_state.valid && render_state.player_two_connected),
    .center_x(player_two_screen_x),
    .bottom_y(player_two_screen_y),
    .pose(render_state.player_two_anim),
    .mirror(1'b1),
    .sprite_valid(far_player_valid_d1),
    .sprite_rgb(far_player_rgb_d1)
  );

  ui_renderer ui (
    .clk_pix,
    .rst_pix_n,
    .pixel_x(raw_x),
    .pixel_y(raw_y),
    .video_data_enable(raw_vde),
    .render_state,
    .ui_valid(ui_valid_d1),
    .ui_rgb(ui_rgb_d1)
  );

  always_comb begin
    ball_dx   = $signed({1'b0, raw_x}) - $signed(ball_screen_x);
    ball_dy   = $signed({1'b0, raw_y}) - $signed(ball_screen_y);
    shadow_dx = $signed({1'b0, raw_x}) - $signed(shadow_screen_x);
    shadow_dy = $signed({1'b0, raw_y}) - $signed(shadow_screen_y);
    ball_valid_raw = 1'b0;
    ball_rgb_raw   = 24'h000000;
    if (raw_vde && render_state.valid && render_state.ball_visible) begin
      if ((ball_dx * ball_dx + ball_dy * ball_dy) <= 25) begin
        ball_valid_raw = 1'b1;
        ball_rgb_raw   = 24'hfff36a;
      end else if ((shadow_dx * shadow_dx * 4 + shadow_dy * shadow_dy * 16) <= 196) begin
        ball_valid_raw = 1'b1;
        ball_rgb_raw   = 24'h143f42;
      end
    end
  end

  pixel_compositor compositor (
    .video_data_enable(video_data_enable_d1),
    .background_rgb(background_rgb_d1),
    .court_valid(court_valid_d1),
    .court_rgb(court_rgb_d1),
    .line_valid(line_valid_d1),
    .line_rgb(line_rgb_d1),
    .net_background_valid(net_background_valid_d1),
    .net_background_rgb(net_background_rgb_d1),
    .far_player_valid(far_player_valid_d1),
    .far_player_rgb(far_player_rgb_d1),
    .net_foreground_valid(net_foreground_valid_d1),
    .net_foreground_rgb(net_foreground_rgb_d1),
    .near_player_valid(near_player_valid_d1),
    .near_player_rgb(near_player_rgb_d1),
    .ball_valid(ball_valid_d1),
    .ball_rgb(ball_rgb_d1),
    .ui_valid(ui_valid_d1),
    .ui_rgb(ui_rgb_d1),
    .composed_rgb
  );

  assign ready_changed = (snapshot_ready_toggle != ready_seen);

  always_ff @(posedge clk_pix or negedge rst_pix_n) begin
    if (!rst_pix_n) begin
      vertical_blank_d      <= 1'b0;
      ready_seen            <= 1'b0;
      vblank_request_toggle <= 1'b0;
      snapshot_pending      <= 1'b0;
    end else begin
      vertical_blank_d <= raw_vertical_blank;
      if (ready_changed) begin
        ready_seen       <= snapshot_ready_toggle;
        snapshot_pending <= 1'b0;
      end
      if (raw_vertical_blank && !vertical_blank_d && (!snapshot_pending || ready_changed)) begin
        vblank_request_toggle <= ~vblank_request_toggle;
        snapshot_pending      <= 1'b1;
      end
    end
  end

  always_ff @(posedge clk_pix or negedge rst_pix_n) begin
    if (!rst_pix_n) begin
      background_rgb_d1      <= '0;
      court_valid_d1         <= 1'b0;
      court_rgb_d1           <= '0;
      line_valid_d1          <= 1'b0;
      line_rgb_d1            <= '0;
      net_background_valid_d1 <= 1'b0;
      net_background_rgb_d1  <= '0;
      net_foreground_valid_d1 <= 1'b0;
      net_foreground_rgb_d1  <= '0;
      ball_valid_d1          <= 1'b0;
      ball_rgb_d1            <= '0;
      pixel_x_d1             <= '0;
      pixel_x_d2             <= '0;
      pixel_y_d1             <= '0;
      pixel_y_d2             <= '0;
      hsync_d1               <= 1'b0;
      hsync_d2               <= 1'b0;
      vsync_d1               <= 1'b0;
      vsync_d2               <= 1'b0;
      video_data_enable_d1   <= 1'b0;
      video_data_enable_d2   <= 1'b0;
      start_of_line_d1       <= 1'b0;
      start_of_line_d2       <= 1'b0;
      start_of_frame_d1      <= 1'b0;
      start_of_frame_d2      <= 1'b0;
      red                    <= 8'h00;
      green                  <= 8'h00;
      blue                   <= 8'h00;
    end else begin
      background_rgb_d1       <= background_rgb_raw;
      court_valid_d1          <= court_valid_raw;
      court_rgb_d1            <= court_rgb_raw;
      line_valid_d1           <= line_valid_raw;
      line_rgb_d1             <= line_rgb_raw;
      net_background_valid_d1 <= net_background_valid_raw;
      net_background_rgb_d1   <= net_background_rgb_raw;
      net_foreground_valid_d1 <= net_foreground_valid_raw;
      net_foreground_rgb_d1   <= net_foreground_rgb_raw;
      ball_valid_d1           <= ball_valid_raw;
      ball_rgb_d1             <= ball_rgb_raw;

      pixel_x_d1 <= raw_x;
      pixel_x_d2 <= pixel_x_d1;
      pixel_y_d1 <= raw_y;
      pixel_y_d2 <= pixel_y_d1;
      hsync_d1 <= raw_hsync;
      hsync_d2 <= hsync_d1;
      vsync_d1 <= raw_vsync;
      vsync_d2 <= vsync_d1;
      video_data_enable_d1 <= raw_vde;
      video_data_enable_d2 <= video_data_enable_d1;
      start_of_line_d1 <= raw_start_of_line;
      start_of_line_d2 <= start_of_line_d1;
      start_of_frame_d1 <= raw_start_of_frame;
      start_of_frame_d2 <= start_of_frame_d1;

      red   <= composed_rgb[23:16];
      green <= composed_rgb[15:8];
      blue  <= composed_rgb[7:0];
    end
  end

  assign pixel_x           = pixel_x_d2;
  assign pixel_y           = pixel_y_d2;
  assign hsync             = hsync_d2;
  assign vsync             = vsync_d2;
  assign video_data_enable = video_data_enable_d2;
  assign start_of_line     = start_of_line_d2;
  assign start_of_frame    = start_of_frame_d2;
endmodule
