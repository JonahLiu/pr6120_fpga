module rx_path(
	input aclk,
	input aresetn,

	// Parameters
	input EN, // Receiver Enable
	//input SBP, // Store Bad Packets
	//input UPE, // Unicast Promiscuous Enable
	//input MPE, // Multicast Promiscuous Enable
	input [1:0] RDMTS, // Receiver Descriptor Mininum Threshold Size
	//input [1:0] MO, // Multicast Offset
	//input BAM, // Broadcast Accept Mode
	input [1:0] BSIZE, // Receive Buffer Size
	input BSEX, // Buffer Size Extension
	//input VFE, // VLAN Filter Enable
	//input CFIEN, // Canonical Form Indicator Enable
	//input CFI, // Canonical Form Indicator Value
	//input DPF, // Discard Pause Frames
	//input PMCF, // Pass MAC Control Frames
	input [63:0] RDBA, // Rx Desc Base Address
	input [12:0] RDLEN, // Rx Desc Memory Size = RDLEN*16*8
	input [15:0] RDH, // Rx Desc Head
	input RDH_set, // RX Desc Head update
	output [15:0] RDH_fb, // Rx Desc Head feedback
	input [15:0] RDT, // Rx Desc Tail
	input RDT_set, // Rx Desc Tail update
	input [5:0] PTHRESH, // Prefetch Threshold
	input [5:0] HTHRESH, // Host Threshold 
	input [5:0] WTHRESH, // Write Back Threshold
	input GRAN, // Rx Desc Threshold Granularity
	input [7:0] PCSS, // Packet Checksum Start
	//input IPOFLD, // IP Checksum Off-load Enable
	//input TUOFLD, // TCP/UDP Checksum Off-load Enable
	//input IPV6OFL, // IPv6 Checksum Offload
	input [15:0] RDTR, // Interrupt Delay
	input FPD, // Flush Pending Descriptor
	input FPD_set, // Flush Pending Desc set
	input [15:0] RADV, // Absolute Interrupt Delay
	output RXDMT0_req, // Rx Desc Min Threshold Interrupt set
	output RXO_req, // Rx Overrun Interrupt set
	output RXT0_req, // Rx Timer Interrupt set

	// Filter Table Access
	//output [3:0] rtbl_index,
	//input [63:0] rtbl_data,
	//output [6:0] mtbl_index,
	//input [31:0] mtbl_data,
	//output [6:0] vtbl_index,
	//input [31:0] vtbl_data,

	// External Bus Access
	output [3:0] axi_m_awid,
	output [63:0] axi_m_awaddr,
	output [7:0] axi_m_awlen,
	output [2:0] axi_m_awsize,
	output [1:0] axi_m_awburst,
	output axi_m_awvalid,
	input  axi_m_awready,

	output [3:0] axi_m_wid,
	output [31:0] axi_m_wdata,
	output [3:0] axi_m_wstrb,
	output axi_m_wlast,
	output axi_m_wvalid,
	input  axi_m_wready,

	input [3:0] axi_m_bid,
	input [1:0] axi_m_bresp,
	input axi_m_bvalid,
	output axi_m_bready,

	output [3:0] axi_m_arid,
	output [63:0] axi_m_araddr,
	output [7:0] axi_m_arlen,
	output [2:0] axi_m_arsize,
	output [1:0] axi_m_arburst,
	output axi_m_arvalid,
	input  axi_m_arready,

	input [3:0] axi_m_rid,
	input [31:0] axi_m_rdata,
	input [1:0] axi_m_rresp,
	input axi_m_rlast,
	input axi_m_rvalid,
	output axi_m_rready,

	// MAC Rx Port
	input [31:0] mac_s_tdata,
	input [3:0] mac_s_tkeep,
	input [15:0] mac_s_tuser,
	input mac_s_tvalid,
	input mac_s_tlast,
	output mac_s_tready	
);

parameter CLK_PERIOD_NS = 8;
parameter DESC_RAM_DWORDS = 1024;
parameter DATA_RAM_DWORDS = 16384;

function integer clogb2 (input integer size);
begin
	size = size - 1;
	for (clogb2=1; size>1; clogb2=clogb2+1)
		size = size >> 1;
end
endfunction

localparam DESC_RAM_AW = clogb2(DESC_RAM_DWORDS)+2;
localparam DATA_RAM_AW = clogb2(DATA_RAM_DWORDS)+2;

wire [63:0] i0_cmd_src;
wire [15:0] i0_cmd_dst;
wire [15:0] i0_cmd_bytes;
wire i0_cmd_valid;
wire i0_cmd_ready;

wire [63:0] i0_rpt_src;
wire [15:0] i0_rpt_dst;
wire [15:0] i0_rpt_bytes;
wire i0_rpt_valid;
wire i0_rpt_ready;

wire [3:0] i0_ext_arid;
wire [63:0] i0_ext_araddr;
wire [7:0] i0_ext_arlen;
wire [2:0] i0_ext_arsize;
wire [1:0] i0_ext_arburst;
wire [3:0] i0_ext_arcache;
wire i0_ext_arvalid;
wire i0_ext_arready;
wire [3:0] i0_ext_rid;
wire [31:0] i0_ext_rdata;
wire [1:0] i0_ext_rresp;
wire i0_ext_rlast;
wire i0_ext_rvalid;
wire i0_ext_rready;
wire [3:0] i0_desc_awid;
wire [15:0] i0_desc_awaddr;
wire [7:0] i0_desc_awlen;
wire [2:0] i0_desc_awsize;
wire [1:0] i0_desc_awburst;
wire [3:0] i0_desc_awcache;
wire i0_desc_awvalid;
wire i0_desc_awready;
wire [3:0] i0_desc_wid;
wire [31:0] i0_desc_wdata;
wire [3:0] i0_desc_wstrb;
wire i0_desc_wlast;
wire i0_desc_wvalid;
wire i0_desc_wready;
wire [3:0] i0_desc_bid;
wire [1:0] i0_desc_bresp;
wire i0_desc_bvalid;
wire i0_desc_bready;

wire [15:0] i1_cmd_src;
wire [63:0] i1_cmd_dst;
wire [15:0] i1_cmd_bytes;
wire i1_cmd_valid;
wire i1_cmd_ready;

