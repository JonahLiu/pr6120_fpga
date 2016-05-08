create_clock -period 8.000 -name p0_tx_clk -waveform {0.000 4.000} [get_ports {p0_txsclk}]
create_clock -period 8.000 -name p0_rx_clk -waveform {0.000 4.000} [get_ports {p0_rxsclk}]

create_generated_clock -name nic_clock [get_pins nic_clk_gen_i/mmcm_adv_inst/CLKOUT0]

set_clock_group -group [get_clocks pci_clock] -group [get_clocks nic_clock] -group [get_clocks p0_tx_clk] -group [get_clocks p0_rx_clk] -asynchronous


set_input_delay -clock p0_rx_clk -max 4.000 [get_ports -filter {NAME =~ p0_rxdat[*]}]
set_input_delay -clock p0_rx_clk -min 0.000 [get_ports -filter {NAME =~ p0_rxdat[*]}]

set_input_delay -clock p0_rx_clk -max 4.000 [get_ports {p0_rxdv p0_rxer p0_crs p0_col}]
set_input_delay -clock p0_rx_clk -min 0.000 [get_ports {p0_rxdv p0_rxer p0_crs p0_col}]

set_output_delay -clock nic_clock -max 4.000 [get_ports -filter {NAME =~ p0_txdat[*]}]
set_output_delay -clock nic_clock -min 0.000 [get_ports -filter {NAME =~ p0_txdat[*]}]

set_output_delay -clock nic_clock -max 4.000 [get_ports {p0_txen p0_txer}]
set_output_delay -clock nic_clock -min 0.000 [get_ports {p0_txen p0_txer}]
