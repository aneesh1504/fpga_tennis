# Out-of-context synthesis for the Board B transport gateway.
# This does not create a bitstream or access connected hardware.

set output_dir [file normalize ".build/vivado/board_b_top_ooc"]
file mkdir $output_dir

set source_files [list \
    rtl/common/uart_rx.sv \
    rtl/common/uart_tx.sv \
    rtl/common/sync_fifo.sv \
    rtl/bridge/frame_forwarder.sv \
    rtl/bridge/board_b_top.sv]

foreach source_file $source_files {
    read_verilog -sv $source_file
}

synth_design \
    -top board_b_top \
    -part xc7s50csga324-1 \
    -mode out_of_context \
    -flatten_hierarchy rebuilt

create_clock -name clk -period 10.000 [get_ports clk]
check_timing -verbose -file [file join $output_dir check_timing.rpt]
report_utilization -file [file join $output_dir utilization.rpt]
report_timing_summary \
    -delay_type min_max \
    -max_paths 10 \
    -file [file join $output_dir timing_summary.rpt]

puts "OOC_SYNTH_PART [get_property PART [current_design]]"
puts "OOC_SYNTH_OUTPUT $output_dir"
puts "OOC_SYNTH_PASS"
