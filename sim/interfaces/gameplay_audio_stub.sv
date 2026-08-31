module gameplay_audio_stub (
  input  logic                         clk_sys,
  input  logic                         rst_sys_n,
  input  logic                         gameplay_valid,
  output logic                         gameplay_ready,
  input  game_types_pkg::audio_event_t gameplay_event,
  output logic                         audio_valid,
  input  logic                         audio_ready,
  output game_types_pkg::audio_event_t audio_event
);
  import game_types_pkg::*;

  audio_event_t event_q;
  logic         valid_q;

  assign gameplay_ready = !valid_q || audio_ready;
  assign audio_valid     = valid_q;
  assign audio_event     = event_q;

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      valid_q <= 1'b0;
      event_q <= '0;
    end else if (gameplay_ready) begin
      valid_q <= gameplay_valid;
      if (gameplay_valid) begin
        event_q <= gameplay_event;
      end
    end
  end
endmodule
