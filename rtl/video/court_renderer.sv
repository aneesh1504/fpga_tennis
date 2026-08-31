module court_renderer (
  input  logic [11:0] pixel_x,
  input  logic [10:0] pixel_y,
  input  logic        video_data_enable,
  output logic [23:0] background_rgb,
  output logic        court_valid,
  output logic [23:0] court_rgb,
  output logic        line_valid,
  output logic [23:0] line_rgb
);
  localparam logic [23:0] COLOR_SKY_DARK  = 24'h10182e;
  localparam logic [23:0] COLOR_CROWD_A   = 24'h29324f;
  localparam logic [23:0] COLOR_CROWD_B   = 24'h3b4669;
  localparam logic [23:0] COLOR_SURROUND  = 24'h176b52;
  localparam logic [23:0] COLOR_COURT     = 24'h1769aa;
  localparam logic [23:0] COLOR_LINE      = 24'hf4f1dc;

  integer x_delta;
  integer absolute_x;
  integer depth;
  integer edge_metric;
  integer point_metric;
  integer edge_error;
  logic inside_court;

  always_comb begin
    x_delta = $signed({1'b0, pixel_x}) - 640;
    if (x_delta < 0) absolute_x = -x_delta;
    else             absolute_x = x_delta;
    depth        = $signed({1'b0, pixel_y}) - 200;
    edge_metric  = 90000 + depth * 370;
    point_metric = absolute_x * 500;
    if (point_metric > edge_metric) edge_error = point_metric - edge_metric;
    else                            edge_error = edge_metric - point_metric;

    inside_court = video_data_enable && (pixel_y >= 200) && (pixel_y <= 700) &&
                   (point_metric <= edge_metric);

    background_rgb = COLOR_SKY_DARK;
    if (video_data_enable) begin
      if (pixel_y < 160) begin
        if ((pixel_x[5] ^ pixel_y[4]) == 1'b1) background_rgb = COLOR_CROWD_A;
        else                                   background_rgb = COLOR_CROWD_B;
      end else begin
        background_rgb = COLOR_SURROUND;
      end
    end

    court_valid = inside_court;
    court_rgb   = COLOR_COURT;
    line_valid  = 1'b0;
    line_rgb    = COLOR_LINE;
    if (inside_court) begin
      if (edge_error <= 1500) line_valid = 1'b1;
      if ((pixel_y >= 696) && (pixel_y <= 700)) line_valid = 1'b1;
      if ((pixel_y >= 497) && (pixel_y <= 501)) line_valid = 1'b1;
      if ((pixel_y >= 258) && (pixel_y <= 262)) line_valid = 1'b1;
      if ((pixel_y >= 500) && (pixel_x >= 638) && (pixel_x <= 642)) line_valid = 1'b1;
    end
  end
endmodule
