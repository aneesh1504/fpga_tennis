module tb_tennis_rules;
  logic clk_sys = 1'b0;
  logic rst_sys_n = 1'b0;
  logic match_reset;
  logic point_valid;
  logic point_winner_two;
  logic player_two_serves;
  logic [1:0] player_one_points;
  logic [1:0] player_two_points;
  logic [3:0] player_one_games;
  logic [3:0] player_two_games;
  logic [1:0] player_one_sets;
  logic [1:0] player_two_sets;
  logic advantage_valid;
  logic advantage_player_two;
  logic game_won_pulse;
  logic set_won_pulse;
  integer game_index;
  integer point_index;

  always #5 clk_sys = ~clk_sys;
  tennis_rules dut (.*);

  task automatic score_point(input logic winner_two);
    begin
      @(negedge clk_sys);
      point_winner_two = winner_two;
      point_valid = 1'b1;
      @(negedge clk_sys);
      point_valid = 1'b0;
      #1;
    end
  endtask

  task automatic reset_match;
    begin
      @(negedge clk_sys);
      match_reset = 1'b1;
      @(negedge clk_sys);
      match_reset = 1'b0;
      #1;
    end
  endtask

  initial begin
    match_reset = 1'b0;
    point_valid = 1'b0;
    point_winner_two = 1'b0;
    repeat (2) @(negedge clk_sys);
    rst_sys_n = 1'b1;

    score_point(1'b0);
    if (player_one_points != 1) $fatal(1, "0->15 failed");
    score_point(1'b0);
    if (player_one_points != 2) $fatal(1, "15->30 failed");
    score_point(1'b0);
    if (player_one_points != 3) $fatal(1, "30->40 failed");
    score_point(1'b0);
    if ((player_one_games != 1) || (player_one_points != 0) || !player_two_serves) begin
      $fatal(1, "game award or serve rotation failed");
    end

    reset_match();
    repeat (3) score_point(1'b0);
    repeat (3) score_point(1'b1);
    score_point(1'b0);
    if (!advantage_valid || advantage_player_two) $fatal(1, "player one advantage failed");
    score_point(1'b1);
    if (advantage_valid) $fatal(1, "advantage cancellation failed");
    score_point(1'b1);
    if (!advantage_valid || !advantage_player_two) $fatal(1, "player two advantage failed");
    score_point(1'b1);
    if ((player_two_games != 1) || advantage_valid) $fatal(1, "deuce game award failed");

    reset_match();
    for (game_index = 0; game_index < 6; game_index = game_index + 1) begin
      for (point_index = 0; point_index < 4; point_index = point_index + 1) begin
        score_point(1'b0);
      end
    end
    if ((player_one_sets != 1) || (player_one_games != 0)
        || (player_two_games != 0)) begin
      $fatal(1, "set progression failed");
    end

    $display("PASS: tennis point, deuce, game, serve, and set progression");
    $finish;
  end
endmodule