wire [15:0] i1_rpt_src;
wire [63:0] i1_rpt_dst;
wire [15:0] i1_rpt_bytes;
wire i1_rpt_valid;
wire i1_rpt_ready;

wire [3:0] i1_desc_arid;
wire [15:0] i1_desc_araddr;
wire [7:0] i1_desc_arlen;
wire [2:0] i1_desc_arsize;
wire [1:0] i1_desc_arburst;
wire [3:0] i1_desc_arcache;
wire i1_desc_arvalid;
wire i1_desc_arready;
wire [3:0] i1_desc_rid;
wire [31:0] i1_desc_rdata;
wire [1:0] i1_desc_rresp;
wire i1_desc_rlast;
wire i1_desc_rvalid;
wire i1_desc_rready;
wire [3:0] i1_ext_awid;
wire [63:0] i1_ext_awaddr;
wire [7:0] i1_ext_awlen;
wire [2:0] i1_ext_awsize;
wire [1:0] i1_ext_awburst;
wire [3:0] i1_ext_awcache;
wire i1_ext_awvalid;
wire i1_ext_awready;
wire [3:0] i1_ext_wid;
wire [31:0] i1_ext_wdata;
wire [3:0] i1_ext_wstrb;
wire i1_ext_wlast;
wire i1_ext_wvalid;
wire i1_ext_wready;
wire [3:0] i1_ext_bid;
wire [1:0] i1_ext_bresp;
wire i1_ext_bvalid;
wire i1_ext_bready;

wire [15:0] i2_cmd_src;
wire [63:0] i2_cmd_dst;
wire [15:0] i2_cmd_bytes;
wire i2_cmd_valid;
wire i2_cmd_ready;

wire [15:0] i2_rpt_src;
wire [63:0] i2_rpt_dst;
wire [15:0] i2_rpt_bytes;
wire i2_rpt_valid;
wire i2_rpt_ready;

wire [3:0] i2_dram_arid;
wire [15:0] i2_dram_araddr;
wire [7:0] i2_dram_arlen;
wire [2:0] i2_dram_arsize;
wire [1:0] i2_dram_arburst;
wire [3:0] i2_dram_arcache;
wire i2_dram_arvalid;
wire i2_dram_arready;
wire [3:0] i2_dram_rid;
wire [31:0] i2_dram_rdata;
wire [1:0] i2_dram_rresp;
wire i2_dram_rlast;
wire i2_dram_rvalid;
wire i2_dram_rready;
wire [3:0] i2_ext_awid;
wire [63:0] i2_ext_awaddr;
wire [7:0] i2_ext_awlen;
wire [2:0] i2_ext_awsize;
wire [1:0] i2_ext_awburst;
wire [3:0] i2_ext_awcache;
wire i2_ext_awvalid;
wire i2_ext_awready;
wire [3:0] i2_ext_wid;
wire [31:0] i2_ext_wdata;
wire [3:0] i2_ext_wstrb;
wire i2_ext_wlast;
wire i2_ext_wvalid;
wire i2_ext_wready;
wire [3:0] i2_ext_bid;
wire [1:0] i2_ext_bresp;
wire i2_ext_bvalid;
wire i2_ext_bready;

wire [31:0] re_cmd_tdata;
wire re_cmd_tvalid;
wire re_cmd_tlast;
wire re_cmd_tready;

wire [31:0] re_rpt_tdata;
wire re_rpt_tvalid;
wire re_rpt_tlast;
wire re_rpt_tready;

wire [3:0] re_desc_awid;
wire [15:0] re_desc_awaddr;
wire [7:0] re_desc_awlen;
wire [2:0] re_desc_awsize;
wire [1:0] re_desc_awburst;
wire [3:0] re_desc_awcache;
wire re_desc_awvalid;
wire re_desc_awready;
wire [3:0] re_desc_wid;
wire [31:0] re_desc_wdata;
wire [3:0] re_desc_wstrb;
wire re_desc_wlast;
wire re_desc_wvalid;
wire re_desc_wready;
wire [3:0] re_desc_bid;
wire [1:0] re_desc_bresp;
wire re_desc_bvalid;
wire re_desc_bready;
wire [3:0] re_desc_arid;
wire [15:0] re_desc_araddr;
wire [7:0] re_desc_arlen;
wire [2:0] re_desc_arsize;
wire [1:0] re_desc_arburst;
wire [3:0] re_desc_arcache;
wire re_desc_arvalid;
wire re_desc_arready;
wire [3:0] re_desc_rid;
wire [31:0] re_desc_rdata;
wire [1:0] re_desc_rresp;
wire re_desc_rlast;
wire re_desc_rvalid;
wire re_desc_rready;

wire [31:0] frm_cmd_tdata;
wire frm_cmd_tvalid;
wire frm_cmd_tlast;
wire frm_cmd_tready;

wire [31:0] frm_rpt_tdata;
wire frm_rpt_tvalid;
wire frm_rpt_tlast;
wire frm_rpt_tready;

wire [3:0] frm_dram_awid;
wire [15:0] frm_dram_awaddr;
wire [7:0] frm_dram_awlen;
wire [2:0] frm_dram_awsize;
wire [1:0] frm_dram_awburst;
wire [3:0] frm_dram_awcache;
wire frm_dram_awvalid;
wire frm_dram_awready;
wire [3:0] frm_dram_wid;
wire [31:0] frm_dram_wdata;
wire [3:0] frm_dram_wstrb;
wire frm_dram_wlast;
wire frm_dram_wvalid;
wire frm_dram_wready;
wire [3:0] frm_dram_bid;
wire [1:0] frm_dram_bresp;
wire frm_dram_bvalid;
wire frm_dram_bready;
wire [3:0] frm_dram_arid;
wire [15:0] frm_dram_araddr;
wire [7:0] frm_dram_arlen;
wire [2:0] frm_dram_arsize;
wire [1:0] frm_dram_arburst;
wire [3:0] frm_dram_arcache;
wire frm_dram_arvalid;
wire frm_dram_arready;
wire [3:0] frm_dram_rid;
wire [31:0] frm_dram_rdata;
wire [1:0] frm_dram_rresp;
wire frm_dram_rlast;
wire frm_dram_rvalid;
wire frm_dram_rready;

