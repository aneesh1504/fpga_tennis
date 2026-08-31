module sprite_renderer #(
  parameter integer SPRITE_WIDTH  = 16,
  parameter integer SPRITE_HEIGHT = 24,
  parameter integer FRAME_COUNT   = 4,
  parameter integer SCALE         = 1,
  parameter MEM_FILE = "assets/generated_mem/player_near.mem"
) (
  input  logic               clk_pix,
  input  logic               rst_pix_n,
  input  logic [11:0]        pixel_x,
  input  logic [10:0]        pixel_y,
  input  logic               video_data_enable,
  input  logic               sprite_enable,
  input  logic signed [12:0] center_x,
  input  logic signed [12:0] bottom_y,
  input  logic [3:0]         pose,
  input  logic               mirror,
  output logic               sprite_valid,
  output logic [23:0]        sprite_rgb
);
  localparam integer PIXELS_PER_FRAME = SPRITE_WIDTH * SPRITE_HEIGHT;
  localparam integer ROM_DEPTH = PIXELS_PER_FRAME * FRAME_COUNT;

  logic [7:0] sprite_rom [0:ROM_DEPTH-1];
  logic [7:0] palette_index;
  logic sample_valid;
  integer sprite_left;
  integer sprite_top;
  integer local_x;
  integer local_y;
  integer source_x;
  integer source_y;
  integer frame_index;
  integer rom_address;
  logic inside_sprite;

  initial begin
    if (SPRITE_WIDTH <= 0 || SPRITE_HEIGHT <= 0 || FRAME_COUNT <= 0 || SCALE <= 0) $fatal(1, "invalid sprite parameters");
    $readmemh(MEM_FILE, sprite_rom);
  end

  always_comb begin
    sprite_left = $signed(center_x) - ((SPRITE_WIDTH * SCALE) / 2);
    sprite_top  = $signed(bottom_y) - (SPRITE_HEIGHT * SCALE);
    local_x = $signed({1'b0, pixel_x}) - sprite_left;
    local_y = $signed({1'b0, pixel_y}) - sprite_top;
    inside_sprite = video_data_enable && sprite_enable &&
                    (local_x >= 0) && (local_x < SPRITE_WIDTH * SCALE) &&
                    (local_y >= 0) && (local_y < SPRITE_HEIGHT * SCALE);
    source_x = local_x / SCALE;
    source_y = local_y / SCALE;
    if (mirror) source_x = SPRITE_WIDTH - 1 - source_x;
    frame_index = pose;
    if (frame_index >= FRAME_COUNT) frame_index = frame_index % FRAME_COUNT;
    rom_address = frame_index * PIXELS_PER_FRAME + source_y * SPRITE_WIDTH + source_x;
  end

  always_ff @(posedge clk_pix or negedge rst_pix_n) begin
    if (!rst_pix_n) begin
      sample_valid  <= 1'b0;
      palette_index <= 8'h00;
    end else begin
      sample_valid <= inside_sprite;
      if (inside_sprite) palette_index <= sprite_rom[rom_address];
      else               palette_index <= 8'h00;
    end
  end

  always_comb begin
    sprite_valid = sample_valid && (palette_index != 0);
    case (palette_index)
      8'h01: sprite_rgb = 24'hf2b38a;
      8'h02: sprite_rgb = 24'hf04b5a;
      8'h03: sprite_rgb = 24'h243a73;
      8'h04: sprite_rgb = 24'he7eef8;
      default: sprite_rgb = 24'h000000;
    endcase
  end
endmodule
