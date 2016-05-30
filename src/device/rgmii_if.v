module rgmii_if(
	input reset,
	input speed, // 0 - 10/100M, 1 - 1000M

	// RGMII interface
	input rgmii_rxclk, // 125M/25M/2.5M
	input [3:0] rgmii_rxdat,
	input rgmii_rxctl,
	output rgmii_gtxclk, // 125M/25M/2.5M
	output [3:0] rgmii_txdat,
	output rgmii_txctl,
	input rgmii_crs,
	input rgmii_col,

	// GMII interface
	output user_clk, // user app use this clock for both tx and rx
	input [7:0] txd,
	input txen,
	input txer,
	output [7:0] rxd,
	output rxdv,
	output rxer,
	output crs,
	output col
);

rgmii_rx rx_i(
	.reset(reset),
	.speed(speed),
	.rgmii_rxclk(rgmii_rxclk),
	.rgmii_rxdat(rgmii_rxdat),
	.rgmii_rxctl(rgmii_rxctl),
	.rgmii_crs(rgmii_crs),
	.rgmii_col(rgmii_col),
	.user_clk(user_clk),
	.rxd(rxd),
	.rxdv(rxdv),
	.rxer(rxer),
	.crs(crs),
	.col(col),
	.clk_x2(clk_x2)
);

rgmii_tx tx_i(
	.reset(reset),
	.speed(speed),
	.clk_x2(clk_x2),
	.user_clk(user_clk),
	.txd(txd),
	.txen(txen),
	.txer(txer),
	.rgmii_gtxclk(rgmii_gtxclk),
	.rgmii_txdat(rgmii_txdat),
	.rgmii_txctl(rgmii_txctl)
);

endmodule
