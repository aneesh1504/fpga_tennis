`timescale 1ns/1ps

module dual_motion_transport_rx #(
  parameter int unsigned CLOCK_HZ = 100_000_000,
  parameter int unsigned PLAYER_1_BAUD = 115_200,
  parameter int unsigned PLAYER_2_BAUD = 115_200,
  parameter int unsigned FRAME_TIMEOUT_MS = 20,
  parameter int unsigned STALE_TIMEOUT_MS = 250
) (
  input  logic                            clk,
  input  logic                            rst_n,
  input  logic                            player_1_serial_rx,
  output logic                            player_1_valid,
  input  logic                            player_1_ready,
  output protocol_pkg::motion_sample_t    player_1_sample,
  output protocol_pkg::transport_health_t player_1_health,
  output protocol_pkg::transport_health_t player_1_debug_health,
  input  logic                            player_2_serial_rx,
  output logic                            player_2_valid,
  input  logic                            player_2_ready,
  output protocol_pkg::motion_sample_t    player_2_sample,
  output protocol_pkg::transport_health_t player_2_health,
  output protocol_pkg::transport_health_t player_2_debug_health
);
  import protocol_pkg::*;

  motion_transport_rx #(
    .CLOCK_HZ(CLOCK_HZ),
    .BAUD(PLAYER_1_BAUD),
    .ACCEPTED_PLAYER_ID(PLAYER_1_ID),
    .FRAME_TIMEOUT_MS(FRAME_TIMEOUT_MS),
    .STALE_TIMEOUT_MS(STALE_TIMEOUT_MS)
  ) player_1_endpoint (
    .clk,
    .rst_n,
    .serial_rx(player_1_serial_rx),
    .sample_valid(player_1_valid),
    .sample_ready(player_1_ready),
    .sample(player_1_sample),
    .sample_health(player_1_health),
    .debug_health(player_1_debug_health)
  );

  motion_transport_rx #(
    .CLOCK_HZ(CLOCK_HZ),
    .BAUD(PLAYER_2_BAUD),
    .ACCEPTED_PLAYER_ID(PLAYER_2_ID),
    .FRAME_TIMEOUT_MS(FRAME_TIMEOUT_MS),
    .STALE_TIMEOUT_MS(STALE_TIMEOUT_MS)
  ) player_2_endpoint (
    .clk,
    .rst_n,
    .serial_rx(player_2_serial_rx),
    .sample_valid(player_2_valid),
    .sample_ready(player_2_ready),
    .sample(player_2_sample),
    .sample_health(player_2_health),
    .debug_health(player_2_debug_health)
  );
endmodule