wire [3:0] desc_s_awid;
wire [15:0] desc_s_awaddr;
wire [7:0] desc_s_awlen;
wire [2:0] desc_s_awsize;
wire [1:0] desc_s_awburst;
wire [3:0] desc_s_awcache;
wire desc_s_awvalid;
wire desc_s_awready;
wire [3:0] desc_s_wid;
wire [31:0] desc_s_wdata;
wire [3:0] desc_s_wstrb;
wire desc_s_wlast;
wire desc_s_wvalid;
wire desc_s_wready;
wire [3:0] desc_s_bid;
wire [1:0] desc_s_bresp;
wire desc_s_bvalid;
wire desc_s_bready;
wire [3:0] desc_s_arid;
wire [15:0] desc_s_araddr;
wire [7:0] desc_s_arlen;
wire [2:0] desc_s_arsize;
wire [1:0] desc_s_arburst;
wire [3:0] desc_s_arcache;
wire desc_s_arvalid;
wire desc_s_arready;
wire [3:0] desc_s_rid;
wire [31:0] desc_s_rdata;
wire [1:0] desc_s_rresp;
wire desc_s_rlast;
wire desc_s_rvalid;
wire desc_s_rready;

wire [3:0] dram_s_awid;
wire [15:0] dram_s_awaddr;
wire [7:0] dram_s_awlen;
wire [2:0] dram_s_awsize;
wire [1:0] dram_s_awburst;
wire [3:0] dram_s_awcache;
wire dram_s_awvalid;
wire dram_s_awready;
wire [3:0] dram_s_wid;
wire [31:0] dram_s_wdata;
wire [3:0] dram_s_wstrb;
wire dram_s_wlast;
wire dram_s_wvalid;
wire dram_s_wready;
wire [3:0] dram_s_bid;
wire [1:0] dram_s_bresp;
wire dram_s_bvalid;
wire dram_s_bready;
wire [3:0] dram_s_arid;
wire [15:0] dram_s_araddr;
wire [7:0] dram_s_arlen;
wire [2:0] dram_s_arsize;
wire [1:0] dram_s_arburst;
wire [3:0] dram_s_arcache;
wire dram_s_arvalid;
wire dram_s_arready;
wire [3:0] dram_s_rid;
wire [31:0] dram_s_rdata;
wire [1:0] dram_s_rresp;
wire dram_s_rlast;
wire dram_s_rvalid;
wire dram_s_rready;

wire [3:0] null_dram_arid = 4'b0;
wire [15:0] null_dram_araddr = 16'b0;
wire [7:0] null_dram_arlen = 8'b0;
wire [2:0] null_dram_arsize = 3'b0;
wire [1:0] null_dram_arburst = 2'b0;
wire [3:0] null_dram_arcache = 4'b0;
wire null_dram_arvalid = 1'b0;
wire null_dram_arready = 1'b0;
wire [3:0] null_dram_rid = 4'b0;
wire [31:0] null_dram_rdata = 32'b0;
wire [1:0] null_dram_rresp = 2'b0;
wire null_dram_rlast = 1'b0;
wire null_dram_rvalid = 1'b0;
wire null_dram_rready = 1'b0;
wire [3:0] null_dram_awid = 4'b0;
wire [15:0] null_dram_awaddr = 16'b0;
wire [7:0] null_dram_awlen = 8'b0;
wire [2:0] null_dram_awsize = 3'b0;
wire [1:0] null_dram_awburst = 2'b0;
wire [3:0] null_dram_awcache = 4'b0;
wire null_dram_awvalid = 1'b0;
wire null_dram_awready = 1'b0;
wire [3:0] null_dram_wid = 4'b0;
wire [31:0] null_dram_wdata = 32'b0;
wire [3:0] null_dram_wstrb = 4'b0;
wire null_dram_wlast = 1'b0;
wire null_dram_wvalid = 1'b0;
wire null_dram_wready = 1'b0;
wire [3:0] null_dram_bid = 4'b0;
wire [1:0] null_dram_bresp = 2'b0;
wire null_dram_bvalid = 1'b0;
wire null_dram_bready = 1'b0;

wire [3:0] null_ext_arid = 4'b0;
wire [63:0] null_ext_araddr = 64'b0;
wire [7:0] null_ext_arlen = 8'b0;
wire [2:0] null_ext_arsize = 3'b0;
wire [1:0] null_ext_arburst = 2'b0;
wire [3:0] null_ext_arcache = 4'b0;
wire null_ext_arvalid = 1'b0;
wire null_ext_arready = 1'b0;
wire [3:0] null_ext_rid = 4'b0;
wire [31:0] null_ext_rdata = 32'b0;
wire [1:0] null_ext_rresp = 2'b0;
wire null_ext_rlast = 1'b0;
wire null_ext_rvalid = 1'b0;
wire null_ext_rready = 1'b0;
wire [3:0] null_ext_awid = 4'b0;
wire [63:0] null_ext_awaddr = 64'b0;
wire [7:0] null_ext_awlen = 8'b0;
wire [2:0] null_ext_awsize = 3'b0;
wire [1:0] null_ext_awburst = 2'b0;
wire [3:0] null_ext_awcache = 4'b0;
wire null_ext_awvalid = 1'b0;
wire null_ext_awready = 1'b0;
wire [3:0] null_ext_wid = 4'b0;
wire [31:0] null_ext_wdata = 32'b0;
wire [3:0] null_ext_wstrb = 4'b0;
wire null_ext_wlast = 1'b0;
wire null_ext_wvalid = 1'b0;
wire null_ext_wready = 1'b0;
wire [3:0] null_ext_bid = 4'b0;
wire [1:0] null_ext_bresp = 2'b0;
wire null_ext_bvalid = 1'b0;
wire null_ext_bready = 1'b0;

