# define input clocks
create_clock -period 30.000 -name pci_clock -waveform {0.000 15.000} [get_ports {PCLK}]

create_clock -period 8.000 -name p0_rxsclk_src -waveform {0.000 4.000} 
create_clock -period 8.000 -name p0_rxsclk -waveform {2.000 6.000} [get_ports {p0_rxsclk}]

create_clock -period 8.000 -name p1_rxsclk_src -waveform {0.000 4.000} 
create_clock -period 8.000 -name p1_rxsclk -waveform {2.000 6.000} [get_ports {p1_rxsclk}]

# create a virtual clock for undeterminate RGMII output clock
# create_clock -period 8.000 -name gtxsclk_dst -waveform {2.000 6.000}

# rename generated clocks
create_generated_clock -name p0_clk_in [get_pins {p0_if_i/rx_i/clk_in_i/O}]
create_generated_clock -name p0_clk_div [get_pins {p0_if_i/rx_i/clk_div_i/O}]

create_generated_clock -name p1_clk_in [get_pins {p1_if_i/rx_i/clk_in_i/O}]
create_generated_clock -name p1_clk_div [get_pins {p1_if_i/rx_i/clk_div_i/O}]

create_generated_clock -name nic_clock [get_pins {nic_wrapper_i/nic_clk_gen_i/mmcm_adv_inst/CLKOUT0}]
create_generated_clock -name can_clock [get_pins {mpc_wrapper_i/can_clk_gen_i/mmcm_adv_inst/CLKOUT0}]
create_generated_clock -name uart_clock [get_pins {mps_wrapper_i/uart_clk_gen_i/mmcm_adv_inst/CLKOUT0}]

# define exclusive clocks
set_clock_group \
				-group {p0_rxsclk_src p0_rxsclk p0_clk_in p0_clk_div} \
				-group {p1_rxsclk_src p1_rxsclk p1_clk_in p1_clk_div} \
				-logically_exclusive 

#set_clock_group -logically_exclusive -group p0_clk_in -group p0_clk_div
#set_clock_group -logically_exclusive -group p1_clk_in -group p1_clk_div

# define unrelated clocks
set_clock_group \
				-group {p0_rxsclk_src p0_rxsclk p0_clk_in p0_clk_div} \
				-group {p1_rxsclk_src p1_rxsclk p1_clk_in p1_clk_div} \
				-group nic_clock \
				-group can_clock \
				-group uart_clock \
				-group pci_clock \
				-asynchronous 

# define IO delays

set_input_delay 0.000 -clock p0_rxsclk_src [get_ports -filter {NAME =~ p0_rxdat[*]}]
set_input_delay 0.000 -clock p0_rxsclk_src [get_ports -filter {NAME =~ p0_rxdat[*]}] -clock_fall -add_delay
set_input_delay 0.000 -clock p0_rxsclk_src [get_ports {p0_rxdv}]
set_input_delay 0.000 -clock p0_rxsclk_src [get_ports {p0_rxdv}] -clock_fall -add_delay
set_input_delay 0.000 -clock p0_rxsclk_src [get_ports {p0_crs}]
set_input_delay 0.000 -clock p0_rxsclk_src [get_ports {p0_col}]
set_input_delay 0.000 -clock p0_rxsclk_src [get_ports {p0_int}]
set_input_delay 0.000 -clock nic_clock [get_ports {p0_mdio}]

set_input_delay 0.000 -clock p1_rxsclk_src [get_ports -filter {NAME =~ p1_rxdat[*]}]
set_input_delay 0.000 -clock p1_rxsclk_src [get_ports -filter {NAME =~ p1_rxdat[*]}] -clock_fall -add_delay
set_input_delay 0.000 -clock p1_rxsclk_src [get_ports {p1_rxdv}]
set_input_delay 0.000 -clock p1_rxsclk_src [get_ports {p1_rxdv}] -clock_fall -add_delay
set_input_delay 0.000 -clock p1_rxsclk_src [get_ports {p1_crs}]
set_input_delay 0.000 -clock p1_rxsclk_src [get_ports {p1_col}]
set_input_delay 0.000 -clock p1_rxsclk_src [get_ports {p1_int}]
set_input_delay 0.000 -clock nic_clock [get_ports {p1_mdio}]

set_output_delay 0.000 [get_ports -filter {NAME =~ p0_txdat[*]}]
set_output_delay 0.000 [get_ports -filter {NAME =~ p0_txdat[*]}] -clock_fall -add_delay
set_output_delay 0.000 [get_ports {p0_txen}]
set_output_delay 0.000 [get_ports {p0_txen}] -clock_fall -add_delay
set_output_delay 0.000 [get_ports {p0_gtxsclk}]
set_output_delay 0.000 [get_ports {p0_gtxsclk}] -clock_fall -add_delay
set_output_delay 0.000 -clock nic_clock [get_ports {p0_mdc}]
set_output_delay 0.000 -clock nic_clock [get_ports {p0_mdio}]
set_output_delay 0.000 -clock nic_clock [get_ports {p0_resetn}]

