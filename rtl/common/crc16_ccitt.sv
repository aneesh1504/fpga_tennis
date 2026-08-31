`timescale 1ns/1ps

module crc16_ccitt (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        clear,
  input  logic        byte_valid,
  input  logic [7:0]  byte_data,
  output logic [15:0] crc
);
  function automatic logic [15:0] update_crc(
    input logic [15:0] crc_in,
    input logic [7:0]  data_in
  );
    logic [15:0] value;
    integer bit_index;
    begin
      value = crc_in ^ {data_in, 8'h00};
      for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
        if (value[15]) value = (value << 1) ^ 16'h1021;
        else           value = value << 1;
      end
      update_crc = value;
    end
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n || clear) begin
      crc <= 16'hffff;
    end else if (byte_valid) begin
      crc <= update_crc(crc, byte_data);
    end
  end
endmodule
