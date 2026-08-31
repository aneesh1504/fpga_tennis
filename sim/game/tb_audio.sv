module tb_audio;
  import game_types_pkg::*;

  logic clk_sys = 1'b0;
  logic rst_sys_n = 1'b0;
  logic audio_tick;
  logic event_valid;
  logic event_ready;
  audio_event_t event_data;
  logic voice_active;
  logic signed [15:0] voice_sample;
  logic signed [15:0] voice_a;
  logic signed [15:0] voice_b;
  logic signed [15:0] mixed_sample;
  logic signed [15:0] pcm_sample;
  logic audio_pwm;
  integer high_count;
  integer cycle_count;

  always #5 clk_sys = ~clk_sys;

  tone_voice #(
    .HIT_PHASE_STEP(24'h800000),
    .HIT_TICKS(16'd4)
  ) voice (.*);
  audio_mixer mixer (.*);
  pwm_audio_out pwm (.*);

  task automatic tick_audio;
    begin
      @(negedge clk_sys);
      audio_tick = 1'b1;
      @(negedge clk_sys);
      audio_tick = 1'b0;
    end
  endtask

  initial begin
    audio_tick = 1'b0;
    event_valid = 1'b0;
    event_data = '0;
    voice_a = '0;
    voice_b = '0;
    pcm_sample = '0;
    high_count = 0;
    repeat (2) @(negedge clk_sys);
    rst_sys_n = 1'b1;

    @(negedge clk_sys);
    event_data.valid = 1'b1;
    event_data.kind = AUDIO_EVENT_HIT;
    event_data.strength = 16'h8000;
    event_valid = 1'b1;
    @(negedge clk_sys);
    event_valid = 1'b0;
    if (!voice_active || (voice_sample == 0)) $fatal(1, "tone did not start");
    repeat (4) tick_audio();
    #1;
    if (voice_active || (voice_sample != 0)) $fatal(1, "tone duration did not expire");

    voice_a = 16'sd30000;
    voice_b = 16'sd30000;
    #1;
    if (mixed_sample != 16'sd32767) $fatal(1, "positive mixer saturation failed");
    voice_a = -16'sd30000;
    voice_b = -16'sd30000;
    #1;
    if (mixed_sample != -16'sd32768) $fatal(1, "negative mixer saturation failed");

    pcm_sample = 16'sd0;
    for (cycle_count = 0; cycle_count < 256; cycle_count = cycle_count + 1) begin
      @(posedge clk_sys);
      #1;
      if (audio_pwm) high_count = high_count + 1;
    end
    if ((high_count < 120) || (high_count > 136)) begin
      $fatal(1, "zero-level PWM density was not near 50 percent: %0d", high_count);
    end

    $display("PASS: audio event tone, duration, mixer saturation, and PWM density");
    $finish;
  end
endmodule
