set output_dir [file normalize [file join $::env(LOCALAPPDATA) fpga_tennis_vivado board_a_transport_bringup]]
file mkdir $output_dir

foreach source_file [list \
    rtl/packages/protocol_pkg.sv \
    rtl/common/reset_sync.sv \
    rtl/common/tick_gen.sv \
    rtl/common/uart_rx.sv \
    rtl/common/crc16_ccitt.sv \
    rtl/common/frame_unescaper.sv \
    rtl/common/motion_packet_decoder.sv \
    rtl/common/motion_transport_rx.sv \
    rtl/board_a_transport_bringup_top.sv] {
    read_verilog -sv $source_file
}
read_xdc config/board_a_transport_bringup.xdc

synth_design -top board_a_transport_bringup_top -part xc7s50csga324-1
opt_design
place_design
phys_opt_design
route_design

report_utilization -file [file join $output_dir utilization.rpt]
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $output_dir timing_summary.rpt]
report_drc -file [file join $output_dir drc.rpt]

set setup_path [get_timing_paths -delay_type max -max_paths 1]
if {[llength $setup_path] == 0} {
    error "No setup timing path was available"
}
set worst_setup_slack [get_property SLACK [lindex $setup_path 0]]
puts "BRINGUP_WNS_NS $worst_setup_slack"
if {$worst_setup_slack < 0.0} {
    error "Bring-up implementation failed setup timing with WNS $worst_setup_slack ns"
}

set bitstream_path [file join $output_dir board_a_transport_bringup.bit]
write_bitstream -force $bitstream_path
puts "BRINGUP_BITSTREAM $bitstream_path"
puts "BRINGUP_BUILD_PASS"
