onerror {quit -f}
onbreak {quit -f}

set vlog_opts {-incr}

vlib work

vlog $vlog_opts ../../src/e1000/axi_wdma.v
vlog $vlog_opts ../../src/e1000/axi_rdma.v
vlog $vlog_opts ../../src/e1000/axi_mdma.v
vlog $vlog_opts ../../src/e1000/axis_realign.v
vlog $vlog_opts ../../src/e1000/axi_ram.v
vlog $vlog_opts ../../src/common/fifo_async.v
vlog $vlog_opts ../../src/test/test_axi_mdma.v

vopt +acc test_axi_mdma -o test_axi_mdma_opt

vsim test_axi_mdma_opt

run -a
