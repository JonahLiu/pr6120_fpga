create_clock -period 8.000 -name p0_tx_clk -waveform {0.000 4.000} [get_ports {p0_txsclk}]
create_clock -period 8.000 -name p0_rx_clk -waveform {0.000 4.000} [get_ports {p0_rxsclk}]
create_clock -period 8.000 -name p1_tx_clk -waveform {0.000 4.000} [get_ports {p1_txsclk}]
create_clock -period 8.000 -name p1_rx_clk -waveform {0.000 4.000} [get_ports {p1_rxsclk}]

create_generated_clock -name nic_clock [get_pins nic_wrapper_i/nic_clk_gen_i/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name can_clock [get_pins mpc_wrapper_i/can_clk_gen_i/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name uart_clock [get_pins mps_wrapper_i/uart_clk_gen_i/mmcm_adv_inst/CLKOUT0]

set_clock_group -group [get_clocks pci_clock] -group [get_clocks nic_clock] -group [get_clocks can_clock] -group [get_clocks uart_clock] -group [get_clocks p0_tx_clk] -group [get_clocks p0_rx_clk] -group [get_clocks p1_tx_clk] -group [get_clocks p1_rx_clk] -asynchronous

set_input_delay -clock p0_rx_clk -max 5.500  [get_ports -filter {NAME =~ p0_rxdat[*]}]
set_input_delay -clock p0_rx_clk -min 0.000  [get_ports -filter {NAME =~ p0_rxdat[*]}]

set_input_delay -clock p0_rx_clk -max 5.500 [get_ports {p0_rxdv p0_rxer p0_crs p0_col}]
set_input_delay -clock p0_rx_clk -min 0.000 [get_ports {p0_rxdv p0_rxer p0_crs p0_col}]

set_output_delay -clock p0_tx_clk -max 0.100 [get_ports -filter {NAME =~ p0_txdat[*]}]
set_output_delay -clock p0_tx_clk -min 0.000 [get_ports -filter {NAME =~ p0_txdat[*]}]

set_output_delay -clock p0_tx_clk -max 0.100 [get_ports {p0_txen p0_txer}]
set_output_delay -clock p0_tx_clk -min 0.000 [get_ports {p0_txen p0_txer}]

set_input_delay -clock p1_rx_clk -max 5.500  [get_ports -filter {NAME =~ p1_rxdat[*]}]
set_input_delay -clock p1_rx_clk -min 0.000  [get_ports -filter {NAME =~ p1_rxdat[*]}]

set_input_delay -clock p1_rx_clk -max 5.500 [get_ports {p1_rxdv p1_rxer p1_crs p1_col}]
set_input_delay -clock p1_rx_clk -min 0.000 [get_ports {p1_rxdv p1_rxer p1_crs p1_col}]

set_output_delay -clock p1_tx_clk -max 0.100 [get_ports -filter {NAME =~ p1_txdat[*]}]
set_output_delay -clock p1_tx_clk -min 0.000 [get_ports -filter {NAME =~ p1_txdat[*]}]

set_output_delay -clock p1_tx_clk -max 0.100 [get_ports {p1_txen p1_txer}]
set_output_delay -clock p1_tx_clk -min 0.000 [get_ports {p1_txen p1_txer}]

