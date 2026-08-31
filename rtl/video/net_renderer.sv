module net_renderer (
  input  logic [11:0] pixel_x,
  input  logic [10:0] pixel_y,
  input  logic        video_data_enable,
  output logic        net_background_valid,
  output logic [23:0] net_background_rgb,
  output logic        net_foreground_valid,
  output logic [23:0] net_foreground_rgb
);
  localparam logic [23:0] COLOR_NET_MESH = 24'hb8c5cf;
  localparam logic [23:0] COLOR_NET_BAND = 24'hfff7dc;
  localparam logic [23:0] COLOR_NET_POST = 24'hd8e1e8;

  integer mesh_x;
  integer mesh_y;

  always_comb begin
    mesh_x = $signed({1'b0, pixel_x}) - 286;
    mesh_y = $signed({1'b0, pixel_y}) - 436;
    net_background_valid = 1'b0;
    net_background_rgb   = COLOR_NET_MESH;
    net_foreground_valid = 1'b0;
    net_foreground_rgb   = COLOR_NET_BAND;

    if (video_data_enable) begin
      if ((pixel_x >= 286) && (pixel_x <= 994) &&
          (pixel_y >= 436) && (pixel_y <= 500) &&
          (((mesh_x % 24) < 2) || ((mesh_y % 14) < 2))) begin
        net_background_valid = 1'b1;
      end
      if ((pixel_x >= 280) && (pixel_x <= 1000) &&
          (pixel_y >= 430) && (pixel_y <= 435)) begin
        net_foreground_valid = 1'b1;
      end
      if ((((pixel_x >= 274) && (pixel_x <= 285)) ||
           ((pixel_x >= 995) && (pixel_x <= 1006))) &&
          (pixel_y >= 420) && (pixel_y <= 510)) begin
        net_foreground_valid = 1'b1;
        net_foreground_rgb   = COLOR_NET_POST;
      end
    end
  end
endmodule
