`timescale 1ns/1ps

module motion_packet_decoder #(
  parameter logic [7:0] ACCEPTED_PLAYER_ID = 8'h00
) (
  input  logic                         clk,
  input  logic                         rst_n,
  input  logic                         raw_valid,
  input  logic [7:0]                   raw_data,
  input  logic [4:0]                   raw_index,
  input  logic                         frame_end,
  input  logic [5:0]                   frame_length,
  input  logic                         frame_error,
  output logic                         motion_valid,
  output protocol_pkg::motion_sample_t motion_sample,
  output logic                         calibrated,
  output logic                         crc_error,
  output logic                         length_error,
  output logic                         header_error
);
  import protocol_pkg::*;

  logic [7:0] bytes [0:MOTION_PAYLOAD_BYTES-1];
  logic [15:0] computed_crc;
  logic crc_clear;
  logic crc_byte_valid;
  logic header_is_valid;

  assign crc_clear = frame_end || frame_error;
  assign crc_byte_valid = raw_valid && (raw_index < MOTION_CRC_INPUT_BYTES);
  assign header_is_valid =
    (bytes[0] == MOTION_PROTOCOL_VERSION) &&
    (bytes[1] == MOTION_MESSAGE_TYPE) &&
    ((bytes[2] == PLAYER_1_ID) || (bytes[2] == PLAYER_2_ID)) &&
    ((ACCEPTED_PLAYER_ID == 8'h00) || (bytes[2] == ACCEPTED_PLAYER_ID)) &&
    (bytes[3][7:1] == 7'h00);

  crc16_ccitt crc_engine (
    .clk,
    .rst_n,
    .clear(crc_clear),
    .byte_valid(crc_byte_valid),
    .byte_data(raw_data),
    .crc(computed_crc)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      motion_valid <= 1'b0;
      motion_sample <= '0;
      calibrated <= 1'b0;
      crc_error <= 1'b0;
      length_error <= 1'b0;
      header_error <= 1'b0;
    end else begin
      motion_valid <= 1'b0;
      crc_error    <= 1'b0;
      length_error <= 1'b0;
      header_error <= 1'b0;

      if (raw_valid) bytes[raw_index] <= raw_data;

      if (frame_end) begin
        if (frame_length != MOTION_PAYLOAD_BYTES) begin
          length_error <= 1'b1;
        end else if (!header_is_valid) begin
          header_error <= 1'b1;
        end else if ({bytes[31], bytes[30]} != computed_crc) begin
          crc_error <= 1'b1;
        end else begin
          motion_valid                   <= 1'b1;
          motion_sample.valid            <= 1'b1;
          motion_sample.stale            <= 1'b0;
          motion_sample.sequence_number  <= {bytes[5], bytes[4]};
          motion_sample.phone_time_ms    <= {bytes[9], bytes[8], bytes[7], bytes[6]};
          motion_sample.accel_x          <= $signed({bytes[11], bytes[10]});
          motion_sample.accel_y          <= $signed({bytes[13], bytes[12]});
          motion_sample.accel_z          <= $signed({bytes[15], bytes[14]});
          motion_sample.gyro_x           <= $signed({bytes[17], bytes[16]});
          motion_sample.gyro_y           <= $signed({bytes[19], bytes[18]});
          motion_sample.gyro_z           <= $signed({bytes[21], bytes[20]});
          motion_sample.quat_w           <= $signed({bytes[23], bytes[22]});
          motion_sample.quat_x           <= $signed({bytes[25], bytes[24]});
          motion_sample.quat_y           <= $signed({bytes[27], bytes[26]});
          motion_sample.quat_z           <= $signed({bytes[29], bytes[28]});
          calibrated                     <= bytes[3][0];
        end
      end
    end
  end
endmodule
