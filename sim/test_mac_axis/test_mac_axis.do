onerror {quit -f}
onbreak {quit -f}

set vlog_opts {-incr}
#set vlog_opts {+acc}

vlib work

vlog $vlog_opts ../../src/e1000/mac_axis.v
vlog $vlog_opts ../../src/mac/afifo.v
vlog $vlog_opts ../../src/mac/Clk_ctrl.v
vlog $vlog_opts ../../src/mac/Phy_int.v
vlog $vlog_opts +incdir+../../src/mac ../../src/mac/MAC_rx.v
vlog $vlog_opts +incdir+../../src/mac ../../src/mac/MAC_tx.v
vlog $vlog_opts ../../src/mac/TECH/CLK_DIV2.v
vlog $vlog_opts ../../src/mac/TECH/CLK_SWITCH.v
vlog $vlog_opts ../../src/mac/TECH/duram.v
vlog $vlog_opts ../../src/mac/MAC_rx/MAC_rx_ctrl.v
vlog $vlog_opts +incdir+../../src/mac ../../src/mac/MAC_rx/MAC_rx_FF.v
vlog $vlog_opts ../../src/mac/MAC_rx/MAC_rx_add_chk.v
vlog $vlog_opts ../../src/mac/MAC_rx/CRC_chk.v
vlog $vlog_opts ../../src/mac/MAC_tx/flow_ctrl.v
vlog $vlog_opts ../../src/mac/MAC_tx/MAC_tx_Ctrl.v
vlog $vlog_opts ../../src/mac/MAC_tx/MAC_tx_addr_add.v
vlog $vlog_opts ../../src/mac/MAC_tx/CRC_gen.v
vlog $vlog_opts ../../src/mac/MAC_tx/Ramdon_gen.v
vlog $vlog_opts +incdir+../../src/mac ../../src/mac/MAC_tx/MAC_tx_FF.v
vlog $vlog_opts ../../src/test/test_mac_axis.v

vopt +acc test_mac_axis -o test_mac_axis_opt

vsim test_mac_axis_opt

run -a
