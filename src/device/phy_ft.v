module phy_ft(
	input rst,
	input clk,	

	output [1:0] speed,
	output full_duplex,
	output link_up,
	output active_port,
	output link_change,

	// GMII Port
	output	[7:0]	rxdat,
	output	rxdv,
	output	rxer,
	output	rxsclk,
	input	[7:0]	txdat,
	input	txen,
	input	txer,
	output	txsclk,
	input	gtxsclk,
	output	crs,
	output	col,

	// MDIO Port
	input	mdc,
	output	mdio_i,
	input	mdio_o,
	input	mdio_oe,
	input   mdio_req,
	output  mdio_gnt,

	// PHY Misc
	output	intr_out,
	input	reset_in,

	// GMII Port
	input	[7:0]	phy0_rxdat,
	input	phy0_rxdv,
	input	phy0_rxer,
	input	phy0_rxsclk,
	output	[7:0]	phy0_txdat,
	output	phy0_txen,
	output	phy0_txer,
	input	phy0_txsclk,
	output	phy0_gtxsclk,
	input	phy0_crs,
	input	phy0_col,

	// MDIO Port
	output	phy0_mdc,
	input	phy0_mdio_i,
	output	phy0_mdio_o,
	output	phy0_mdio_oe,

	// PHY Misc
	input	phy0_int,
	output	phy0_reset_out,

	// GMII Port
	input	[7:0]	phy1_rxdat,
	input	phy1_rxdv,
	input	phy1_rxer,
	input	phy1_rxsclk,
	output	[7:0]	phy1_txdat,
	output	phy1_txen,
	output	phy1_txer,
	input	phy1_txsclk,
	output	phy1_gtxsclk,
	input	phy1_crs,
	input	phy1_col,

	// MDIO Port
	output	phy1_mdc,
	input	phy1_mdio_i,
	output	phy1_mdio_o,
	output	phy1_mdio_oe,

	// PHY Misc
	input	phy1_int,
	output	phy1_reset_out
);

parameter PHY_ADDR = 5'b0;
parameter CLK_PERIOD_NS = 8;
localparam MDIO_DIV = (1000000000/8000000)/CLK_PERIOD_NS+1;

wire p0_mdc;
wire p0_mdio_i;
wire p0_mdio_o;
wire p0_mdio_oe;
wire [15:0] p0_rd_data;
wire p0_rd_done;
wire p0_wr_done;
wire [31:0] p0_wr_data;
wire p0_start;

wire p1_mdc;
wire p1_mdio_i;
wire p1_mdio_o;
wire p1_mdio_oe;
wire [15:0] p1_rd_data;
wire p1_rd_done;
wire p1_wr_done;
wire [31:0] p1_wr_data;
wire p1_start;

reg change;
reg start;
reg up;
reg [1:0] curr_speed;
reg curr_duplex;
reg select;
reg [31:0] wr_data;
reg p0_up;
reg [1:0] p0_speed;
reg p0_duplex;
reg p1_up;
reg [1:0] p1_speed;
reg p1_duplex;

reg mdio_gnt_r;

reg [7:0] rxdat_r;
reg rxdv_r;
reg rxer_r;
reg crs_r;
reg col_r;
reg txsclk_r;

wire rxsclk_a;
wire [7:0] rxdat_a;
wire rxdv_a;
wire rxer_a;
wire crs_a;
wire col_a;
wire txsclk_a;

integer state, state_next;
localparam S_IDLE=0, S_HOST_ACCESS=1, S_READ_STRB=2, S_READ_WAIT=3, S_READ_LATCH=4,
	S_SELECT=5;

assign rxsclk_a = select? phy1_rxsclk:phy0_rxsclk;
assign rxdat_a = select? phy1_rxdat:phy0_rxdat;
assign rxdv_a = select? phy1_rxdat:phy0_rxdat;
assign rxer_a = select? phy1_rxdat:phy0_rxdat;
assign crs_a = select? phy1_rxdat:phy0_rxdat;
assign col_a = select? phy1_rxdat:phy0_rxdat;

assign txsclk_a = select? phy1_txsclk:phy0_txsclk;

assign rxsclk = rxsclk_a;
assign rxdat = rxdat_r;
assign rxdv = rxdv_r;
assign rxer = rxer_r;
assign crs = crs_r;
assign col = col_r;
assign txsclk = txsclk_a;

assign mdio_i = select? phy1_mdio_i:phy0_mdio_i;

assign intr_out = select? phy1_int:phy0_int;

assign phy0_txdat = txdat;
assign phy0_txen = (!select)? txen:1'b0;
assign phy0_txer = (!select)? txer:1'b0;
assign phy0_gtxsclk = gtxsclk;

assign phy0_reset_out = reset_in;

assign phy0_mdc = mdio_gnt? mdc:p0_mdc;
assign phy0_mdio_o = mdio_gnt? mdio_o:p0_mdio_o;
assign phy0_mdio_oe = mdio_gnt? mdio_oe:p0_mdio_oe;

assign phy1_txdat = txdat;
assign phy1_txen = (select)? txen:1'b0;
assign phy1_txer = (select)? txer:1'b0;
assign phy1_gtxsclk = gtxsclk;

assign phy1_reset_out = reset_in;

assign phy1_mdc = mdio_gnt? mdc:p1_mdc;
assign phy1_mdio_o = mdio_gnt? mdio_o:p1_mdio_o;
assign phy1_mdio_oe = mdio_gnt? mdio_oe:p1_mdio_oe;