axi_mdma #(
	.SRC_ADDRESS_BITS(64), 
	.SRC_BIG_ENDIAN("FALSE"),
	.DST_ADDRESS_BITS(16), 
	.DST_BIG_ENDIAN("FALSE"),
	.LENGTH_BITS(16)
) i0_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.cmd_src_addr(i0_cmd_src),
	.cmd_dst_addr(i0_cmd_dst),
	.cmd_bytes(i0_cmd_bytes),
	.cmd_valid(i0_cmd_valid),
	.cmd_ready(i0_cmd_ready),

	.rpt_src_addr(i0_rpt_src),
	.rpt_dst_addr(i0_rpt_dst),
	.rpt_status(i0_rpt_status),
	.rpt_bytes(i0_rpt_bytes),
	.rpt_valid(i0_rpt_valid),
	.rpt_ready(i0_rpt_ready),

	.src_m_arid(i0_ext_arid),
	.src_m_araddr(i0_ext_araddr),
	.src_m_arlen(i0_ext_arlen),
	.src_m_arsize(i0_ext_arsize),
	.src_m_arburst(i0_ext_arburst),
	.src_m_arvalid(i0_ext_arvalid),
	.src_m_arready(i0_ext_arready),

	.src_m_rid(i0_ext_rid),
	.src_m_rdata(i0_ext_rdata),
	.src_m_rresp(i0_ext_rresp),
	.src_m_rlast(i0_ext_rlast),
	.src_m_rvalid(i0_ext_rvalid),
	.src_m_rready(i0_ext_rready),

	.dst_m_awid(i0_desc_awid),
	.dst_m_awaddr(i0_desc_awaddr),
	.dst_m_awlen(i0_desc_awlen),
	.dst_m_awsize(i0_desc_awsize),
	.dst_m_awburst(i0_desc_awburst),
	.dst_m_awvalid(i0_desc_awvalid),
	.dst_m_awready(i0_desc_awready),

	.dst_m_wid(i0_desc_wid),
	.dst_m_wdata(i0_desc_wdata),
	.dst_m_wstrb(i0_desc_wstrb),
	.dst_m_wlast(i0_desc_wlast),
	.dst_m_wvalid(i0_desc_wvalid),
	.dst_m_wready(i0_desc_wready),

	.dst_m_bid(i0_desc_bid),
	.dst_m_bresp(i0_desc_bresp),
	.dst_m_bvalid(i0_desc_bvalid),
	.dst_m_bready(i0_desc_bready)
);

axi_mdma #(
	.SRC_ADDRESS_BITS(16), 
	.SRC_BIG_ENDIAN("FALSE"),
	.DST_ADDRESS_BITS(64), 
	.DST_BIG_ENDIAN("FALSE"),
	.LENGTH_BITS(16)
) i1_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.cmd_src_addr(i1_cmd_src),
	.cmd_dst_addr(i1_cmd_dst),
	.cmd_bytes(i1_cmd_bytes),
	.cmd_valid(i1_cmd_valid),
	.cmd_ready(i1_cmd_ready),

	.rpt_src_addr(i1_rpt_src),
	.rpt_dst_addr(i1_rpt_dst),
	.rpt_status(i1_rpt_status),
	.rpt_bytes(i1_rpt_bytes),
	.rpt_valid(i1_rpt_valid),
	.rpt_ready(i1_rpt_ready),

	.src_m_arid(i1_desc_arid),
	.src_m_araddr(i1_desc_araddr),
	.src_m_arlen(i1_desc_arlen),
	.src_m_arsize(i1_desc_arsize),
	.src_m_arburst(i1_desc_arburst),
	.src_m_arvalid(i1_desc_arvalid),
	.src_m_arready(i1_desc_arready),

	.src_m_rid(i1_desc_rid),
	.src_m_rdata(i1_desc_rdata),
	.src_m_rresp(i1_desc_rresp),
	.src_m_rlast(i1_desc_rlast),
	.src_m_rvalid(i1_desc_rvalid),
	.src_m_rready(i1_desc_rready),

	.dst_m_awid(i1_ext_awid),
	.dst_m_awaddr(i1_ext_awaddr),
	.dst_m_awlen(i1_ext_awlen),
	.dst_m_awsize(i1_ext_awsize),
	.dst_m_awburst(i1_ext_awburst),
	.dst_m_awvalid(i1_ext_awvalid),
	.dst_m_awready(i1_ext_awready),

	.dst_m_wid(i1_ext_wid),
	.dst_m_wdata(i1_ext_wdata),
	.dst_m_wstrb(i1_ext_wstrb),
	.dst_m_wlast(i1_ext_wlast),
	.dst_m_wvalid(i1_ext_wvalid),
	.dst_m_wready(i1_ext_wready),

	.dst_m_bid(i1_ext_bid),
	.dst_m_bresp(i1_ext_bresp),
	.dst_m_bvalid(i1_ext_bvalid),
	.dst_m_bready(i1_ext_bready)
);

axi_mdma #(
	.SRC_ADDRESS_BITS(16), 
	.SRC_BIG_ENDIAN("FALSE"),
	.DST_ADDRESS_BITS(64), 
	.DST_BIG_ENDIAN("FALSE"),
	.LENGTH_BITS(16)
) i2_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.cmd_src_addr(i2_cmd_src),
	.cmd_dst_addr(i2_cmd_dst),
	.cmd_bytes(i2_cmd_bytes),
	.cmd_valid(i2_cmd_valid),
	.cmd_ready(i2_cmd_ready),

	.rpt_src_addr(i2_rpt_src),
	.rpt_dst_addr(i2_rpt_dst),
	.rpt_status(i2_rpt_status),
	.rpt_bytes(i2_rpt_bytes),
	.rpt_valid(i2_rpt_valid),
	.rpt_ready(i2_rpt_ready),

	.src_m_arid(i2_dram_arid),
	.src_m_araddr(i2_dram_araddr),
	.src_m_arlen(i2_dram_arlen),
	.src_m_arsize(i2_dram_arsize),
	.src_m_arburst(i2_dram_arburst),
	.src_m_arvalid(i2_dram_arvalid),
	.src_m_arready(i2_dram_arready),

	.src_m_rid(i2_dram_rid),
	.src_m_rdata(i2_dram_rdata),
	.src_m_rresp(i2_dram_rresp),
	.src_m_rlast(i2_dram_rlast),
	.src_m_rvalid(i2_dram_rvalid),
	.src_m_rready(i2_dram_rready),

	.dst_m_awid(i2_ext_awid),
	.dst_m_awaddr(i2_ext_awaddr),
	.dst_m_awlen(i2_ext_awlen),
	.dst_m_awsize(i2_ext_awsize),
	.dst_m_awburst(i2_ext_awburst),
	.dst_m_awvalid(i2_ext_awvalid),
	.dst_m_awready(i2_ext_awready),

	.dst_m_wid(i2_ext_wid),
	.dst_m_wdata(i2_ext_wdata),
	.dst_m_wstrb(i2_ext_wstrb),
	.dst_m_wlast(i2_ext_wlast),
	.dst_m_wvalid(i2_ext_wvalid),
	.dst_m_wready(i2_ext_wready),

	.dst_m_bid(i2_ext_bid),
	.dst_m_bresp(i2_ext_bresp),
	.dst_m_bvalid(i2_ext_bvalid),
	.dst_m_bready(i2_ext_bready)
);

