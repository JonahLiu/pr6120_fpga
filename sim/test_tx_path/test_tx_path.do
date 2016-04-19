onerror {quit -f}
onbreak {quit -f}

set vlog_opts {-incr}

vlib work

vlog $vlog_opts ../../src/e1000/axi_mux.v
vlog $vlog_opts ../../src/e1000/axi_idma.v
vlog $vlog_opts ../../src/e1000/axi_ram.v
vlog $vlog_opts ../../src/e1000/tx_desc_ctrl.v
vlog $vlog_opts ../../src/e1000/tx_engine.v
vlog $vlog_opts ../../src/e1000/tx_path.v

vopt +acc tx_path -o tx_path_opt

vsim tx_path_opt

run -a
