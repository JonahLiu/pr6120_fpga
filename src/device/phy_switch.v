`timescale 1ns/1ps
module phy_switch(
	input	rst,
	input	[47:0] mac_address,
	input	mac_valid,

	input	select,

	input	phy0_rxclk,
	input	[7:0]	phy0_rxdat,
	input	phy0_rxdv,
	input	phy0_rxer,
	output	phy0_txclk,
	output	[7:0]	phy0_txdat,
	output	phy0_txen,
	output	phy0_txer,
	input	phy0_crs,
	input	phy0_col,

	input   phy1_rxclk,
	input	[7:0]	phy1_rxdat,
	input	phy1_rxdv,
	input	phy1_rxer,
	input   phy1_txclk,
	output	[7:0]	phy1_txdat,
	output	phy1_txen,
	output	phy1_txer,
	input	phy1_crs,
	input	phy1_col,

	output	rxclk,
	output	[7:0]	rxdat,
	output	rxdv,
	output	rxer,
	input	txclk,
	input	[7:0]	txdat,
	input	txen,
	input	txer,
	output	crs,
	output	col
);

////////////////////////////////////////////////////////////////////////////////
// Rx stage

wire rxclk_i;

reg rx_sel_0;
reg rx_sel_1;
reg rx_sel_2;

reg [7:0] rxdat_0;
reg rxdv_0;
reg rxer_0;
reg crs_0;
reg col_0;

reg [7:0] rxdat_1;
reg rxdv_1;
reg rxer_1;
reg crs_1;
reg col_1;

assign rxdat = rxdat_1;
assign rxdv = rxdv_1;
assign rxer = rxer_1;
assign crs = crs_1;
assign col = col_1;

BUFGMUX_CTRL clk_mux_i(.I0(phy0_rxclk), .I1(phy1_rxclk), .S(select), .O(rxclk_i));
assign #1 rxclk = rxclk_i;

always @(posedge rxclk)
begin
	rx_sel_0 <= select;
end

always @(negedge rxclk)
begin
	rx_sel_1 <= rx_sel_0;
end

always @(posedge rxclk)
begin
	rx_sel_2 <= rx_sel_1;
end

always @(negedge rxclk)
begin
	if(rx_sel_1) begin
		rxdat_0 <= phy1_rxdat;
		rxdv_0 <= phy1_rxdv;
		rxer_0 <= phy1_rxer;
		crs_0 <= phy1_crs;
		col_0 <= phy1_col;
	end
	else begin
		rxdat_0 <= phy0_rxdat;
		rxdv_0 <= phy0_rxdv;
		rxer_0 <= phy0_rxer;
		crs_0 <= phy0_crs;
		col_0 <= phy0_col;
	end
end

always @(posedge rxclk)
begin
	rxdat_1 <= rxdat_0;
	rxdv_1 <= rxdv_0;
	rxer_1 <= rxer_0;
	crs_1 <= crs_0;
	col_1 <= col_0;
end

////////////////////////////////////////////////////////////////////////////////
// Tx stage

reg tx_sel_0;
reg tx_sel_1;

reg [7:0] phy0_txdat_0;
reg phy0_txen_0;
reg phy0_txer_0;

reg [7:0] phy1_txdat_0;
reg phy1_txen_0;
reg phy1_txer_0;

assign phy0_txclk = txclk;
assign phy0_txdat = phy0_txdat_0;
assign phy0_txen = phy0_txen_0;
assign phy0_txer = phy0_txer_0;

assign phy1_txclk = txclk;
assign phy1_txdat = phy1_txdat_0;
assign phy1_txen = phy1_txen_0;
assign phy1_txer = phy1_txer_0;

always @(posedge txclk)
begin
	tx_sel_0 <= select;
	tx_sel_1 <= tx_sel_0;
end

wire [7:0] post_txdat;
wire post_txen;
wire post_txer;
wire post_trigger = tx_sel_1!=tx_sel_0;

post_switch post_switch_i(
	.rst(rst),
	.clk(txclk),
	.mac_address(mac_address),
	.mac_valid(mac_valid),
	.trigger(post_trigger),
	.up_data(txdat),
	.up_dv(txen),
	.up_er(txer),
	.down_data(post_txdat),
	.down_dv(post_txen),
	.down_er(post_txer)
);

always @(posedge txclk)
begin
	if(tx_sel_1) begin
		phy0_txdat_0 <= 1'b0;
		phy0_txen_0 <= 1'b0;
		phy0_txer_0 <= 1'b0;
		phy1_txdat_0 <= post_txdat;
		phy1_txen_0 <= post_txen;
		phy1_txer_0 <= post_txer;
	end
	else begin
		phy0_txdat_0 <= post_txdat;
		phy0_txen_0 <= post_txen;
		phy0_txer_0 <= post_txer;
		phy1_txdat_0 <= 1'b0;
		phy1_txen_0 <= 1'b0;
		phy1_txer_0 <= 1'b0;
	end
end

endmodule
