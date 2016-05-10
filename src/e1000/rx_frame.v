module rx_frame(
	input aclk,
	input aresetn,

	input [7:0] PCSS, // Packet Checksum Start

	// Command Port
	// C1: [31:16]=Length, [15:0]=Local Address (Free Buffer)
	input [31:0] cmd_s_tdata,
	input cmd_s_tvalid,
	input cmd_s_tlast,
	output cmd_s_tready,

	// Report Port
	// [31:16]=Length, [15:0]=Local Address (Valid Buffer)
	// C2: [31:0]=DESC_DW2
	// C3: [31:0]=DESC_DW3
	output reg [31:0] stat_m_tdata,
	output reg stat_m_tvalid,
	output reg stat_m_tlast,
	input stat_m_tready,

	output [3:0] dram_m_awid,
	output [15:0] dram_m_awaddr,
	output [7:0] dram_m_awlen,
	output [2:0] dram_m_awsize,
	output [1:0] dram_m_awburst,
	output dram_m_awvalid,
	input dram_m_awready,

	output [3:0] dram_m_wid,
	output [31:0] dram_m_wdata,
	output [3:0] dram_m_wstrb,
	output dram_m_wlast,
	output dram_m_wvalid,
	input dram_m_wready,

	input [3:0] dram_m_bid,
	input [1:0] dram_m_bresp,
	input dram_m_bvalid,
	output dram_m_bready,

	output [3:0] dram_m_arid,
	output [15:0] dram_m_araddr,
	output [7:0] dram_m_arlen,
	output [2:0] dram_m_arsize,
	output [1:0] dram_m_arburst,
	output dram_m_arvalid,
	input dram_m_arready,

	input [3:0] dram_m_rid,
	input [31:0] dram_m_rdata,
	input [1:0] dram_m_rresp,
	input dram_m_rlast,
	input dram_m_rvalid,
	output dram_m_rready,

	// MAC Rx Port
	input [31:0] mac_s_tdata,
	input [3:0] mac_s_tkeep,
	input mac_s_tvalid,
	input mac_s_tlast,
	output mac_s_tready	
);

wire [31:0] buf_fifo_din;
wire buf_fifo_wr;
wire buf_fifo_full;
wire [31:0] buf_fifo_dout;
wire buf_fifo_rd;
wire buf_fifo_empty;

wire [31:0] wdma_cmd_tdata;
wire wdma_cmd_tvalid;
wire wdma_cmd_tlast;
wire wdma_cmd_tready;

wire [31:0] wdma_rpt_tdata;
wire wdma_rpt_tvalid;
wire wdma_rpt_tlast;
reg wdma_rpt_tready;

wire [31:0] din_s_tdata;
wire din_s_tvalid;
wire din_s_tlast;
wire din_s_tready;

reg [31:0] valid_data;
reg [15:0] checksum;

integer state, state_next;

localparam S_IDLE=0, S_WAIT=1, S_RPT_STB=2, S_RPT_C0=3, S_RPT_C1=4, S_RPT_C2=5;

assign buf_fifo_din = cmd_s_tdata;
assign buf_fifo_wr = cmd_s_tvalid & cmd_s_tready;
assign cmd_s_tready = !buf_fifo_full;

assign wdma_cmd_tdata = buf_fifo_dout;
assign wdma_cmd_tlast = 1'b0;
assign wdma_cmd_tvalid = !buf_fifo_empty;
assign buf_fifo_rd = wdma_cmd_tvalid & wdma_cmd_tready;

assign din_s_tdata = mac_s_tdata;
assign din_s_tlast = mac_s_tlast;
assign din_s_tvalid = (state==S_IDLE)?mac_s_tvalid:1'b0;
assign mac_s_tready = (state==S_IDLE)?din_s_tready:1'b0;

assign dram_m_bready = 1'b1;
assign dram_m_arvalid = 1'b0;
assign dram_m_rready = 1'b1;

// FIXME: replace with fifo_sync
fifo_async #(.DSIZE(32),.ASIZE(4),.MODE("FWFT")) buf_fifo_i(
	.wr_rst(!aresetn),
	.wr_clk(aclk),
	.din(buf_fifo_din),
	.wr_en(buf_fifo_wr),
	.full(buf_fifo_full),
	.rd_rst(!aresetn),
	.rd_clk(aclk),
	.dout(buf_fifo_dout),
	.rd_en(buf_fifo_rd),
	.empty(buf_fifo_empty)
);