assign speed = curr_speed;
assign full_duplex = curr_duplex;
assign link_up = up;
assign link_change = change;
assign active_port = select;

assign mdio_gnt = mdio_gnt_r;

assign p0_wr_data = wr_data;
assign p0_start = start;
assign p1_wr_data = wr_data;
assign p1_start = start;

shift_mdio #(.div(MDIO_DIV)) p0_mc_i(
	.clk(clk),
	.rst(rst),
	.mdc_o(p0_mdc),
	.mdio_i(p0_mdio_i),
	.mdio_o(p0_mdio_o),
	.mdio_oe(p0_mdio_oe),
	.rdatao(p0_rd_data),
	.rd_doneo(p0_rd_done),
	.eni(p0_start),
	.wdatai(p0_wr_data),
	.wr_doneo(p0_wr_done),
	.bus_req(),
	.bus_gnt(1'b1)
);

shift_mdio #(.div(MDIO_DIV)) p1_mc_i(
	.clk(clk),
	.rst(rst),
	.mdc_o(p1_mdc),
	.mdio_i(p1_mdio_i),
	.mdio_o(p1_mdio_o),
	.mdio_oe(p1_mdio_oe),
	.rdatao(p1_rd_data),
	.rd_doneo(p1_rd_done),
	.eni(p1_start),
	.wdatai(p1_wr_data),
	.wr_doneo(p1_wr_done),
	.bus_req(),
	.bus_gnt(1'b1)
);

always @(posedge rxsclk)
begin
	rxdat_r <= rxdat_a;
	rxdv_r <= rxdv_a;
	rxer_r <= rxer_a;
	crs_r <= crs_a;
	col_r <= col_a;
end

always @(posedge clk, posedge rst)
begin
	if(rst)
		state <= S_IDLE;
	else
		state <= state_next;
end

always @(*)
begin
	case(state)
		S_IDLE: begin
			if(mdio_req)
				state_next = S_HOST_ACCESS;
			else 
				state_next = S_READ_STRB;
		end
		S_READ_STRB: begin
			if(!m0_rd_done && !m1_rd_done)
				state_next = S_READ_WAIT;
			else
				state_next = S_READ_STRB;
		end
		S_READ_WAIT: begin
			if(m0_rd_done && m1_rd_done)
				state_next = S_READ_LATCH;
			else
				state_next = S_READ_WAIT;
		end
		S_READ_LATCH: begin
			state_next = S_SELECT;
		end
		S_SELECT: begin
			state_next = S_IDLE;
		end
		default: begin
			state_next = 'bx;
		end
	endcase
end


always @(posedge clk, posedge rst)
begin
	if(rst) begin
		change <= 1'b0;
		start <= 1'b0;
		up <= 1'b0;
		curr_speed <= 'b0;
		curr_duplex <= 1'b0;
		select <= 1'b1;
		mdio_gnt_r <= 1'b0;

		wr_data <= 'bx;
		p0_up <= 1'b0;
		p0_speed <= 2'b10;
		p0_duplex <= 1'b1;
		p1_up <= 1'b0;
		p1_speed <= 2'b10;
		p1_duplex <= 1'b1;
	end
	else case
		S_IDLE: begin
			change <= 1'b0;
			mdio_gnt <= 1'b0;
		end
		S_HOST_ACCESS: begin
			mdio_gnt <= 1'b1;
		end
		S_READ_STRB: begin
			wr_data[31:30] <= 2'b01;
			wr_data[29:28] <= 2'b10; // read
			wr_data[27:23] <= PHY_ADDR;
			wr_data[22:18] <= 17; // PHY specific status register
			wr_data[17:16] <= 2'b10;
			wr_data[15:0] <= 16'b0;
			start <= 1'b1;
		end
		S_READ_WAIT: begin
			start <= 1'b0;
		end
		S_READ_LATCH: begin
			p0_up <= p0_rd_data[10];
			// FIXME: enable speed switch
			//p0_speed <= p0_rd_data[15:14];
			//p0_duplex <= p0_rd_data[13];
			p1_up <= p1_rd_data[10];
			//p1_speed <= p1_rd_data[15:14];
			//p1_duplex <= p1_rd_data[13];
		end
		S_SELECT: begin
			if(up) begin
				if(!p0_up && !p1_up) begin
					curr_speed <= 'b0;
					curr_duplex <= 'b0;
					up <= 1'b0;
					change <= 1'b1;
				end
				else if(!select && !p0_up) begin
					curr_speed <= p1_speed;
					curr_duplex <= p1_duplex;
					up <= 1'b1;
					if(p1_speed!=curr_speed || p1_duplex!=curr_duplex)
						change <= 1'b1;
				end
				else if(select && !p1_up) begin // if(select)
					curr_speed <= p0_speed;
					curr_duplex <= p0_duplex;
					up <= 1'b1;
					if(p0_speed!=curr_speed || p0_duplex!=curr_duplex)
						change <= 1'b1;
				end
				// else keep status
			end
			else begin // if(!up)
				if(p0_up) begin
					curr_speed <= p0_speed;
					curr_duplex <= p0_duplex;
					up <= 1'b1;
					change <= 1'b1;
				end
				else if(p1_up) begin
					curr_speed <= p1_speed;
					curr_duplex <= p1_duplex;
					up <= 1'b1;
					change <= 1'b1;
				end
				// else keep status
			end
		end
	endcase
end


endmodule
