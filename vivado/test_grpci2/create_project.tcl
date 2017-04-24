set projName grpci2_device
set part xc7k325tffg900-1
set top grpci2_device
set simTop test_grpci2_device
set configMode SPIx1

set outputDir ./

create_project $projName $outputDir -part $part -force

set projDir [get_property directory [current_project]]

add_files -fileset sources_1 -force -norecurse {
	../../src/grpci2/grlib/amba.vhd
	../../src/grpci2/grlib/config.vhd
	../../src/grpci2/grlib/config_types.vhd
	../../src/grpci2/grlib/devices.vhd
	../../src/grpci2/grlib/dftlib.vhd
	../../src/grpci2/grlib/stdlib.vhd
	../../src/grpci2/grlib/synciotest.vhd
	../../src/grpci2/grlib/version.vhd
	../../src/grpci2/grlib/util.vhd
	../../src/grpci2/gaisler/grpci2.vhd
	../../src/grpci2/gaisler/grpci2_ahb_mst.vhd
	../../src/grpci2/gaisler/grpci2_phy.vhd
	../../src/grpci2/gaisler/grpci2_phy_wrapper.vhd
	../../src/grpci2/gaisler/pci.vhd
	../../src/grpci2/gaisler/pcilib2.vhd
	../../src/grpci2/techmap/syncram_2p.vhd
	../../src/grpci2/techmap/memory_inferred.vhd
	../../src/grpci2/techmap/allmem.vhd
	../../src/grpci2/techmap/gencomp.vhd
	../../src/grpci2/techmap/memrwcol.vhd
	../../src/grpci2/techmap/netcomp.vhd
	../../src/grpci2/grpci2_device.vhd
}
set_property library grlib [get_files [glob ../../src/grpci2/grlib/*.vhd]]
set_property library gaisler [get_files [glob ../../src/grpci2/gaisler/*.vhd]]
set_property library techmap [get_files [glob ../../src/grpci2/techmap/*.vhd]]

#set_property FILE_TYPE {VHDL 2008} [get_files [glob ../../src/grpci2/grlib/*.vhd]]

add_files -fileset sim_1 -force -norecurse {
	../../src/test/test_grpci2_device.v
	../../src/test/pci_behavioral_master.v
	../../src/test/pci_behavioral_target.v
	../../src/test/pci_blue_arbiter.v
}

set_property include_dirs ../../src/test [get_filesets sim_1]

#import_ip -srcset sources_1 {
#	../xci/tri_mode_ethernet_mac_0.xci
#	../xci/selectio_wiz_0.xci
#	../xci/axi_interconnect_0.xci
#	../xci/vdma.xci
#	../xci/clk_wiz_0.xci
#	../xci/clk_wiz_1.xci
#	../xci/proc_sys_reset_0.xci
#	../xci/vio_debug.xci
#	../xci/ila_36.xci
#}

add_files -fileset constrs_1 -force -norecurse {
	../../src/grpci2/grpci2_device.xdc
}

set_property top $top [current_fileset]
set_property top $simTop [get_filesets sim_1]
set_property target_language verilog [current_project]

set_property -name {steps.synth_design.args.more options} -value {-mode out_of_context} -objects [get_runs synth_1]

update_compile_order

#launch_runs synth_1 -verbose
#wait_on_run synth_1

#launch_runs impl_1 -to_step write_bitstream -verbose
#wait_on_run impl_1

#set bitstream_fn [format "%s/%s.runs/impl_1/%s.bit" $projDir $projName $top]
#set cfgmem_fn [format "%s/%s.runs/impl_1/%s.mcs" $projDir $projName $projName]

#write_cfgmem -force -format mcs \
#	-interface $configMode \
#	-loadbit "up 0x0 $bitstream_fn" \
#	-file $cfgmem_fn

puts "INFO: Project created"

