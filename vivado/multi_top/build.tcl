source create_project.tcl

#synth_design -rtl -name rtl_1

launch_runs [current_run -synthesis]
wait_on_run [current_run -synthesis]

launch_runs [current_run -implementation] -to_step write_bitstream
wait_on_run [current_run -implementation]

set top [get_property top [current_fileset]]
set projName [get_property name [current_project]]
set prefix [get_property DIRECTORY [current_run -implementation]]
set bitstream_fn [format "%s/%s.bit" $prefix $top]

set cfg_mode BPIx16
set cfgmem_fn [format "%s/%s_%s.mcs" $prefix $projName $cfg_mode]

write_cfgmem -force -format mcs \
	-interface $cfg_mode \
	-loadbit "up 0x0 $bitstream_fn" \
	-file $cfgmem_fn

# Generate other files

open_run [current_run -implementation]

set cfg_mode SPIx1
set bitstream_fn [format "%s/%s_%s.bit" $prefix $top $cfg_mode]
set cfgmem_fn [format "%s/%s_%s.mcs" $prefix $projName $cfg_mode]
set_property CONFIG_MODE SPIx1 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
write_bitstream -force $bitstream_fn

write_cfgmem -force -format mcs \
	-interface $cfg_mode \
	-loadbit "up 0x0 $bitstream_fn" \
	-file $cfgmem_fn

set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
archive_project -force [format "%s_%s.xpr" [current_project] $timestamp]