//% Descriptor Processor
rx_desc_ctrl #(
	.CLK_PERIOD_NS(CLK_PERIOD_NS),
	.DESC_RAM_DWORDS(DESC_RAM_DWORDS)
)rx_desc_ctrl_i(
	.aclk(aclk),
	.aresetn(aresetn),

	// Parameters
	.EN(EN),
	.RDBA(RDBA),
	.RDLEN(RDLEN),
	.RDH(RDH),
	.RDH_set(RDH_set),
	.RDH_fb(RDH_fb),
	.RDT(RDT),
	.RDT_set(RDT_set),
	.PTHRESH(PTHRESH),
	.HTHRESH(HTHRESH),
	.WTHRESH(WTHRESH),
	.GRAN(GRAN),
	.RDTR(RDTR),
	.FPD(FPD),
	.FPD_set(FPD_set),
	.RADV(RADV),
	.RDMTS(RDMTS),
	.RXDMT0_req(RXDMT0_req),
	//.RXO_req(RXO_req),
	.RXT0_req(RXT0_req),

	// idma Command Port
	.idma_src_addr(i0_cmd_src),
	.idma_dst_addr(i0_cmd_dst),
	.idma_bytes(i0_cmd_bytes),
	.idma_valid(i0_cmd_valid),
	.idma_ready(i0_cmd_ready),

	// idma Response Port
	.irpt_src_addr(i0_rpt_src),
	.irpt_dst_addr(i0_rpt_dst),
	.irpt_bytes(i0_rpt_bytes),
	.irpt_valid(i0_rpt_valid),
	.irpt_ready(i0_rpt_ready),

	// odma Command Port
	.odma_src_addr(i1_cmd_src),
	.odma_dst_addr(i1_cmd_dst),
	.odma_bytes(i1_cmd_bytes),
	.odma_valid(i1_cmd_valid),
	.odma_ready(i1_cmd_ready),

	// odma Response Port
	.orpt_src_addr(i1_rpt_src),
	.orpt_dst_addr(i1_rpt_dst),
	.orpt_bytes(i1_rpt_bytes),
	.orpt_valid(i1_rpt_valid),
	.orpt_ready(i1_rpt_ready),

	// RX Engine 
	.reng_m_tdata(re_cmd_tdata),
	.reng_m_tvalid(re_cmd_tvalid),
	.reng_m_tlast(re_cmd_tlast),
	.reng_m_tready(re_cmd_tready),

	.reng_s_tdata(re_rpt_tdata),
	.reng_s_tvalid(re_rpt_tvalid),
	.reng_s_tlast(re_rpt_tlast),
	.reng_s_tready(re_rpt_tready)
);

// Receiver state machine
rx_engine rx_engine_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.BSIZE(BSIZE),
	.BSEX(BSEX),

	// Command Port
	.cmd_s_tdata(re_cmd_tdata),
	.cmd_s_tvalid(re_cmd_tvalid),
	.cmd_s_tlast(re_cmd_tlast),
	.cmd_s_tready(re_cmd_tready),

	// Status Port
	.stat_m_tdata(re_rpt_tdata),
	.stat_m_tvalid(re_rpt_tvalid),
	.stat_m_tlast(re_rpt_tlast),
	.stat_m_tready(re_rpt_tready),

	// Internal RAM Access Port
	.ram_m_awid(re_desc_awid),
	.ram_m_awaddr(re_desc_awaddr),
	.ram_m_awlen(re_desc_awlen),
	.ram_m_awsize(re_desc_awsize),
	.ram_m_awburst(re_desc_awburst),
	.ram_m_awvalid(re_desc_awvalid),
	.ram_m_awready(re_desc_awready),

	.ram_m_wid(re_desc_wid),
	.ram_m_wdata(re_desc_wdata),
	.ram_m_wstrb(re_desc_wstrb),
	.ram_m_wlast(re_desc_wlast),
	.ram_m_wvalid(re_desc_wvalid),
	.ram_m_wready(re_desc_wready),

	.ram_m_bid(re_desc_bid),
	.ram_m_bresp(re_desc_bresp),
	.ram_m_bvalid(re_desc_bvalid),
	.ram_m_bready(re_desc_bready),

	.ram_m_arid(re_desc_arid),
	.ram_m_araddr(re_desc_araddr),
	.ram_m_arlen(re_desc_arlen),
	.ram_m_arsize(re_desc_arsize),
	.ram_m_arburst(re_desc_arburst),
	.ram_m_arvalid(re_desc_arvalid),
	.ram_m_arready(re_desc_arready),

	.ram_m_rid(re_desc_rid),
	.ram_m_rdata(re_desc_rdata),
	.ram_m_rresp(re_desc_rresp),
	.ram_m_rlast(re_desc_rlast),
	.ram_m_rvalid(re_desc_rvalid),
	.ram_m_rready(re_desc_rready),

	// dma Command Port
	.dma_src_addr(i2_cmd_src),
	.dma_dst_addr(i2_cmd_dst),
	.dma_bytes(i2_cmd_bytes),
	.dma_valid(i2_cmd_valid),
	.dma_ready(i2_cmd_ready),

	// dma Response Port
	.rpt_src_addr(i2_rpt_src),
	.rpt_dst_addr(i2_rpt_dst),
	.rpt_bytes(i2_rpt_bytes),
	.rpt_valid(i2_rpt_valid),
	.rpt_ready(i2_rpt_ready),

	.frm_m_tdata(frm_cmd_tdata),
	.frm_m_tvalid(frm_cmd_tvalid),
	.frm_m_tlast(frm_cmd_tlast),
	.frm_m_tready(frm_cmd_tready),

	.frm_s_tdata(frm_rpt_tdata),
	.frm_s_tvalid(frm_rpt_tvalid),
	.frm_s_tlast(frm_rpt_tlast),
	.frm_s_tready(frm_rpt_tready)
);

