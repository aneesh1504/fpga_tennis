module perspective_projector (
  input  logic signed [15:0] court_x_q8_8,
  input  logic signed [15:0] court_y_q8_8,
  input  logic signed [15:0] height_q8_8,
  output logic signed [12:0] screen_x,
  output logic signed [12:0] screen_y,
  output logic        [9:0]  perspective_width
);
  integer x_integer;
  integer y_integer;
  integer height_integer;
  integer depth_clamped;
  integer half_width;
  integer projected_x;
  integer projected_y;

  function automatic signed [12:0] clamp_screen(input integer value);
    begin
      if (value < -4096)      clamp_screen = -13'sd4096;
      else if (value > 4095)  clamp_screen = 13'sd4095;
      else                    clamp_screen = value;
    end
  endfunction

  always_comb begin
    x_integer      = $signed(court_x_q8_8) >>> 8;
    y_integer      = $signed(court_y_q8_8) >>> 8;
    height_integer = $signed(height_q8_8) >>> 8;

    if (y_integer < 0)         depth_clamped = 0;
    else if (y_integer > 127)  depth_clamped = 127;
    else                       depth_clamped = y_integer;

    // Signed Q8.8 gives a logical integer range of -128..+127. Court x uses
    // that full span; non-negative court y narrows the scene toward horizon.
    half_width = 520 - ((depth_clamped * 360) >>> 7);
    projected_x = 640 + ((x_integer * half_width) >>> 7);
    projected_y = 650 - ((depth_clamped * 400) >>> 7) - height_integer;

    screen_x         = clamp_screen(projected_x);
    screen_y         = clamp_screen(projected_y);
    perspective_width = half_width;
  end
endmodule
