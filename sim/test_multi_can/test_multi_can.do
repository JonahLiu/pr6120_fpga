onerror {quit -f}
onbreak {quit -f}

set vlog_opts {-incr}

vlib work

vlog $vlog_opts ../../src/test/test_multi_can.v
vlog $vlog_opts ../../src/test/axi_lite_model.v
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

vopt +acc test_multi_can -o test_multi_can_opt

vsim test_multi_can_opt

run -a
