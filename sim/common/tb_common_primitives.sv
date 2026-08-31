`timescale 1ns/1ps

module tb_common_primitives;
  localparam int unsigned CLOCK_HZ = 1_000_000;
  localparam int unsigned BAUD = 100_000;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;

  logic tx_valid;
  logic tx_ready;
  logic [7:0] tx_data;
  logic serial_loop;
  logic tx_busy;
  logic rx_valid;
  logic [7:0] rx_data;
  logic rx_error;
  logic [31:0] rx_error_count;
  logic mismatch_serial;
  logic mismatch_valid;
  logic [7:0] mismatch_data;
  logic mismatch_error;
  logic [31:0] mismatch_error_count;

  logic crc_clear;
  logic crc_valid;
  logic [7:0] crc_data;
  logic [15:0] crc;

  logic fifo_in_valid;
  logic fifo_in_ready;
  logic [7:0] fifo_in_data;
  logic fifo_out_valid;
  logic fifo_out_ready;
  logic [7:0] fifo_out_data;
  logic [3:0] fifo_level;
  logic [3:0] fifo_high_water;
  logic fifo_overflow;
  logic fifo_underflow;

  logic async_reset_n;
  logic synced_reset_n;
  logic millisecond_tick;
  integer tick_count;

  integer received_count;
  logic [7:0] received [0:7];
  integer mismatch_count;
  logic [7:0] mismatch_last_data;
  integer index;
  reg [71:0] check_text;

  uart_tx #(.CLOCK_HZ(CLOCK_HZ), .BAUD(BAUD)) tx (
    .clk, .rst_n, .data_valid(tx_valid), .data_ready(tx_ready),
    .data(tx_data), .serial_tx(serial_loop), .busy(tx_busy)
  );

  uart_rx #(.CLOCK_HZ(CLOCK_HZ), .BAUD(BAUD)) rx (
    .clk, .rst_n, .serial_rx(serial_loop), .data_valid(rx_valid),
    .data(rx_data), .framing_error(rx_error),
    .framing_error_count(rx_error_count)
  );

  uart_rx #(.CLOCK_HZ(CLOCK_HZ), .BAUD(BAUD)) mismatch_rx (
    .clk, .rst_n, .serial_rx(mismatch_serial),
    .data_valid(mismatch_valid), .data(mismatch_data),
    .framing_error(mismatch_error),
    .framing_error_count(mismatch_error_count)
  );

  crc16_ccitt crc_dut (
    .clk, .rst_n, .clear(crc_clear), .byte_valid(crc_valid),
    .byte_data(crc_data), .crc
  );

  sync_fifo #(.WIDTH(8), .DEPTH(8)) fifo (
    .clk, .rst_n, .in_valid(fifo_in_valid), .in_ready(fifo_in_ready),
    .in_data(fifo_in_data), .out_valid(fifo_out_valid),
    .out_ready(fifo_out_ready), .out_data(fifo_out_data),
    .level(fifo_level), .high_water(fifo_high_water),
    .overflow(fifo_overflow), .underflow(fifo_underflow)
  );

  reset_sync reset_dut (
    .clk, .async_rst_n(async_reset_n), .sync_rst_n(synced_reset_n)
  );

  tick_gen #(.CLOCK_HZ(100), .TICK_HZ(10)) tick_dut (
    .clk, .rst_n, .tick(millisecond_tick)
  );

  always @(posedge clk) begin
    if (rx_valid) begin
      received[received_count] <= rx_data;
      received_count <= received_count + 1;
    end
    if (millisecond_tick) tick_count <= tick_count + 1;
    if (mismatch_valid) begin
      mismatch_count <= mismatch_count + 1;
      mismatch_last_data <= mismatch_data;
    end
  end

  task automatic send_uart(input logic [7:0] value);
    begin
      while (!tx_ready) @(posedge clk);
      @(negedge clk);
      tx_data = value;
      tx_valid = 1'b1;
      @(negedge clk);
      tx_valid = 1'b0;
    end
  endtask

  task automatic crc_byte(input logic [7:0] value);
    begin
      @(negedge clk);
      crc_data = value;
      crc_valid = 1'b1;
      @(negedge clk);
      crc_valid = 1'b0;
    end
  endtask

  task automatic drive_mismatched_uart(
    input logic [7:0] value,
    input logic       bad_stop
  );
    integer bit_number;
    begin
      mismatch_serial = 1'b0;
      #101;
      for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
        mismatch_serial = value[bit_number];
        #101;
      end
      mismatch_serial = !bad_stop;
      #101;
      mismatch_serial = 1'b1;
      #202;
    end
  endtask

  initial begin
    tx_valid = 1'b0;
    tx_data = '0;
    mismatch_serial = 1'b1;
    crc_clear = 1'b0;
    crc_valid = 1'b0;
    crc_data = '0;
    fifo_in_valid = 1'b0;
    fifo_in_data = '0;
    fifo_out_ready = 1'b0;
    received_count = 0;
    mismatch_count = 0;
    mismatch_last_data = '0;
    async_reset_n = 1'b0;
    tick_count = 0;
    check_text = "123456789";

    repeat (4) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
    async_reset_n = 1'b1;
    @(posedge clk);
    #1;
    if (synced_reset_n) $fatal(1, "reset synchronizer released too early");
    @(posedge clk);
    #1;
    if (!synced_reset_n) $fatal(1, "reset synchronizer did not release after two stages");

    send_uart(8'h00);
    send_uart(8'h55);
    send_uart(8'haa);
    send_uart(8'hff);
    wait (received_count == 4);
    repeat (2) @(posedge clk);
    if (received[0] !== 8'h00 || received[1] !== 8'h55 ||
        received[2] !== 8'haa || received[3] !== 8'hff) begin
      $fatal(1, "UART loopback byte mismatch");
    end
    if (rx_error_count != 0) $fatal(1, "unexpected UART framing error");
    if (tick_count < 40 || tick_count > 50) $fatal(1, "fractional tick generator count %0d", tick_count);

    drive_mismatched_uart(8'h3c, 1'b0);
    if (mismatch_count != 1 || mismatch_last_data !== 8'h3c) $fatal(1, "UART mismatch tolerance failed");
    drive_mismatched_uart(8'ha5, 1'b1);
    if (mismatch_error_count != 1) $fatal(1, "UART framing error count was %0d", mismatch_error_count);

    crc_clear = 1'b1;
    @(posedge clk);
    crc_clear = 1'b0;
    for (index = 8; index >= 0; index = index - 1) begin
      crc_byte(check_text[index*8 +: 8]);
    end
    @(posedge clk);
    if (crc !== 16'h29b1) $fatal(1, "CRC check value was %04x", crc);

    for (index = 0; index < 8; index = index + 1) begin
      @(negedge clk);
      if (!fifo_in_ready) $fatal(1, "FIFO became full early");
      fifo_in_data = index[7:0];
      fifo_in_valid = 1'b1;
    end
    @(negedge clk);
    fifo_in_valid = 1'b0;
    if (fifo_level != 8 || fifo_high_water != 8) $fatal(1, "FIFO level/high-water mismatch");

    @(negedge clk);
    fifo_in_data = 8'hee;
    fifo_in_valid = 1'b1;
    @(posedge clk);
    #1;
    if (!fifo_overflow) $fatal(1, "FIFO overflow was not reported");
    @(negedge clk);
    fifo_in_valid = 1'b0;

    for (index = 0; index < 8; index = index + 1) begin
      @(negedge clk);
      if (!fifo_out_valid || fifo_out_data !== index[7:0]) $fatal(1, "FIFO order mismatch at %0d", index);
      fifo_out_ready = 1'b1;
      @(negedge clk);
      fifo_out_ready = 1'b0;
    end
    @(negedge clk);
    fifo_out_ready = 1'b1;
    @(posedge clk);
    #1;
    if (!fifo_underflow) $fatal(1, "FIFO underflow was not reported");

    $display("PASS: reset/tick-independent UART, CRC, and synchronous FIFO primitives");
    $finish;
  end
endmodule
