onbreak {quit -f}
onerror {quit -f}

#set vlog_opts {+acc}
set vlog_opts {-incr}

set vcom_opts {-93}

vlib work

vlog +incdir+../../src/test $vlog_opts ../../src/test/pci_blue_arbiter.v

vlog $vlog_opts ../../src/test/test_pci_axi_top.v
vlog $vlog_opts ../../src/test/pci_behavioral_master.v
vlog $vlog_opts ../../src/test/pci_behavioral_target.v
vlog $vlog_opts ../../src/test/axi_memory_model.v
vlog $vlog_opts ../../src/test/axi_master_model.v

vlog $vlog_opts ../../src/pci/pci_axi_top.v
vlog $vlog_opts ../../src/pci/pci_target.v
vlog $vlog_opts ../../src/pci/pci_master.v
vlog $vlog_opts ../../src/pci/pci_master_wpath.v
vlog $vlog_opts ../../src/pci/pci_master_rpath.v
vlog $vlog_opts ../../src/pci/pci_master_ctrl.v
vlog $vlog_opts ../../src/pci/fifo_async.v
vlog $vlog_opts ../../src/pci/pci_lc.v
vlog $vlog_opts ../../src/pci/pci32_0.v
#vlog $vlog_opts ../../src/pci/pci32_0_top.v
#vcom $vcom_opts ../../src/pci/pci32_v5_0_rfs.vhd
#vlog $vlog_opts ../../src/pci/pci32_v5_0_rfs.v

vlog ../../src/test/glbl.v

vopt +acc -L unisims_ver -L unimacro_ver -L secureip -L pci32_v5_0 test_pci_axi_top glbl -o test_pci_axi_top_opt

vsim test_pci_axi_top_opt

#vsim -L unisims_ver -L unimacro_ver -L secureip -L pci32_v5_0 test_pci_axi_top glbl 
run -a

