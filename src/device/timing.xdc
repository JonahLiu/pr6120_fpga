create_generated_clock -name nic_clock [get_pins nic_clk_gen_i/inst/mmcm_adv_inst/CLKOUT0]
set_clock_group -group [get_clocks pci_clock] -group [get_clocks nic_clock] -asynchronous
