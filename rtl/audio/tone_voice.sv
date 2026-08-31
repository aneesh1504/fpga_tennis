module tone_voice #(
  parameter logic [23:0] HIT_PHASE_STEP    = 24'd153791,
  parameter logic [23:0] BOUNCE_PHASE_STEP = 24'd76900,
  parameter logic [23:0] FAULT_PHASE_STEP  = 24'd38450,
  parameter logic [23:0] SCORE_PHASE_STEP  = 24'd230687,
  parameter logic [15:0] HIT_TICKS          = 16'd2400,
  parameter logic [15:0] BOUNCE_TICKS       = 16'd1600,
  parameter logic [15:0] FAULT_TICKS        = 16'd4800,
  parameter logic [15:0] SCORE_TICKS        = 16'd7200
) (
  input  logic                         clk_sys,
  input  logic                         rst_sys_n,
  input  logic                         audio_tick,
  input  logic                         event_valid,
  output logic                         event_ready,
  input  game_types_pkg::audio_event_t event_data,
  output logic                         voice_active,
  output logic signed [15:0]           voice_sample
);
  import game_types_pkg::*;

  logic [23:0] phase_q;
  logic [23:0] phase_step_q;
  logic [15:0] ticks_left_q;
  logic signed [15:0] amplitude_q;

  assign event_ready = 1'b1;
  assign voice_active = (ticks_left_q != 0);
  assign voice_sample = voice_active
                      ? (phase_q[23] ? -amplitude_q : amplitude_q)
                      : 16'sd0;

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      phase_q <= '0;
      phase_step_q <= '0;
      ticks_left_q <= '0;
      amplitude_q <= '0;
    end else begin
      if (event_valid && event_ready && event_data.valid
          && (event_data.kind != AUDIO_EVENT_NONE)) begin
        phase_q <= '0;
        amplitude_q <= {1'b0, event_data.strength[15:1]};
        case (event_data.kind)
          AUDIO_EVENT_HIT: begin
            phase_step_q <= HIT_PHASE_STEP;
            ticks_left_q <= HIT_TICKS;
          end
          AUDIO_EVENT_BOUNCE: begin
            phase_step_q <= BOUNCE_PHASE_STEP;
            ticks_left_q <= BOUNCE_TICKS;
          end
          AUDIO_EVENT_FAULT: begin
            phase_step_q <= FAULT_PHASE_STEP;
            ticks_left_q <= FAULT_TICKS;
          end
          default: begin
            phase_step_q <= SCORE_PHASE_STEP;
            ticks_left_q <= SCORE_TICKS;
          end
        endcase
      end else if (audio_tick && (ticks_left_q != 0)) begin
        phase_q <= phase_q + phase_step_q;
        ticks_left_q <= ticks_left_q - 1'b1;
      end
    end
  end
endmodule
