package gameplay_tuning_pkg;
  localparam logic [17:0] SWING_ENTRY_ENERGY   = 18'd1800;
  localparam logic [17:0] SWING_RELEASE_ENERGY = 18'd700;
  localparam logic [17:0] SWING_FALL_DELTA     = 18'd320;
  localparam logic [7:0]  SWING_MAX_SAMPLES    = 8'd12;
  localparam logic [7:0]  SWING_COOLDOWN_SAMPLES = 8'd8;

  localparam logic signed [31:0] Q16_ONE = 32'sh0001_0000;
  localparam logic signed [31:0] COURT_HALF_X_Q16 = 32'sh0004_0000;
  localparam logic signed [31:0] COURT_HALF_Y_Q16 = 32'sh0008_0000;
  localparam logic signed [31:0] NET_HEIGHT_Q16 = 32'sh0001_0000;
  localparam logic signed [31:0] GRAVITY_PER_TICK_Q16 = -32'sd256;
  localparam logic signed [31:0] STOP_VERTICAL_SPEED_Q16 = 32'sd768;

  function automatic logic [16:0] abs_s16(input logic signed [15:0] value);
    if (value == -16'sd32768) begin
      abs_s16 = 17'd32768;
    end else if (value < 0) begin
      abs_s16 = $unsigned(-value);
    end else begin
      abs_s16 = $unsigned(value);
    end
  endfunction

  function automatic logic signed [31:0] sat_s32(input logic signed [63:0] value);
    if (value > 64'sh0000_0000_7fff_ffff) begin
      sat_s32 = 32'sh7fff_ffff;
    end else if (value < -64'sh0000_0000_8000_0000) begin
      sat_s32 = -32'sh8000_0000;
    end else begin
      sat_s32 = value[31:0];
    end
  endfunction

  function automatic logic [15:0] sat_u16(input logic [21:0] value);
    if (|value[21:16]) begin
      sat_u16 = 16'hffff;
    end else begin
      sat_u16 = value[15:0];
    end
  endfunction
endpackage
