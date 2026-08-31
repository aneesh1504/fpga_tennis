package video_types_pkg;
  localparam logic [15:0] VIDEO_INTERFACE_VERSION = 16'h0100;

  typedef struct packed {
    logic               valid;
    logic               player_one_connected;
    logic               player_two_connected;
    logic               player_two_serves;
    logic signed [15:0] player_one_x_q8_8;
    logic signed [15:0] player_one_y_q8_8;
    logic signed [15:0] player_two_x_q8_8;
    logic signed [15:0] player_two_y_q8_8;
    logic        [3:0]  player_one_anim;
    logic        [3:0]  player_two_anim;
    logic               ball_visible;
    logic signed [15:0] ball_x_q8_8;
    logic signed [15:0] ball_y_q8_8;
    logic signed [15:0] ball_z_q8_8;
    logic        [1:0]  player_one_points;
    logic        [1:0]  player_two_points;
    logic        [3:0]  player_one_games;
    logic        [3:0]  player_two_games;
    logic        [1:0]  player_one_sets;
    logic        [1:0]  player_two_sets;
    logic        [15:0] player_one_swing_meter;
    logic        [15:0] player_two_swing_meter;
  } game_render_state_t;
endpackage
