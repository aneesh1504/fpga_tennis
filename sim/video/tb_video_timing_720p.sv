module tb_video_timing_720p;
  localparam integer H_TOTAL = 1650;
  localparam integer V_TOTAL = 750;
  localparam integer FRAME_CYCLES = H_TOTAL * V_TOTAL;

  logic clk_pix = 1'b0;
  logic rst_pix_n = 1'b0;
  logic [11:0] pixel_x;
  logic [10:0] pixel_y;
  logic hsync;
  logic vsync;
  logic video_data_enable;
  logic start_of_line;
  logic start_of_frame;
  logic vertical_blank;

  integer cycles;
  integer active_pixels;
  integer hsync_pixels;
  integer vsync_pixels;
  integer line_starts;
  integer blank_pixels;

  always #1 clk_pix = ~clk_pix;

  video_timing_720p dut (.*);

  initial begin
    repeat (3) @(negedge clk_pix);
    rst_pix_n = 1'b1;
    wait (start_of_frame);
    cycles = 0;
    active_pixels = 0;
    hsync_pixels = 0;
    vsync_pixels = 0;
    line_starts = 0;
    blank_pixels = 0;

    while ((cycles == 0) || !start_of_frame) begin
      if (pixel_x >= H_TOTAL || pixel_y >= V_TOTAL) $fatal(1, "coordinate out of range");
      if (video_data_enable && (pixel_x >= 1280 || pixel_y >= 720)) $fatal(1, "VDE outside active region");
      if (vertical_blank != (pixel_y >= 720)) $fatal(1, "vertical blank mismatch");
      cycles = cycles + 1;
      if (video_data_enable) active_pixels = active_pixels + 1;
      if (hsync) hsync_pixels = hsync_pixels + 1;
      if (vsync) vsync_pixels = vsync_pixels + 1;
      if (start_of_line) line_starts = line_starts + 1;
      if (vertical_blank) blank_pixels = blank_pixels + 1;
      @(negedge clk_pix);
    end

    if (cycles != FRAME_CYCLES) $fatal(1, "frame length %0d", cycles);
    if (active_pixels != 1280 * 720) $fatal(1, "active pixel count %0d", active_pixels);
    if (hsync_pixels != 40 * V_TOTAL) $fatal(1, "hsync width/count %0d", hsync_pixels);
    if (vsync_pixels != 5 * H_TOTAL) $fatal(1, "vsync width/count %0d", vsync_pixels);
    if (line_starts != V_TOTAL) $fatal(1, "line count %0d", line_starts);
    if (blank_pixels != (V_TOTAL - 720) * H_TOTAL) $fatal(1, "vertical blank count %0d", blank_pixels);
    $display("PASS: nominal 720p timing totals, positive sync widths, VDE, coordinates, and blanking");
    $finish;
  end
endmodule
