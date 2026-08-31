module pixel_compositor (
  input  logic        video_data_enable,
  input  logic [23:0] background_rgb,
  input  logic        court_valid,
  input  logic [23:0] court_rgb,
  input  logic        line_valid,
  input  logic [23:0] line_rgb,
  input  logic        net_background_valid,
  input  logic [23:0] net_background_rgb,
  input  logic        far_player_valid,
  input  logic [23:0] far_player_rgb,
  input  logic        net_foreground_valid,
  input  logic [23:0] net_foreground_rgb,
  input  logic        near_player_valid,
  input  logic [23:0] near_player_rgb,
  input  logic        ball_valid,
  input  logic [23:0] ball_rgb,
  input  logic        ui_valid,
  input  logic [23:0] ui_rgb,
  output logic [23:0] composed_rgb
);
  always_comb begin
    composed_rgb = video_data_enable ? background_rgb : 24'h000000;
    if (video_data_enable && court_valid)          composed_rgb = court_rgb;
    if (video_data_enable && line_valid)           composed_rgb = line_rgb;
    if (video_data_enable && net_background_valid) composed_rgb = net_background_rgb;
    if (video_data_enable && far_player_valid)     composed_rgb = far_player_rgb;
    if (video_data_enable && net_foreground_valid) composed_rgb = net_foreground_rgb;
    if (video_data_enable && near_player_valid)    composed_rgb = near_player_rgb;
    if (video_data_enable && ball_valid)           composed_rgb = ball_rgb;
    if (video_data_enable && ui_valid)             composed_rgb = ui_rgb;
  end
endmodule
