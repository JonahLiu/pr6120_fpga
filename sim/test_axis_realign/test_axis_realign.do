onerror {quit -f}
onbreak {quit -f}

set vlog_opts {-incr}

vlib work

vlog $vlog_opts ../../src/e1000/axis_realign.v
vlog $vlog_opts ../../src/test/test_axis_realign.v

vopt +acc test_axis_realign -o test_axis_realign_opt

vsim test_axis_realign_opt

run -a
