onbreak {quit -f}
onerror {quit -f}

#set vlog_opts {+acc}
set vlog_opts {-incr}

set vcom_opts {-93}

vlib work

vlog $vlog_opts ../../src/test/test_nic_device.v

vlog $vlog_opts ../../src/test/pci_behavioral_master.v
vlog $vlog_opts ../../src/test/pci_behavioral_target.v
vlog +incdir+../../src/test $vlog_opts ../../src/test/pci_blue_arbiter.v

vlog $vlog_opts ../../src/device/device_top.v
vlog $vlog_opts ../../src/device/nic_clk_gen.v

vlog $vlog_opts ../../src/pci/pci_axi_top.v
vlog $vlog_opts ../../src/pci/pci_target.v
vlog $vlog_opts ../../src/pci/pci_master.v
vlog $vlog_opts ../../src/pci/pci_master_wpath.v
vlog $vlog_opts ../../src/pci/pci_master_rpath.v
vlog $vlog_opts ../../src/pci/pci_master_ctrl.v
vlog $vlog_opts ../../src/pci/fifo_async.v
vlog $vlog_opts ../../src/pci/pci_lc.v
vlog $vlog_opts ../../src/pci/pci32_0.v

vlog $vlog_opts ../../src/e1000/e1000_top.v
vlog $vlog_opts ../../src/e1000/e1000_regs.v
vlog $vlog_opts ../../src/e1000/e1000_register.v
vlog $vlog_opts ../../src/e1000/shift_eeprom.v
vlog $vlog_opts ../../src/e1000/eeprom_emu.v
vlog $vlog_opts ../../src/e1000/config_rom.v
vlog $vlog_opts ../../src/e1000/mdio_emu.v
vlog $vlog_opts ../../src/e1000/shift_mdio.v
vlog $vlog_opts ../../src/e1000/intr_ctrl.v

vlog $vlog_opts ../../src/e1000/axi_mux.v
vlog $vlog_opts ../../src/e1000/axi_idma.v
vlog $vlog_opts ../../src/e1000/axi_ram.v
vlog $vlog_opts ../../src/e1000/tx_desc_ctrl.v
vlog $vlog_opts ../../src/e1000/tx_engine.v
vlog $vlog_opts ../../src/e1000/tx_frame.v
vlog $vlog_opts ../../src/e1000/tx_path.v
vlog $vlog_opts ../../src/e1000/axis_realign.v
vlog $vlog_opts ../../src/e1000/axi_rdma.v

vlog ../../src/test/glbl.v

vopt +acc -L unisims_ver -L unimacro_ver -L secureip -L pci32_v5_0 test_nic_device glbl -o test_nic_device_opt

vsim test_nic_device_opt

#vsim -L unisims_ver -L unimacro_ver -L secureip -L pci32_v5_0 test_pci_axi_top glbl 
run -a

