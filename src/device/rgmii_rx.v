`timescale 1ns/1ps
module rgmii_rx(
	input reset,
	input speed, // 0 - 10/100M, 1 - 1000M

	// RGMII interface
	input rgmii_rxclk, // 125M/25M/2.5M
	input [3:0] rgmii_rxdat,
	input rgmii_rxctl,
	input rgmii_crs,
	input rgmii_col,

	// GMII interface
	output rxclk_x2,
	output rxclk,
	output [7:0] rxd,
	output rxdv,
	output rxer,
	output crs,
	output col
);

// STANDARD - input clock edge aligned with data edge (Source Synchronous)
// DELAYED - input clock edge has 2ns delay after data edge (Clock Delayed)
// SYSTEM - input clock edge is ahead of data edge (System Synchronous)
parameter MODE = "STANDARD"; 

wire clk_src;
wire clk_in;
wire clk_div;
wire rxclk_i;
wire [7:0] data_in;
wire rxctl_r;
wire rxctl_f;

wire crs_in;
wire col_in;

wire clk_dly;
wire [3:0] dat_dly;
wire ctl_dly;
wire crs_dly;
wire col_dly;

reg odd_flag;
reg [7:0] data_0;
reg valid_0;
reg error_0;
reg crs_0;
reg col_0;
reg [7:0] data_1;
reg valid_1;
reg error_1;
reg crs_1;
reg col_1;

reg [3:0] rst_sync;
wire rst_in;

//assign rxdv_in = rxctl_r|rxctl_f;
assign rxdv_in = rxctl_r;
assign rxer_in = rxctl_r^rxctl_f;

assign rxd = data_1;
assign rxdv = valid_1;
assign rxer = error_1;
assign crs = crs_1;
assign col = col_1;
assign rxclk_x2 = clk_in;

assign rst_in = !rst_sync[3];

always @(posedge clk_div, posedge reset)
begin
	if(reset)
		rst_sync <= 'b0;
	else
		rst_sync <= {rst_sync, 1'b1};
end

generate
if(MODE=="STANDARD") begin
	assign #2 clk_dly = rgmii_rxclk; // simulation only
	assign clk_src = clk_in;
	//BUFIO clk_src_i(.I(clk_dly), .O(clk_src)); // BUFIO has a delay of about 1ns
	BUFR #(.BUFR_DIVIDE("1")) clk_in_i(.I(clk_dly), .CLR(1'b0), .CE(1'b1), .O(clk_in));
	BUFR #(.BUFR_DIVIDE("2")) clk_div_i(.I(clk_dly), .CLR(1'b0), .CE(1'b1), .O(clk_div));
end
else if(MODE=="DELAYED") begin
	assign clk_dly = rgmii_rxclk;
	assign clk_src = clk_in;
	//BUFG clk_in_i (.I(clk_dly), .O(clk_in)); // BUFG has smallest delay
	BUFR #(.BUFR_DIVIDE("BYPASS")) clk_in_i(.I(clk_dly), .CLR(1'b0), .CE(1'b1), .O(clk_in));
	BUFR #(.BUFR_DIVIDE("2")) clk_div_i(.I(clk_dly), .CLR(1'b0), .CE(1'b1), .O(clk_div));
end
else if(MODE=="SYSTEM") begin
	assign clk_dly = !rgmii_rxclk;
	assign clk_src = clk_in;
	BUFG clk_in_i (.I(clk_dly), .O(clk_in)); // BUFG has smallest delay
	BUFR #(.BUFR_DIVIDE("2")) clk_div_i(.I(clk_dly), .CLR(1'b0), .CE(1'b1), .O(clk_div));
end

//if(MODE=="SYSTEM") begin
//	ZHOLD_DELAY dat0_dly_i(.DLYFABRIC(), .DLYIFF(dat_dly[0]), .DLYIN(rgmii_rxdat[0]));
//	ZHOLD_DELAY dat1_dly_i(.DLYFABRIC(), .DLYIFF(dat_dly[1]), .DLYIN(rgmii_rxdat[1]));
//	ZHOLD_DELAY dat2_dly_i(.DLYFABRIC(), .DLYIFF(dat_dly[2]), .DLYIN(rgmii_rxdat[2]));
//	ZHOLD_DELAY dat3_dly_i(.DLYFABRIC(), .DLYIFF(dat_dly[3]), .DLYIN(rgmii_rxdat[3]));
//	ZHOLD_DELAY ctl_dly_i(.DLYFABRIC(), .DLYIFF(ctl_dly), .DLYIN(rgmii_rxctl));
//	ZHOLD_DELAY crs_dly_i(.DLYFABRIC(), .DLYIFF(crs_dly), .DLYIN(rgmii_crs));
//	ZHOLD_DELAY col_dly_i(.DLYFABRIC(), .DLYIFF(col_dly), .DLYIN(rgmii_col));
//end
//else begin
	assign dat_dly = rgmii_rxdat;
	assign ctl_dly = rgmii_rxctl;
	assign crs_dly = rgmii_crs;
	assign col_dly = rgmii_col;
//end
endgenerate

BUFGMUX_CTRL clk_mux_i(.I0(clk_div), .I1(clk_in), .S(speed), .O(rxclk_i));
assign #1 rxclk = rxclk_i; // for simulation purpose

IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED")) d0_iddr_i(
	.D(dat_dly[0]),.C(clk_src),.Q1(data_in[0]),.Q2(data_in[4]),.CE(1'b1),.S(1'b0),.R(rst_in));

IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED")) d1_iddr_i(
	.D(dat_dly[1]),.C(clk_src),.Q1(data_in[1]),.Q2(data_in[5]),.CE(1'b1),.S(1'b0),.R(rst_in));

IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED")) d2_iddr_i(
	.D(dat_dly[2]),.C(clk_src),.Q1(data_in[2]),.Q2(data_in[6]),.CE(1'b1),.S(1'b0),.R(rst_in));

IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED")) d3_iddr_i(
	.D(dat_dly[3]),.C(clk_src),.Q1(data_in[3]),.Q2(data_in[7]),.CE(1'b1),.S(1'b0),.R(rst_in));

IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED")) ctl_iddr_i(
	.D(ctl_dly),.C(clk_src),.Q1(rxctl_r),.Q2(rxctl_f),.CE(1'b1),.S(1'b0),.R(rst_in));

IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED")) crs_iddr_i(
	.D(crs_dly),.C(clk_src),.Q1(crs_in),.Q2(),.CE(1'b1),.S(1'b0),.R(rst_in));

IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED")) col_iddr_i(
	.D(col_dly),.C(clk_src),.Q1(col_in),.Q2(),.CE(1'b1),.S(1'b0),.R(rst_in));

always @(negedge clk_in, posedge rst_in)
begin
	if(rst_in) begin
		data_0 <= 'b0;
		valid_0 <= 1'b0;
		error_0 <= 1'b0;
		crs_0 <= 1'b0;
		col_0 <= 1'b0;
		odd_flag <= 1'b0;
	end
	else if(speed) begin
		data_0 <= data_in;
		valid_0 <= rxdv_in;
		error_0 <= rxer_in;
		crs_0 <= crs_in;
		col_0 <= col_in;
		odd_flag <= 1'b0;
	end
	else begin
		if(!odd_flag) begin
			if(rxdv_in)
				data_0[3:0] <= data_in[3:0];

			if(rxdv_in || valid_0) begin
				odd_flag <= 1'b1;
			end
		end
		else begin
			data_0[7:4] <= data_in[3:0];
			valid_0 <= rxdv_in;
			error_0 <= rxer_in;
			odd_flag <= 1'b0;
		end
		crs_0 <= crs_in;
		col_0 <= col_in;
	end
end

always @(posedge rxclk, posedge rst_in)
begin
	if(rst_in) begin
		data_1 <= 'b0;
		valid_1 <= 1'b0;
		error_1 <= 1'b0;
		crs_1 <= 1'b0;
		col_1 <= 1'b0;
	end
	else begin
		data_1 <= data_0;
		valid_1 <= valid_0;
		error_1 <= error_0;
		crs_1 <= crs_0;
		col_1 <= col_0;
	end
end

endmodule
