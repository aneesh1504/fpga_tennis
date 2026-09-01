set bitstream_path [file normalize [file join $::env(LOCALAPPDATA) fpga_tennis_vivado board_a_transport_diagnostic board_a_transport_diagnostic.bit]]
if {![file exists $bitstream_path]} { error "Diagnostic bitstream missing: $bitstream_path" }
cd [file dirname $bitstream_path]
open_hw_manager
connect_hw_server -allow_non_jtag
set targets [get_hw_targets *887235230329A*]
if {[llength $targets] != 1} { error "Expected target 887235230329A, found [llength $targets]" }
open_hw_target [lindex $targets 0]
set devices [get_hw_devices xc7s50_0]
if {[llength $devices] != 1} { error "Expected one xc7s50_0, found [llength $devices]" }
set device [lindex $devices 0]
set_property PROGRAM.FILE $bitstream_path $device
program_hw_devices $device
refresh_hw_device $device
puts "DIAGNOSTIC_PROGRAM_TARGET [lindex $targets 0]"
puts "DIAGNOSTIC_PROGRAM_DEVICE $device"
puts "DIAGNOSTIC_PROGRAM_PASS"
close_hw_target
disconnect_hw_server
close_hw_manager
