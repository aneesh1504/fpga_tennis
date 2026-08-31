module gameplay_video_stub (
  input  logic                                clk_sys,
  input  logic                                rst_sys_n,
  input  video_types_pkg::game_render_state_t render_state_sys,
  input  logic                                clk_pix,
  input  logic                                rst_pix_n,
  input  logic                                vblank_request_toggle,
  output logic                                snapshot_ready_toggle,
  output logic                                pixel_state_valid,
  output video_types_pkg::game_render_state_t render_state_pix
);
  import video_types_pkg::*;

  game_render_state_t shadow_sys;
  logic request_meta_sys;
  logic request_sync_sys;
  logic request_seen_sys;
  logic ready_meta_pix;
  logic ready_sync_pix;
  logic ready_seen_pix;

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      request_meta_sys      <= 1'b0;
      request_sync_sys      <= 1'b0;
      request_seen_sys      <= 1'b0;
      snapshot_ready_toggle <= 1'b0;
      shadow_sys            <= '0;
    end else begin
      request_meta_sys <= vblank_request_toggle;
      request_sync_sys <= request_meta_sys;
      if (request_sync_sys != request_seen_sys) begin
        shadow_sys            <= render_state_sys;
        request_seen_sys      <= request_sync_sys;
        snapshot_ready_toggle <= ~snapshot_ready_toggle;
      end
    end
  end

  always_ff @(posedge clk_pix or negedge rst_pix_n) begin
    if (!rst_pix_n) begin
      ready_meta_pix  <= 1'b0;
      ready_sync_pix  <= 1'b0;
      ready_seen_pix  <= 1'b0;
      pixel_state_valid <= 1'b0;
      render_state_pix  <= '0;
    end else begin
      ready_meta_pix    <= snapshot_ready_toggle;
      ready_sync_pix    <= ready_meta_pix;
      pixel_state_valid <= 1'b0;
      if (ready_sync_pix != ready_seen_pix) begin
        render_state_pix  <= shadow_sys;
        pixel_state_valid <= 1'b1;
        ready_seen_pix    <= ready_sync_pix;
      end
    end
  end
endmodule
