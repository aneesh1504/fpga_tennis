module tennis_rules (
  input  logic       clk_sys,
  input  logic       rst_sys_n,
  input  logic       match_reset,
  input  logic       point_valid,
  input  logic       point_winner_two,
  output logic       player_two_serves,
  output logic [1:0] player_one_points,
  output logic [1:0] player_two_points,
  output logic [3:0] player_one_games,
  output logic [3:0] player_two_games,
  output logic [1:0] player_one_sets,
  output logic [1:0] player_two_sets,
  output logic       advantage_valid,
  output logic       advantage_player_two,
  output logic       game_won_pulse,
  output logic       set_won_pulse
);
  logic game_winner_two;
  logic [4:0] winner_games_after;
  logic [4:0] loser_games;

  task automatic award_game(input logic winner_two);
    begin
      game_winner_two = winner_two;
      player_one_points <= 2'd0;
      player_two_points <= 2'd0;
      advantage_valid <= 1'b0;
      game_won_pulse <= 1'b1;
      player_two_serves <= ~player_two_serves;

      if (winner_two) begin
        winner_games_after = {1'b0, player_two_games} + 1'b1;
        loser_games = {1'b0, player_one_games};
        if (((winner_games_after >= 6) && (winner_games_after >= loser_games + 2))
            || (winner_games_after == 7)) begin
          player_two_sets <= player_two_sets + 1'b1;
          player_one_games <= '0;
          player_two_games <= '0;
          set_won_pulse <= 1'b1;
        end else begin
          player_two_games <= winner_games_after[3:0];
        end
      end else begin
        winner_games_after = {1'b0, player_one_games} + 1'b1;
        loser_games = {1'b0, player_two_games};
        if (((winner_games_after >= 6) && (winner_games_after >= loser_games + 2))
            || (winner_games_after == 7)) begin
          player_one_sets <= player_one_sets + 1'b1;
          player_one_games <= '0;
          player_two_games <= '0;
          set_won_pulse <= 1'b1;
        end else begin
          player_one_games <= winner_games_after[3:0];
        end
      end
    end
  endtask

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      player_two_serves <= 1'b0;
      player_one_points <= '0;
      player_two_points <= '0;
      player_one_games <= '0;
      player_two_games <= '0;
      player_one_sets <= '0;
      player_two_sets <= '0;
      advantage_valid <= 1'b0;
      advantage_player_two <= 1'b0;
      game_won_pulse <= 1'b0;
      set_won_pulse <= 1'b0;
      game_winner_two <= 1'b0;
      winner_games_after <= '0;
      loser_games <= '0;
    end else begin
      game_won_pulse <= 1'b0;
      set_won_pulse <= 1'b0;
      if (match_reset) begin
        player_two_serves <= 1'b0;
        player_one_points <= '0;
        player_two_points <= '0;
        player_one_games <= '0;
        player_two_games <= '0;
        player_one_sets <= '0;
        player_two_sets <= '0;
        advantage_valid <= 1'b0;
        advantage_player_two <= 1'b0;
      end else if (point_valid) begin
        if ((player_one_points == 3) && (player_two_points == 3)) begin
          if (!advantage_valid) begin
            advantage_valid <= 1'b1;
            advantage_player_two <= point_winner_two;
          end else if (advantage_player_two == point_winner_two) begin
            award_game(point_winner_two);
          end else begin
            advantage_valid <= 1'b0;
          end
        end else if (point_winner_two) begin
          if (player_two_points == 3) begin
            award_game(1'b1);
          end else begin
            player_two_points <= player_two_points + 1'b1;
          end
        end else begin
          if (player_one_points == 3) begin
            award_game(1'b0);
          end else begin
            player_one_points <= player_one_points + 1'b1;
          end
        end
      end
    end
  end
endmodule
