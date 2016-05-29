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
reg crs_0;
reg col_0;
reg crs_1;
reg col_1;

assign crs = crs_1;
assign col = col_1;

rgmii_rx rx_i(
	.reset(reset),
	.speed(speed),
	.rgmii_rxclk(rgmii_rxclk),
	.rgmii_rxdat(rgmii_rxdat),
	.rgmii_rxctl(rgmii_rxctl),
	.user_clk(user_clk),
	.rxd(rxd),
	.rxdv(rxdv),
	.rxer(rxer),
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

always @(posedge user_clk)
begin
	crs_0 <= rgmii_crs;
	col_0 <= rgmii_col;
	crs_1 <= crs_0;
	col_1 <= col_0;
end

endmodule
