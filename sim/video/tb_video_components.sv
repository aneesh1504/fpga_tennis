module tb_video_components;
  import video_types_pkg::*;

  logic clk_pix = 1'b0;
  logic rst_pix_n = 1'b0;
  always #5 clk_pix = ~clk_pix;

  logic signed [15:0] court_x_q8_8;
  logic signed [15:0] court_y_q8_8;
  logic signed [15:0] height_q8_8;
  logic signed [12:0] screen_x;
  logic signed [12:0] screen_y;
  logic [9:0] perspective_width;

  logic [11:0] pixel_x;
  logic [10:0] pixel_y;
  logic video_data_enable;
  logic [23:0] background_rgb;
  logic court_valid;
  logic [23:0] court_rgb;
  logic line_valid;
  logic [23:0] line_rgb;
  logic net_background_valid;
  logic [23:0] net_background_rgb;
  logic net_foreground_valid;
  logic [23:0] net_foreground_rgb;

  logic sprite_enable;
  logic signed [12:0] sprite_center_x;
  logic signed [12:0] sprite_bottom_y;
  logic [3:0] pose;
  logic mirror;
  logic sprite_valid;
  logic [23:0] sprite_rgb;

  logic [9:0] font_address;
  logic [7:0] font_row;
  game_render_state_t ui_state;
  logic ui_valid;
  logic [23:0] ui_rgb;

  logic comp_vde;
  logic comp_court_valid;
  logic comp_line_valid;
  logic comp_net_back_valid;
  logic comp_far_valid;
  logic comp_net_front_valid;
  logic comp_near_valid;
  logic comp_ball_valid;
  logic comp_ui_valid;
  logic [23:0] composed_rgb;

  integer right_x;

  perspective_projector projector (.*);
  court_renderer court (.*);
  net_renderer net (.*);

  sprite_renderer #(
    .SPRITE_WIDTH(16), .SPRITE_HEIGHT(24), .FRAME_COUNT(4), .SCALE(1),
    .MEM_FILE("assets/generated_mem/player_near.mem")
  ) sprite (
    .clk_pix, .rst_pix_n, .pixel_x, .pixel_y, .video_data_enable,
    .sprite_enable, .center_x(sprite_center_x), .bottom_y(sprite_bottom_y),
    .pose, .mirror, .sprite_valid, .sprite_rgb
  );

  font_rom font (.clk_pix, .address(font_address), .row_bits(font_row));

  ui_renderer ui (
    .clk_pix, .rst_pix_n, .pixel_x, .pixel_y, .video_data_enable,
    .render_state(ui_state), .ui_valid, .ui_rgb
  );

  pixel_compositor compositor (
    .video_data_enable(comp_vde),
    .background_rgb(24'h010101),
    .court_valid(comp_court_valid), .court_rgb(24'h020202),
    .line_valid(comp_line_valid), .line_rgb(24'h030303),
    .net_background_valid(comp_net_back_valid), .net_background_rgb(24'h040404),
    .far_player_valid(comp_far_valid), .far_player_rgb(24'h050505),
    .net_foreground_valid(comp_net_front_valid), .net_foreground_rgb(24'h060606),
    .near_player_valid(comp_near_valid), .near_player_rgb(24'h070707),
    .ball_valid(comp_ball_valid), .ball_rgb(24'h080808),
    .ui_valid(comp_ui_valid), .ui_rgb(24'h090909),
    .composed_rgb
  );

  task automatic sample_sprite(input integer x, input integer y);
    begin
      @(negedge clk_pix);
      pixel_x = x;
      pixel_y = y;
      @(posedge clk_pix);
      #1;
    end
  endtask

  task automatic sample_ui(input integer x, input integer y);
    begin
      @(negedge clk_pix);
      pixel_x = x;
      pixel_y = y;
      @(posedge clk_pix);
      #1;
    end
  endtask

  initial begin
    court_x_q8_8 = 16'sd0;
    court_y_q8_8 = 16'sd0;
    height_q8_8 = 16'sd0;
    pixel_x = 0;
    pixel_y = 0;
    video_data_enable = 1'b1;
    sprite_enable = 1'b1;
    sprite_center_x = 13'sd100;
    sprite_bottom_y = 13'sd100;
    pose = 0;
    mirror = 1'b0;
    font_address = 0;
    ui_state = '0;
    comp_vde = 1'b1;
    comp_court_valid = 1'b0;
    comp_line_valid = 1'b0;
    comp_net_back_valid = 1'b0;
    comp_far_valid = 1'b0;
    comp_net_front_valid = 1'b0;
    comp_near_valid = 1'b0;
    comp_ball_valid = 1'b0;
    comp_ui_valid = 1'b0;
    repeat (2) @(negedge clk_pix);
    rst_pix_n = 1'b1;

    court_x_q8_8 = 16'sd64 <<< 8;
    #1;
    if (screen_x != 900 || screen_y != 650 || perspective_width != 520) $fatal(1, "near projection");
    right_x = screen_x;
    court_x_q8_8 = -16'sd64 <<< 8;
    #1;
    if ((screen_x + right_x) != 1280) $fatal(1, "projector symmetry");
    court_x_q8_8 = 16'sd0;
    court_y_q8_8 = 16'sd64 <<< 8;
    height_q8_8 = 16'sd32 <<< 8;
    #1;
    if (screen_x != 640 || screen_y != 418 || perspective_width != 340) $fatal(1, "depth/height projection");

    pixel_x = 640; pixel_y = 450; #1;
    if (!court_valid || line_valid || court_rgb != 24'h1769aa) $fatal(1, "court interior");
    pixel_x = 640; pixel_y = 600; #1;
    if (!court_valid || !line_valid) $fatal(1, "court center line");
    pixel_x = 400; pixel_y = 600; #1;
    if (!court_valid) $fatal(1, "left court symmetry sample");
    pixel_x = 880; pixel_y = 600; #1;
    if (!court_valid) $fatal(1, "right court symmetry sample");
    pixel_x = 100; pixel_y = 600; #1;
    if (court_valid || background_rgb != 24'h176b52) $fatal(1, "court exterior");

    pixel_x = 280; pixel_y = 432; #1;
    if (!net_foreground_valid) $fatal(1, "net band");
    pixel_x = 300; pixel_y = 450; #1;
    if (!net_background_valid || net_foreground_valid) $fatal(1, "net mesh");

    font_address = (65 - 32) * 8;
    @(posedge clk_pix); #1;
    if (font_row != 8'h38) $fatal(1, "font A row 0: %02x", font_row);

    ui_state.player_one_points = 2'd2;
    sample_ui(74, 22);
    if (!ui_valid || ui_rgb != 24'hfff7dc) $fatal(1, "score glyph for two");
    ui_state.player_one_points = 2'd3;
    sample_ui(74, 22);
    if (ui_valid) $fatal(1, "score glyph selection did not change for three");

    sample_sprite(100, 88);
    if (!sprite_valid || sprite_rgb != 24'hf04b5a) $fatal(1, "sprite body palette/address");
    sample_sprite(92, 76);
    if (sprite_valid) $fatal(1, "sprite transparent corner");
    sprite_center_x = 0;
    sample_sprite(0, 88);
    if (!sprite_valid) $fatal(1, "sprite clipping at left edge");

    #1; if (composed_rgb != 24'h010101) $fatal(1, "background priority");
    comp_court_valid = 1'b1; #1; if (composed_rgb != 24'h020202) $fatal(1, "court priority");
    comp_line_valid = 1'b1; #1; if (composed_rgb != 24'h030303) $fatal(1, "line priority");
    comp_net_back_valid = 1'b1; #1; if (composed_rgb != 24'h040404) $fatal(1, "net back priority");
    comp_far_valid = 1'b1; #1; if (composed_rgb != 24'h050505) $fatal(1, "far player priority");
    comp_net_front_valid = 1'b1; #1; if (composed_rgb != 24'h060606) $fatal(1, "net front priority");
    comp_near_valid = 1'b1; #1; if (composed_rgb != 24'h070707) $fatal(1, "near player priority");
    comp_ball_valid = 1'b1; #1; if (composed_rgb != 24'h080808) $fatal(1, "ball priority");
    comp_ui_valid = 1'b1; #1; if (composed_rgb != 24'h090909) $fatal(1, "UI priority");
    comp_vde = 1'b0; #1; if (composed_rgb != 24'h000000) $fatal(1, "blanking priority");

    $display("PASS: projection, court symmetry/boundaries, net, font, sprite transparency/clipping, and compositor priority");
    $finish;
  end
endmodule
