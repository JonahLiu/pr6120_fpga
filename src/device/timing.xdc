# define input clocks
create_clock -period 8.000 -name p0_rxsclk -waveform {0.000 4.000} [get_ports {p0_rxsclk}]
create_clock -period 8.000 -name p1_rxsclk -waveform {0.000 4.000} [get_ports {p1_rxsclk}]

# rename generated clocks
create_generated_clock -name p0_clk_in [get_pins {p0_if_i/rx_i/clk_in_i/O}]
create_generated_clock -name p0_clk_div [get_pins {p0_if_i/rx_i/clk_div_i/O}]
#create_generated_clock -name p0_usrclk [get_pins {p0_if_i/rx_i/clk_mux_i/O}]

create_generated_clock -name p1_clk_in [get_pins {p1_if_i/rx_i/clk_in_i/O}]
create_generated_clock -name p1_clk_div [get_pins {p1_if_i/rx_i/clk_div_i/O}]
#create_generated_clock -name p1_usrclk [get_pins {p1_if_i/rx_i/clk_mux_i/O}]

#create_generated_clock -name mac_usrclk [get_pins {phy_ft_i/clk_mux_i/O}]

create_generated_clock -name nic_clock [get_pins nic_wrapper_i/nic_clk_gen_i/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name can_clock [get_pins mpc_wrapper_i/can_clk_gen_i/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name uart_clock [get_pins mps_wrapper_i/uart_clk_gen_i/mmcm_adv_inst/CLKOUT0]

# define exclusive clocks
set_clock_group -physically_exclusive -group [get_clocks p0_clk_in] -group [get_clocks p0_clk_div] -group [get_clocks p1_clk_in] -group [get_clocks p1_clk_div]
#set_clock_group -physically_exclusive -group [get_clocks p1_clk_in] -group [get_clocks p1_clk_div]
#set_clock_group -physically_exclusive -group [get_clocks p0_usrclk] -group [get_clocks p1_usrclk]

# define unrelated clocks
set_clock_group -group [get_clocks pci_clock] -group [get_clocks nic_clock] -group [get_clocks p0_clk_in] -asynchronous
set_clock_group -group [get_clocks pci_clock] -group [get_clocks nic_clock] -group [get_clocks p0_clk_div] -asynchronous
set_clock_group -group [get_clocks pci_clock] -group [get_clocks nic_clock] -group [get_clocks p1_clk_in] -asynchronous
set_clock_group -group [get_clocks pci_clock] -group [get_clocks nic_clock] -group [get_clocks p1_clk_div] -asynchronous

set_clock_group -group [get_clocks pci_clock] -group [get_clocks can_clock] -asynchronous

set_clock_group -group [get_clocks pci_clock] -group [get_clocks uart_clock] -asynchronous

