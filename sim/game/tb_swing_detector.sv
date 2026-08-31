module tb_swing_detector;
  import protocol_pkg::*;
  import game_types_pkg::*;

  logic clk_sys = 1'b0;
  logic rst_sys_n = 1'b0;
  logic sample_valid;
  logic sample_ready;
  motion_sample_t sample;
  transport_health_t health;
  logic swing_valid;
  logic swing_ready;
  swing_event_t swing_event;
  integer event_count;
  swing_event_t captured_event;

  always #5 clk_sys = ~clk_sys;

  swing_detector dut (.*);

  always @(posedge clk_sys) begin
    if (swing_valid && swing_ready) begin
      event_count <= event_count + 1;
      captured_event <= swing_event;
    end
  end

  task automatic send_sample(
    input integer gx,
    input integer gy,
    input integer gz,
    input integer az,
    input integer qy,
    input logic stale_value
  );
    begin
      while (!sample_ready) @(negedge clk_sys);
      @(negedge clk_sys);
      sample = '0;
      sample.valid = 1'b1;
      sample.stale = stale_value;
      sample.gyro_x = gx;
      sample.gyro_y = gy;
      sample.gyro_z = gz;
      sample.accel_z = az;
      sample.quat_y = qy;
      sample_valid = 1'b1;
      @(negedge clk_sys);
      sample_valid = 1'b0;
    end
  endtask

  task automatic settle_cooldown;
    integer index;
    begin
      for (index = 0; index < 10; index = index + 1) begin
        send_sample(50, 50, 50, 0, 0, 1'b0);
      end
    end
  endtask

  initial begin
    sample_valid = 1'b0;
    sample = '0;
    health = '0;
    health.connected = 1'b1;
    health.calibrated = 1'b1;
    swing_ready = 1'b1;
    event_count = 0;
    captured_event = '0;

    repeat (2) @(negedge clk_sys);
    rst_sys_n = 1'b1;

    repeat (8) send_sample(100, 120, 80, 0, 0, 1'b0);
    if (event_count != 0) $fatal(1, "idle/noise emitted a swing");

    repeat (6) send_sample(0, 600, 0, 0, 0, 1'b0);
    if (event_count != 0) $fatal(1, "slow repositioning emitted a swing");

    health.calibrated = 1'b0;
    send_sample(0, 2200, 0, 1000, 0, 1'b0);
    send_sample(0, 3000, 0, 1000, 0, 1'b0);
    send_sample(0, 1000, 0, 1000, 0, 1'b0);
    health.calibrated = 1'b1;
    if (event_count != 0) $fatal(1, "uncalibrated input emitted a swing");

    send_sample(0, 2200, 0, 1000, 0, 1'b1);
    send_sample(0, 3000, 0, 1000, 0, 1'b1);
    if (event_count != 0) $fatal(1, "stale input emitted a swing");

    send_sample(0, 1900, 0, 1200, 1000, 1'b0);
    send_sample(0, 2600, 0, 1200, 1000, 1'b0);
    send_sample(0, 3000, 0, 1200, 1000, 1'b0);
    send_sample(0, 2400, 0, 1200, 1000, 1'b0);
    wait (event_count == 1);
    if (!captured_event.forehand || !captured_event.upward
        || (captured_event.strength == 0) || (captured_event.aim_x != 1000)) begin
      $fatal(1, "forehand classification/payload mismatch");
    end

    settle_cooldown();
    send_sample(0, -1900, 0, -800, -1200, 1'b0);
    send_sample(0, -2700, 0, -800, -1200, 1'b0);
    send_sample(0, -3100, 0, -800, -1200, 1'b0);
    send_sample(0, -2500, 0, -800, -1200, 1'b0);
    wait (event_count == 2);
    if (captured_event.forehand || captured_event.upward
        || (captured_event.aim_x != -1200)) begin
      $fatal(1, "backhand classification/payload mismatch");
    end

    settle_cooldown();
    send_sample(0, 1800, 0, 0, 0, 1'b0);
    send_sample(0, 2200, 0, 0, 0, 1'b0);
    send_sample(0, 1600, 0, 0, 0, 1'b0);
    wait (event_count == 3);
    if (captured_event.strength == 0) $fatal(1, "threshold-edge swing was not bounded/mapped");

    settle_cooldown();
    send_sample(0, 32760, 0, 32767, 32767, 1'b0);
    send_sample(-32768, 32767, 32767, 32767, 32767, 1'b0);
    send_sample(0, 100, 0, 0, 0, 1'b0);
    wait (event_count == 4);
    if (captured_event.strength != 16'hffff) $fatal(1, "saturated swing did not clamp strength");

    repeat (10) @(posedge clk_sys);
    if (event_count != 4) $fatal(1, "detector double-triggered");
    $display("PASS: deterministic swing traces and saturation");
    $finish;
  end
endmodule
