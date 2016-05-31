onerror {quit -f}
onbreak {quit -f}

set vlog_opts {-incr}

vlib work

vlog $vlog_opts ../../src/device/phy_ft.v
vlog $vlog_opts ../../src/device/phy_switch.v
vlog $vlog_opts ../../src/e1000/shift_mdio.v
vlog $vlog_opts ../../src/test/test_phy_ft.v
vlog $vlog_opts ../../src/test/glbl.v

vopt +acc test_phy_ft glbl -o test_phy_ft_opt -L unisims_ver 

vsim test_phy_ft_opt 

run -a
