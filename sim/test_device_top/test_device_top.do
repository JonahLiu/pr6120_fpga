onbreak {quit -f}
onerror {quit -f}

#set vlog_opts {+acc}
set vlog_opts {-incr}

set vcom_opts {-93}

vlib work

vlog $vlog_opts ../../src/test/test_device_top.v
vlog $vlog_opts ../../src/test/eth_pkt_gen.v

vlog $vlog_opts ../../src/test/pci_behavioral_master.v
vlog $vlog_opts ../../src/test/pci_behavioral_target.v
vlog +incdir+../../src/test $vlog_opts ../../src/test/pci_blue_arbiter.v

vlog $vlog_opts ../../src/device/device_top.v
vlog $vlog_opts ../../src/device/nic_clk_gen.v
vlog $vlog_opts ../../src/device/can_clk_gen.v
vlog $vlog_opts ../../src/device/uart_clk_gen.v
vlog $vlog_opts ../../src/device/nic_wrapper.v
vlog $vlog_opts ../../src/device/mpc_wrapper.v
vlog $vlog_opts ../../src/device/mps_wrapper.v

vlog $vlog_opts ../../src/pci/pci_target.v
vlog $vlog_opts ../../src/pci/pci_master.v
vlog $vlog_opts ../../src/pci/pci_master_wpath.v
vlog $vlog_opts ../../src/pci/pci_master_rpath.v
vlog $vlog_opts ../../src/pci/pci_master_ctrl.v
vlog $vlog_opts ../../src/pci/pci_multi.v
vlog $vlog_opts ../../ip/pci32_p0.v
vlog $vlog_opts ../../ip/pci32_p1.v
vlog $vlog_opts ../../ip/pci32_p2.v

vlog $vlog_opts ../../src/common/fifo_async.v
vlog $vlog_opts ../../src/common/axi_mux.v
vlog $vlog_opts ../../src/common/axi_mdma.v
vlog $vlog_opts ../../src/common/axi_rdma.v
vlog $vlog_opts ../../src/common/axi_wdma.v
vlog $vlog_opts ../../src/common/axi_ram.v
vlog $vlog_opts ../../src/common/axis_realign.v

vlog $vlog_opts ../../src/e1000/e1000_top.v
vlog $vlog_opts ../../src/e1000/e1000_regs.v
vlog $vlog_opts ../../src/e1000/e1000_register.v
vlog $vlog_opts ../../src/e1000/shift_eeprom.v
vlog $vlog_opts ../../src/e1000/eeprom_emu.v
vlog $vlog_opts ../../src/e1000/config_rom.v
vlog $vlog_opts ../../src/e1000/mdio_emu.v
vlog $vlog_opts ../../src/e1000/shift_mdio.v
vlog $vlog_opts ../../src/e1000/intr_ctrl.v

vlog $vlog_opts ../../src/e1000/mac_axis.v
vlog $vlog_opts ../../src/e1000/tx_desc_ctrl.v
vlog $vlog_opts ../../src/e1000/tx_engine.v
vlog $vlog_opts ../../src/e1000/tx_frame.v
vlog $vlog_opts ../../src/e1000/tx_path.v
vlog $vlog_opts ../../src/e1000/rx_desc_ctrl.v
vlog $vlog_opts ../../src/e1000/rx_engine.v
vlog $vlog_opts ../../src/e1000/rx_frame.v
vlog $vlog_opts ../../src/e1000/rx_checksum.v
vlog $vlog_opts ../../src/e1000/rx_path.v

vlog $vlog_opts ../../src/mac/Clk_ctrl.v
vlog $vlog_opts ../../src/mac/Phy_int.v
vlog $vlog_opts +incdir+../../src/mac ../../src/mac/MAC_rx.v
vlog $vlog_opts ../../src/mac/MAC_rx/CRC_chk.v
vlog $vlog_opts ../../src/mac/MAC_rx/MAC_rx_ctrl.v
vlog $vlog_opts +incdir+../../src/mac ../../src/mac/MAC_rx/MAC_rx_FF.v
vlog $vlog_opts +incdir+../../src/mac ../../src/mac/MAC_tx.v
vlog $vlog_opts ../../src/mac/MAC_tx/CRC_gen.v
vlog $vlog_opts ../../src/mac/MAC_tx/flow_ctrl.v
vlog $vlog_opts ../../src/mac/MAC_tx/MAC_tx_Ctrl.v
vlog $vlog_opts +incdir+../../src/mac ../../src/mac/MAC_tx/MAC_tx_FF.v
vlog $vlog_opts ../../src/mac/MAC_tx/Ramdon_gen.v
vlog $vlog_opts ../../src/mac/TECH/duram.v
vlog $vlog_opts ../../src/mac/TECH/CLK_DIV2.v
vlog $vlog_opts ../../src/mac/TECH/CLK_SWITCH.v

vlog $vlog_opts ../../src/mpc/mpc_top.v
vlog $vlog_opts +incdir+../../src/sja1000 ../../src/sja1000/can_acf.v
vlog $vlog_opts +incdir+../../src/sja1000 ../../src/sja1000/can_axi.v
vlog $vlog_opts +incdir+../../src/sja1000 ../../src/sja1000/can_bsp.v
vlog $vlog_opts +incdir+../../src/sja1000 ../../src/sja1000/can_btl.v
vlog $vlog_opts +incdir+../../src/sja1000 ../../src/sja1000/can_crc.v
vlog $vlog_opts +incdir+../../src/sja1000 ../../src/sja1000/can_fifo.v
vlog $vlog_opts +incdir+../../src/sja1000 ../../src/sja1000/can_ibo.v
vlog $vlog_opts +incdir+../../src/sja1000 ../../src/sja1000/can_register.v
vlog $vlog_opts +incdir+../../src/sja1000 ../../src/sja1000/can_register_asyn.v
vlog $vlog_opts +incdir+../../src/sja1000 ../../src/sja1000/can_register_asyn_syn.v
vlog $vlog_opts +incdir+../../src/sja1000 ../../src/sja1000/can_register_syn.v
vlog $vlog_opts +incdir+../../src/sja1000 ../../src/sja1000/can_registers.v
vlog $vlog_opts +incdir+../../src/sja1000 ../../src/sja1000/can_top.v
vlog $vlog_opts +incdir+../../src/sja1000 ../../src/sja1000/multi_can.v

vlog $vlog_opts ../../src/mps/mps_top.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/raminfr.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/uart_debug_if.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/uart_receiver.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/uart_regs.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/uart_rfifo.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/uart_sync_flops.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/uart_tfifo.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/uart_transmitter.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/uart_axi.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/multi_serial.v

vlog ../../src/test/glbl.v

vopt +acc -L unisims_ver -L unimacro_ver -L secureip -L pci32_v5_0_7 test_device_top glbl -o test_device_top_opt

vsim test_device_top_opt

run -a

