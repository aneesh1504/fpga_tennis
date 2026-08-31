# Read-only Vivado Hardware Manager probe for a connected Boolean Board.
# This script does not program, reset, or otherwise modify the FPGA.

proc emit_property {object property_name} {
    if {[catch {get_property $property_name $object} value]} {
        puts "PROBE_PROPERTY $property_name=<unavailable>"
    } else {
        puts "PROBE_PROPERTY $property_name=$value"
    }
}

set probe_exit_code 0

if {[catch {
    puts "PROBE_BEGIN"
    puts "PROBE_VIVADO_VERSION [version -short]"
    open_hw_manager
    connect_hw_server -allow_non_jtag

    set targets [get_hw_targets]
    puts "PROBE_TARGET_COUNT [llength $targets]"
    if {[llength $targets] == 0} {
        error "No hardware targets were discovered"
    }

    foreach target $targets {
        puts "PROBE_TARGET $target"
        current_hw_target $target
        open_hw_target

        set devices [get_hw_devices]
        puts "PROBE_DEVICE_COUNT [llength $devices]"
        foreach device $devices {
            puts "PROBE_DEVICE $device"
            emit_property $device PART
            emit_property $device IDCODE
            emit_property $device DEVICE_ID
            emit_property $device REGISTER.IR.BIT_LEN
        }

        close_hw_target
    }

    disconnect_hw_server
    close_hw_manager
    puts "PROBE_PASS"
} probe_error]} {
    puts stderr "PROBE_FAIL $probe_error"
    set probe_exit_code 1
    catch {close_hw_target}
    catch {disconnect_hw_server}
    catch {close_hw_manager}
}

exit $probe_exit_code
