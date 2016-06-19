onbreak {quit -f}
onerror {quit -f}

#set vlog_opts {+acc}
set vlog_opts {-incr}

set vcom_opts {-93}

vlib work


vlog $vlog_opts ../../src/e1000/dna.v
vlog $vlog_opts ../../src/test/test_dna.v
vlog $vlog_opts ../../src/test/glbl.v

vopt +acc test_dna glbl -o test_dna_opt -L unisims_ver

vsim test_dna_opt

run -a
