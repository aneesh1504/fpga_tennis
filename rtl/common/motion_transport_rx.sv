`timescale 1ns/1ps

module motion_transport_rx #(
  parameter int unsigned CLOCK_HZ = 100_000_000,
  parameter int unsigned BAUD = 115_200,
  parameter logic [7:0] ACCEPTED_PLAYER_ID = 8'h00,
  parameter int unsigned FRAME_TIMEOUT_MS = 20,
  parameter int unsigned STALE_TIMEOUT_MS = 250
) (
  input  logic                            clk,
  input  logic                            rst_n,
  input  logic                            serial_rx,
  output logic                            sample_valid,
  input  logic                            sample_ready,
  output protocol_pkg::motion_sample_t    sample,
  output protocol_pkg::transport_health_t sample_health,
  output protocol_pkg::transport_health_t debug_health
);
  import protocol_pkg::*;

  localparam int unsigned FRAME_AGE_WIDTH = (FRAME_TIMEOUT_MS < 2) ? 1 : $clog2(FRAME_TIMEOUT_MS + 1);
  localparam int unsigned STALE_AGE_WIDTH = (STALE_TIMEOUT_MS < 2) ? 1 : $clog2(STALE_TIMEOUT_MS + 1);

  logic uart_valid;
  logic [7:0] uart_data;
  logic uart_framing_error;
  logic [31:0] uart_framing_error_count_unused;
  logic raw_valid;
  logic [7:0] raw_data;
  logic [4:0] raw_index;
  logic frame_end;
  logic [5:0] frame_length;
  logic unescape_error;
  logic frame_active;
  logic frame_timeout;
  logic tick_ms;
  logic [FRAME_AGE_WIDTH-1:0] frame_age_q;
  logic decoded_valid;
  motion_sample_t decoded_sample;
  logic decoded_calibrated;
  logic crc_error;
  logic length_error;
  logic header_error;

  transport_health_t health_q;
  transport_health_t health_next;
  motion_sample_t last_sample_q;
  motion_sample_t last_sample_next;
  logic have_sequence_q;
  logic have_sequence_next;
  logic [STALE_AGE_WIDTH-1:0] stale_age_q;
  logic [STALE_AGE_WIDTH-1:0] stale_age_next;
  logic stale_transition;
  logic publish_request;
  logic publish_available;
  motion_sample_t publish_sample;
  logic stale_pending_q;
  logic stale_pending_next;

  function automatic logic [31:0] sat_inc(input logic [31:0] value);
    if (value == 32'hffff_ffff) sat_inc = value;
    else                        sat_inc = value + 1'b1;
  endfunction

  initial begin
    if (FRAME_TIMEOUT_MS == 0 || STALE_TIMEOUT_MS == 0) begin
      $fatal(1, "motion_transport_rx timeout parameters must be nonzero");
    end
  end

  uart_rx #(.CLOCK_HZ(CLOCK_HZ), .BAUD(BAUD)) uart (
    .clk,
    .rst_n,
    .serial_rx,
    .data_valid(uart_valid),
    .data(uart_data),
    .framing_error(uart_framing_error),
    .framing_error_count(uart_framing_error_count_unused)
  );

  tick_gen #(.CLOCK_HZ(CLOCK_HZ), .TICK_HZ(1_000)) ms_tick (
    .clk,
    .rst_n,
    .tick(tick_ms)
  );

  frame_unescaper #(.MAX_RAW_BYTES(MOTION_PAYLOAD_BYTES)) unescaper (
    .clk,
    .rst_n,
    .byte_valid(uart_valid),
    .byte_data(uart_data),
    .timeout(frame_timeout || uart_framing_error),
    .raw_valid,
    .raw_data,
    .raw_index,
    .frame_end,
    .frame_length,
    .frame_error(unescape_error),
    .frame_active
  );

  motion_packet_decoder #(.ACCEPTED_PLAYER_ID(ACCEPTED_PLAYER_ID)) decoder (
    .clk,
    .rst_n,
    .raw_valid,
    .raw_data,
    .raw_index,
    .frame_end,
    .frame_length,
    .frame_error(unescape_error || uart_framing_error),
    .motion_valid(decoded_valid),
    .motion_sample(decoded_sample),
    .calibrated(decoded_calibrated),
    .crc_error,
    .length_error,
    .header_error
  );

  assign frame_timeout = frame_active && tick_ms && (frame_age_q == FRAME_TIMEOUT_MS - 1);
  assign publish_available = !sample_valid || sample_ready;
  assign debug_health = health_q;

  always_comb begin
    health_next = health_q;
    last_sample_next = last_sample_q;
    have_sequence_next = have_sequence_q;
    stale_age_next = stale_age_q;
    stale_transition = 1'b0;
    stale_pending_next = stale_pending_q;

    if (uart_framing_error || unescape_error || length_error || header_error) begin
      health_next.framing_errors = sat_inc(health_next.framing_errors);
    end
    if (crc_error) health_next.crc_errors = sat_inc(health_next.crc_errors);

    if (decoded_valid) begin
      health_next.connected = 1'b1;
      health_next.calibrated = decoded_calibrated;
      health_next.stale = 1'b0;
      health_next.received_frames = sat_inc(health_next.received_frames);
      if (have_sequence_q && decoded_sample.sequence_number != health_q.last_sequence + 1'b1) begin
        health_next.sequence_gaps = sat_inc(health_next.sequence_gaps);
      end
      health_next.last_sequence = decoded_sample.sequence_number;
      have_sequence_next = 1'b1;
      stale_age_next = '0;
      last_sample_next = decoded_sample;
      last_sample_next.stale = 1'b0;
      stale_pending_next = 1'b0;
    end else if (tick_ms && health_q.connected && !health_q.stale) begin
      if (stale_age_q == STALE_TIMEOUT_MS - 1) begin
        health_next.stale = 1'b1;
        health_next.stale_events = sat_inc(health_next.stale_events);
        last_sample_next.stale = 1'b1;
        stale_transition = 1'b1;
      end else begin
        stale_age_next = stale_age_q + 1'b1;
      end
    end

    publish_request = decoded_valid || stale_transition || stale_pending_q;
    publish_sample = decoded_valid ? decoded_sample : last_sample_next;
    if ((stale_transition || stale_pending_q) && !decoded_valid) begin
      stale_pending_next = !publish_available;
    end
    if (publish_request && !publish_available && decoded_valid) begin
      health_next.fifo_overflows = sat_inc(health_next.fifo_overflows);
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frame_age_q <= '0;
    end else if (!frame_active || frame_timeout || uart_framing_error) begin
      frame_age_q <= '0;
    end else if (tick_ms && frame_age_q != FRAME_TIMEOUT_MS - 1) begin
      frame_age_q <= frame_age_q + 1'b1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      health_q <= '0;
      last_sample_q <= '0;
      have_sequence_q <= 1'b0;
      stale_age_q <= '0;
      stale_pending_q <= 1'b0;
      sample_valid <= 1'b0;
      sample <= '0;
      sample_health <= '0;
    end else begin
      health_q <= health_next;
      last_sample_q <= last_sample_next;
      have_sequence_q <= have_sequence_next;
      stale_age_q <= stale_age_next;
      stale_pending_q <= stale_pending_next;

      if (publish_request && publish_available) begin
        sample_valid <= 1'b1;
        sample <= publish_sample;
        sample_health <= health_next;
      end else if (sample_valid && sample_ready) begin
        sample_valid <= 1'b0;
      end
    end
  end
endmodule
