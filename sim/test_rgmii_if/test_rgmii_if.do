onerror {quit -f}
onbreak {quit -f}

set vlog_opts {-incr}

vlib work

vlog $vlog_opts ../../src/device/rgmii_if.v
vlog $vlog_opts ../../src/device/rgmii_rx.v
vlog $vlog_opts ../../src/device/rgmii_tx.v
vlog $vlog_opts ../../src/test/test_rgmii_if.v
vlog $vlog_opts ../../src/test/eth_pkt_gen.v
vlog $vlog_opts ../../src/test/glbl.v

vopt +acc test_rgmii_if glbl -o test_rgmii_if_opt -L unisims_ver 

vsim test_rgmii_if_opt 

run -a
