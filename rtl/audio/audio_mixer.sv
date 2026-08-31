module audio_mixer (
  input  logic signed [15:0] voice_a,
  input  logic signed [15:0] voice_b,
  output logic signed [15:0] mixed_sample
);
  logic signed [16:0] sum;

  function automatic logic signed [15:0] saturate_mix(input logic signed [16:0] value);
    if (value > 17'sd32767) begin
      saturate_mix = 16'sh7fff;
    end else if (value < -17'sd32768) begin
      saturate_mix = -16'sh8000;
    end else begin
      saturate_mix = value[15:0];
    end
  endfunction

  assign sum = $signed(voice_a) + $signed(voice_b);
  assign mixed_sample = saturate_mix(sum);
endmodule
