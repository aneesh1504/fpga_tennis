module tb_render_state_mailbox;
  import video_types_pkg::*;

  logic clk_sys = 1'b0;
  logic rst_sys_n = 1'b0;
  logic clk_pix = 1'b0;
  logic rst_pix_n = 1'b0;
  game_render_state_t render_state_sys;
  logic vblank_request_toggle;
  logic snapshot_ready_toggle;
  logic pixel_state_valid;
  game_render_state_t render_state_pix;
  integer valid_count;

  always #5 clk_sys = ~clk_sys;
  always #7 clk_pix = ~clk_pix;
  render_state_mailbox dut (.*);

  always @(posedge clk_pix) begin
    if (pixel_state_valid) valid_count <= valid_count + 1;
  end

  initial begin
    render_state_sys = '0;
    vblank_request_toggle = 1'b0;
    valid_count = 0;
    #22;
    rst_sys_n = 1'b1;
    rst_pix_n = 1'b1;

    @(negedge clk_sys);
    render_state_sys.valid = 1'b1;
    render_state_sys.ball_x_q8_8 = 16'sh1234;
    render_state_sys.player_one_points = 2'd2;
    @(negedge clk_pix);
    vblank_request_toggle = ~vblank_request_toggle;
    wait (snapshot_ready_toggle == 1'b1);
    render_state_sys.ball_x_q8_8 = -16'sh2222;
    render_state_sys.player_one_points = 2'd3;
    wait (pixel_state_valid);
    if ((render_state_pix.ball_x_q8_8 != 16'sh1234)
        || (render_state_pix.player_one_points != 2'd2)) begin
      $fatal(1, "snapshot was not atomic/stable");
    end

    repeat (4) @(posedge clk_pix);
    if (valid_count != 1) $fatal(1, "snapshot produced duplicate valid pulses");
    $display("PASS: atomic toggle-based render snapshot publication");
    $finish;
  end
endmodule
