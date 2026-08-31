module font_rom #(
  parameter MEM_FILE = "assets/generated_mem/font8x8.mem"
) (
  input  logic       clk_pix,
  input  logic [9:0] address,
  output logic [7:0] row_bits
);
  logic [7:0] font_memory [0:767];

  initial $readmemh(MEM_FILE, font_memory);

  always_ff @(posedge clk_pix) begin
    if (address < 768) row_bits <= font_memory[address];
    else               row_bits <= 8'h00;
  end
endmodule
