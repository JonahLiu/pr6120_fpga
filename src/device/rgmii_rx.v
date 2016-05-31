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

wire clk_in;
wire clk_div;
wire rxclk_i;
wire [7:0] data_in;
wire rxctl_r;
wire rxctl_f;

reg crs_l;
reg col_l;

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

assign rxdv_in = rxctl_r|rxctl_f;
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

BUFR #(.BUFR_DIVIDE("1")) clk_in_i(.I(rgmii_rxclk), .CLR(1'b0), .CE(1'b1), .O(clk_in));
BUFR #(.BUFR_DIVIDE("2")) clk_div_i(.I(rgmii_rxclk), .CLR(1'b0), .CE(1'b1), .O(clk_div));
BUFGMUX_CTRL clk_mux_i(.I0(clk_div), .I1(clk_in), .S(speed), .O(rxclk_i));
assign #1 rxclk = rxclk_i; // for simulation purpose

IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED")) d0_iddr_i(
	.D(rgmii_rxdat[0]),.C(clk_in),.Q1(data_in[0]),.Q2(data_in[4]),.CE(1'b1),.S(1'b0),.R(rst_in));

IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED")) d1_iddr_i(
	.D(rgmii_rxdat[1]),.C(clk_in),.Q1(data_in[1]),.Q2(data_in[5]),.CE(1'b1),.S(1'b0),.R(rst_in));

IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED")) d2_iddr_i(
	.D(rgmii_rxdat[2]),.C(clk_in),.Q1(data_in[2]),.Q2(data_in[6]),.CE(1'b1),.S(1'b0),.R(rst_in));

IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED")) d3_iddr_i(
	.D(rgmii_rxdat[3]),.C(clk_in),.Q1(data_in[3]),.Q2(data_in[7]),.CE(1'b1),.S(1'b0),.R(rst_in));

IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED")) ctl_iddr_i(
	.D(rgmii_rxctl),.C(clk_in),.Q1(rxctl_r),.Q2(rxctl_f),.CE(1'b1),.S(1'b0),.R(rst_in));

always @(posedge clk_in)
begin
	crs_l <= rgmii_crs;
	col_l <= rgmii_col;
end

always @(negedge clk_in)
begin
	crs_0 <= crs_l;
	col_0 <= col_l;
end

always @(negedge clk_in, posedge rst_in)
begin
	if(rst_in) begin
		data_0 <= 'b0;
		valid_0 <= 1'b0;
		error_0 <= 1'b0;
		odd_flag <= 1'b0;
	end
	else if(speed) begin
		data_0 <= data_in;
		valid_0 <= rxdv_in;
		error_0 <= rxer_in;
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
