# build.tcl
# A Vivado script that demonstrates a very simple RTL-to-bitstream batch flow
#
# NOTE: typical usage would be "vivado -mode tcl -source build.tcl"
#       or in vival tcl shell "source build.tcl"

#
# STEP#0: define output directory area.
#
set projName nic_device
set outputDir ./output
set part xc7k325tffg900-2
set top device_top

# clean up old outputs
close_design -quiet
close_project -quiet
file delete -force $outputDir

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
read_verilog ../../src/pci/pci_axi_top.v
read_verilog ../../src/pci/pci_lc.v
read_verilog ../../src/pci/pci_target.v
read_verilog ../../src/pci/pci_master.v
read_verilog ../../src/pci/pci_master_ctrl.v
read_verilog ../../src/pci/pci_master_rpath.v
read_verilog ../../src/pci/pci_master_wpath.v
read_verilog ../../src/pci/fifo_async.v
read_verilog ../../src/e1000/config_rom.v
read_verilog ../../src/e1000/e1000_register.v
read_verilog ../../src/e1000/e1000_regs.v
read_verilog ../../src/e1000/e1000_top.v
read_verilog ../../src/e1000/eeprom_emu.v
read_verilog ../../src/e1000/shift_mdio.v
read_verilog ../../src/e1000/shift_eeprom.v
read_verilog ../../src/e1000/intr_ctrl.v
read_verilog ../../src/e1000/tx_path.v
read_verilog ../../src/e1000/tx_desc_ctrl.v
read_verilog ../../src/e1000/tx_engine.v
read_verilog ../../src/e1000/axi_idma.v
read_verilog ../../src/e1000/axi_mux.v
read_verilog ../../src/e1000/axi_ram.v

file mkdir pci32_0
file copy -force ../../ip/pci32_0.xci pci32_0
read_ip pci32_0/pci32_0.xci
#set_property GENERATE_SYNTH_CHECKPOINT FALSE [get_files pci32_0/pci32_0.xci]
upgrade_ip [get_ips pci32_0]
generate_target -force {all} [get_ips pci32_0]

file mkdir nic_clk_gen
file copy -force ../../ip/nic_clk_gen.xci nic_clk_gen
read_ip nic_clk_gen/nic_clk_gen.xci
upgrade_ip [get_ips nic_clk_gen]
set_property GENERATE_SYNTH_CHECKPOINT FALSE [get_files nic_clk_gen/nic_clk_gen.xci]
generate_target -force {all} [get_ips nic_clk_gen]

file mkdir ila_0
file copy -force ../../ip/ila_0.xci ila_0
file copy -force ../../ip/ila_0.xml ila_0
read_ip ila_0/ila_0.xci
upgrade_ip [get_ips ila_0]
set_property GENERATE_SYNTH_CHECKPOINT FALSE [get_files ila_0/ila_0.xci]
generate_target -force {all} [get_ips ila_0]

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
synth_design -top $top -part $part -flatten rebuilt
write_checkpoint -force [format "$outputDir/%s_synth" $projName]
#report_timing_summary -file $outputDir/post_synth_timing_summary.rpt
#report_power -file $outputDir/post_synth_power.rpt

#
# STEP#3: run placement and logic optimization, report utilization and timing estimates, write checkpoint design
#
opt_design
#power_opt_design
place_design
#phys_opt_design
write_debug_probes -force [format "$outputDir/%s_debug.ltx" $projName]
write_checkpoint -force [format "$outputDir/%s_place" $projName]
#report_timing_summary -file $outputDir/post_place_timing_summary.rpt

#
# STEP#4: run router, write verilog and xdc out
#
route_design
write_checkpoint -force [format "$outputDir/%s_route" $projName]
write_verilog -force -include_xilinx_libs -mode funcsim [format "$outputDir/%s_funcsim.v" $projName]
write_verilog -force -include_xilinx_libs -mode timesim -sdf_anno true [format "$outputDir/%s_timesim.v" $projName]
write_sdf -force -mode timesim [format "$outputDir/%s_timesim.sdf" $projName]
write_xdc -force -constraints INVALID $outputDir/ignored_constraints.xdc
write_csv -force [format "$outputDir/%s_pins.csv" $projName]

#
# STEP#5: generate final reports
#
report_timing_summary -no_detailed_paths -file $outputDir/post_route_timing_summary.rpt
report_timing -sort_by group -delay_type min_max -file $outputDir/post_route_timing.rpt
report_clocks -file $outputDir/clocks.rpt
report_clock_utilization -file $outputDir/clock_utilization.rpt
report_clock_networks -file $outputDir/clock_networks.rpt
report_clock_interaction -file $outputDir/clock_interaction.rpt
report_datasheet -file $outputDir/datasheet.rpt
report_utilization -file $outputDir/utilization.rpt
report_utilization -hierarchical -hierarchical_depth 3 -file $outputDir/utilization_hierarchical.rpt
report_io -file $outputDir/io.rpt
report_power -file $outputDir/power.rpt
report_drc -file $outputDir/drc.rpt

#
# STEP#6: generate a bitstream, write bmm file
#
write_bitstream -force [format "$outputDir/%s.bit" $projName]
write_bmm -force -quiet [format "$outputDir/%s.bmm" $projName]

