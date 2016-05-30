module rgmii_tx(
	input reset,
	input speed, // 0 - 10/100M, 1 - 1000M

	// GMII interface
	input clk_x2, // for 10/100M mode, 125M/25M/2.5M
	input user_clk, // 125M/12.5M/1.25M
	input [7:0] txd,
	input txen,
	input txer,

	// RGMII interface
	output rgmii_gtxclk, // 125M/25M/2.5M
	output [3:0] rgmii_txdat,
	output rgmii_txctl
);

reg [3:0] rst_sync;
wire rst_in;

wire txctl_r;
wire txctl_f;

assign txctl_r = txen;
assign txctl_f = txen^txer;

assign rst_in = !rst_sync[3];

always @(posedge user_clk, posedge reset)
begin
	if(reset)
		rst_sync <= 'b0;
	else
		rst_sync <= {rst_sync, 1'b1};
end

BUFGMUX_CTRL(.I0(clk_x2), .I1(user_clk), .S(speed), .O(clk_out));

ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) d0_oddr_i(
	.D1(txd[0]), .D2(txd[4]), .CE(1'b1), .C(user_clk), .S(1'b0), .R(rst_in), .Q(rgmii_txdat[0]));

ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) d1_oddr_i(
	.D1(txd[1]), .D2(txd[5]), .CE(1'b1), .C(user_clk), .S(1'b0), .R(rst_in), .Q(rgmii_txdat[1]));

ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) d2_oddr_i(
	.D1(txd[2]), .D2(txd[6]), .CE(1'b1), .C(user_clk), .S(1'b0), .R(rst_in), .Q(rgmii_txdat[2]));

ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) d3_oddr_i(
	.D1(txd[3]), .D2(txd[7]), .CE(1'b1), .C(user_clk), .S(1'b0), .R(rst_in), .Q(rgmii_txdat[3]));

ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) ctl_oddr_i(
	.D1(txctl_r), .D2(txctl_f), .CE(1'b1), .C(clk_out), .S(1'b0), .R(rst_in), .Q(rgmii_txctl));

ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) clk_oddr_i(
	.D1(1'b1), .D2(1'b0), .CE(1'b1), .C(clk_out), .S(1'b0), .R(rst_in), .Q(rgmii_gtxclk));



endmodule
