set repo_root [file normalize [file join [file dirname [info script]] ..]]
set output_dir [file normalize [file join $::env(LOCALAPPDATA) fpga_tennis_vivado board_a_transport_diagnostic]]
file mkdir $output_dir
cd $output_dir
foreach source_file [list rtl/packages/protocol_pkg.sv rtl/common/reset_sync.sv rtl/common/tick_gen.sv rtl/common/uart_rx.sv rtl/common/crc16_ccitt.sv rtl/common/frame_unescaper.sv rtl/common/motion_packet_decoder.sv rtl/common/motion_transport_rx.sv rtl/board_a_transport_diagnostic_top.sv] {
    read_verilog -sv [file join $repo_root $source_file]
}
read_xdc [file join $repo_root config board_a_transport_diagnostic.xdc]
synth_design -top board_a_transport_diagnostic_top -part xc7s50csga324-1
opt_design
place_design
phys_opt_design
route_design
report_utilization -file [file join $output_dir utilization.rpt]
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $output_dir timing_summary.rpt]
report_drc -file [file join $output_dir drc.rpt]
set setup_path [get_timing_paths -delay_type max -max_paths 1]
set hold_path [get_timing_paths -delay_type min -max_paths 1]
if {[llength $setup_path] == 0 || [llength $hold_path] == 0} { error "Timing paths unavailable" }
set wns [get_property SLACK [lindex $setup_path 0]]
set whs [get_property SLACK [lindex $hold_path 0]]
puts "DIAGNOSTIC_WNS_NS $wns"
puts "DIAGNOSTIC_WHS_NS $whs"
if {$wns < 0.0 || $whs < 0.0} { error "Diagnostic implementation timing failed" }
set bitstream_path [file join $output_dir board_a_transport_diagnostic.bit]
write_bitstream -force $bitstream_path
puts "DIAGNOSTIC_BITSTREAM $bitstream_path"
puts "DIAGNOSTIC_BUILD_PASS"
