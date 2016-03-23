
set_property PACKAGE_PIN AD23 [get_ports clk_ref_p]
set_property PACKAGE_PIN AE24 [get_ports clk_ref_n]

set_property IOSTANDARD LVDS_25 [get_ports clk_ref_p]
set_property IOSTANDARD LVDS_25 [get_ports clk_ref_n]

create_clock -period 5.000 -name reference_clock -waveform {0.000 2.500} [get_ports clk_ref_p]