rx_frame #(
	.DATA_RAM_DWORDS(DATA_RAM_DWORDS)
)rx_frame_i(
	.aclk(aclk),
	.aresetn(aresetn),
	
	.PCSS(PCSS),

	// Frame Command Port
	.cmd_s_tdata(frm_cmd_tdata),
	.cmd_s_tvalid(frm_cmd_tvalid),
	.cmd_s_tlast(frm_cmd_tlast),
	.cmd_s_tready(frm_cmd_tready),

	// Frame Status Port
	.stat_m_tdata(frm_rpt_tdata),
	.stat_m_tvalid(frm_rpt_tvalid),
	.stat_m_tlast(frm_rpt_tlast),
	.stat_m_tready(frm_rpt_tready),

	// Data RAM Access Port
	.dram_m_arid(frm_dram_arid),
	.dram_m_araddr(frm_dram_araddr),
	.dram_m_arlen(frm_dram_arlen),
	.dram_m_arsize(frm_dram_arsize),
	.dram_m_arburst(frm_dram_arburst),
	.dram_m_arvalid(frm_dram_arvalid),
	.dram_m_arready(frm_dram_arready),

	.dram_m_rid(frm_dram_rid),
	.dram_m_rdata(frm_dram_rdata),
	.dram_m_rresp(frm_dram_rresp),
	.dram_m_rlast(frm_dram_rlast),
	.dram_m_rvalid(frm_dram_rvalid),
	.dram_m_rready(frm_dram_rready),

	.dram_m_awid(frm_dram_awid),
	.dram_m_awaddr(frm_dram_awaddr),
	.dram_m_awlen(frm_dram_awlen),
	.dram_m_awsize(frm_dram_awsize),
	.dram_m_awburst(frm_dram_awburst),
	.dram_m_awvalid(frm_dram_awvalid),
	.dram_m_awready(frm_dram_awready),

	.dram_m_wid(frm_dram_wid),
	.dram_m_wdata(frm_dram_wdata),
	.dram_m_wstrb(frm_dram_wstrb),
	.dram_m_wlast(frm_dram_wlast),
	.dram_m_wvalid(frm_dram_wvalid),
	.dram_m_wready(frm_dram_wready),

	.dram_m_bid(frm_dram_bid),
	.dram_m_bresp(frm_dram_bresp),
	.dram_m_bvalid(frm_dram_bvalid),
	.dram_m_bready(frm_dram_bready),

	// MAC Tx Stream Port
	.mac_s_tdata(mac_s_tdata),
	.mac_s_tkeep(mac_s_tkeep),
	.mac_s_tuser(mac_s_tuser),
	.mac_s_tvalid(mac_s_tvalid),
	.mac_s_tlast(mac_s_tlast),
	.mac_s_tready(mac_s_tready)
);

//% Rx Descriptor RAM
axi_ram #(
	.MEMORY_DEPTH(DESC_RAM_DWORDS),
	.DATA_WIDTH(32),
	.ID_WIDTH(4)
) rx_desc_ram_i (
	.aclk(aclk),
	.aresetn(aresetn),

	.s_awid(desc_s_awid),
	.s_awaddr(desc_s_awaddr[DESC_RAM_AW-1:0]),
	.s_awlen(desc_s_awlen),
	.s_awsize(desc_s_awsize),
	.s_awburst(desc_s_awburst),
	.s_awvalid(desc_s_awvalid),
	.s_awready(desc_s_awready),

	.s_wid(desc_s_wid),
	.s_wdata(desc_s_wdata),
	.s_wstrb(desc_s_wstrb),
	.s_wlast(desc_s_wlast),
	.s_wvalid(desc_s_wvalid),
	.s_wready(desc_s_wready),

	.s_bid(desc_s_bid),
	.s_bresp(desc_s_bresp),
	.s_bvalid(desc_s_bvalid),
	.s_bready(desc_s_bready),

	.s_arid(desc_s_arid),
	.s_araddr(desc_s_araddr[DESC_RAM_AW-1:0]),
	.s_arlen(desc_s_arlen),
	.s_arsize(desc_s_arsize),
	.s_arburst(desc_s_arburst),
	.s_arvalid(desc_s_arvalid),
	.s_arready(desc_s_arready),

	.s_rid(desc_s_rid),
	.s_rdata(desc_s_rdata),
	.s_rresp(desc_s_rresp),
	.s_rlast(desc_s_rlast),
	.s_rvalid(desc_s_rvalid),
	.s_rready(desc_s_rready)
);

//% Rx Data Ram 65536 Bytes
axi_ram #(
	.MEMORY_DEPTH(DATA_RAM_DWORDS),
	.DATA_WIDTH(32),
	.ID_WIDTH(4)
) rx_data_ram_i (
	.aclk(aclk),
	.aresetn(aresetn),

	.s_awid(dram_s_awid),
	.s_awaddr(dram_s_awaddr[DATA_RAM_AW-1:0]),
	.s_awlen(dram_s_awlen),
	.s_awsize(dram_s_awsize),
	.s_awburst(dram_s_awburst),
	.s_awvalid(dram_s_awvalid),
	.s_awready(dram_s_awready),

	.s_wid(dram_s_wid),
	.s_wdata(dram_s_wdata),
	.s_wstrb(dram_s_wstrb),
	.s_wlast(dram_s_wlast),
	.s_wvalid(dram_s_wvalid),
	.s_wready(dram_s_wready),

	.s_bid(dram_s_bid),
	.s_bresp(dram_s_bresp),
	.s_bvalid(dram_s_bvalid),
	.s_bready(dram_s_bready),

	.s_arid(dram_s_arid),
	.s_araddr(dram_s_araddr[DATA_RAM_AW-1:0]),
	.s_arlen(dram_s_arlen),
	.s_arsize(dram_s_arsize),
	.s_arburst(dram_s_arburst),
	.s_arvalid(dram_s_arvalid),
	.s_arready(dram_s_arready),

	.s_rid(dram_s_rid),
	.s_rdata(dram_s_rdata),
	.s_rresp(dram_s_rresp),
	.s_rlast(dram_s_rlast),
	.s_rvalid(dram_s_rvalid),
	.s_rready(dram_s_rready)
);

