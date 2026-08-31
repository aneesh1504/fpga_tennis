# Out-of-context synthesis for the simulation-verified Board A structural core.
# This does not create a bitstream or access connected hardware.

set output_dir [file normalize ".build/vivado/board_a_system_ooc"]
file mkdir $output_dir

set source_files [list \
    rtl/packages/protocol_pkg.sv \
    rtl/packages/game_types_pkg.sv \
    rtl/packages/video_types_pkg.sv \
    rtl/common/reset_sync.sv \
    rtl/common/tick_gen.sv \
    rtl/common/uart_rx.sv \
    rtl/common/crc16_ccitt.sv \
    rtl/common/frame_unescaper.sv \
    rtl/common/motion_packet_decoder.sv \
    rtl/common/motion_transport_rx.sv \
    rtl/common/dual_motion_transport_rx.sv \
    rtl/game/gameplay_tuning_pkg.sv \
    rtl/game/swing_detector.sv \
    rtl/game/scripted_opponent.sv \
    rtl/game/shot_mapper.sv \
    rtl/game/ball_physics.sv \
    rtl/game/tennis_rules.sv \
    rtl/game/rally_judge.sv \
    rtl/game/game_engine.sv \
    rtl/game/render_state_mailbox.sv \
    rtl/audio/tone_voice.sv \
    rtl/audio/pwm_audio_out.sv \
    rtl/audio/audio_engine.sv \
    rtl/video/video_timing_720p.sv \
    rtl/video/perspective_projector.sv \
    rtl/video/court_renderer.sv \
    rtl/video/net_renderer.sv \
    rtl/video/sprite_renderer.sv \
    rtl/video/font_rom.sv \
    rtl/video/ui_renderer.sv \
    rtl/video/pixel_compositor.sv \
    rtl/video/video_pipeline.sv \
    rtl/board_a_system.sv]

foreach source_file $source_files {
    read_verilog -sv $source_file
}

synth_design \
    -top board_a_system \
    -part xc7s50csga324-1 \
    -mode out_of_context \
    -flatten_hierarchy rebuilt

create_clock -name clk_sys -period 10.000 [get_ports clk_sys]
create_clock -name clk_pix -period 13.468 [get_ports clk_pix]
set_clock_groups -asynchronous \
    -group [get_clocks clk_sys] \
    -group [get_clocks clk_pix]

check_timing -verbose -file [file join $output_dir check_timing.rpt]
report_utilization -file [file join $output_dir utilization.rpt]
report_timing_summary \
    -delay_type min_max \
    -max_paths 10 \
    -file [file join $output_dir timing_summary.rpt]

puts "OOC_SYNTH_PART [get_property PART [current_design]]"
puts "OOC_SYNTH_OUTPUT $output_dir"
puts "OOC_SYNTH_PASS"
