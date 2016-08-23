module phy_ft(
	input rst,
	input clk,	

	output [1:0] speed,
	output full_duplex,
	output link_up,
	output active_port,
	output link_change,
	output [1:0] phy0_speed,
	output phy0_duplex,
	output phy0_up,
	output [1:0] phy1_speed,
	output phy1_duplex,
	output phy1_up,

	// GMII Port
	output	rxclk,
	output	[7:0]	rxdat,
	output	rxdv,
	output	rxer,
	input	txclk,
	input	[7:0]	txdat,
	input	txen,
	input	txer,
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

	// In-band Status
	input phy0_ibs_up,
	input [1:0] phy0_ibs_spd,
	input phy0_ibs_dplx,

	// MDIO Port
	output	phy0_mdc,
	input	phy0_mdio_i,
	output	phy0_mdio_o,
	output	phy0_mdio_oe,

	// PHY Misc
	input	phy0_int,
	output	phy0_reset_out,

	// MAC Port
	input   phy1_rxclk,
	input	[7:0]	phy1_rxdat,
	input	phy1_rxdv,
	input	phy1_rxer,
	output	phy1_txclk,
	output	[7:0]	phy1_txdat,
	output	phy1_txen,
	output	phy1_txer,
	input	phy1_crs,
	input	phy1_col,

	// In-band Status
	input phy1_ibs_up,
	input [1:0] phy1_ibs_spd,
	input phy1_ibs_dplx,

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
parameter INIT_TIMEOUT = 6000000/CLK_PERIOD_NS+1;
parameter INIT_EPCR = "TRUE";
parameter USE_PHY_IBS = "TRUE";
parameter USE_POLLING = "TRUE";
parameter LINK_UP_DELAY_CYCLES = (500000000/CLK_PERIOD_NS);
parameter POLLING_INTERVAL_US = 100;

localparam POLLING_INTERVAL = POLLING_INTERVAL_US*1000/CLK_PERIOD_NS;

parameter MASSIVE_ERROR_THRESHOLD = 10;

wire reset;

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
reg p0_new_page;
reg p0_massive_error;
reg p1_up;
reg [1:0] p1_speed;
reg p1_duplex;
reg p1_new_page;
reg p1_massive_error;

reg mdio_gnt_r;

reg mdio_req_0, mdio_req_1;

reg [23:0] init_timer;

reg phy0_ibs_up_0, phy0_ibs_up_1, phy0_ibs_up_d;
reg phy0_ibs_dplx_0, phy0_ibs_dplx_1;
reg [1:0] phy0_ibs_spd_0, phy0_ibs_spd_1;
reg [31:0] phy0_up_delay;
reg phy1_ibs_up_0, phy1_ibs_up_1, phy1_ibs_up_d;
reg phy1_ibs_dplx_0, phy1_ibs_dplx_1;
reg [1:0] phy1_ibs_spd_0, phy1_ibs_spd_1;
reg [31:0] phy1_up_delay;

reg [31:0] polling_timer;
wire polling_timeout;

integer state, state_next;
localparam 
	S_INIT=0,S_REPCR_STRB=1,S_REPCR_WAIT=2,S_WEPCR_STRB=3,S_WEPCR_WAIT=4,
	S_RCTRL_STRB=5,S_RCTRL_WAIT=6,S_WCTRL_STRB=7,S_WCTRL_WAIT=8,
	S_IDLE=9, S_HOST_ACCESS=10, S_READ_STRB=11, S_READ_WAIT=12, 
	S_READ_LATCH=13, S_SELECT=14, S_RECR_STRB=15, S_RECR_WAIT=16, S_RECR_LATCH=17;

assign reset = rst|reset_in;

assign mdio_i = select? phy1_mdio_i:phy0_mdio_i;

assign intr_out = select? phy1_int:phy0_int;

assign phy0_reset_out = reset;

assign phy0_mdc = mdio_gnt? mdc:p0_mdc;
assign phy0_mdio_o = mdio_gnt? mdio_o:p0_mdio_o;
assign phy0_mdio_oe = mdio_gnt? mdio_oe:p0_mdio_oe;
assign p0_mdio_i = phy0_mdio_i;

assign phy1_reset_out = reset;

assign phy1_mdc = mdio_gnt? mdc:p1_mdc;
assign phy1_mdio_o = mdio_gnt? mdio_o:p1_mdio_o;
assign phy1_mdio_oe = mdio_gnt? mdio_oe:p1_mdio_oe;
assign p1_mdio_i = phy1_mdio_i;

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

assign phy0_speed = p0_speed;
assign phy0_up = p0_up;
assign phy0_duplex = p0_duplex;
assign phy1_speed = p1_speed;
assign phy1_up = p1_up;
assign phy1_duplex = p1_duplex;

always @(posedge clk)
begin
	phy0_ibs_spd_0 <= phy0_ibs_spd;
	phy0_ibs_spd_1 <= phy0_ibs_spd_0;

	phy0_ibs_dplx_0 <= phy0_ibs_dplx;
	phy0_ibs_dplx_1 <= phy0_ibs_dplx_0;

	phy0_ibs_up_0 <= phy0_ibs_up;
	phy0_ibs_up_1 <= phy0_ibs_up_0;

	phy1_ibs_spd_0 <= phy1_ibs_spd;
	phy1_ibs_spd_1 <= phy1_ibs_spd_0;

	phy1_ibs_up_0 <= phy1_ibs_up;
	phy1_ibs_up_1 <= phy1_ibs_up_0;

	phy1_ibs_dplx_0 <= phy1_ibs_dplx;
	phy1_ibs_dplx_1 <= phy1_ibs_dplx_0;
end

phy_switch switch_i(
	.select(select),
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
	.rxclk(rxclk),
	.rxdat(rxdat),
	.rxdv(rxdv),
	.rxer(rxer),
	.txclk(txclk),
	.txdat(txdat),
	.txen(txen),
	.txer(txer),
	.crs(crs),
	.col(col)
);

shift_mdio #(.div(MDIO_DIV)) p0_mc_i(
	.clk(clk),
	.rst(reset),
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
	.rst(reset),
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

always @(posedge clk)
begin
	mdio_req_0 <= mdio_req;
	mdio_req_1 <= mdio_req_0;
end

always @(posedge clk, posedge reset)
begin
	if(reset)
		state <= S_INIT;
	else
		state <= state_next;
end

always @(*)
begin
	case(state)
		S_INIT: begin
			if(init_timer==INIT_TIMEOUT) 
				if(INIT_EPCR=="TRUE")
					state_next = S_REPCR_STRB;
				else
					state_next = S_IDLE;
			else
				state_next = S_INIT;
		end
		S_REPCR_STRB: begin
			if(!p0_rd_done)
				state_next = S_REPCR_WAIT;
			else
				state_next = S_REPCR_STRB;
		end
		S_REPCR_WAIT: begin
			if(p0_rd_done)
				state_next = S_WEPCR_STRB;
			else
				state_next = S_REPCR_WAIT;
		end
		S_WEPCR_STRB: begin
			if(!p0_wr_done)
				state_next = S_WEPCR_WAIT;
			else
				state_next = S_WEPCR_STRB;
		end
		S_WEPCR_WAIT: begin
			if(p0_wr_done)
				state_next = S_RCTRL_STRB;
			else
				state_next = S_WEPCR_WAIT;
		end
		S_RCTRL_STRB: begin
			if(!p0_rd_done)
				state_next = S_RCTRL_WAIT;
			else
				state_next = S_RCTRL_STRB;
		end
		S_RCTRL_WAIT: begin
			if(p0_rd_done)
				state_next = S_WCTRL_STRB;
			else
				state_next = S_RCTRL_WAIT;
		end
		S_WCTRL_STRB: begin
			if(!p0_wr_done)
				state_next = S_WCTRL_WAIT;
			else
				state_next = S_WCTRL_STRB;
		end
		S_WCTRL_WAIT: begin
			if(p0_wr_done)
				state_next = S_IDLE;
			else
				state_next = S_WCTRL_WAIT;
		end
		S_IDLE: begin
			if(mdio_req_1)
				state_next = S_HOST_ACCESS;
			else if(USE_POLLING == "TRUE" && polling_timeout)
				state_next = S_READ_STRB;
			else
				state_next = S_SELECT;
		end
		S_HOST_ACCESS: begin
			if(!mdio_req_1)
				state_next = S_IDLE;
			else
				state_next = S_HOST_ACCESS;
		end
		S_READ_STRB: begin
			if(!p0_rd_done && !p1_rd_done)
				state_next = S_READ_WAIT;
			else
				state_next = S_READ_STRB;
		end
		S_READ_WAIT: begin
			if(p0_rd_done && p1_rd_done)
				state_next = S_READ_LATCH;
			else
				state_next = S_READ_WAIT;
		end
		S_READ_LATCH: begin
			state_next = S_RECR_STRB;
		end
		S_RECR_STRB: begin
			if(!p0_rd_done && !p1_rd_done)
				state_next = S_RECR_WAIT;
			else
				state_next = S_RECR_STRB;
		end
		S_RECR_WAIT: begin
			if(p0_rd_done && p1_rd_done)
				state_next = S_RECR_LATCH;
			else
				state_next = S_RECR_WAIT;
		end
		S_RECR_LATCH: begin
			state_next = S_IDLE;
		end
		S_SELECT: begin
			state_next = S_IDLE;
		end
		default: begin
			state_next = 'bx;
		end
	endcase
end

always @(posedge clk, posedge reset)
begin
	if(reset) begin
		change <= 1'b0;
		start <= 1'b0;
		up <= 1'b0;
		curr_speed <= 'b0;
		curr_duplex <= 1'b0;
		select <= 1'b0;
		mdio_gnt_r <= 1'b0;

		wr_data <= 'bx;
		p0_up <= 1'b0;
		p0_speed <= 2'b10;
		p0_duplex <= 1'b1;
		p0_new_page <= 1'b0;
		p0_massive_error <= 1'b0;
		p1_up <= 1'b0;
		p1_speed <= 2'b10;
		p1_duplex <= 1'b1;
		p1_new_page <= 1'b0;
		p1_massive_error <= 1'b0;

		init_timer <= 'b0;
	end
	else case(state_next)
		S_INIT: begin
			init_timer <= init_timer+1;
		end
		S_REPCR_STRB: begin
			wr_data[31:30] <= 2'b01;
			wr_data[29:28] <= 2'b10; // read
			wr_data[27:23] <= PHY_ADDR;
			wr_data[22:18] <= 20; // Extended PHY specific control register
			wr_data[17:16] <= 2'b10;
			wr_data[15:0] <= 16'b0;
			start <= 1'b1;
		end
		S_REPCR_WAIT: begin
			start <= 1'b0;
		end
		S_WEPCR_STRB: begin
			wr_data[31:30] <= 2'b01;
			wr_data[29:28] <= 2'b01; // write
			wr_data[27:23] <= PHY_ADDR;
			wr_data[22:18] <= 20; // Extended PHY specific control register
			wr_data[17:16] <= 2'b10;
			wr_data[15:0] <= p0_rd_data|16'h0082; // Enable delay
			start <= 1'b1;
		end
		S_WEPCR_WAIT: begin
			start <= 1'b0;
		end
		S_RCTRL_STRB: begin
			wr_data[31:30] <= 2'b01;
			wr_data[29:28] <= 2'b10; // read
			wr_data[27:23] <= PHY_ADDR;
			wr_data[22:18] <= 0; // control register
			wr_data[17:16] <= 2'b10;
			wr_data[15:0] <= 16'b0;
			start <= 1'b1;
		end
		S_RCTRL_WAIT: begin
			start <= 1'b0;
		end
		S_WCTRL_STRB: begin
			wr_data[31:30] <= 2'b01;
			wr_data[29:28] <= 2'b01; // write
			wr_data[27:23] <= PHY_ADDR;
			wr_data[22:18] <= 0; // control register
			wr_data[17:16] <= 2'b10;
			wr_data[15:0] <= p0_rd_data|16'h8000; // reset
			start <= 1'b1;
		end
		S_WCTRL_WAIT: begin
			start <= 1'b0;
		end
		S_IDLE: begin
			change <= 1'b0;
			mdio_gnt_r <= 1'b0;
			start <= 1'b0;
			if(USE_PHY_IBS == "TRUE") begin
				p0_up <= phy0_ibs_up_d;
				p1_up <= phy1_ibs_up_d;
				p0_speed <= phy0_ibs_spd_1;
				p0_duplex <= phy0_ibs_dplx_1;
				p1_speed <= phy1_ibs_spd_1;
				p1_duplex <= phy1_ibs_dplx_1;
			end
		end
		S_HOST_ACCESS: begin
			mdio_gnt_r <= 1'b1;
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
			p0_up <= p0_rd_data[10] && p0_rd_data[12];
			p0_speed <= p0_rd_data[15:14];
			p0_duplex <= p0_rd_data[13];
			p1_up <= p1_rd_data[10] && p1_rd_data[12];
			p1_speed <= p1_rd_data[15:14];
			p1_duplex <= p1_rd_data[13];
			p0_new_page <= p0_rd_data[12];
			p1_new_page <= p1_rd_data[12];
		end
		S_RECR_STRB: begin
			wr_data[31:30] <= 2'b01;
			wr_data[29:28] <= 2'b10; // read
			wr_data[27:23] <= PHY_ADDR;
			wr_data[22:18] <= 21; // Error counter register
			wr_data[17:16] <= 2'b10;
			wr_data[15:0] <= 16'b0;
			start <= 1'b1;
		end
		S_RECR_WAIT: begin
			start <= 1'b0;
		end
		S_RECR_LATCH: begin
			p0_massive_error <= p0_rd_data > MASSIVE_ERROR_THRESHOLD;
			p1_massive_error <= p1_rd_data > MASSIVE_ERROR_THRESHOLD;
		end
		S_SELECT: begin
			if(up) begin
				if(!phy0_up && !phy1_up) begin
					curr_speed <= 'b0;
					curr_duplex <= 'b0;
					up <= 1'b0;
					change <= 1'b1;
					select <= 1'b0;
				end
				//else if(select && !phy1_up) begin // if(select)
				else if(select && phy0_up) begin // P0 has priority
					curr_speed <= phy0_speed;
					curr_duplex <= phy0_duplex;
					if(phy0_speed!=curr_speed || phy0_duplex!=curr_duplex)
						change <= 1'b1;
					select <= 1'b0;
				end
				else if(!select && !phy0_up) begin
					curr_speed <= phy1_speed;
					curr_duplex <= phy1_duplex;
					if(phy1_speed!=curr_speed || phy1_duplex!=curr_duplex)
						change <= 1'b1;
					select <= 1'b1;
				end
				// else keep status
			end
			else begin // if(!up)
				if(phy0_up) begin
					curr_speed <= phy0_speed;
					curr_duplex <= phy0_duplex;
					up <= 1'b1;
					change <= 1'b1;
					select <= 1'b0;
				end
				else if(phy1_up) begin
					curr_speed <= phy1_speed;
					curr_duplex <= phy1_duplex;
					up <= 1'b1;
					change <= 1'b1;
					select <= 1'b1;
				end
				// else keep status
			end
		end
	endcase
end

always @(posedge clk, posedge reset)
begin
	if(reset) begin
		phy0_up_delay <= 1'b0;
		phy0_ibs_up_d <= 1'b0;
	end
	else if(!phy0_ibs_up_1 || p0_massive_error) begin
		phy0_up_delay <= 1'b0;
		phy0_ibs_up_d <= 1'b0;
	end
	else if(phy0_up_delay == LINK_UP_DELAY_CYCLES) begin
		phy0_ibs_up_d <= 1'b1;
	end
	else begin
		phy0_up_delay <= phy0_up_delay+1;
	end
end

always @(posedge clk, posedge reset)
begin
	if(reset) begin
		phy1_up_delay <= 1'b0;
		phy1_ibs_up_d <= 1'b0;
	end
	else if(!phy1_ibs_up_1 || p1_massive_error) begin
		phy1_up_delay <= 1'b0;
		phy1_ibs_up_d <= 1'b0;
	end
	else if(phy1_up_delay == LINK_UP_DELAY_CYCLES) begin
		phy1_ibs_up_d <= 1'b1;
	end
	else begin
		phy1_up_delay <= phy1_up_delay+1;
	end
end

always @(posedge clk, posedge reset)
begin
	if(reset) begin
		polling_timer <= 'b0;
	end
	else if(state_next == S_READ_STRB) begin
		polling_timer <= 'b0;
	end
	else if(polling_timer != POLLING_INTERVAL) begin
		polling_timer <= polling_timer + 1;
	end
end
assign polling_timeout = polling_timer==POLLING_INTERVAL;

endmodule
