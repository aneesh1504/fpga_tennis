module board_a_transport_bringup_top (
  input  logic        clk,
  input  logic        btn_reset,
  input  logic        ble_uart_rx,
  output logic [15:0] led
);
  import protocol_pkg::*;

  logic rst_n;
  logic sample_valid;
  motion_sample_t sample;
  transport_health_t sample_health;
  transport_health_t debug_health;

  reset_sync reset_sync_inst (
    .clk,
    .async_rst_n(~btn_reset),
    .sync_rst_n(rst_n)
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

  always_comb begin
    led = '0;
    led[0] = rst_n;
    led[1] = debug_health.connected;
    led[2] = debug_health.calibrated;
    led[3] = debug_health.stale;
    led[4] = sample_valid;
    led[5] = |debug_health.crc_errors;
    led[6] = |debug_health.framing_errors;
    led[7] = |debug_health.sequence_gaps;
    led[15:8] = sample.gyro_y[15:8];
  end
endmodule
