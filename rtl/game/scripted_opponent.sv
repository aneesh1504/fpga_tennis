module scripted_opponent (
  input  logic                                clk_sys,
  input  logic                                rst_sys_n,
  input  logic                                enable,
  input  logic                                game_tick,
  input  video_types_pkg::game_render_state_t render_state,
  output logic                                sample_valid,
  input  logic                                sample_ready,
  output protocol_pkg::motion_sample_t        sample,
  output protocol_pkg::transport_health_t     health
);
  import protocol_pkg::*;

  typedef enum logic [2:0] {
    OPPONENT_IDLE,
    OPPONENT_SAMPLE_0,
    OPPONENT_SAMPLE_1,
    OPPONENT_SAMPLE_2,
    OPPONENT_SAMPLE_3,
    OPPONENT_WAIT_RETURN
  } opponent_state_t;

  opponent_state_t state_q;
  logic [15:0] sequence_q;

  assign sample_valid = enable
                     && (state_q >= OPPONENT_SAMPLE_0)
                     && (state_q <= OPPONENT_SAMPLE_3);

  always_comb begin
    sample = '0;
    sample.valid = sample_valid;
    sample.sequence_number = sequence_q;
    sample.accel_z = 16'sd1100;
    sample.quat_y = -16'sd500;
    case (state_q)
      OPPONENT_SAMPLE_0: sample.gyro_y = -16'sd1900;
      OPPONENT_SAMPLE_1: sample.gyro_y = -16'sd2600;
      OPPONENT_SAMPLE_2: sample.gyro_y = -16'sd3000;
      OPPONENT_SAMPLE_3: sample.gyro_y = -16'sd2400;
      default: sample.gyro_y = 16'sd0;
    endcase

    health = '0;
    health.connected = enable;
    health.calibrated = enable;
    health.last_sequence = sequence_q;
    health.received_frames = {16'd0, sequence_q};
  end

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      state_q <= OPPONENT_IDLE;
      sequence_q <= '0;
    end else if (!enable) begin
      state_q <= OPPONENT_IDLE;
      sequence_q <= '0;
    end else begin
      case (state_q)
        OPPONENT_IDLE: begin
          if (game_tick && render_state.ball_visible
              && ($signed(render_state.ball_y_q8_8) >= 16'sh0580)) begin
            state_q <= OPPONENT_SAMPLE_0;
          end
        end
        OPPONENT_SAMPLE_0,
        OPPONENT_SAMPLE_1,
        OPPONENT_SAMPLE_2: begin
          if (sample_valid && sample_ready) begin
            state_q <= state_q + 1'b1;
            sequence_q <= sequence_q + 1'b1;
          end
        end
        OPPONENT_SAMPLE_3: begin
          if (sample_valid && sample_ready) begin
            state_q <= OPPONENT_WAIT_RETURN;
            sequence_q <= sequence_q + 1'b1;
          end
        end
        OPPONENT_WAIT_RETURN: begin
          if (game_tick && (!render_state.ball_visible
              || ($signed(render_state.ball_y_q8_8) < 0))) begin
            state_q <= OPPONENT_IDLE;
          end
        end
        default: state_q <= OPPONENT_IDLE;
      endcase
    end
  end
endmodule
