module video_timing_720p #(
  parameter integer H_ACTIVE = 1280,
  parameter integer H_FRONT  = 110,
  parameter integer H_SYNC   = 40,
  parameter integer H_BACK   = 220,
  parameter integer V_ACTIVE = 720,
  parameter integer V_FRONT  = 5,
  parameter integer V_SYNC   = 5,
  parameter integer V_BACK   = 20,
  parameter logic   HSYNC_POSITIVE = 1'b1,
  parameter logic   VSYNC_POSITIVE = 1'b1
) (
  input  logic        clk_pix,
  input  logic        rst_pix_n,
  output logic [11:0] pixel_x,
  output logic [10:0] pixel_y,
  output logic        hsync,
  output logic        vsync,
  output logic        video_data_enable,
  output logic        start_of_line,
  output logic        start_of_frame,
  output logic        vertical_blank
);
  localparam integer H_TOTAL = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;
  localparam integer V_TOTAL = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;
  localparam integer H_COUNT_BITS = $clog2(H_TOTAL);
  localparam integer V_COUNT_BITS = $clog2(V_TOTAL);

  logic [H_COUNT_BITS-1:0] horizontal_count;
  logic [V_COUNT_BITS-1:0] vertical_count;
  logic hsync_active;
  logic vsync_active;

  initial begin
    if (H_TOTAL > 4096 || V_TOTAL > 2048) $fatal(1, "timing counters exceed output widths");
    if (H_ACTIVE <= 0 || V_ACTIVE <= 0 || H_SYNC <= 0 || V_SYNC <= 0) $fatal(1, "invalid video timing parameters");
  end

  always_ff @(posedge clk_pix or negedge rst_pix_n) begin
    if (!rst_pix_n) begin
      horizontal_count <= '0;
      vertical_count   <= '0;
    end else if (horizontal_count == H_TOTAL - 1) begin
      horizontal_count <= '0;
      if (vertical_count == V_TOTAL - 1) vertical_count <= '0;
      else                               vertical_count <= vertical_count + 1'b1;
    end else begin
      horizontal_count <= horizontal_count + 1'b1;
    end
  end

  always_comb begin
    pixel_x = horizontal_count;
    pixel_y = vertical_count;
    video_data_enable = (horizontal_count < H_ACTIVE) && (vertical_count < V_ACTIVE);
    start_of_line      = (horizontal_count == 0);
    start_of_frame     = (horizontal_count == 0) && (vertical_count == 0);
    vertical_blank     = (vertical_count >= V_ACTIVE);

    hsync_active = (horizontal_count >= H_ACTIVE + H_FRONT) &&
                   (horizontal_count <  H_ACTIVE + H_FRONT + H_SYNC);
    vsync_active = (vertical_count >= V_ACTIVE + V_FRONT) &&
                   (vertical_count <  V_ACTIVE + V_FRONT + V_SYNC);
    hsync = HSYNC_POSITIVE ? hsync_active : ~hsync_active;
    vsync = VSYNC_POSITIVE ? vsync_active : ~vsync_active;
  end
endmodule
