onbreak {quit -f}
onerror {quit -f}

#set vlog_opts {+acc}
set vlog_opts {-incr}

set vcom_opts {-93}

vlib work


vlog $vlog_opts ../../src/e1000/eeprom_ctrl.v
vlog $vlog_opts ../../src/e1000/axi4_eeprom.v
vlog $vlog_opts ../../src/e1000/shift_eeprom.v
vlog $vlog_opts ../../src/e1000/eeprom_emu.v
vlog $vlog_opts ../../src/test/axi_lite_model.v
vlog $vlog_opts ../../src/test/test_eeprom.v

vopt +acc test_eeprom -o test_eeprom_opt

vsim test_eeprom_opt

run -a