axi_wdma #(.ADDRESS_BITS(16), .LENGTH_BITS(16)) wdma_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.cmd_s_tdata(wdma_cmd_tdata),
	.cmd_s_tvalid(wdma_cmd_tvalid),
	.cmd_s_tlast(wdma_cmd_tlast),
	.cmd_s_tready(wdma_cmd_tready),

	.rpt_m_tdata(wdma_rpt_tdata),
	.rpt_m_tvalid(wdma_rpt_tvalid),
	.rpt_m_tlast(wdma_rpt_tlast),
	.rpt_m_tready(wdma_rpt_tready),

	.axi_m_awid(dram_m_awid),
	.axi_m_awaddr(dram_m_awaddr),
	.axi_m_awlen(dram_m_awlen),
	.axi_m_awsize(dram_m_awsize),
	.axi_m_awburst(dram_m_awburst),
	.axi_m_awvalid(dram_m_awvalid),
	.axi_m_awready(dram_m_awready),

	.axi_m_wid(dram_m_wid),
	.axi_m_wdata(dram_m_wdata),
	.axi_m_wlast(dram_m_wlast),
	.axi_m_wvalid(dram_m_wvalid),
	.axi_m_wready(dram_m_wready),

	.axi_m_bid(dram_m_bid),
	.axi_m_bresp(dram_m_bresp),
	.axi_m_bvalid(dram_m_bvalid),
	.axi_m_bready(dram_m_bready),

	.din_s_tdata(din_s_tdata),
	.din_s_tkeep(din_s_tkeep),
	.din_s_tlast(din_s_tlast),
	.din_s_tvalid(din_s_tvalid),
	.din_s_tready(din_s_tready)
);

always @(*)
begin
	valid_data[31:24] = mac_s_tkeep[3]?mac_s_tdata[31:24]:8'b0;
	valid_data[23:16] = mac_s_tkeep[2]?mac_s_tdata[23:16]:8'b0;
	valid_data[15:8] = mac_s_tkeep[1]?mac_s_tdata[15:8]:8'b0;
	valid_data[7:0] = mac_s_tkeep[0]?mac_s_tdata[7:0]:8'b0;
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		checksum <= 'b0;
	end
	else if(din_s_tvalid && din_s_tready) begin
		checksum <= checksum + valid_data[31:16] + valid_data[15:0];
	end
	else if(stat_m_tvalid && stat_m_tlast && stat_m_tready) begin
		checksum <= 'b0;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn)
		state <= S_IDLE;
	else
		state <= state_next;
end

always @(*)
begin
	case(state)
		S_IDLE: begin
			if(din_s_tvalid && din_s_tlast && din_s_tready) 
				state_next = S_WAIT;
			else
				state_next = S_IDLE;
		end
		S_WAIT: begin
			if(wdma_rpt_tvalid && wdma_rpt_tready)
				state_next = S_RPT_STB;
			else
				state_next = S_WAIT;
		end
		S_RPT_STB,S_RPT_C0: begin
			if(stat_m_tready)
				state_next = S_RPT_C1;
			else
				state_next = S_RPT_C0;
		end
		S_RPT_C1: begin
			if(stat_m_tready)
				state_next = S_RPT_C2;
			else
				state_next = S_RPT_C1;
		end
		S_RPT_C2: begin
			if(stat_m_tready)
				state_next = S_IDLE;
			else
				state_next = S_RPT_C2;
		end
		default: begin
			state_next = 'bx;
		end
	endcase
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
	end
	else case(state_next)
		S_IDLE: begin
			stat_m_tvalid <= 1'b0;
			stat_m_tlast <= 1'b0;
			wdma_rpt_tready <= 1'b0;
		end
		S_WAIT: begin
			wdma_rpt_tready <= 1'b1;
		end
		S_RPT_STB: begin
			wdma_rpt_tready <= 1'b0;
			stat_m_tdata <= wdma_rpt_tdata; 
			stat_m_tvalid <= 1'b1;
		end
		S_RPT_C0: begin
		end
		S_RPT_C1: begin
			stat_m_tdata[31:16] <= checksum; 
			stat_m_tdata[15:0] <= stat_m_tdata[31:16];
		end
		S_RPT_C2: begin
			stat_m_tdata <= 'b0;
			stat_m_tlast <= 1'b1;
		end
	endcase
end

endmodule
