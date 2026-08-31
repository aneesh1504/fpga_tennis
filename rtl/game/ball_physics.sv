module ball_physics (
  input  logic                     clk_sys,
  input  logic                     rst_sys_n,
  input  logic                     game_tick,
  input  logic                     state_load,
  input  logic                     load_active,
  input  logic signed [31:0]        load_x_q16,
  input  logic signed [31:0]        load_y_q16,
  input  logic signed [31:0]        load_z_q16,
  input  logic signed [31:0]        load_vx_q16,
  input  logic signed [31:0]        load_vy_q16,
  input  logic signed [31:0]        load_vz_q16,
  output logic                     ball_active,
  output logic signed [31:0]        ball_x_q16,
  output logic signed [31:0]        ball_y_q16,
  output logic signed [31:0]        ball_z_q16,
  output logic signed [31:0]        ball_vx_q16,
  output logic signed [31:0]        ball_vy_q16,
  output logic signed [31:0]        ball_vz_q16,
  output logic                     net_cross_pulse,
  output logic                     net_fault_pulse,
  output logic                     bounce_pulse,
  output logic                     bounce_in_bounds,
  output logic                     out_of_bounds_pulse,
  output logic                     stopped_pulse
);
  import gameplay_tuning_pkg::*;

  logic signed [31:0] next_x;
  logic signed [31:0] next_y;
  logic signed [31:0] next_z;
  logic signed [31:0] next_vz;
  logic signed [63:0] restitution_product;
  logic crossing_net;
  logic next_in_bounds;

  assign next_x = sat_s32($signed(ball_x_q16) + $signed(ball_vx_q16));
  assign next_y = sat_s32($signed(ball_y_q16) + $signed(ball_vy_q16));
  assign next_vz = sat_s32($signed(ball_vz_q16) + $signed(GRAVITY_PER_TICK_Q16));
  assign next_z = sat_s32($signed(ball_z_q16) + $signed(next_vz));
  assign crossing_net = (($signed(ball_y_q16) < 0) && ($signed(next_y) >= 0))
                     || (($signed(ball_y_q16) > 0) && ($signed(next_y) <= 0));
  assign next_in_bounds = ($signed(next_x) >= -$signed(COURT_HALF_X_Q16))
                       && ($signed(next_x) <= $signed(COURT_HALF_X_Q16))
                       && ($signed(next_y) >= -$signed(COURT_HALF_Y_Q16))
                       && ($signed(next_y) <= $signed(COURT_HALF_Y_Q16));
  assign restitution_product = -$signed(next_vz) * 64'sd3;

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      ball_active <= 1'b0;
      ball_x_q16 <= '0;
      ball_y_q16 <= '0;
      ball_z_q16 <= '0;
      ball_vx_q16 <= '0;
      ball_vy_q16 <= '0;
      ball_vz_q16 <= '0;
      net_cross_pulse <= 1'b0;
      net_fault_pulse <= 1'b0;
      bounce_pulse <= 1'b0;
      bounce_in_bounds <= 1'b0;
      out_of_bounds_pulse <= 1'b0;
      stopped_pulse <= 1'b0;
    end else begin
      net_cross_pulse <= 1'b0;
      net_fault_pulse <= 1'b0;
      bounce_pulse <= 1'b0;
      out_of_bounds_pulse <= 1'b0;
      stopped_pulse <= 1'b0;

      if (state_load) begin
        ball_active <= load_active;
        ball_x_q16 <= load_x_q16;
        ball_y_q16 <= load_y_q16;
        ball_z_q16 <= load_z_q16;
        ball_vx_q16 <= load_vx_q16;
        ball_vy_q16 <= load_vy_q16;
        ball_vz_q16 <= load_vz_q16;
        bounce_in_bounds <= 1'b0;
      end else if (game_tick && ball_active) begin
        ball_x_q16 <= next_x;
        ball_y_q16 <= next_y;
        ball_z_q16 <= next_z;
        ball_vz_q16 <= next_vz;

        if (crossing_net) begin
          net_cross_pulse <= 1'b1;
          if ($signed(next_z) < $signed(NET_HEIGHT_Q16)) begin
            ball_active <= 1'b0;
            net_fault_pulse <= 1'b1;
          end
        end

        if (($signed(next_z) <= 0) && ($signed(next_vz) < 0) && !crossing_net) begin
          bounce_pulse <= 1'b1;
          bounce_in_bounds <= next_in_bounds;
          ball_z_q16 <= '0;
          if (!next_in_bounds) begin
            ball_active <= 1'b0;
            out_of_bounds_pulse <= 1'b1;
          end else if ($signed(restitution_product >>> 2)
                       <= $signed(STOP_VERTICAL_SPEED_Q16)) begin
            ball_active <= 1'b0;
            ball_vz_q16 <= '0;
            stopped_pulse <= 1'b1;
          end else begin
            ball_vz_q16 <= sat_s32(restitution_product >>> 2);
          end
        end
      end
    end
  end
endmodule
