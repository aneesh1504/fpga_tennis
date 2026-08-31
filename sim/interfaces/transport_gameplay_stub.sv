module transport_gameplay_stub (
  input  logic                            clk_sys,
  input  logic                            rst_sys_n,
  input  logic                            transport_valid,
  output logic                            transport_ready,
  input  protocol_pkg::motion_sample_t    transport_sample,
  input  protocol_pkg::transport_health_t transport_health,
  output logic                            gameplay_valid,
  input  logic                            gameplay_ready,
  output protocol_pkg::motion_sample_t    gameplay_sample,
  output protocol_pkg::transport_health_t gameplay_health
);
  import protocol_pkg::*;

  motion_sample_t    sample_q;
  transport_health_t health_q;
  logic              valid_q;

  assign transport_ready = !valid_q || gameplay_ready;
  assign gameplay_valid  = valid_q;
  assign gameplay_sample = sample_q;
  assign gameplay_health = health_q;

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      valid_q  <= 1'b0;
      sample_q <= '0;
      health_q <= '0;
    end else if (transport_ready) begin
      valid_q <= transport_valid;
      if (transport_valid) begin
        sample_q <= transport_sample;
        health_q <= transport_health;
      end
    end
  end
endmodule