set_output_delay 0.000 [get_ports -filter {NAME =~ p1_txdat[*]}]
set_output_delay 0.000 [get_ports -filter {NAME =~ p1_txdat[*]}] -clock_fall -add_delay
set_output_delay 0.000 [get_ports {p1_txen}]
set_output_delay 0.000 [get_ports {p1_txen}] -clock_fall -add_delay
set_output_delay 0.000 [get_ports {p1_gtxsclk}]
set_output_delay 0.000 [get_ports {p1_gtxsclk}] -clock_fall -add_delay
set_output_delay 0.000 -clock nic_clock [get_ports {p1_mdc}]
set_output_delay 0.000 -clock nic_clock [get_ports {p1_mdio}]
set_output_delay 0.000 -clock nic_clock [get_ports {p1_resetn}]

#set_false_path -rise_from p0_clk_in -fall_to gtxsclk_dst
#set_false_path -fall_from p0_clk_in -rise_to gtxsclk_dst
set_false_path -rise_from p0_rxsclk_src -fall_to p0_clk_in
set_false_path -fall_from p0_rxsclk_src -rise_to p0_clk_in

#set_false_path -rise_from p1_clk_in -fall_to gtxsclk_dst
#set_false_path -fall_from p1_clk_in -rise_to gtxsclk_dst
set_false_path -rise_from p1_rxsclk_src -fall_to p1_clk_in
set_false_path -fall_from p1_rxsclk_src -rise_to p1_clk_in

set_input_delay 0.000 -clock uart_clock [get_ports {uart0_rx}]
set_input_delay 0.000 -clock uart_clock [get_ports {uart1_rx}]
set_input_delay 0.000 -clock uart_clock [get_ports {uart2_rx}]
set_input_delay 0.000 -clock uart_clock [get_ports {uart3_rx}]
set_output_delay 0.000 -clock uart_clock [get_ports {uart0_tx}]
set_output_delay 0.000 -clock uart_clock [get_ports {uart1_tx}]
set_output_delay 0.000 -clock uart_clock [get_ports {uart2_tx}]
set_output_delay 0.000 -clock uart_clock [get_ports {uart3_tx}]

set_input_delay 0.000 -clock can_clock [get_ports {can0_rx}]
set_input_delay 0.000 -clock can_clock [get_ports {can1_rx}]
set_output_delay 0.000 -clock can_clock [get_ports {can0_tx}]
set_output_delay 0.000 -clock can_clock [get_ports {can1_tx}]

set_input_delay -clock pci_clock 1.000 [get_ports -filter {NAME =~ AD[*]}]
set_input_delay -clock pci_clock 1.000 [get_ports -filter {NAME =~ CBE[*]}]
set_input_delay -clock pci_clock 1.000 [get_ports -filter {NAME =~ GNT_N[*]}]
set_input_delay -clock pci_clock 1.000 [get_ports {PAR FRAME_N TRDY_N IRDY_N STOP_N DEVSEL_N PERR_N SERR_N RST_N}]
set_output_delay -clock pci_clock 1.000 [get_ports -filter {NAME =~ AD[*]}]
set_output_delay -clock pci_clock 1.000 [get_ports -filter {NAME =~ CBE[*]}]
set_output_delay -clock pci_clock 1.000 [get_ports -filter {NAME =~ REQ_N[*]}]
set_output_delay -clock pci_clock 1.000 [get_ports {PAR FRAME_N TRDY_N IRDY_N STOP_N DEVSEL_N PERR_N SERR_N INTA_N INTB_N INTC_N INTD_N}]

#set_input_delay -clock pci_clock -max 23.000 [get_ports -filter {NAME =~ AD[*]}]
#set_input_delay -clock pci_clock -min 0.000 [get_ports -filter {NAME =~ AD[*]}]
#set_output_delay -clock pci_clock -max 7.000 [get_ports -filter {NAME =~ AD[*]}]
#set_output_delay -clock pci_clock -min 0.000 [get_ports -filter {NAME =~ AD[*]}]

#set_input_delay -clock pci_clock -max 23.000 [get_ports -filter {NAME =~ CBE[*]}]
#set_input_delay -clock pci_clock -min 0.000 [get_ports -filter {NAME =~ CBE[*]}]
#set_output_delay -clock pci_clock -max 7.000 [get_ports -filter {NAME =~ CBE[*]}]
#set_output_delay -clock pci_clock -min 0.000 [get_ports -filter {NAME =~ CBE[*]}]

#set_input_delay -clock pci_clock -max 23.000 [get_ports {PAR FRAME_N TRDY_N IRDY_N STOP_N DEVSEL_N PERR_N SERR_N GNT_N RST_N}]
#set_input_delay -clock pci_clock -min 0.000 [get_ports {PAR FRAME_N TRDY_N IRDY_N STOP_N DEVSEL_N PERR_N SERR_N GNT_N RST_N}]
#set_output_delay -clock pci_clock -max 7.000 [get_ports {PAR FRAME_N TRDY_N IRDY_N STOP_N DEVSEL_N PERR_N SERR_N INTA_N REQ_N}]
#set_output_delay -clock pci_clock -min 0.000 [get_ports {PAR FRAME_N TRDY_N IRDY_N STOP_N DEVSEL_N PERR_N SERR_N INTA_N REQ_N}]

