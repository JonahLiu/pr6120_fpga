# build.tcl
# A Vivado script that demonstrates a very simple RTL-to-bitstream batch flow
#
# NOTE: typical usage would be "vivado -mode tcl -source build.tcl"
#       or in vival tcl shell "source build.tcl"

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
read_verilog ../../src/device/device_top.v
read_verilog ../../src/e1000/config_rom.v
read_verilog ../../src/e1000/e1000_register.v
read_verilog ../../src/e1000/e1000_regs.v
read_verilog ../../src/e1000/e1000_top.v
read_verilog ../../src/e1000/eeprom_emu.v
read_verilog ../../src/e1000/shift_mdio.v
read_verilog ../../src/e1000/shift_eeprom.v
read_verilog ../../src/e1000/intr_ctrl.v
read_verilog ../../src/pci/pci_axi_top.v
read_verilog ../../src/pci/pci_lc.v
read_verilog ../../src/pci/pci_target.v
#read_verilog ../../src/pci/pci32_0.v

file mkdir pci32_0
file copy -force ../../ip/pci32_0.xci pci32_0
read_ip pci32_0/pci32_0.xci
generate_target -force {all} [get_ips pci32_0]

file mkdir clock_generation
file copy -force ../../ip/clock_generation.xci clock_generation
read_ip clock_generation/clock_generation.xci
generate_target -force {all} [get_ips clock_generation]

file mkdir ila_axi_0
file copy -force ../../ip/ila_axi_0.xci ila_axi_0
file copy -force ../../ip/ila_axi_0.xml ila_axi_0
read_ip ila_axi_0/ila_axi_0.xci
set_property GENERATE_SYNTH_CHECKPOINT FALSE [get_files ila_axi_0/ila_axi_0.xci]
generate_target -force {all} [get_ips ila_axi_0]

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
read_xdc ../../src/device/timing.xdc

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
synth_design -top device_top -part $part -flatten rebuilt
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
