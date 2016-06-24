module rgmii_if(
	input reset,
	input speed, // 0 - 10/100M, 1 - 1000M

	// In-band Status
	output ibs_up,
	output [1:0] ibs_spd,
	output ibs_dplx,

	// RGMII interface
	input rgmii_rxclk, // 125M/25M/2.5M
	input [3:0] rgmii_rxdat,
	input rgmii_rxctl,
	output rgmii_gtxclk, // 125M/25M/2.5M
	output [3:0] rgmii_txdat,
	output rgmii_txctl,
	input rgmii_crs,
	input rgmii_col,

	output [7:0] dbg_data,
	output dbg_dv,
	output dbg_er,

	// GMII interface
	input txclk_x2, // 125M/25M/2.5M, used in 10M/100M mode
	input txclk, // 125M/12.5M/1.25M
	input [7:0] txd,
	input txen,
	input txer,
	output rxclk_x2, // 125M/25M/2.5M
	output rxclk, // 125M/12.5M/1.25M
	output [7:0] rxd,
	output rxdv,
	output rxer,
	output crs,
	output col
);
// EXTERNAL - input clock has 2ns delay, output clock edge-aligned with data
// INTERNAL - input clock has no delay, output clock delayed 2ns after data
parameter DELAY_MODE = "INTERNAL";
parameter RX_MODE = (DELAY_MODE=="INTERNAL") ? "STANDARD" : "DELAYED";
parameter TX_MODE = (DELAY_MODE=="INTERNAL") ? "DELAYED" : "STANDARD";

rgmii_rx #(.MODE(RX_MODE)) rx_i(
	.reset(reset),
	.speed(speed),
	.ibs_up(ibs_up),
	.ibs_spd(ibs_spd),
	.ibs_dplx(ibs_dplx),
	.rgmii_rxclk(rgmii_rxclk),
	.rgmii_rxdat(rgmii_rxdat),
	.rgmii_rxctl(rgmii_rxctl),
	.rgmii_crs(rgmii_crs),
	.rgmii_col(rgmii_col),
	.dbg_data(dbg_data),
	.dbg_dv(dbg_dv),
	.dbg_er(dbg_er),
	.rxclk_x2(rxclk_x2),
	.rxclk(rxclk),
	.rxd(rxd),
	.rxdv(rxdv),
	.rxer(rxer),
	.crs(crs),
	.col(col)
);

rgmii_tx #(.MODE(TX_MODE)) tx_i(
	.reset(reset),
	.speed(speed),
	.txclk_x2(txclk_x2),
	.txclk(txclk),
	.txd(txd),
	.txen(txen),
	.txer(txer),
	.rgmii_gtxclk(rgmii_gtxclk),
	.rgmii_txdat(rgmii_txdat),
	.rgmii_txctl(rgmii_txctl)
);

endmodule
