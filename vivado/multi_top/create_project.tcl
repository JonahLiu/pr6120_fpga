set projName multi_top
set part xc7k325tffg900-1
set top multi_top
set simTop test_multi_top

set outputDir ./

create_project $projName $outputDir -part $part -force

add_files -fileset [current_fileset] -force -norecurse {
    ../../src/common/fifo_async.v
    ../../src/common/axis_realign.v
    ../../src/common/axi_mdma.v
    ../../src/common/axi_rdma.v
    ../../src/common/axi_wdma.v
    ../../src/common/axi_mux.v
    ../../src/common/axi_ram.v
}
set_property library common [get_files [glob ../../src/common/*.v]]

add_files -fileset [current_fileset] -force -norecurse {
	../../src/device/can_clk_gen.v
	../../src/device/CRC_gen.v
	../../src/device/mpc_pci_wrapper.v
	../../src/device/mps_pci_wrapper.v
	../../src/device/multi_top.v
	../../src/device/nic_clk_gen.v
	../../src/device/nic_pci_wrapper.v
	../../src/device/phy_ft.v
	../../src/device/phy_switch.v
	../../src/device/post_switch.v
	../../src/device/rgmii_if.v
	../../src/device/rgmii_rx.v
	../../src/device/rgmii_tx.v
	../../src/device/uart_clk_gen.v
}

add_files -fileset [current_fileset] -force -norecurse {
    ../../src/e1000/config_rom.v
    ../../src/e1000/e1000_register.v
    ../../src/e1000/e1000_regs.v
    ../../src/e1000/e1000_top.v
    ../../src/e1000/eeprom_emu.v
    ../../src/e1000/shift_mdio.v
    ../../src/e1000/shift_eeprom.v
    ../../src/e1000/intr_ctrl.v
    ../../src/e1000/tx_path.v
    ../../src/e1000/tx_desc_ctrl.v
    ../../src/e1000/tx_engine.v
    ../../src/e1000/tx_frame.v
    ../../src/e1000/rx_path.v
    ../../src/e1000/rx_desc_ctrl.v
    ../../src/e1000/rx_engine.v
    ../../src/e1000/rx_frame.v
    ../../src/e1000/rx_checksum.v
    ../../src/e1000/mac_axis.v
    ../../src/e1000/dna.v
}
set_property library e1000 [get_files [glob ../../src/e1000/*.v]]

add_files -fileset [current_fileset] -force -norecurse {
    ../../src/mac/Clk_ctrl.v
    ../../src/mac/Phy_int.v
    ../../src/mac/MAC_rx.v
    ../../src/mac/MAC_rx/CRC_chk.v
    ../../src/mac/MAC_rx/MAC_rx_ctrl.v
    ../../src/mac/MAC_rx/MAC_rx_FF.v
    ../../src/mac/MAC_tx.v
    ../../src/mac/MAC_tx/CRC_gen.v
    ../../src/mac/MAC_tx/flow_ctrl.v
    ../../src/mac/MAC_tx/MAC_tx_Ctrl.v
    ../../src/mac/MAC_tx/MAC_tx_FF.v
    ../../src/mac/MAC_tx/Ramdon_gen.v
    ../../src/mac/TECH/duram.v
    ../../src/mac/TECH/CLK_DIV2.v
    ../../src/mac/TECH/CLK_SWITCH.v
}
set_property library mac [get_files [glob ../../src/mac/*.v]]
set_property library mac [get_files [glob ../../src/mac/*/*.v]]

add_files -fileset [current_fileset] -force -norecurse {
    ../../src/mpc/mpc_top.v
    ../../src/sja1000/can_acf.v
    ../../src/sja1000/can_axi.v
    ../../src/sja1000/can_bsp.v
    ../../src/sja1000/can_btl.v
    ../../src/sja1000/can_crc.v
    ../../src/sja1000/can_fifo.v
    ../../src/sja1000/can_ibo.v
    ../../src/sja1000/can_register.v
    ../../src/sja1000/can_register_asyn.v
    ../../src/sja1000/can_register_asyn_syn.v
    ../../src/sja1000/can_register_syn.v
    ../../src/sja1000/can_registers.v
    ../../src/sja1000/can_top.v
    ../../src/sja1000/multi_can.v
}
set_property library can [get_files [glob ../../src/sja1000/*.v]]
set_property library can [get_files [glob ../../src/mpc/*.v]]

add_files -fileset [current_fileset] -force -norecurse {
    ../../src/mps/mps_top.v
    ../../src/uart16550/raminfr.v
    ../../src/uart16550/uart_debug_if.v
    ../../src/uart16550/uart_receiver.v
    ../../src/uart16550/uart_regs.v
    ../../src/uart16550/uart_rfifo.v
    ../../src/uart16550/uart_sync_flops.v
    ../../src/uart16550/uart_tfifo.v
    ../../src/uart16550/uart_transmitter.v
    ../../src/uart16550/uart_axi.v
    ../../src/uart16550/multi_serial.v
}
set_property library uart [get_files [glob ../../src/uart16550/*.v]]
set_property library uart [get_files [glob ../../src/mps/*.v]]

add_files -fileset [current_fileset] -force -norecurse {
	../../src/pci/grpci2_axi_lite_tgt.v
	../../src/pci/grpci2_axi_mst.v
	../../src/pci/grpci2_master_ctrl.v
	../../src/pci/pci_master_rpath.v
	../../src/pci/pci_master_wpath.v
	../../src/pci/pci_mux.v
}
set_property library pci [get_files [glob ../../src/pci/*.v]]

add_files -fileset [current_fileset] -force -norecurse {
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
set_property library pci [get_files [glob ../../src/grpci2/*.vhd]]

#add_files -fileset [current_fileset] -force -norecurse {
import_ip -srcset [current_fileset] {
	../../ip/vio_debug.xci
}

add_files -fileset [current_fileset -simset] -force -norecurse {
	../../src/test/test_multi_top.v
	../../src/test/eth_pkt_gen.v
	../../src/test/pci_behavioral_master.v
	../../src/test/pci_behavioral_target.v
	../../src/test/pci_blue_arbiter.v
	../../src/test/axi_memory_model.v
	../../src/test/axi_master_model.v
}

set_property include_dirs ../../src/mac [current_fileset]
set_property include_dirs ../../src/mac [current_fileset -simset]
set_property include_dirs ../../src/test [current_fileset -simset]

add_files -fileset [current_fileset -constrset] -force -norecurse {
    ../../constraints/io_default.xdc
    ../../constraints/pci.xdc
    ../../constraints/eth.xdc
    ../../constraints/can.xdc
    ../../constraints/uart.xdc
    ../../constraints/device.xdc
    ../../constraints/timing.xdc
    ../../constraints/debug.xdc
}
set_property target_constrs_file {../../constraints/debug.xdc} [current_fileset -constrset]
set_property top $top [current_fileset]
set_property top $simTop [current_fileset -simset]
set_property target_language verilog [current_project]

#set_property -name {steps.synth_design.args.more options} -value {-mode out_of_context} -objects [get_runs synth_1]

update_compile_order


