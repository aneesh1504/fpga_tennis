module render_state_mailbox (
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

  game_render_state_t shadow_sys_q;
  logic request_meta_sys_q;
  logic request_sync_sys_q;
  logic request_seen_sys_q;
  logic ready_meta_pix_q;
  logic ready_sync_pix_q;
  logic ready_seen_pix_q;

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      shadow_sys_q <= '0;
      request_meta_sys_q <= 1'b0;
      request_sync_sys_q <= 1'b0;
      request_seen_sys_q <= 1'b0;
      snapshot_ready_toggle <= 1'b0;
    end else begin
      request_meta_sys_q <= vblank_request_toggle;
      request_sync_sys_q <= request_meta_sys_q;
      if (request_sync_sys_q != request_seen_sys_q) begin
        shadow_sys_q <= render_state_sys;
        request_seen_sys_q <= request_sync_sys_q;
        snapshot_ready_toggle <= ~snapshot_ready_toggle;
      end
    end
  end

  always_ff @(posedge clk_pix or negedge rst_pix_n) begin
    if (!rst_pix_n) begin
      ready_meta_pix_q <= 1'b0;
      ready_sync_pix_q <= 1'b0;
      ready_seen_pix_q <= 1'b0;
      pixel_state_valid <= 1'b0;
      render_state_pix <= '0;
    end else begin
      ready_meta_pix_q <= snapshot_ready_toggle;
      ready_sync_pix_q <= ready_meta_pix_q;
      pixel_state_valid <= 1'b0;
      if (ready_sync_pix_q != ready_seen_pix_q) begin
        render_state_pix <= shadow_sys_q;
        pixel_state_valid <= 1'b1;
        ready_seen_pix_q <= ready_sync_pix_q;
      end
    end
  end
endmodule
