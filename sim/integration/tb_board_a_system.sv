`timescale 1ns/1ps

module tb_board_a_system;
  import protocol_pkg::*;
  import video_types_pkg::*;

  localparam int CLOCK_HZ = 1_000_000;
  localparam int BAUD = 100_000;
  localparam int BIT_CLOCKS = CLOCK_HZ / BAUD;

  logic clk_sys = 1'b0;
  logic clk_pix = 1'b0;
  logic async_rst_n = 1'b0;
  logic player_1_serial_rx = 1'b1;
  logic player_2_serial_rx = 1'b1;
  logic match_reset = 1'b0;
  logic scripted_opponent_enable = 1'b1;
  transport_health_t player_1_debug_health;
  transport_health_t player_2_debug_health;
  game_render_state_t render_state_sys_debug;
  game_render_state_t render_state_pix_debug;
  logic game_tick_debug;
  logic pixel_state_valid_debug;
  logic snapshot_pending;
  logic [11:0] pixel_x;
  logic [10:0] pixel_y;
  logic hsync;
  logic vsync;
  logic video_data_enable;
  logic start_of_line;
  logic start_of_frame;
  logic [7:0] red;
  logic [7:0] green;
  logic [7:0] blue;
  logic signed [15:0] audio_pcm;
  logic audio_pwm;
  logic audio_voice_active;

  logic [7:0] payload [0:31];
  logic audio_seen;
  logic game_tick_seen;
  integer index;

  always #5 clk_sys = ~clk_sys;
  always #1 clk_pix = ~clk_pix;

  board_a_system #(
    .CLOCK_HZ(CLOCK_HZ),
    .PLAYER_1_BAUD(BAUD),
    .PLAYER_2_BAUD(BAUD),
    .FRAME_TIMEOUT_MS(20),
    .STALE_TIMEOUT_MS(2_000)
  ) dut (.*);

  always @(posedge clk_sys) begin
    if (audio_voice_active) audio_seen <= 1'b1;
    if (game_tick_debug) game_tick_seen <= 1'b1;
  end

  function automatic logic [15:0] crc_byte(
    input logic [15:0] crc_input,
    input logic [7:0] data
  );
    logic [15:0] crc;
    integer bit_index;
    begin
      crc = crc_input ^ {data, 8'h00};
      for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
        if (crc[15]) crc = (crc << 1) ^ 16'h1021;
        else crc = crc << 1;
      end
      crc_byte = crc;
    end
  endfunction

  task automatic uart_send_byte(input logic [7:0] value);
    integer bit_index;
    integer hold_index;
    begin
      player_1_serial_rx = 1'b0;
      repeat (BIT_CLOCKS) @(negedge clk_sys);
      for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
        player_1_serial_rx = value[bit_index];
        for (hold_index = 0; hold_index < BIT_CLOCKS; hold_index = hold_index + 1) begin
          @(negedge clk_sys);
        end
      end
      player_1_serial_rx = 1'b1;
      repeat (BIT_CLOCKS) @(negedge clk_sys);
    end
  endtask

  task automatic send_escaped_byte(input logic [7:0] value);
    begin
      if ((value == 8'h0a) || (value == 8'h7d)) begin
        uart_send_byte(8'h7d);
        uart_send_byte(value ^ 8'h20);
      end else begin
        uart_send_byte(value);
      end
    end
  endtask

  task automatic send_motion_frame(
    input logic [15:0] sequence_number,
    input integer gyro_y,
    input integer accel_z,
    input integer quat_y
  );
    logic [15:0] crc;
    integer payload_index;
    begin
      for (payload_index = 0; payload_index < 32; payload_index = payload_index + 1) begin
        payload[payload_index] = 8'h00;
      end
      payload[0] = 8'h01;
      payload[1] = 8'h01;
      payload[2] = 8'h01;
      payload[3] = 8'h01;
      payload[4] = sequence_number[7:0];
      payload[5] = sequence_number[15:8];
      payload[6] = sequence_number[7:0];
      payload[7] = sequence_number[15:8];
      payload[14] = accel_z[7:0];
      payload[15] = accel_z[15:8];
      payload[18] = gyro_y[7:0];
      payload[19] = gyro_y[15:8];
      payload[22] = 8'hff;
      payload[23] = 8'h7f;
      payload[26] = quat_y[7:0];
      payload[27] = quat_y[15:8];

      crc = 16'hffff;
      for (payload_index = 0; payload_index < 30; payload_index = payload_index + 1) begin
        crc = crc_byte(crc, payload[payload_index]);
      end
      payload[30] = crc[7:0];
      payload[31] = crc[15:8];

      for (payload_index = 0; payload_index < 32; payload_index = payload_index + 1) begin
        send_escaped_byte(payload[payload_index]);
      end
      uart_send_byte(8'h0a);
    end
  endtask

  initial begin
    #20_000_000;
    $fatal(1, "board_a_system integration watchdog expired");
  end

  initial begin
    audio_seen = 1'b0;
    game_tick_seen = 1'b0;

    repeat (8) @(negedge clk_sys);
    async_rst_n = 1'b1;
    repeat (8) @(negedge clk_sys);

    send_motion_frame(16'd1, 1900, 1200, 1000);
    send_motion_frame(16'd2, 2600, 1200, 1000);
    send_motion_frame(16'd3, 3000, 1200, 1000);
    send_motion_frame(16'd4, 2400, 1200, 1000);

    wait (player_1_debug_health.received_frames == 32'd4);
    if (!player_1_debug_health.connected || !player_1_debug_health.calibrated
        || (player_1_debug_health.crc_errors != 0)
        || (player_1_debug_health.framing_errors != 0)) begin
      $fatal(1, "transport health did not reach gameplay intact");
    end

    wait (render_state_sys_debug.ball_visible);
    wait (audio_seen);
    if (!render_state_sys_debug.valid || !render_state_sys_debug.player_one_connected) begin
      $fatal(1, "game render state did not reflect connected Player 1");
    end

    wait (pixel_state_valid_debug);
    if (!render_state_pix_debug.valid || !render_state_pix_debug.player_one_connected) begin
      $fatal(1, "atomic pixel snapshot did not contain the game state");
    end

    wait (video_data_enable && ({red, green, blue} != 24'h000000));
    if (!game_tick_seen) $fatal(1, "60 Hz enable was never observed");

    $display("PASS: serial transport -> gameplay -> snapshot/video + audio Board A integration");
    $finish;
  end
endmodule
