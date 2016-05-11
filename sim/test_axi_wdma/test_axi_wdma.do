onerror {quit -f}
onbreak {quit -f}

set vlog_opts {-incr}

vlib work

vlog $vlog_opts ../../src/e1000/axi_wdma.v
vlog $vlog_opts ../../src/e1000/axi_rdma.v
vlog $vlog_opts ../../src/e1000/axis_realign.v
vlog $vlog_opts ../../src/e1000/axi_ram.v
vlog $vlog_opts ../../src/test/test_axi_wdma.v

vopt +acc test_axi_wdma -o test_axi_wdma_opt

vsim test_axi_wdma_opt

run -a
