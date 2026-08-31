`timescale 1ns/1ps

module tb_board_b_top;
  localparam int CLOCK_HZ = 1_000_000;
  localparam int BAUD = 100_000;
  localparam int CLKS_PER_BIT = CLOCK_HZ / BAUD;
  localparam int FIFO_DEPTH = 16;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;

  logic ble_uart_rx;
  logic ble_uart_tx;
  logic pmod_uart_rx;
  logic pmod_uart_tx;
  logic [31:0] forward_input_bytes;
  logic [31:0] forward_output_bytes;
  logic [31:0] forward_complete_frames;
  logic [31:0] forward_fifo_overflows;
  logic [4:0] forward_fifo_high_water;
  logic [31:0] reverse_input_bytes;
  logic [31:0] reverse_output_bytes;
  logic [31:0] reverse_complete_frames;
  logic [31:0] reverse_fifo_overflows;
  logic [4:0] reverse_fifo_high_water;
  logic [31:0] ble_rx_framing_errors;
  logic [31:0] pmod_rx_framing_errors;

  logic pmod_monitor_valid;
  logic [7:0] pmod_monitor_data;
  logic pmod_monitor_error;
  logic [31:0] pmod_monitor_error_count;
  logic ble_monitor_valid;
  logic [7:0] ble_monitor_data;
  logic ble_monitor_error;
  logic [31:0] ble_monitor_error_count;
  logic [7:0] pmod_received [0:7];
  logic [7:0] ble_received [0:7];
  integer pmod_count;
  integer ble_count;

  board_b_top #(
    .CLOCK_HZ(CLOCK_HZ), .BLE_BAUD(BAUD), .PMOD_BAUD(BAUD),
    .FIFO_DEPTH(FIFO_DEPTH)
  ) dut (
    .clk, .rst_n, .ble_uart_rx, .ble_uart_tx, .pmod_uart_rx,
    .pmod_uart_tx, .forward_input_bytes, .forward_output_bytes,
    .forward_complete_frames, .forward_fifo_overflows,
    .forward_fifo_high_water, .reverse_input_bytes,
    .reverse_output_bytes, .reverse_complete_frames,
    .reverse_fifo_overflows, .reverse_fifo_high_water,
    .ble_rx_framing_errors, .pmod_rx_framing_errors
  );

  uart_rx #(.CLOCK_HZ(CLOCK_HZ), .BAUD(BAUD)) pmod_monitor (
    .clk, .rst_n, .serial_rx(pmod_uart_tx),
    .data_valid(pmod_monitor_valid), .data(pmod_monitor_data),
    .framing_error(pmod_monitor_error),
    .framing_error_count(pmod_monitor_error_count)
  );

  uart_rx #(.CLOCK_HZ(CLOCK_HZ), .BAUD(BAUD)) ble_monitor (
    .clk, .rst_n, .serial_rx(ble_uart_tx),
    .data_valid(ble_monitor_valid), .data(ble_monitor_data),
    .framing_error(ble_monitor_error),
    .framing_error_count(ble_monitor_error_count)
  );

  always @(posedge clk) begin
    if (pmod_monitor_valid) begin
      pmod_received[pmod_count] <= pmod_monitor_data;
      pmod_count <= pmod_count + 1;
    end
    if (ble_monitor_valid) begin
      ble_received[ble_count] <= ble_monitor_data;
      ble_count <= ble_count + 1;
    end
  end

  task automatic drive_ble_byte(input logic [7:0] value);
    integer bit_number;
    begin
      @(negedge clk);
      ble_uart_rx = 1'b0;
      repeat (CLKS_PER_BIT) @(negedge clk);
      for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
        ble_uart_rx = value[bit_number];
        repeat (CLKS_PER_BIT) @(negedge clk);
      end
      ble_uart_rx = 1'b1;
      repeat (CLKS_PER_BIT) @(negedge clk);
    end
  endtask

  task automatic drive_pmod_byte(input logic [7:0] value);
    integer bit_number;
    begin
      @(negedge clk);
      pmod_uart_rx = 1'b0;
      repeat (CLKS_PER_BIT) @(negedge clk);
      for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
        pmod_uart_rx = value[bit_number];
        repeat (CLKS_PER_BIT) @(negedge clk);
      end
      pmod_uart_rx = 1'b1;
      repeat (CLKS_PER_BIT) @(negedge clk);
    end
  endtask

  initial begin
    ble_uart_rx = 1'b1;
    pmod_uart_rx = 1'b1;
    pmod_count = 0;
    ble_count = 0;
    repeat (5) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;

    fork
      begin
        drive_ble_byte(8'h01);
        drive_ble_byte(8'h7d);
        drive_ble_byte(8'h2a);
        drive_ble_byte(8'h0a);
      end
      begin
        drive_pmod_byte(8'ha5);
        drive_pmod_byte(8'h5a);
        drive_pmod_byte(8'h0a);
      end
    join

    wait (pmod_count == 4 && ble_count == 3);
    repeat (10) @(posedge clk);
    if (pmod_received[0] !== 8'h01 || pmod_received[1] !== 8'h7d ||
        pmod_received[2] !== 8'h2a || pmod_received[3] !== 8'h0a) begin
      $fatal(1, "forward UART path changed bytes");
    end
    if (ble_received[0] !== 8'ha5 || ble_received[1] !== 8'h5a || ble_received[2] !== 8'h0a) begin
      $fatal(1, "reverse UART path changed bytes");
    end
    if (forward_input_bytes != 4 || forward_output_bytes != 4 || forward_complete_frames != 1) begin
      $fatal(1, "forward UART counters mismatch");
    end
    if (reverse_input_bytes != 3 || reverse_output_bytes != 3 || reverse_complete_frames != 1) begin
      $fatal(1, "reverse UART counters mismatch");
    end
    if (forward_fifo_overflows != 0 || reverse_fifo_overflows != 0 ||
        ble_rx_framing_errors != 0 || pmod_rx_framing_errors != 0 ||
        pmod_monitor_error_count != 0 || ble_monitor_error_count != 0) begin
      $fatal(1, "unexpected full-duplex bridge error");
    end

    $display("PASS: Board B simultaneous full-duplex byte-transparent UART forwarding");
    $finish;
  end
endmodule
