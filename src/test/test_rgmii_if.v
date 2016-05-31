`timescale 1ns/1ps
module test_rgmii_if(
);

reg reset;
reg speed;
reg clk125;
reg clk25;
reg clk12p5;

wire p0_rxsclk;
wire [3:0] p0_rxdat;
wire p0_rxdv;
wire p0_gtxsclk;
wire [3:0] p0_txdat;
wire p0_txen;
wire p0_crs;
wire p0_col;

wire p1_rxsclk;
wire [3:0] p1_rxdat;
wire p1_rxdv;
wire p1_gtxsclk;
wire [3:0] p1_txdat;
wire p1_txen;
wire p1_crs;
wire p1_col;

wire phy0_txclk;
wire phy0_txclk_x2;
wire [7:0] phy0_txdat;
wire phy0_txen;
wire phy0_txer;
wire phy0_rxclk_x2;
wire phy0_rxclk;
wire [7:0] phy0_rxdat;
wire phy0_rxdv;
wire phy0_rxer;
wire phy0_crs;
wire phy0_col;

wire phy1_txclk;
wire phy1_txclk_x2;
wire [7:0] phy1_txdat;
wire phy1_txen;
wire phy1_txer;
wire phy1_rxclk_x2;
wire phy1_rxclk;
wire [7:0] phy1_rxdat;
wire phy1_rxdv;
wire phy1_rxer;
wire phy1_crs;
wire phy1_col;

assign phy0_txclk_x2 = speed ? clk125 : clk25;
assign phy0_txclk = speed ? clk125 : clk12p5;

assign phy1_txclk_x2 = speed ? clk125 : clk25;
assign phy1_txclk = speed ? clk125 : clk12p5;

assign p0_rxsclk = p1_gtxsclk;
assign p0_rxdat = p1_txdat;
assign p0_rxdv = p1_txen;
assign p0_crs = 1'b0;
assign p0_col = 1'b0;

assign p1_rxsclk = p0_gtxsclk;
assign p1_rxdat = p0_txdat;
assign p1_rxdv = p0_txen;
assign p1_crs = 1'b0;
assign p1_col = 1'b0;

rgmii_if #(.DELAY_MODE("INTERNAL")) dut0(
	.reset(reset),
	.speed(speed),

	.rgmii_rxclk(p0_rxsclk),
	.rgmii_rxdat(p0_rxdat[3:0]),
	.rgmii_rxctl(p0_rxdv),
	.rgmii_gtxclk(p0_gtxsclk),
	.rgmii_txdat(p0_txdat[3:0]),
	.rgmii_txctl(p0_txen),
	.rgmii_crs(p0_crs),
	.rgmii_col(p0_col),

	.txclk_x2(phy0_txclk_x2),
	.txclk(phy0_txclk),
	.txd(phy0_txdat),
	.txen(phy0_txen),
	.txer(phy0_txer),
	.rxclk_x2(phy0_rxclk_x2),
	.rxclk(phy0_rxclk),
	.rxd(phy0_rxdat),
	.rxdv(phy0_rxdv),
	.rxer(phy0_rxer),
	.crs(phy0_crs),
	.col(phy0_col)
);

rgmii_if #(.DELAY_MODE("EXTERNAL")) dut1(
	.reset(reset),
	.speed(speed),

	.rgmii_rxclk(p1_rxsclk),
	.rgmii_rxdat(p1_rxdat[3:0]),
	.rgmii_rxctl(p1_rxdv),
	.rgmii_gtxclk(p1_gtxsclk),
	.rgmii_txdat(p1_txdat[3:0]),
	.rgmii_txctl(p1_txen),
	.rgmii_crs(p1_crs),
	.rgmii_col(p1_col),

	.txclk_x2(phy1_txclk_x2),
	.txclk(phy1_txclk),
	.txd(phy1_txdat),
	.txen(phy1_txen),
	.txer(phy1_txer),
	.rxclk_x2(phy1_rxclk_x2),
	.rxclk(phy1_rxclk),
	.rxd(phy1_rxdat),
	.rxdv(phy1_rxdv),
	.rxer(phy1_rxer),
	.crs(phy1_crs),
	.col(phy1_col)
);

eth_pkt_gen pg0(
	.clk(phy0_txclk),
	.tx_clk(),
	.tx_dat(phy0_txdat),
	.tx_en(phy0_txen),
	.tx_er(phy0_txer)
);

eth_pkt_gen pg1(
	.clk(phy1_txclk),
	.tx_clk(),
	.tx_dat(phy1_txdat),
	.tx_en(phy1_txen),
	.tx_er(phy1_txer)
);


initial
begin
	clk125 = 0;
	forever #4 clk125 = !clk125;
end

initial
begin
	clk25 = 0;
	forever #20 clk25 = !clk25;
end

initial clk12p5=0;
always @(posedge clk25)
begin
	clk12p5 <= !clk12p5;
end

initial
begin
	$dumpfile("test_rgmii_if.vcd");
	$dumpvars(0);
	reset <= 1;
	speed = 1;
	#20 reset <= 0;
	#1000;
	pg0.send(60);
	pg1.send(60);
	pg0.send_err(60,16);
	pg1.send_err(60,16);
	#1000;
	speed = 0;
	#1000;
	pg0.send(60);
	pg1.send(60);
	pg0.send_err(60,16);
	pg1.send_err(60,16);
	#1000;
	$finish();
end

endmodule
