package game_types_pkg;
  localparam logic [15:0] GAME_INTERFACE_VERSION = 16'h0100;

  typedef struct packed {
    logic               valid;
    logic               forehand;
    logic               upward;
    logic        [15:0] strength;
    logic signed [15:0] aim_x;
    logic signed [15:0] lift;
  } swing_event_t;

  typedef enum logic [2:0] {
    AUDIO_EVENT_NONE   = 3'd0,
    AUDIO_EVENT_HIT    = 3'd1,
    AUDIO_EVENT_BOUNCE = 3'd2,
    AUDIO_EVENT_FAULT  = 3'd3,
    AUDIO_EVENT_SCORE  = 3'd4
  } audio_event_kind_t;

  typedef struct packed {
    logic              valid;
    audio_event_kind_t kind;
    logic              player_two;
    logic       [15:0] strength;
  } audio_event_t;
endpackage
