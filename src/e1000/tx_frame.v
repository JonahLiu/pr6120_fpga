module tx_frame(
	input aclk,
	input aresetn,

	// Command Port
	// C1: [31:16]=Length, [15:0]=Local Address 
	// C2: [31:0]=DESC_DW2
	// C3: [31:0]=DESC_DW3
	input [31:0] cmd_s_tdata,
	input cmd_s_tvalid,
	input cmd_s_tlast,
	output cmd_s_tready,

	// Response Port
	// [31:16]=Length, [15:0]=Local Address
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

	output  [3:0] dram_m_arid,
	output  [15:0] dram_m_araddr,
	output  [7:0] dram_m_arlen,
	output  [2:0] dram_m_arsize,
	output  [1:0] dram_m_arburst,
	output  dram_m_arvalid,
	input dram_m_arready,

	input [3:0] dram_m_rid,
	input [31:0] dram_m_rdata,
	input [1:0] dram_m_rresp,
	input dram_m_rlast,
	input dram_m_rvalid,
	output dram_m_rready,

	// MAC Tx Port
	output [31:0] mac_m_tdata,
	output [3:0] mac_m_tkeep,
	output mac_m_tvalid,
	output mac_m_tlast,
	input mac_m_tready	
);

reg [15:0] length;
reg [15:0] local_addr;
reg [31:0] desc_dw2;
reg [31:0] desc_dw3;

wire [15:0] buf_length;
wire [15:0] buf_addr;

wire [7:0] desc_cmd;
wire desc_eop;

wire [31:0] rdma_tdata;
wire [3:0] rdma_tkeep;
wire rdma_tvalid;
wire rdma_tlast;
wire rdma_tready;

wire [31:0] algn_tdata;
wire [3:0] algn_tkeep;
wire algn_tlast;
wire algn_tvalid;
wire algn_tready;

wire [32:0] fifo_din;
wire [32:0] fifo_dout;
wire fifo_full;
wire fifo_empty;
wire fifo_wr_en;
wire fifo_rd_en;

reg [1:0] cmd_cnt;

wire cmd_valid;
wire cmd_ready;

reg [3:0] pkt_cnt;

reg start_xmit;

reg is_eop;

assign desc_cmd = desc_dw2[31:24];
assign desc_eop = desc_cmd[0];

assign fifo_din = {desc_eop, length, local_addr};
assign fifo_wr_en = cmd_s_tready && cmd_s_tvalid && cmd_s_tlast;

assign fifo_rd_en = cmd_valid && cmd_ready;

assign buf_eop = fifo_dout[32];
assign buf_length = fifo_dout[31:16];
assign buf_addr = fifo_dout[15:0];

assign cmd_s_tready = !fifo_full;

assign cmd_valid = start_xmit && !fifo_empty;

assign algn_tdata = rdma_tdata;
assign algn_tkeep = rdma_tkeep;
assign algn_tvalid = rdma_tvalid;
assign algn_tlast = rdma_tlast & is_eop;
assign rdma_tready = algn_tready;

assign dram_m_awid = 'bx;
assign dram_m_awaddr = 'bx;
assign dram_m_awlen = 'bx;
assign dram_m_awsize = 'bx;
assign dram_m_awburst = 'bx;
assign dram_m_awvalid = 1'b0;
assign darm_m_wid = 'bx;
assign dram_m_wdata = 'bx;
assign dram_m_wstrb = 'bx;
assign dram_m_wlast = 1'bx;
assign dram_m_wvalid = 1'b0;
assign dram_m_bready = 1'b1;

