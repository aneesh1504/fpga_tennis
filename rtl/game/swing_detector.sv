module swing_detector (
  input  logic                            clk_sys,
  input  logic                            rst_sys_n,
  input  logic                            sample_valid,
  output logic                            sample_ready,
  input  protocol_pkg::motion_sample_t    sample,
  input  protocol_pkg::transport_health_t health,
  output logic                            swing_valid,
  input  logic                            swing_ready,
  output game_types_pkg::swing_event_t    swing_event
);
  import protocol_pkg::*;
  import game_types_pkg::*;
  import gameplay_tuning_pkg::*;

  typedef enum logic [2:0] {
    SWING_IDLE,
    SWING_ARMED,
    SWING_TRACKING,
    SWING_EMIT,
    SWING_COOLDOWN
  } swing_state_t;

  swing_state_t state_q;
  motion_sample_t peak_sample_q;
  swing_event_t event_q;
  logic [17:0] peak_energy_q;
  logic [7:0] tracking_samples_q;
  logic [7:0] cooldown_samples_q;
  logic [17:0] sample_energy;
  logic sample_qualified;
  logic [21:0] strength_scaled;

  assign sample_energy = abs_s16(sample.gyro_x)
                       + abs_s16(sample.gyro_y)
                       + abs_s16(sample.gyro_z);
  assign sample_qualified = sample.valid
                         && !sample.stale
                         && health.connected
                         && health.calibrated
                         && !health.stale;
  assign strength_scaled = (peak_energy_q > SWING_ENTRY_ENERGY)
                         ? ((peak_energy_q - SWING_ENTRY_ENERGY) << 4)
                         : 22'd0;

  assign sample_ready = (state_q != SWING_EMIT);
  assign swing_valid = (state_q == SWING_EMIT);
  assign swing_event = event_q;

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      state_q <= SWING_IDLE;
      peak_sample_q <= '0;
      event_q <= '0;
      peak_energy_q <= '0;
      tracking_samples_q <= '0;
      cooldown_samples_q <= '0;
    end else begin
      case (state_q)
        SWING_IDLE: begin
          event_q.valid <= 1'b0;
          if (sample_valid && sample_ready && sample_qualified
              && (sample_energy >= SWING_ENTRY_ENERGY)) begin
            peak_sample_q <= sample;
            peak_energy_q <= sample_energy;
            tracking_samples_q <= 8'd1;
            state_q <= SWING_ARMED;
          end
        end

        SWING_ARMED: begin
          if (sample_valid && sample_ready) begin
            if (!sample_qualified) begin
              state_q <= SWING_IDLE;
            end else if (sample_energy < SWING_RELEASE_ENERGY) begin
              state_q <= SWING_IDLE;
            end else begin
              tracking_samples_q <= tracking_samples_q + 1'b1;
              if (sample_energy > peak_energy_q) begin
                peak_sample_q <= sample;
                peak_energy_q <= sample_energy;
                state_q <= SWING_TRACKING;
              end
            end
          end
        end

        SWING_TRACKING: begin
          if (sample_valid && sample_ready) begin
            if (!sample_qualified) begin
              state_q <= SWING_IDLE;
            end else if ((sample_energy + SWING_FALL_DELTA < peak_energy_q)
                         || (tracking_samples_q >= SWING_MAX_SAMPLES)) begin
              event_q.valid <= 1'b1;
              event_q.forehand <= !peak_sample_q.gyro_y[15];
              event_q.upward <= !peak_sample_q.accel_z[15];
              event_q.strength <= sat_u16(strength_scaled);
              event_q.aim_x <= peak_sample_q.quat_y;
              event_q.lift <= peak_sample_q.accel_z;
              state_q <= SWING_EMIT;
            end else begin
              tracking_samples_q <= tracking_samples_q + 1'b1;
              if (sample_energy > peak_energy_q) begin
                peak_sample_q <= sample;
                peak_energy_q <= sample_energy;
              end
            end
          end
        end

        SWING_EMIT: begin
          if (swing_ready) begin
            event_q.valid <= 1'b0;
            cooldown_samples_q <= SWING_COOLDOWN_SAMPLES;
            state_q <= SWING_COOLDOWN;
          end
        end

        SWING_COOLDOWN: begin
          if (sample_valid && sample_ready) begin
            if (!sample_qualified) begin
              cooldown_samples_q <= '0;
              state_q <= SWING_IDLE;
            end else if (cooldown_samples_q != 0) begin
              cooldown_samples_q <= cooldown_samples_q - 1'b1;
            end else if (sample_energy < SWING_RELEASE_ENERGY) begin
              state_q <= SWING_IDLE;
            end
          end
        end

        default: state_q <= SWING_IDLE;
      endcase
    end
  end
endmodule
