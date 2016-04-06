# build.tcl
# A Vivado script that demonstrates a very simple RTL-to-bitstream batch flow
#
# NOTE: typical usage would be "vivado -mode tcl -source build.tcl"
#       or in vival tcl shell "source build.tcl"

# Clean up cache
close_design -quiet
close_project -quiet

#
# STEP#0: define output directory area.
#
set outputDir ./output
set part xc7k325tffg900-2
file mkdir $outputDir
set_part $part
#
# STEP#1: setup design sources and constraints
#
#read_vhdl -library bftLib [ glob ./Sources/hdl/bftLib/*.vhdl ]
#read_vhdl ./Sources/hdl/bft.vhdl
#read_verilog [ glob ./Sources/hdl/*.v ]
#read_xdc ./Sources/bft_full.xdc
read_verilog ../../src/mps/device_top.v
read_verilog ../../src/mps/pci_lc.v
read_verilog ../../src/mps/mps_top.v
read_verilog ../../src/pci/pci_axi_top.v
read_verilog ../../src/pci/pci_target.v
read_verilog ../../src/uart16550/raminfr.v
read_verilog ../../src/uart16550/uart_debug_if.v
read_verilog ../../src/uart16550/uart_receiver.v
read_verilog ../../src/uart16550/uart_regs.v
read_verilog ../../src/uart16550/uart_rfifo.v
read_verilog ../../src/uart16550/uart_sync_flops.v
read_verilog ../../src/uart16550/uart_tfifo.v
read_verilog ../../src/uart16550/uart_transmitter.v
read_verilog ../../src/uart16550/uart_axi.v
read_verilog ../../src/uart16550/multi_serial.v
#read_verilog ../../src/pci/pci32_0.v

file mkdir pci32_mps
file copy -force ../../ip/pci32_mps.xci pci32_mps
read_ip pci32_mps/pci32_mps.xci
generate_target -force {all} [get_ips pci32_mps]

file mkdir uart_clk_gen
file copy -force ../../ip/uart_clk_gen.xci uart_clk_gen
read_ip uart_clk_gen/uart_clk_gen.xci
set_property GENERATE_SYNTH_CHECKPOINT FALSE [get_files uart_clk_gen/uart_clk_gen.xci]
generate_target -force {all} [get_ips uart_clk_gen]

file mkdir ila_0
file copy -force ../../ip/ila_0.xci ila_0
file copy -force ../../ip/ila_0.xml ila_0
read_ip ila_0/ila_0.xci
set_property GENERATE_SYNTH_CHECKPOINT FALSE [get_files ila_0/ila_0.xci]
generate_target -force {all} [get_ips ila_0]

#file mkdir ila_axi_0
#create_ip -name ila -vendor xilinx.com -library ip -version 5.0 -module_name ila_axi_0 
#set_property -dict [list CONFIG.C_SLOT_0_AXI_ID_WIDTH {0} CONFIG.C_SLOT_0_AXI_PROTOCOL {AXI4LITE} CONFIG.C_MONITOR_TYPE {AXI} CONFIG.C_NUM_OF_PROBES {19} CONFIG.C_ENABLE_ILA_AXI_MON {true}] [get_ips ila_axi_0]
#generate_target -force {all} [get_ips ila_axi_0]
#synth_ip [get_ips ila_axi_0]

read_xdc ../../constraints/io_default.xdc
read_xdc ../../constraints/pci.xdc
read_xdc ../../constraints/eth.xdc
read_xdc ../../constraints/can.xdc
read_xdc ../../constraints/uart.xdc
read_xdc ../../constraints/device.xdc
read_xdc ../../src/mps/timing.xdc

#generate_target -force {all} [get_files ../../src/pci/pci32_0.xci]
#generate_target -force {all} [get_files ../../src/device/clock_generation.xci]
#synth_ip -force [get_files ../../src/pci/pci32_0.xci]
#synth_ip -force [get_files ../../src/device/clock_generation.xci]
#synth_ip -force [get_ips pci32_0]
#synth_ip -force [get_ips clock_generation]
#set_property GENERATE_SYNTH_CHECKPOINT true [get_files ../../src/pci/pci32_0.xci]
#set_property GENERATE_SYNTH_CHECKPOINT true [get_files ../../src/device/clock_generation.xci]

#
## STEP#2: run synthesis, report utilization and timing estimates, write checkpoint design
#
synth_design -top device_top -part $part -flatten rebuilt -include_dirs {../../src/uart16550}
write_checkpoint -force $outputDir/post_synth
report_timing_summary -file $outputDir/post_synth_timing_summary.rpt
report_power -file $outputDir/post_synth_power.rpt
#
# STEP#3: run placement and logic optimization, report utilization and timing estimates, write checkpoint design
#
opt_design
write_debug_probes -force $outputDir/debug.ltx
#power_opt_design
place_design
#phys_opt_design
write_checkpoint -force $outputDir/post_place
report_timing_summary -file $outputDir/post_place_timing_summary.rpt
#
# STEP#4: run router, report actual utilization and timing, write checkpoint design, run drc, write verilog and xdc out
#
route_design
write_checkpoint -force $outputDir/post_route
report_timing_summary -file $outputDir/post_route_timing_summary.rpt
report_timing -sort_by group -max_paths 100 -path_type summary -file $outputDir/post_route_timing.rpt
report_clock_utilization -file $outputDir/clock_util.rpt
report_utilization -file $outputDir/post_route_util.rpt
report_power -file $outputDir/post_route_power.rpt
report_drc -file $outputDir/post_imp_drc.rpt
write_verilog -force -mode timesim -sdf_anno true $outputDir/post_imp.v
write_xdc -no_fixed_only -force $outputDir/post_imp.xdc
#
# STEP#5: generate a bitstream
#
write_bitstream -force $outputDir/device_top.bit
