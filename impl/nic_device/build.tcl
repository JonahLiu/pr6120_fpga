################################################################################
# build.tcl
# A Vivado script that demonstrates a very simple RTL-to-bitstream batch flow
#
# NOTE: typical usage would be "vivado -mode tcl -source build.tcl"
#       or in vival tcl shell "source build.tcl"
################################################################################

################################################################################
# STEP#0: define output directory area.
#
set projName nic_device
set outputDir ./output
set ipDir ./ip
set part xc7k325tffg900-2
set top device_top

# clean up old outputs
close_design -quiet
close_project -quiet
file delete -force $outputDir

file mkdir $outputDir
set_part $part

set_param general.maxThreads 8
set_param synth.maxThreads 8

################################################################################
# STEP#1: setup design sources and constraints
#
################################################################################
# Import Source Files
#read_vhdl -library bftLib [ glob ./Sources/hdl/bftLib/*.vhdl ]
#read_vhdl ./Sources/hdl/bft.vhdl
#read_verilog [ glob ./Sources/hdl/*.v ]
#read_xdc ./Sources/bft_full.xdc
read_verilog ../../src/device/device_top.v
read_verilog ../../src/device/nic_clk_gen.v
read_verilog ../../src/pci/pci_axi_top.v
read_verilog ../../src/pci/pci_lc.v
read_verilog ../../src/pci/pci_target.v
read_verilog ../../src/pci/pci_master.v
read_verilog ../../src/pci/pci_master_ctrl.v
read_verilog ../../src/pci/pci_master_rpath.v
read_verilog ../../src/pci/pci_master_wpath.v
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
read_verilog ../../src/e1000/tx_frame.v
read_verilog ../../src/e1000/rx_path.v
read_verilog ../../src/e1000/rx_desc_ctrl.v
read_verilog ../../src/e1000/rx_engine.v
read_verilog ../../src/e1000/rx_frame.v
read_verilog ../../src/e1000/rx_checksum.v
read_verilog ../../src/e1000/axis_realign.v
read_verilog ../../src/e1000/axi_mdma.v
read_verilog ../../src/e1000/axi_rdma.v
read_verilog ../../src/e1000/axi_wdma.v
read_verilog ../../src/e1000/axi_mux.v
read_verilog ../../src/e1000/axi_ram.v
read_verilog ../../src/e1000/mac_axis.v
read_verilog ../../src/mac/Clk_ctrl.v
read_verilog ../../src/mac/Phy_int.v
read_verilog ../../src/mac/MAC_rx.v
read_verilog ../../src/mac/MAC_rx/CRC_chk.v
read_verilog ../../src/mac/MAC_rx/MAC_rx_ctrl.v
read_verilog ../../src/mac/MAC_rx/MAC_rx_FF.v
read_verilog ../../src/mac/MAC_tx.v
read_verilog ../../src/mac/MAC_tx/CRC_gen.v
read_verilog ../../src/mac/MAC_tx/flow_ctrl.v
read_verilog ../../src/mac/MAC_tx/MAC_tx_Ctrl.v
read_verilog ../../src/mac/MAC_tx/MAC_tx_FF.v
read_verilog ../../src/mac/MAC_tx/Ramdon_gen.v
read_verilog ../../src/mac/TECH/duram.v
read_verilog ../../src/mac/TECH/CLK_DIV2.v
read_verilog ../../src/mac/TECH/CLK_SWITCH.v
read_verilog ../../src/common/fifo_async.v

################################################################################
# Import IP Cores
file mkdir $ipDir/pci32_0
file copy -force ../../ip/pci32_0.xci $ipDir/pci32_0
read_ip $ipDir/pci32_0/pci32_0.xci
upgrade_ip [get_ips pci32_0]
#set_property GENERATE_SYNTH_CHECKPOINT FALSE [get_files $ipDir/pci32_0/pci32_0.xci]
#generate_target -force {all} [get_ips pci32_0]

