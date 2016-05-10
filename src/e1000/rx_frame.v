module rx_frame(
	input aclk,
	input aresetn,

	input [7:0] PCSS, // Packet Checksum Start

	output RXO_req, // RX FIFO Overrun Interrupt Request

	// Command Port
	// C1: [31:16]=Length, [15:0]=Local Address (Free Buffer)
	input [31:0] cmd_s_tdata,
	input cmd_s_tvalid,
	input cmd_s_tlast,
	output reg cmd_s_tready,

	// Report Port
	// [31:16]=Length, [15:0]=Local Address (Valid Buffer)
	// C2: [31:0]=DESC_DW2
	// C3: [31:0]=DESC_DW3
	output reg [31:0] stat_m_tdata,
	output reg stat_m_tvalid,
	output reg stat_m_tlast,
	input stat_m_tready,

	output reg [3:0] dram_m_awid,
	output reg [15:0] dram_m_awaddr,
	output reg [7:0] dram_m_awlen,
	output reg [2:0] dram_m_awsize,
	output reg [1:0] dram_m_awburst,
	output reg dram_m_awvalid,
	input dram_m_awready,

	output reg [3:0] dram_m_wid,
	output reg [31:0] dram_m_wdata,
	output reg [3:0] dram_m_wstrb,
	output reg dram_m_wlast,
	output reg dram_m_wvalid,
	input dram_m_wready,

	input [3:0] dram_m_bid,
	input [1:0] dram_m_bresp,
	input dram_m_bvalid,
	output reg dram_m_bready,

	output reg  [3:0] dram_m_arid,
	output reg  [15:0] dram_m_araddr,
	output reg  [7:0] dram_m_arlen,
	output reg  [2:0] dram_m_arsize,
	output reg  [1:0] dram_m_arburst,
	output reg  dram_m_arvalid,
	input dram_m_arready,

	input [3:0] dram_m_rid,
	input [31:0] dram_m_rdata,
	input [1:0] dram_m_rresp,
	input dram_m_rlast,
	input dram_m_rvalid,
	output reg dram_m_rready,

	// MAC Rx Port
	input [31:0] mac_s_tdata,
	input [3:0] mac_s_tkeep,
	input mac_s_tvalid,
	input mac_s_tlast,
	output reg mac_s_tready	
);

reg [31:0] desc_dw2;
reg [31:0] desc_dw3;

wire [31:0] wdma_tdata;
wire [3:0] wdma_tkeep;
wire wdma_tvalid;
wire wdma_tlast;
wire wdma_tready;

wire [31:0] pkt_fifo_din;
wire pkt_fifo_wr;
wire pkt_fifo_full;
wire [31:0] pkt_fifo_dout;
reg pkt_fifo_rd;
wire pkt_fifo_empty;

assign mac_m_tdata = wdma_tdata;
assign mac_m_tkeep = wdma_tkeep;
assign mac_m_tvalid = wdma_tvalid;
assign mac_m_tlast = wdma_tlast & desc_eop;
assign wdma_tready = mac_m_tready;

assign buf_fifo_din = cmd_s_tdata;
assign buf_fifo_wr = cmd_s_tvalid & cmd_s_tready;
assign cmd_s_tready = !buf_fifo_full;

assign cmd_address = buf_fifo_dout[15:0];
assign cmd_bytes = buf_fifo_dout[31:16];
assign cmd_valid = !buf_fifo_empty;
assign buf_fifo_rd = cmd_valid & cmd_ready;

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

axi_wdma #(.ADDRESS_BITS(16), .LENGTH_BITS(16)) rdma_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.cmd_address(cmd_address),
	.cmd_bytes(cmd_bytes),
	.cmd_valid(cmd_valid),
	.cmd_ready(cmd_ready),

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

	.din_tdata(mac_s_tdata),
	.din_tkeep(mac_s_tkeep),
	.din_tlast(mac_s_tlast),
	.din_tvalid(mac_s_tvalid),
	.din_tready(mac_s_tready)
);


endmodule
