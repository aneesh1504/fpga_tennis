module audio_engine #(
  parameter integer CLOCK_HZ = 100_000_000,
  parameter integer SAMPLE_HZ = 48_000
) (
  input  logic                         clk_sys,
  input  logic                         rst_sys_n,
  input  logic                         event_valid,
  output logic                         event_ready,
  input  game_types_pkg::audio_event_t event_data,
  output logic signed [15:0]           pcm_sample,
  output logic                         audio_pwm,
  output logic                         voice_active
);
  localparam integer SAMPLE_ACCUM_WIDTH = $clog2(CLOCK_HZ + 1);

  logic [SAMPLE_ACCUM_WIDTH-1:0] sample_accumulator_q;
  logic [SAMPLE_ACCUM_WIDTH:0] sample_accumulator_next;
  logic audio_tick;

  always_comb begin
    sample_accumulator_next = sample_accumulator_q + SAMPLE_HZ;
  end

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      sample_accumulator_q <= '0;
      audio_tick <= 1'b0;
    end else if (sample_accumulator_next >= CLOCK_HZ) begin
      sample_accumulator_q <= sample_accumulator_next - CLOCK_HZ;
      audio_tick <= 1'b1;
    end else begin
      sample_accumulator_q <= sample_accumulator_next[SAMPLE_ACCUM_WIDTH-1:0];
      audio_tick <= 1'b0;
    end
  end

  tone_voice voice (
    .clk_sys,
    .rst_sys_n,
    .audio_tick,
    .event_valid,
    .event_ready,
    .event_data,
    .voice_active,
    .voice_sample(pcm_sample)
  );

  pwm_audio_out output_stage (
    .clk_sys,
    .rst_sys_n,
    .pcm_sample,
    .audio_pwm
  );

  initial begin
    if ((SAMPLE_HZ <= 0) || (SAMPLE_HZ >= CLOCK_HZ)) begin
      $error("SAMPLE_HZ must be greater than zero and less than CLOCK_HZ");
    end
  end
endmodule
