set_false_path -from [get_cells -hierarchical -filter { NAME =~ "*/pci_target_i/write_ready_reg*"} ] -to [get_clocks pci_clock]
set_false_path -from [get_cells -hierarchical -filter { NAME =~ "*/pci_target_i/read_ready_reg*"} ] -to [get_clocks pci_clock]
set_false_path -from [get_cells -hierarchical -filter { NAME =~ "*/pci_target_i/read_data_reg*"} ] -to [get_clocks pci_clock]

set_false_path -from [get_cells -hierarchical -filter { NAME =~ "*/pci_target_i/s_addr_r_reg*"} ] -to [get_clocks clk_out1_can_clk_gen]
set_false_path -from [get_cells -hierarchical -filter { NAME =~ "*/pci_target_i/s_data_r_reg*"} ] -to [get_clocks clk_out1_can_clk_gen]
set_false_path -from [get_cells -hierarchical -filter { NAME =~ "*/pci_target_i/s_be_r_reg*"} ] -to [get_clocks clk_out1_can_clk_gen]
set_false_path -from [get_cells -hierarchical -filter { NAME =~ "*/pci_target_i/write_enable_reg*"} ] -to [get_clocks clk_out1_can_clk_gen]
set_false_path -from [get_cells -hierarchical -filter { NAME =~ "*/pci_target_i/read_enable_reg*"} ] -to [get_clocks clk_out1_can_clk_gen]

set_false_path -to [get_pins pci_axi_i/intr_n_sync_reg/D]  
