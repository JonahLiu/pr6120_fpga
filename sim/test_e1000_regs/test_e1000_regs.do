onerror {quit -f}
onbreak {quit -f}

set vlog_opts {-incr}

vlib work

vlog $vlog_opts ../../src/test/test_e1000_regs.v
vlog $vlog_opts ../../src/test/axi_lite_model.v
vlog $vlog_opts ../../src/e1000/e1000_regs.v
vlog $vlog_opts ../../src/e1000/e1000_register.v
vlog $vlog_opts ../../src/e1000/shift_eeprom.v
vlog $vlog_opts ../../src/e1000/eeprom_emu.v
vlog $vlog_opts ../../src/e1000/config_rom.v
vlog $vlog_opts ../../src/e1000/mdio_emu.v
vlog $vlog_opts ../../src/e1000/shift_mdio.v

vopt +acc test_e1000_regs -o test_e1000_regs_opt

vsim test_e1000_regs_opt

run -a
