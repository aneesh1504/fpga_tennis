module pwm_audio_out (
  input  logic               clk_sys,
  input  logic               rst_sys_n,
  input  logic signed [15:0] pcm_sample,
  output logic               audio_pwm
);
  logic [16:0] accumulator_q;
  logic [15:0] unsigned_sample;

  always_comb begin
    unsigned_sample = $unsigned($signed(pcm_sample) + 17'sd32768);
  end

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      accumulator_q <= '0;
      audio_pwm <= 1'b0;
    end else begin
      accumulator_q <= {1'b0, accumulator_q[15:0]} + {1'b0, unsigned_sample};
      audio_pwm <= accumulator_q[16];
    end
  end
endmodule