axi_mux #(
	.SLAVE_NUM(2),
	.ID_WIDTH(4),
	.ADDR_WIDTH(16),
	.DATA_WIDTH(32),
	.LEN_WIDTH(8)
) desc_mux_i (
	.aclk(aclk),
	.aresetn(aresetn),

	.s_awid({re_desc_awid,i0_desc_awid}),
	.s_awaddr({re_desc_awaddr,i0_desc_awaddr}),
	.s_awlen({re_desc_awlen,i0_desc_awlen}),
	.s_awsize({re_desc_awsize,i0_desc_awsize}),
	.s_awburst({re_desc_awburst,i0_desc_awburst}),
	.s_awvalid({re_desc_awvalid,i0_desc_awvalid}),
	.s_awready({re_desc_awready,i0_desc_awready}),

	.s_wid({re_desc_wid,i0_desc_wid}),
	.s_wdata({re_desc_wdata,i0_desc_wdata}),
	.s_wstrb({re_desc_wstrb,i0_desc_wstrb}),
	.s_wlast({re_desc_wlast,i0_desc_wlast}),
	.s_wvalid({re_desc_wvalid,i0_desc_wvalid}),
	.s_wready({re_desc_wready,i0_desc_wready}),

	.s_bid({re_desc_bid,i0_desc_bid}),
	.s_bresp({re_desc_bresp,i0_desc_bresp}),
	.s_bvalid({re_desc_bvalid,i0_desc_bvalid}),
	.s_bready({re_desc_bready,i0_desc_bready}),

	.s_arid({re_desc_arid,i1_desc_arid}),
	.s_araddr({re_desc_araddr,i1_desc_araddr}),
	.s_arlen({re_desc_arlen,i1_desc_arlen}),
	.s_arsize({re_desc_arsize,i1_desc_arsize}),
	.s_arburst({re_desc_arburst,i1_desc_arburst}),
	.s_arvalid({re_desc_arvalid,i1_desc_arvalid}),
	.s_arready({re_desc_arready,i1_desc_arready}),

	.s_rid({re_desc_rid,i1_desc_rid}),
	.s_rdata({re_desc_rdata,i1_desc_rdata}),
	.s_rresp({re_desc_rresp,i1_desc_rresp}),
	.s_rlast({re_desc_rlast,i1_desc_rlast}),
	.s_rvalid({re_desc_rvalid,i1_desc_rvalid}),
	.s_rready({re_desc_rready,i1_desc_rready}),

	.m_awid(desc_s_awid),
	.m_awaddr(desc_s_awaddr),
	.m_awlen(desc_s_awlen),
	.m_awsize(desc_s_awsize),
	.m_awburst(desc_s_awburst),
	.m_awvalid(desc_s_awvalid),
	.m_awready(desc_s_awready),

	.m_wid(desc_s_wid),
	.m_wdata(desc_s_wdata),
	.m_wstrb(desc_s_wstrb),
	.m_wlast(desc_s_wlast),
	.m_wvalid(desc_s_wvalid),
	.m_wready(desc_s_wready),

	.m_bid(desc_s_bid),
	.m_bresp(desc_s_bresp),
	.m_bvalid(desc_s_bvalid),
	.m_bready(desc_s_bready),

	.m_arid(desc_s_arid),
	.m_araddr(desc_s_araddr),
	.m_arlen(desc_s_arlen),
	.m_arsize(desc_s_arsize),
	.m_arburst(desc_s_arburst),
	.m_arvalid(desc_s_arvalid),
	.m_arready(desc_s_arready),

	.m_rid(desc_s_rid),
	.m_rdata(desc_s_rdata),
	.m_rresp(desc_s_rresp),
	.m_rlast(desc_s_rlast),
	.m_rvalid(desc_s_rvalid),
	.m_rready(desc_s_rready)
);

