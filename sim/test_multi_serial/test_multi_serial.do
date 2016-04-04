onerror {quit -f}
onbreak {quit -f}

set vlog_opts {-incr}

vlib work

vlog $vlog_opts ../../src/test/test_multi_serial.v
vlog $vlog_opts ../../src/test/axi_lite_model.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/raminfr.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/uart_debug_if.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/uart_receiver.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/uart_regs.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/uart_rfifo.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/uart_sync_flops.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/uart_tfifo.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/uart_transmitter.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/uart_axi.v
vlog $vlog_opts +incdir+../../src/uart16550 ../../src/uart16550/multi_serial.v

vopt +acc test_multi_serial -o test_multi_serial_opt

vsim test_multi_serial_opt

run -a
