`timescale 1ns/1ps

module uart_rx #(
  parameter int unsigned CLOCK_HZ = 100_000_000,
  parameter int unsigned BAUD     = 115_200
) (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       serial_rx,
  output logic       data_valid,
  output logic [7:0] data,
  output logic       framing_error,
  output logic [31:0] framing_error_count
);
  localparam int unsigned CLKS_PER_BIT = (CLOCK_HZ + (BAUD / 2)) / BAUD;
  localparam int unsigned COUNT_WIDTH  = (CLKS_PER_BIT <= 2) ? 1 : $clog2(CLKS_PER_BIT);

  typedef enum logic [1:0] {IDLE, START, DATA_BITS, STOP} state_t;
  state_t state_q;

  logic rx_meta_q;
  logic rx_sync_q;
  logic [COUNT_WIDTH-1:0] count_q;
  logic [2:0] bit_index_q;
  logic [7:0] shift_q;

  initial begin
    if (BAUD == 0 || CLKS_PER_BIT < 4) begin
      $fatal(1, "uart_rx requires at least four clocks per bit");
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_meta_q <= 1'b1;
      rx_sync_q <= 1'b1;
    end else begin
      rx_meta_q <= serial_rx;
      rx_sync_q <= rx_meta_q;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q              <= IDLE;
      count_q              <= '0;
      bit_index_q          <= '0;
      shift_q              <= '0;
      data                 <= '0;
      data_valid           <= 1'b0;
      framing_error        <= 1'b0;
      framing_error_count  <= '0;
    end else begin
      data_valid    <= 1'b0;
      framing_error <= 1'b0;

      case (state_q)
        IDLE: begin
          if (!rx_sync_q) begin
            count_q <= (CLKS_PER_BIT / 2) - 1;
            state_q <= START;
          end
        end

        START: begin
          if (count_q != 0) begin
            count_q <= count_q - 1'b1;
          end else if (!rx_sync_q) begin
            count_q     <= CLKS_PER_BIT - 1;
            bit_index_q <= '0;
            state_q     <= DATA_BITS;
          end else begin
            state_q <= IDLE;
          end
        end

        DATA_BITS: begin
          if (count_q != 0) begin
            count_q <= count_q - 1'b1;
          end else begin
            shift_q[bit_index_q] <= rx_sync_q;
            count_q <= CLKS_PER_BIT - 1;
            if (bit_index_q == 3'd7) begin
              state_q <= STOP;
            end else begin
              bit_index_q <= bit_index_q + 1'b1;
            end
          end
        end

        STOP: begin
          if (count_q != 0) begin
            count_q <= count_q - 1'b1;
          end else begin
            if (rx_sync_q) begin
              data       <= shift_q;
              data_valid <= 1'b1;
            end else begin
              framing_error <= 1'b1;
              if (framing_error_count != 32'hffff_ffff) begin
                framing_error_count <= framing_error_count + 1'b1;
              end
            end
            state_q <= IDLE;
          end
        end

        default: state_q <= IDLE;
      endcase
    end
  end
endmodule
