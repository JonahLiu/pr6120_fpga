`timescale 1ns/1ps
module test_phy_ft;
reg rst;
reg clk;	

wire [1:0] speed;
wire full_duplex;
wire link_up;
wire active_port;
wire link_change;
wire [1:0] phy0_speed;
wire phy0_up;
wire [1:0] phy1_speed;
wire phy1_up;

// GMII Port
wire  rxclk;
wire	[7:0]	rxdat;
wire	rxdv;
wire	rxer;
wire txclk;
reg	[7:0]	txdat;
reg	txen;
reg	txer;
wire	crs;
wire	col;

// MDIO Port
reg	mdc;
wire	mdio_i;
reg	mdio_o;
reg	mdio_oe;
reg   mdio_req;
wire  mdio_gnt;

// PHY Misc
wire	intr_out;
reg	reset_in;

// MAC Port
reg	phy0_rxclk;
reg	[7:0]	phy0_rxdat;
reg	phy0_rxdv;
reg	phy0_rxer;
wire	phy0_txclk;
wire	[7:0]	phy0_txdat;
wire	phy0_txen;
wire	phy0_txer;
reg	phy0_crs;
reg	phy0_col;

// MDIO Port
wire	phy0_mdc;
wire phy0_mdio_i;
wire	phy0_mdio_o;
wire	phy0_mdio_oe;

// PHY Misc
reg	phy0_int;
wire	phy0_reset_out;

// MAC Port
reg   phy1_rxclk;
reg	[7:0]	phy1_rxdat;
reg	phy1_rxdv;
reg	phy1_rxer;
wire	phy1_txclk;
wire	[7:0]	phy1_txdat;
wire	phy1_txen;
wire	phy1_txer;
reg	phy1_crs;
reg	phy1_col;

// MDIO Port
wire	phy1_mdc;
wire phy1_mdio_i;
wire	phy1_mdio_o;
wire	phy1_mdio_oe;

// PHY Misc
reg	phy1_int;
wire	phy1_reset_out;

reg [15:0] phy0_shift;
reg [7:0] phy0_cnt;
reg phy0_start;
reg [15:0] phy0_reg_val;
reg [15:0] phy1_shift;
reg [7:0] phy1_cnt;
reg phy1_start;
reg [15:0] phy1_reg_val;

assign phy0_mdio_i=phy0_mdio_oe?phy0_mdio_o:phy0_shift[15];
assign phy1_mdio_i=phy1_mdio_oe?phy1_mdio_o:phy1_shift[15];

phy_ft #(.CLK_PERIOD_NS(30),.INIT_TIMEOUT(100)) dut(
	.rst(rst),
	.clk(clk),
	.speed(speed),
	.full_duplex(full_duplex),
	.link_up(link_up),
	.active_port(active_port),
	.link_change(link_change),
	.phy0_speed(phy0_speed),
	.phy0_up(phy0_up),
	.phy1_speed(phy1_speed),
	.phy1_up(phy1_up),
	.rxclk(rxclk),
	.rxdat(rxdat),
	.rxdv(rxdv),
	.rxer(rxer),
	.txclk(txclk),
	.txdat(txdat),
	.txen(txen),
	.txer(txer),
	.crs(crs),
	.col(col),
	.mdc(mdc),
	.mdio_i(mdio_i),
	.mdio_o(mdio_o),
	.mdio_oe(mdio_oe),
	.mdio_req(mdio_req),
	.mdio_gnt(mdio_gnt),
	.intr_out(intr_out),
	.reset_in(reset_in),
	.phy0_rxclk(phy0_rxclk),
	.phy0_rxdat(phy0_rxdat),
	.phy0_rxdv(phy0_rxdv),
	.phy0_rxer(phy0_rxer),
	.phy0_txclk(phy0_txclk),
	.phy0_txdat(phy0_txdat),
	.phy0_txen(phy0_txen),
	.phy0_txer(phy0_txer),
	.phy0_crs(phy0_crs),
	.phy0_col(phy0_col),
	.phy0_mdc(phy0_mdc),
	.phy0_mdio_i(phy0_mdio_i),
	.phy0_mdio_o(phy0_mdio_o),
	.phy0_mdio_oe(phy0_mdio_oe),
	.phy0_int(phy0_int),
	.phy0_reset_out(phy0_reset_out),
	.phy1_rxclk(phy1_rxclk),
	.phy1_rxdat(phy1_rxdat),
	.phy1_rxdv(phy1_rxdv),
	.phy1_rxer(phy1_rxer),
	.phy1_txclk(phy1_txclk),
	.phy1_txdat(phy1_txdat),
	.phy1_txen(phy1_txen),
	.phy1_txer(phy1_txer),
	.phy1_crs(phy1_crs),
	.phy1_col(phy1_col),
	.phy1_mdc(phy1_mdc),
	.phy1_mdio_i(phy1_mdio_i),
	.phy1_mdio_o(phy1_mdio_o),
	.phy1_mdio_oe(phy1_mdio_oe),
	.phy1_int(phy1_int),
	.phy1_reset_out(phy1_reset_out)
);


always @(posedge phy0_mdc, posedge rst)
begin
	if(rst) begin
		phy0_start <= 1'b0;
	end
	else if(phy0_start) begin
		if(phy0_cnt>=16)
			phy0_shift <= {phy0_shift,1'b0};
		if(phy0_cnt==32)
			phy0_start <= 1'b0;
		phy0_cnt <= phy0_cnt+1;
	end
	else if(phy0_mdio_i==0) begin
		phy0_start <= 1;
		phy0_cnt <= 1;
		phy0_shift <= phy0_reg_val;
	end
end

always @(posedge phy1_mdc, posedge rst)
begin
	if(rst) begin
		phy1_start <= 1'b0;
	end
	else if(phy1_start) begin
		if(phy1_cnt>=16)
			phy1_shift <= {phy1_shift,1'b0};
		if(phy1_cnt==32)
			phy1_start <= 1'b0;
		phy1_cnt <= phy1_cnt+1;
	end
	else if(phy1_mdio_i==0) begin
		phy1_start <= 1;
		phy1_cnt <= 1;
		phy1_shift <= phy1_reg_val;
	end
end


initial 
begin
	clk=0;
	forever #15 clk=!clk;
end

initial
begin
	phy0_rxclk = 0;
	forever #4 phy0_rxclk = !phy0_rxclk;
end

initial
begin
	phy1_rxclk = 0;
	forever #20 phy1_rxclk = !phy1_rxclk;
end

assign txclk = rxclk;

always @(posedge phy0_rxclk, posedge rst)
begin
	if(rst) begin
		phy0_rxdat <= 0;
		phy0_rxdv <= 1'b0;
		phy0_rxer <= 1'b0;
		phy0_crs <= 1'b0;
		phy0_col <= 1'b0;
	end
	else begin
		phy0_rxdat <= phy0_rxdat+1;
		phy0_rxdv <= phy0_rxdat[5];
		phy0_rxer <= phy0_rxdat[4];
		phy0_crs <= phy0_rxdat[6];
		phy0_col <= phy0_rxdat[7];
	end
end

always @(posedge phy1_rxclk, posedge rst)
begin
	if(rst) begin
		phy1_rxdat <= 0;
		phy1_rxdv <= 1'b0;
		phy1_rxer <= 1'b0;
		phy1_crs <= 1'b0;
		phy1_col <= 1'b0;
	end
	else begin
		phy1_rxdat <= phy1_rxdat+1;
		phy1_rxdv <= phy1_rxdat[5];
		phy1_rxer <= phy1_rxdat[4];
		phy1_crs <= phy1_rxdat[6];
		phy1_col <= phy1_rxdat[7];
	end
end

always @(posedge txclk, posedge rst)
begin
	if(rst) begin
		txdat <= 0;
		txen <= 1'b0;
		txer <= 1'b0;
	end
	else begin
		txdat <= txdat+1;
		txen <= txdat[5];
		txer <= txdat[4];
	end
end

initial
begin
	$dumpfile("test_phy_ft.vcd");
	$dumpvars(0);
	rst <= 1;
	reset_in <= 1'b0;
	mdio_req <= 1'b0;
	phy0_int <= 1'b0;
	phy1_int <= 1'b0;
	phy0_reg_val <= 16'h0000;
	phy1_reg_val <= 16'h0000;
	@(posedge clk);
	rst <= 0;
	#100000;
	phy0_reg_val <= 16'hAC0C;
	#100000;
	phy1_reg_val <= 16'h6C0C;
	#100000;
	phy0_reg_val <= 16'h0000;
	#100000;
	phy1_reg_val <= 16'h0000;
	#100000;
	phy1_reg_val <= 16'hAC0C;
	#100000;
	phy0_reg_val <= 16'h6C0C;
	#100000;
	mdio_req <= 1'b1;
	mdc <= 1;
	mdio_o <= 0;
	mdio_oe <= 1'b1;
	#100000;
	mdc <= 0;
	mdio_o <= 1;
	mdio_oe <= 1'b0;
	#100000;
	mdio_req <= 1'b0;
	#100000;
	$finish();
end

endmodule
