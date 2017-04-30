source create_project.tcl

#synth_design -rtl -name rtl_1

launch_runs [current_run -synthesis]
wait_on_run [current_run -synthesis]

launch_runs [current_run -implementation] -to_step write_bitstream
wait_on_run [current_run -implementation]

#launch_runs [current_run -synthesis] [current_run -implementation] -to_step write_bitstream

set top [get_property top [current_fileset]]
set projDir [get_property directory [current_project]]
set projName [get_property name [current_project]]
set prefix [format "%s/%s.runs/%s" $projDir $projName [current_run -implementation]]
set bitstream_fn [format "%s/%s.bit" $prefix $top]

set cfg_mode SPIx1
set cfgmem_fn [format "%s/%s_%s.mcs" $prefix $projName $cfg_mode]

write_cfgmem -force -format mcs \
	-interface $cfg_mode \
	-loadbit "up 0x0 $bitstream_fn" \
	-file $cfgmem_fn

set cfg_mode BPIx16
set cfgmem_fn [format "%s/%s_%s.mcs" $prefix $projName $cfg_mode]

write_cfgmem -force -format mcs \
	-interface $cfg_mode \
	-loadbit "up 0x0 $bitstream_fn" \
	-file $cfgmem_fn

set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
archive_project -force [format "%s_%s.xpr" [current_project] $timestamp]
