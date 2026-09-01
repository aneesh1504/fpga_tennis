set bitstream_path [file normalize [file join $::env(LOCALAPPDATA) fpga_tennis_vivado board_a_transport_bringup board_a_transport_bringup.bit]]
if {![file exists $bitstream_path]} {
    error "Bring-up bitstream does not exist: $bitstream_path"
}

open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
set devices [get_hw_devices xc7s50_0]
if {[llength $devices] != 1} {
    error "Expected exactly one xc7s50_0 hardware device, found [llength $devices]"
}
set device [lindex $devices 0]
set_property PROGRAM.FILE $bitstream_path $device
program_hw_devices $device
refresh_hw_device $device
puts "PROGRAM_DEVICE $device"
puts "PROGRAM_BITSTREAM $bitstream_path"
puts "PROGRAM_PASS"
close_hw_target
disconnect_hw_server
close_hw_manager
