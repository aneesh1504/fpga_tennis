package protocol_pkg;
  localparam logic [15:0] PROTOCOL_INTERFACE_VERSION = 16'h0100;
  localparam logic [7:0]  MOTION_PROTOCOL_VERSION  = 8'h01;
  localparam logic [7:0]  MOTION_MESSAGE_TYPE     = 8'h01;
  localparam logic [7:0]  PLAYER_1_ID             = 8'h01;
  localparam logic [7:0]  PLAYER_2_ID             = 8'h02;
  localparam int unsigned MOTION_PAYLOAD_BYTES    = 32;
  localparam int unsigned MOTION_CRC_INPUT_BYTES  = 30;
  localparam logic [15:0] CRC16_CCITT_POLYNOMIAL  = 16'h1021;
  localparam logic [15:0] CRC16_CCITT_INITIAL     = 16'hffff;
  localparam logic [15:0] CRC16_CCITT_FINAL_XOR   = 16'h0000;
  localparam logic [7:0]  FRAME_TERMINATOR        = 8'h0a;
  localparam logic [7:0]  FRAME_ESCAPE            = 8'h7d;
  localparam logic [7:0]  FRAME_ESCAPE_XOR        = 8'h20;

  typedef struct packed {
    logic               valid;
    logic               stale;
    logic        [15:0] sequence_number;
    logic        [31:0] phone_time_ms;
    logic signed [15:0] accel_x;
    logic signed [15:0] accel_y;
    logic signed [15:0] accel_z;
    logic signed [15:0] gyro_x;
    logic signed [15:0] gyro_y;
    logic signed [15:0] gyro_z;
    logic signed [15:0] quat_w;
    logic signed [15:0] quat_x;
    logic signed [15:0] quat_y;
    logic signed [15:0] quat_z;
  } motion_sample_t;

  typedef struct packed {
    logic        connected;
    logic        calibrated;
    logic        stale;
    logic [15:0] last_sequence;
    logic [31:0] received_frames;
    logic [31:0] crc_errors;
    logic [31:0] framing_errors;
    logic [31:0] sequence_gaps;
    logic [31:0] fifo_overflows;
    logic [31:0] stale_events;
  } transport_health_t;
endpackage
