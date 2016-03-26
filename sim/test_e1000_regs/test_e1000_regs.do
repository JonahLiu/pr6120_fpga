onerror {quit -f}
onbreak {quit -f}

set vlog_opts {-incr}

vlib work

vlog $vlog_opts ../../src/test/test_e1000_regs.v
vlog $vlog_opts ../../src/test/axi_lite_model.v
vlog $vlog_opts ../../src/e1000/e1000_regs.v
vlog $vlog_opts ../../src/e1000/e1000_register.v

vopt +acc test_e1000_regs -o test_e1000_regs_opt

vsim test_e1000_regs_opt

run -a
