# define input clocks
create_clock -period 30.000 -name pci_clock -waveform {0.000 15.000} [get_ports {PCLK}]
create_clock -period 8.000 -name p0_rxsclk -waveform {0.000 4.000} [get_ports {p0_rxsclk}]
create_clock -period 8.000 -name p1_rxsclk -waveform {0.000 4.000} [get_ports {p1_rxsclk}]

# rename generated clocks
create_generated_clock -name p0_clk_in [get_pins {p0_if_i/rx_i/clk_in_i/O}]
create_generated_clock -name p0_clk_div [get_pins {p0_if_i/rx_i/clk_div_i/O}]

create_generated_clock -name p1_clk_in [get_pins {p1_if_i/rx_i/clk_in_i/O}]
create_generated_clock -name p1_clk_div [get_pins {p1_if_i/rx_i/clk_div_i/O}]

create_generated_clock -name nic_clock [get_pins nic_wrapper_i/nic_clk_gen_i/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name can_clock [get_pins mpc_wrapper_i/can_clk_gen_i/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name uart_clock [get_pins mps_wrapper_i/uart_clk_gen_i/mmcm_adv_inst/CLKOUT0]

# define exclusive clocks
set_clock_group -logically_exclusive -group [get_clocks p0_rxsclk] -group [get_clocks p1_rxsclk]
set_clock_group -logically_exclusive -group [get_clocks p0_clk_in] -group [get_clocks p0_clk_div]
set_clock_group -logically_exclusive -group [get_clocks p1_clk_in] -group [get_clocks p1_clk_div]

# define unrelated clocks
set_clock_group -group [get_clocks pci_clock] -group [get_clocks nic_clock] -group [get_clocks p0_clk_in] -asynchronous
set_clock_group -group [get_clocks pci_clock] -group [get_clocks nic_clock] -group [get_clocks p0_clk_div] -asynchronous
set_clock_group -group [get_clocks pci_clock] -group [get_clocks nic_clock] -group [get_clocks p1_clk_in] -asynchronous
set_clock_group -group [get_clocks pci_clock] -group [get_clocks nic_clock] -group [get_clocks p1_clk_div] -asynchronous

set_clock_group -group [get_clocks pci_clock] -group [get_clocks can_clock] -asynchronous

set_clock_group -group [get_clocks pci_clock] -group [get_clocks uart_clock] -asynchronous

# define IO delays
#set_input_delay 0.000 -clock p0_clk_in [get_ports -filter {NAME =~ p0_rxdat[*]}]
#set_input_delay 0.000 -clock p0_clk_in [get_ports -filter {NAME =~ p0_rxdat[*]} -clock_fall -add_delay
#set_input_delay 0.000 -clock p0_clk_in [get_ports {p0_rxdv}]
#set_input_delay 0.000 -clock p0_clk_in [get_ports {p0_rxdv} -clock_fall -add_delay
#set_input_delay 0.000 -clock p0_rxsclk [get_ports {p0_crs}]
#set_input_delay 0.000 -clock p0_rxsclk [get_ports {p0_col}]
#set_input_delay 0.000 -clock p0_rxsclk [get_ports {p0_int}]
#set_output_delay 0.000 -clock p0_rxsclk [get_ports -filter {NAME =~ p0_txdat[*]}]
#set_output_delay 0.000 -clock p0_rxsclk [get_ports -filter {NAME =~ p0_txdat[*]} -clock_fall -add_delay
#set_output_delay 0.000 -clock p0_rxsclk [get_ports {p0_txen}]
#set_output_delay 0.000 -clock p0_rxsclk [get_ports {p0_txen} -clock_fall -add_delay
#set_output_delay 0.000 -clock p0_rxsclk [get_ports {p0_gtxsclk}]
#set_output_delay 0.000 -clock p0_rxsclk [get_ports {p0_gtxsclk} -clock_fall -add_delay
#set_output_delay 0.000 -clock p0_rxsclk [get_ports {p0_mdc}]
#set_output_delay 0.000 -clock p0_rxsclk [get_ports {p0_mdio}]
#set_output_delay 0.000 -clock p0_rxsclk [get_ports {p0_resetn}]

#set_input_delay 0.000 -clock p1_clk_in [get_ports -filter {NAME =~ p1_rxdat[*]}]
#set_input_delay 0.000 -clock p1_clk_in [get_ports -filter {NAME =~ p1_rxdat[*]} -clock_fall -add_delay
#set_input_delay 0.000 -clock p1_clk_in [get_ports {p1_rxdv}]
#set_input_delay 0.000 -clock p1_clk_in [get_ports {p1_rxdv} -clock_fall -add_delay
#set_input_delay 0.000 -clock p1_rxsclk [get_ports {p1_crs}]
#set_input_delay 0.000 -clock p1_rxsclk [get_ports {p1_col}]
#set_input_delay 0.000 -clock p1_rxsclk [get_ports {p1_int}]
#set_output_delay 0.000 -clock p1_rxsclk [get_ports -filter {NAME =~ p1_txdat[*]}]
#set_output_delay 0.000 -clock p1_rxsclk [get_ports -filter {NAME =~ p1_txdat[*]} -clock_fall -add_delay
#set_output_delay 0.000 -clock p1_rxsclk [get_ports {p1_txen}]
#set_output_delay 0.000 -clock p1_rxsclk [get_ports {p1_txen} -clock_fall -add_delay
#set_output_delay 0.000 -clock p1_rxsclk [get_ports {p1_gtxsclk}]
#set_output_delay 0.000 -clock p1_rxsclk [get_ports {p1_gtxsclk} -clock_fall -add_delay
#set_output_delay 0.000 -clock p1_rxsclk [get_ports {p1_mdc}]
#set_output_delay 0.000 -clock p1_rxsclk [get_ports {p1_mdio}]
#set_output_delay 0.000 -clock p1_rxsclk [get_ports {p1_resetn}]

#set_input_delay 0.000 -clock uart_clock [get_ports {uart0_rx}]
#set_input_delay 0.000 -clock uart_clock [get_ports {uart1_rx}]
#set_input_delay 0.000 -clock uart_clock [get_ports {uart2_rx}]
#set_input_delay 0.000 -clock uart_clock [get_ports {uart3_rx}]
#set_output_delay 0.000 -clock uart_clock [get_ports {uart0_tx}]
#set_output_delay 0.000 -clock uart_clock [get_ports {uart1_tx}]
#set_output_delay 0.000 -clock uart_clock [get_ports {uart2_tx}]
#set_output_delay 0.000 -clock uart_clock [get_ports {uart3_tx}]

#set_input_delay 0.000 -clock can_clock [get_ports {can0_rx}]
#set_input_delay 0.000 -clock can_clock [get_ports {can1_rx}]
#set_output_delay 0.000 -clock can_clock [get_ports {can0_tx}]
#set_output_delay 0.000 -clock can_clock [get_ports {can1_tx}]

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
