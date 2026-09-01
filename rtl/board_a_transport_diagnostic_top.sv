module board_a_transport_diagnostic_top (
  input  logic        clk,
  input  logic        btn_reset,
  input  logic        ble_uart_rx,
  input  logic [2:0]  sw,
  output logic [15:0] led,
  output logic [3:0]  D0_AN,
  output logic [7:0]  D0_SEG,
  output logic [3:0]  D1_AN,
  output logic [7:0]  D1_SEG
);
  import protocol_pkg::*;

  logic rst_n;
  logic raw_valid;
  logic [7:0] raw_byte;
  logic raw_framing_error;
  logic [31:0] raw_framing_error_count;
  logic [31:0] raw_byte_count;
  logic [7:0] last_raw_byte;
  logic seen_probe_byte;
  logic raw_activity_toggle;

  logic sample_valid;
  motion_sample_t sample;
  transport_health_t sample_health;
  transport_health_t debug_health;
  logic decoded_activity_toggle;

  logic [31:0] display_value;
  logic [17:0] scan_counter;
  logic [2:0] scan_digit;
  logic [3:0] scan_nibble;

  reset_sync reset_sync_inst (
    .clk,
    .async_rst_n(~btn_reset),
    .sync_rst_n(rst_n)
  );

  uart_rx #(
    .CLOCK_HZ(100_000_000),
    .BAUD(115_200)
  ) raw_uart_monitor (
    .clk,
    .rst_n,
    .serial_rx(ble_uart_rx),
    .data_valid(raw_valid),
    .data(raw_byte),
    .framing_error(raw_framing_error),
    .framing_error_count(raw_framing_error_count)
  );

  motion_transport_rx #(
    .CLOCK_HZ(100_000_000),
    .BAUD(115_200),
    .ACCEPTED_PLAYER_ID(PLAYER_1_ID),
    .FRAME_TIMEOUT_MS(20),
    .STALE_TIMEOUT_MS(250)
  ) transport (
    .clk,
    .rst_n,
    .serial_rx(ble_uart_rx),
    .sample_valid,
    .sample_ready(1'b1),
    .sample,
    .sample_health,
    .debug_health
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      raw_byte_count <= '0;
      last_raw_byte <= '0;
      seen_probe_byte <= 1'b0;
      raw_activity_toggle <= 1'b0;
      decoded_activity_toggle <= 1'b0;
      scan_counter <= '0;
    end else begin
      scan_counter <= scan_counter + 1'b1;
      if (raw_valid) begin
        raw_byte_count <= raw_byte_count + 1'b1;
        last_raw_byte <= raw_byte;
        if (raw_byte == 8'h41) begin
          seen_probe_byte <= 1'b1;
        end
        raw_activity_toggle <= ~raw_activity_toggle;
      end
      if (sample_valid) begin
        decoded_activity_toggle <= ~decoded_activity_toggle;
      end
    end
  end

  always_comb begin
    case (sw)
      3'd0: display_value = raw_byte_count;
      3'd1: display_value = {24'h0, last_raw_byte};
      3'd2: display_value = debug_health.received_frames;
      3'd3: display_value = {16'h0, debug_health.last_sequence};
      3'd4: display_value = debug_health.crc_errors;
      3'd5: display_value = debug_health.framing_errors + raw_framing_error_count;
      3'd6: display_value = debug_health.sequence_gaps;
      default: display_value = debug_health.fifo_overflows;
    endcase

    led = '0;
    led[0] = rst_n;
    led[1] = raw_activity_toggle;
    led[2] = seen_probe_byte;
    led[3] = decoded_activity_toggle;
    led[4] = debug_health.connected;
    led[5] = debug_health.calibrated;
    led[6] = debug_health.stale;
    led[7] = |debug_health.crc_errors;
    led[8] = |debug_health.framing_errors | |raw_framing_error_count;
    led[9] = |debug_health.sequence_gaps;
    led[10] = |debug_health.fifo_overflows;
    led[11] = |raw_byte_count;
    led[12] = |debug_health.received_frames;
    led[13] = |debug_health.last_sequence;
    led[14] = ~ble_uart_rx;
    led[15] = 1'b1;

    scan_digit = scan_counter[17:15];
    scan_nibble = display_value >> (scan_digit * 4);
    D0_AN = 4'hf;
    D1_AN = 4'hf;
    D0_SEG = 8'hff;
    D1_SEG = 8'hff;
    if (scan_digit < 4) begin
      D0_AN[scan_digit] = 1'b0;
      D0_SEG = hex_segments(scan_nibble);
    end else begin
      D1_AN[scan_digit - 4] = 1'b0;
      D1_SEG = hex_segments(scan_nibble);
    end
  end

  function automatic logic [7:0] hex_segments(input logic [3:0] value);
    case (value)
      4'h0: hex_segments = 8'hc0;
      4'h1: hex_segments = 8'hf9;
      4'h2: hex_segments = 8'ha4;
      4'h3: hex_segments = 8'hb0;
      4'h4: hex_segments = 8'h99;
      4'h5: hex_segments = 8'h92;
      4'h6: hex_segments = 8'h82;
      4'h7: hex_segments = 8'hf8;
      4'h8: hex_segments = 8'h80;
      4'h9: hex_segments = 8'h90;
      4'ha: hex_segments = 8'h88;
      4'hb: hex_segments = 8'h83;
      4'hc: hex_segments = 8'hc6;
      4'hd: hex_segments = 8'ha1;
      4'he: hex_segments = 8'h86;
      default: hex_segments = 8'h8e;
    endcase
  endfunction
endmodule
