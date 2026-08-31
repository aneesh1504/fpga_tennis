module shot_mapper (
  input  logic                    toward_player_two,
  input  logic [15:0]             strength,
  input  logic signed [15:0]      aim_x,
  input  logic signed [15:0]      lift,
  input  logic signed [31:0]      timing_error_q16,
  output logic signed [31:0]      velocity_x_q16,
  output logic signed [31:0]      velocity_y_q16,
  output logic signed [31:0]      velocity_z_q16
);
  import gameplay_tuning_pkg::*;

  logic signed [63:0] lateral_sum;
  logic signed [31:0] speed_magnitude;
  logic signed [31:0] lift_candidate;

  function automatic logic signed [31:0] clamp_lift(input logic signed [31:0] value);
    if (value < SHOT_MIN_LIFT_Q16) begin
      clamp_lift = SHOT_MIN_LIFT_Q16;
    end else if (value > SHOT_MAX_LIFT_Q16) begin
      clamp_lift = SHOT_MAX_LIFT_Q16;
    end else begin
      clamp_lift = value;
    end
  endfunction

  assign lateral_sum = ($signed(aim_x) >>> 1) + ($signed(timing_error_q16) >>> 2);
  assign velocity_x_q16 = sat_s32(lateral_sum);
  assign speed_magnitude = 32'sd32768 + $signed({1'b0, strength});
  assign velocity_y_q16 = toward_player_two ? speed_magnitude : -speed_magnitude;
  assign lift_candidate = SHOT_BASE_LIFT_Q16 + ($signed(lift) <<< 1);
  assign velocity_z_q16 = clamp_lift(lift_candidate);
endmodule
