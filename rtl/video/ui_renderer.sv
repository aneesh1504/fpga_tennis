module ui_renderer (
  input  logic                                clk_pix,
  input  logic                                rst_pix_n,
  input  logic [11:0]                         pixel_x,
  input  logic [10:0]                         pixel_y,
  input  logic                                video_data_enable,
  input  video_types_pkg::game_render_state_t render_state,
  output logic                                ui_valid,
  output logic [23:0]                         ui_rgb
);
  logic [9:0] font_address;
  logic [7:0] font_row;
  logic [7:0] character_code;
  logic [2:0] glyph_x;
  logic [2:0] glyph_y;
  logic text_candidate;
  logic procedural_valid;
  logic [23:0] procedural_rgb;
  integer text_x;
  integer character_column;
  integer p1_bar_length;
  integer p2_bar_length;

  logic [2:0] glyph_x_d;
  logic text_candidate_d;
  logic procedural_valid_d;
  logic [23:0] procedural_rgb_d;

  font_rom font (
    .clk_pix,
    .address(font_address),
    .row_bits(font_row)
  );

  always_comb begin
    text_x = $signed({1'b0, pixel_x}) - 24;
    character_column = text_x >>> 4;
    glyph_x = (text_x >>> 1) & 7;
    glyph_y = (($signed({1'b0, pixel_y}) - 20) >>> 1) & 7;
    character_code = 8'd32;
    text_candidate = video_data_enable && (pixel_x >= 24) && (pixel_x < 168) &&
                     (pixel_y >= 20) && (pixel_y < 36);
    case (character_column)
      0: character_code = "P";
      1: character_code = "1";
      2: character_code = ":";
      3: character_code = 8'd48 + {6'd0, render_state.player_one_points};
      4: character_code = " ";
      5: character_code = "P";
      6: character_code = "2";
      7: character_code = ":";
      8: character_code = 8'd48 + {6'd0, render_state.player_two_points};
      default: character_code = " ";
    endcase
    if (character_code >= 32 && character_code < 128)
      font_address = ((character_code - 32) << 3) + glyph_y;
    else
      font_address = 10'd0;

    p1_bar_length = (render_state.player_one_swing_meter * 256) >>> 16;
    p2_bar_length = (render_state.player_two_swing_meter * 256) >>> 16;
    procedural_valid = 1'b0;
    procedural_rgb   = 24'hffffff;

    if (video_data_enable && pixel_y >= 48 && pixel_y < 56 && pixel_x >= 24 && pixel_x < 32) begin
      procedural_valid = 1'b1;
      procedural_rgb = render_state.player_one_connected ? 24'h45e36f : 24'he34343;
    end else if (video_data_enable && pixel_y >= 48 && pixel_y < 56 && pixel_x >= 40 && pixel_x < 48) begin
      procedural_valid = 1'b1;
      procedural_rgb = render_state.player_two_connected ? 24'h45e36f : 24'he34343;
    end else if (video_data_enable && pixel_y >= 680 && pixel_y < 692 && pixel_x >= 40 && pixel_x < 296) begin
      procedural_valid = 1'b1;
      if (($signed({1'b0, pixel_x}) - 40) < p1_bar_length) procedural_rgb = 24'h52d6ff;
      else                                                procedural_rgb = 24'h28364c;
    end else if (video_data_enable && pixel_y >= 680 && pixel_y < 692 && pixel_x >= 984 && pixel_x < 1240) begin
      procedural_valid = 1'b1;
      if (($signed({1'b0, pixel_x}) - 984) < p2_bar_length) procedural_rgb = 24'hffb84a;
      else                                                 procedural_rgb = 24'h28364c;
    end
  end

  always_ff @(posedge clk_pix or negedge rst_pix_n) begin
    if (!rst_pix_n) begin
      glyph_x_d           <= '0;
      text_candidate_d    <= 1'b0;
      procedural_valid_d  <= 1'b0;
      procedural_rgb_d    <= '0;
    end else begin
      glyph_x_d           <= glyph_x;
      text_candidate_d    <= text_candidate;
      procedural_valid_d  <= procedural_valid;
      procedural_rgb_d    <= procedural_rgb;
    end
  end

  always_comb begin
    ui_valid = procedural_valid_d ||
               (text_candidate_d && font_row[7 - glyph_x_d]);
    if (procedural_valid_d) ui_rgb = procedural_rgb_d;
    else                    ui_rgb = 24'hfff7dc;
  end
endmodule