axi_rdma #(
	.ADDRESS_BITS(16), 
	.LENGTH_BITS(16),
	.STREAM_BIG_ENDIAN("TRUE"),
	.MEM_BIG_ENDIAN("FALSE")
) rdma_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.cmd_address(buf_addr),
	.cmd_bytes(buf_length),
	.cmd_valid(cmd_valid),
	.cmd_ready(cmd_ready),

	.axi_m_arid(dram_m_arid),
	.axi_m_araddr(dram_m_araddr),
	.axi_m_arlen(dram_m_arlen),
	.axi_m_arsize(dram_m_arsize),
	.axi_m_arburst(dram_m_arburst),
	.axi_m_arvalid(dram_m_arvalid),
	.axi_m_arready(dram_m_arready),

	.axi_m_rid(dram_m_rid),
	.axi_m_rdata(dram_m_rdata),
	.axi_m_rresp(dram_m_rresp),
	.axi_m_rlast(dram_m_rlast),
	.axi_m_rvalid(dram_m_rvalid),
	.axi_m_rready(dram_m_rready),

	.dout_tdata(rdma_tdata),
	.dout_tkeep(rdma_tkeep),
	.dout_tlast(rdma_tlast),
	.dout_tvalid(rdma_tvalid),
	.dout_tready(rdma_tready)
);

axis_realign #(
	.INPUT_BIG_ENDIAN("TRUE"), 
	.OUTPUT_BIG_ENDIAN("TRUE")
) tx_align_i(
	.aclk(aclk),
	.aresetn(aresetn),
	.s_tdata(algn_tdata),
	.s_tkeep(algn_tkeep),
	.s_tuser(2'b0),
	.s_tlast(algn_tlast),
	.s_tvalid(algn_tvalid),
	.s_tready(algn_tready),
	.m_tdata(mac_m_tdata),
	.m_tkeep(mac_m_tkeep),
	.m_tlast(mac_m_tlast),
	.m_tvalid(mac_m_tvalid),
	.m_tready(mac_m_tready)
);

// FIXME: replace with fifo_sync
fifo_async #(.DSIZE(33),.ASIZE(4),.MODE("FWFT")) addr_fifo_i(
	.wr_rst(!aresetn),
	.wr_clk(aclk),
	.din(fifo_din),
	.wr_en(cmd_s_tready && cmd_s_tvalid && cmd_s_tlast),
	.full(fifo_full),
	.rd_rst(!aresetn),
	.rd_clk(aclk),
	.dout(fifo_dout),
	.rd_en(fifo_rd_en),
	.empty(fifo_empty)
);

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		cmd_cnt <= 'b0;
		length <= 'bx;
		local_addr <= 'bx;
		desc_dw2 <= 'bx;
		desc_dw3 <= 'bx;
	end
	else if(cmd_s_tready && cmd_s_tvalid) begin
		case(cmd_cnt) /* synthesis parallel_case */
			0: begin
				length <= cmd_s_tdata[31:16];
				local_addr <= cmd_s_tdata[15:0];
			end
			1: begin
				desc_dw2 <= cmd_s_tdata;
			end
			2: begin
				desc_dw3 <= cmd_s_tdata;
			end
		endcase
		if(cmd_s_tlast) 
			cmd_cnt <= 0;
		else
			cmd_cnt <= cmd_cnt+1;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		pkt_cnt <= 'b0;
		start_xmit <= 1'b0;
	end
	else if(fifo_wr_en && desc_eop) begin
		if(fifo_rd_en && buf_eop) begin
			pkt_cnt <= pkt_cnt;
		end
		else begin
			pkt_cnt <= pkt_cnt+1;
			start_xmit <= 1'b1;
		end
	end
	else if(fifo_rd_en && buf_eop) begin
		if(pkt_cnt==1)
			start_xmit <= 1'b0;
		pkt_cnt <= pkt_cnt-1;
	end
	else if(fifo_full) begin
		start_xmit <= 1'b1;
	end
end

always @(posedge aclk)
begin
	if(cmd_valid && cmd_ready) begin
		stat_m_tdata <= {buf_length, buf_addr};
		is_eop <= buf_eop;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		stat_m_tvalid <= 1'b0;
		stat_m_tlast <= 1'b1;
	end
	else if(rdma_tvalid && rdma_tlast && rdma_tready) begin
		stat_m_tvalid <= 1'b1;
	end
	else if(stat_m_tvalid && stat_m_tready && stat_m_tlast) begin
		stat_m_tvalid <= 1'b0;
	end
end

endmodule