file mkdir $ipDir/ila_0
file copy -force ../../ip/ila_0.xci $ipDir/ila_0
file copy -force ../../ip/ila_0.xml $ipDir/ila_0
read_ip $ipDir/ila_0/ila_0.xci
upgrade_ip [get_ips ila_0]
set_property GENERATE_SYNTH_CHECKPOINT FALSE [get_files $ipDir/ila_0/ila_0.xci]
#generate_target -force {all} [get_ips ila_0]

################################################################################
# Import Constraints
read_xdc ../../constraints/io_default.xdc
read_xdc ../../constraints/pci.xdc
read_xdc ../../constraints/eth.xdc
read_xdc ../../constraints/can.xdc
read_xdc ../../constraints/uart.xdc
read_xdc ../../constraints/device.xdc
read_xdc ../../src/device/timing.xdc

################################################################################
# STEP#2: run synthesis, report utilization and timing estimates, write checkpoint design
#
################################################################################
# Generate targets if necessory
#generate_target -force {all} [get_files ../../src/pci/pci32_0.xci]
#generate_target -force {all} [get_files ../../src/device/clock_generation.xci]
#synth_ip -force [get_files ../../src/pci/pci32_0.xci]
#synth_ip -force [get_files ../../src/device/clock_generation.xci]
#synth_ip -force [get_ips pci32_0]
#synth_ip -force [get_ips clock_generation]
#set_property GENERATE_SYNTH_CHECKPOINT true [get_files ../../src/pci/pci32_0.xci]
#set_property GENERATE_SYNTH_CHECKPOINT true [get_files ../../src/device/clock_generation.xci]

foreach ip [get_ips] {
	generate_target -force {all} $ip
}

synth_design -top $top -part $part -include_dirs {../../src/mac} -gated_clock_conversion on
write_checkpoint -force [format "$outputDir/%s_synth" $projName]
#report_timing_summary -file $outputDir/post_synth_timing_summary.rpt
#report_power -file $outputDir/post_synth_power.rpt

################################################################################
# STEP#3: run placement and logic optimization, report utilization and timing estimates, write checkpoint design
#
opt_design
#power_opt_design
place_design
#phys_opt_design
write_checkpoint -force [format "$outputDir/%s_place" $projName]
#report_timing_summary -file $outputDir/post_place_timing_summary.rpt

################################################################################
# STEP#4: run router, write verilog and xdc out
#
route_design
write_checkpoint -force [format "$outputDir/%s_route" $projName]
write_verilog -force -include_xilinx_libs -mode funcsim [format "$outputDir/%s_funcsim.v" $projName]
write_verilog -force -include_xilinx_libs -mode timesim -sdf_anno true [format "$outputDir/%s_timesim.v" $projName]
write_sdf -force -mode timesim [format "$outputDir/%s_timesim.sdf" $projName]
write_xdc -force -constraints INVALID $outputDir/ignored_constraints.xdc
write_csv -force [format "$outputDir/%s_pins.csv" $projName]

################################################################################
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

################################################################################
# STEP#6: generate a bitstream, write bmm file and other configuration files
#
set bitstream_fn [format "$outputDir/%s.bit" $projName]
set probes_fn [format "$outputDir/%s.ltx" $projName]

write_bitstream -force $bitstream_fn
write_debug_probes -force $probes_fn

#set output_fn [format "$outputDir/%s.bmm" $projName]
#write_bmm -force -quiet $output_fn

set output_fn [format "$outputDir/%s_spi_x1.mcs" $projName]
write_cfgmem -force -format MCS -interface SPIx1 -loadbit "up 0x0 $bitstream_fn" $output_fn 

set output_fn [format "$outputDir/%s_bpi_x16.mcs" $projName]
write_cfgmem -force -format MCS -interface BPIx16 -loadbit "up 0x0 $bitstream_fn" $output_fn

