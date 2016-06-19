onbreak {quit -f}
onerror {quit -f}

#set vlog_opts {+acc}
set vlog_opts {-incr}

set vcom_opts {-93}

vlib work


vlog $vlog_opts ../../src/e1000/dna.v
vlog $vlog_opts ../../src/e1000/config_rom.v
vlog $vlog_opts ../../src/test/test_config_rom.v
vlog $vlog_opts ../../src/test/glbl.v

vopt +acc test_config_rom glbl -o test_config_rom_opt -L unisims_ver

vsim test_config_rom_opt

run -a