axi_mux #(
	.SLAVE_NUM(2),
	.ID_WIDTH(4),
	.ADDR_WIDTH(16),
	.DATA_WIDTH(32),
	.LEN_WIDTH(8)
) dram_mux_i (
	.aclk(aclk),
	.aresetn(aresetn),

	.s_awid({frm_dram_awid,null_dram_awid}),
	.s_awaddr({frm_dram_awaddr,null_dram_awaddr}),
	.s_awlen({frm_dram_awlen,null_dram_awlen}),
	.s_awsize({frm_dram_awsize,null_dram_awsize}),
	.s_awburst({frm_dram_awburst,null_dram_awburst}),
	.s_awvalid({frm_dram_awvalid,null_dram_awvalid}),
	.s_awready({frm_dram_awready,null_dram_awready}),

	.s_wid({frm_dram_wid,null_dram_wid}),
	.s_wdata({frm_dram_wdata,null_dram_wdata}),
	.s_wstrb({frm_dram_wstrb,null_dram_wstrb}),
	.s_wlast({frm_dram_wlast,null_dram_wlast}),
	.s_wvalid({frm_dram_wvalid,null_dram_wvalid}),
	.s_wready({frm_dram_wready,null_dram_wready}),

	.s_bid({frm_dram_bid,null_dram_bid}),
	.s_bresp({frm_dram_bresp,null_dram_bresp}),
	.s_bvalid({frm_dram_bvalid,null_dram_bvalid}),
	.s_bready({frm_dram_bready,null_dram_bready}),

	.s_arid({frm_dram_arid,i2_dram_arid}),
	.s_araddr({frm_dram_araddr,i2_dram_araddr}),
	.s_arlen({frm_dram_arlen,i2_dram_arlen}),
	.s_arsize({frm_dram_arsize,i2_dram_arsize}),
	.s_arburst({frm_dram_arburst,i2_dram_arburst}),
	.s_arvalid({frm_dram_arvalid,i2_dram_arvalid}),
	.s_arready({frm_dram_arready,i2_dram_arready}),

	.s_rid({frm_dram_rid,i2_dram_rid}),
	.s_rdata({frm_dram_rdata,i2_dram_rdata}),
	.s_rresp({frm_dram_rresp,i2_dram_rresp}),
	.s_rlast({frm_dram_rlast,i2_dram_rlast}),
	.s_rvalid({frm_dram_rvalid,i2_dram_rvalid}),
	.s_rready({frm_dram_rready,i2_dram_rready}),

	.m_awid(dram_s_awid),
	.m_awaddr(dram_s_awaddr),
	.m_awlen(dram_s_awlen),
	.m_awsize(dram_s_awsize),
	.m_awburst(dram_s_awburst),
	.m_awvalid(dram_s_awvalid),
	.m_awready(dram_s_awready),

	.m_wid(dram_s_wid),
	.m_wdata(dram_s_wdata),
	.m_wstrb(dram_s_wstrb),
	.m_wlast(dram_s_wlast),
	.m_wvalid(dram_s_wvalid),
	.m_wready(dram_s_wready),

	.m_bid(dram_s_bid),
	.m_bresp(dram_s_bresp),
	.m_bvalid(dram_s_bvalid),
	.m_bready(dram_s_bready),

	.m_arid(dram_s_arid),
	.m_araddr(dram_s_araddr),
	.m_arlen(dram_s_arlen),
	.m_arsize(dram_s_arsize),
	.m_arburst(dram_s_arburst),
	.m_arvalid(dram_s_arvalid),
	.m_arready(dram_s_arready),

	.m_rid(dram_s_rid),
	.m_rdata(dram_s_rdata),
	.m_rresp(dram_s_rresp),
	.m_rlast(dram_s_rlast),
	.m_rvalid(dram_s_rvalid),
	.m_rready(dram_s_rready)
);

axi_mux #(
	.SLAVE_NUM(2),
	.ID_WIDTH(4),
	.ADDR_WIDTH(64),
	.DATA_WIDTH(32),
	.LEN_WIDTH(8)
) ext_mux_i (
	.aclk(aclk),
	.aresetn(aresetn),

	.s_awid({i2_ext_awid,i1_ext_awid}),
	.s_awaddr({i2_ext_awaddr,i1_ext_awaddr}),
	.s_awlen({i2_ext_awlen,i1_ext_awlen}),
	.s_awsize({i2_ext_awsize,i1_ext_awsize}),
	.s_awburst({i2_ext_awburst,i1_ext_awburst}),
	.s_awvalid({i2_ext_awvalid,i1_ext_awvalid}),
	.s_awready({i2_ext_awready,i1_ext_awready}),

	.s_wid({i2_ext_wid,i1_ext_wid}),
	.s_wdata({i2_ext_wdata,i1_ext_wdata}),
	.s_wstrb({i2_ext_wstrb,i1_ext_wstrb}),
	.s_wlast({i2_ext_wlast,i1_ext_wlast}),
	.s_wvalid({i2_ext_wvalid,i1_ext_wvalid}),
	.s_wready({i2_ext_wready,i1_ext_wready}),

	.s_bid({i2_ext_bid,i1_ext_bid}),
	.s_bresp({i2_ext_bresp,i1_ext_bresp}),
	.s_bvalid({i2_ext_bvalid,i1_ext_bvalid}),
	.s_bready({i2_ext_bready,i1_ext_bready}),

	.s_arid({null_ext_arid,i0_ext_arid}),
	.s_araddr({null_ext_araddr,i0_ext_araddr}),
	.s_arlen({null_ext_arlen,i0_ext_arlen}),
	.s_arsize({null_ext_arsize,i0_ext_arsize}),
	.s_arburst({null_ext_arburst,i0_ext_arburst}),
	.s_arvalid({null_ext_arvalid,i0_ext_arvalid}),
	.s_arready({null_ext_arready,i0_ext_arready}),

	.s_rid({null_ext_rid,i0_ext_rid}),
	.s_rdata({null_ext_rdata,i0_ext_rdata}),
	.s_rresp({null_ext_rresp,i0_ext_rresp}),
	.s_rlast({null_ext_rlast,i0_ext_rlast}),
	.s_rvalid({null_ext_rvalid,i0_ext_rvalid}),
	.s_rready({null_ext_rready,i0_ext_rready}),

	.m_awid(axi_m_awid),
	.m_awaddr(axi_m_awaddr),
	.m_awlen(axi_m_awlen),
	.m_awsize(axi_m_awsize),
	.m_awburst(axi_m_awburst),
	.m_awvalid(axi_m_awvalid),
	.m_awready(axi_m_awready),

	.m_wid(axi_m_wid),
	.m_wdata(axi_m_wdata),
	.m_wstrb(axi_m_wstrb),
	.m_wlast(axi_m_wlast),
	.m_wvalid(axi_m_wvalid),
	.m_wready(axi_m_wready),

	.m_bid(axi_m_bid),
	.m_bresp(axi_m_bresp),
	.m_bvalid(axi_m_bvalid),
	.m_bready(axi_m_bready),

	.m_arid(axi_m_arid),
	.m_araddr(axi_m_araddr),
	.m_arlen(axi_m_arlen),
	.m_arsize(axi_m_arsize),
	.m_arburst(axi_m_arburst),
	.m_arvalid(axi_m_arvalid),
	.m_arready(axi_m_arready),

	.m_rid(axi_m_rid),
	.m_rdata(axi_m_rdata),
	.m_rresp(axi_m_rresp),
	.m_rlast(axi_m_rlast),
	.m_rvalid(axi_m_rvalid),
	.m_rready(axi_m_rready)
);
endmodule
