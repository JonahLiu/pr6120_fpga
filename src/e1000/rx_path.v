module rx_path(
	input aclk,
	input aresetn,

	// Parameters
	input EN, // Receiver Enable
	input SBP, // Store Bad Packets
	input UPE, // Unicast Promiscuous Enable
	input MPE, // Multicast Promiscuous Enable
	input LPE, // Long Packet Receiption Enable
	input [1:0] RDMTS, // Receiver Descriptor Mininum Threshold Size
	input [1:0] MO, // Multicast Offset
	input BAM, // Broadcast Accept Mode
	input [1:0] BSIZE, // Receive Buffer Size
	input VFE, // VLAN Filter Enable
	input CFIEN, // Canonical Form Indicator Enable
	input CFI, // Canonical Form Indicator Value
	input DPF, // Discard Pause Frames
	input PMCF, // Pass MAC Control Frames
	input BSEX, // Buffer Size Extension
	input SECRC, // Strip Ethernet CRC
	input [63:0] RDBA, // Rx Desc Base Address
	input [12:0] RDLEN, // Rx Desc Memory Size = RDLEN*16*8
	input [15:0] RDH, // Rx Desc Head
	input RDH_set, // RX Desc Head update
	input [15:0] RDH_fb, // Rx Desc Head feedback
	input [15:0] RDT, // Rx Desc Tail
	input RDT_set, // Rx Desc Tail update
	input [5:0] PTHRESH, // Prefetch Threshold
	input [5:0] HTHRESH, // Host Threshold 
	input [5:0] WTHRESH, // Write Back Threshold
	input GRAN, // Rx Desc Threshold Granularity
	input [7:0] PCSS, // Packet Checksum Start
	input IPOFLD, // IP Checksum Off-load Enable
	input TUOFLD, // TCP/UDP Checksum Off-load Enable
	input IPV6OFL, // IPv6 Checksum Offload
	input [15:0] TIDV, // Interrupt Delay
	input FPD, // Flush Pending Descriptor
	input [15:0] TADV, // Absolute Interrupt Delay
	output RXDMT0_req, // Rx Desc Min Threshold Interrupt set
	output RXO_req, // Rx Overrun Interrupt set
	output RXT0, // Rx Timer Interrupt set

	// Filter Table Access
	output [3:0] rtbl_index,
	input [63:0] rtbl_data,
	output [6:0] mtbl_index,
	input [31:0] mtbl_data,
	output [6:0] vtbl_index,
	input [31:0] vtbl_data,

	// External Bus Access
	input [3:0] axi_m_awid,
	input [63:0] axi_m_awaddr,
	input [3:0] axi_m_awlen,
	input [2:0] axi_m_awsize,
	input [1:0] axi_m_awburst,
	input axi_m_awvalid,
	output axi_m_awready,

	input [3:0] axi_m_wid,
	input [31:0] axi_m_wdata,
	input [3:0] axi_m_wstrb,
	input axi_m_wlast,
	input axi_m_wvalid,
	output axi_m_wready,

	input [3:0] axi_m_bid,
	input [1:0] axi_m_bresp,
	input axi_m_bvalid,
	output axi_m_bready,

	input [3:0] axi_m_arid,
	input [63:0] axi_m_araddr,
	input [3:0] axi_m_arlen,
	input [2:0] axi_m_arsize,
	input [1:0] axi_m_arburst,
	input axi_m_arvalid,
	output axi_m_arready,

	input [3:0] axi_m_rid,
	input [31:0] axi_m_rdata,
	input [1:0] axi_m_rresp,
	input axi_m_rlast,
	input axi_m_rvalid,
	output axi_m_rready,

	// MAC Rx Port
	input [31:0] mac_s_tdata,
	input [3:0] mac_s_tkeep,
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

// DMA controller between external bus and local ram 
axi_idma re_desc_idma_i(
	.aclk(aclk),
	.aresetn(aresetn),

	// DMA Command Port
	.cmd_s_tdata(i0_cmd_tdata),
	.cmd_s_tvalid(i0_cmd_tvalid),
	.cmd_s_tlast(i0_cmd_tlast),
	.cmd_s_tready(i0_cmd_tready),

	// DMA Status Port
	.stat_m_tdata(i0_rpt_tdata),
	.stat_m_tvalid(i0_rpt_tvalid),
	.stat_m_tlast(i0_rpt_tlast),
	.stat_m_tready(i0_rpt_tready),

	// External Bus Access Port
	.ext_m_awid(i0_ext_awid),
	.ext_m_awaddr(i0_ext_awaddr),
	.ext_m_awlen(i0_ext_awlen),
	.ext_m_awsize(i0_ext_awsize),
	.ext_m_awburst(i0_ext_awburst),
	.ext_m_awvalid(i0_ext_awvalid),
	.ext_m_awready(i0_ext_awready),

	.ext_m_wid(i0_ext_wid),
	.ext_m_wdata(i0_ext_wdata),
	.ext_m_wstrb(i0_ext_wstrb),
	.ext_m_wlast(i0_ext_wlast),
	.ext_m_wvalid(i0_ext_wvalid),
	.ext_m_wready(i0_ext_wready),

	.ext_m_bid(i0_ext_bid),
	.ext_m_bresp(i0_ext_bresp),
	.ext_m_bvalid(i0_ext_bvalid),
	.ext_m_bready(i0_ext_bready),

	.ext_m_arid(i0_ext_arid),
	.ext_m_araddr(i0_ext_araddr),
	.ext_m_arlen(i0_ext_arlen),
	.ext_m_arsize(i0_ext_arsize),
	.ext_m_arburst(i0_ext_arburst),
	.ext_m_arvalid(i0_ext_arvalid),
	.ext_m_arready(i0_ext_arready),

	.ext_m_rid(i0_ext_rid),
	.ext_m_rdata(i0_ext_rdata),
	.ext_m_rresp(i0_ext_rresp),
	.ext_m_rlast(i0_ext_rlast),
	.ext_m_rvalid(i0_ext_rvalid),
	.ext_m_rready(i0_ext_rready),

	// Internal RAM Access Port
	.int_m_awid(i0_desc_awid),
	.int_m_awaddr(i0_desc_awaddr),
	.int_m_awlen(i0_desc_awlen),
	.int_m_awsize(i0_desc_awsize),
	.int_m_awburst(i0_desc_awburst),
	.int_m_awvalid(i0_desc_awvalid),
	.int_m_awready(i0_desc_awready),

	.int_m_wid(i0_desc_wid),
	.int_m_wdata(i0_desc_wdata),
	.int_m_wstrb(i0_desc_wstrb),
	.int_m_wlast(i0_desc_wlast),
	.int_m_wvalid(i0_desc_wvalid),
	.int_m_wready(i0_desc_wready),

	.int_m_bid(i0_desc_bid),
	.int_m_bresp(i0_desc_bresp),
	.int_m_bvalid(i0_desc_bvalid),
	.int_m_bready(i0_desc_bready),

	.int_m_arid(i0_desc_arid),
	.int_m_araddr(i0_desc_araddr),
	.int_m_arlen(i0_desc_arlen),
	.int_m_arsize(i0_desc_arsize),
	.int_m_arburst(i0_desc_arburst),
	.int_m_arvalid(i0_desc_arvalid),
	.int_m_arready(i0_desc_arready),

	.int_m_rid(i0_desc_rid),
	.int_m_rdata(i0_desc_rdata),
	.int_m_rresp(i0_desc_rresp),
	.int_m_rlast(i0_desc_rlast),
	.int_m_rvalid(i0_desc_rvalid),
	.int_m_rready(i0_desc_rready)
);

//% Data idma
axi_idma tx_data_idma_i(
	.aclk(aclk),
	.aresetn(aresetn),

	// DMA Command Port
	.cmd_s_tdata(i1_cmd_tdata),
	.cmd_s_tvalid(i1_cmd_tvalid),
	.cmd_s_tlast(i1_cmd_tlast),
	.cmd_s_tready(i1_cmd_tready),

	// DMA Status Port
	.stat_m_tdata(i1_rpt_tdata),
	.stat_m_tvalid(i1_rpt_tvalid),
	.stat_m_tlast(i1_rpt_tlast),
	.stat_m_tready(i1_rpt_tready),

	// External Bus Access Port
	.ext_m_awid(i1_ext_awid),
	.ext_m_awaddr(i1_ext_awaddr),
	.ext_m_awlen(i1_ext_awlen),
	.ext_m_awsize(i1_ext_awsize),
	.ext_m_awburst(i1_ext_awburst),
	.ext_m_awvalid(i1_ext_awvalid),
	.ext_m_awready(i1_ext_awready),

	.ext_m_wid(i1_ext_wid),
	.ext_m_wdata(i1_ext_wdata),
	.ext_m_wstrb(i1_ext_wstrb),
	.ext_m_wlast(i1_ext_wlast),
	.ext_m_wvalid(i1_ext_wvalid),
	.ext_m_wready(i1_ext_wready),

	.ext_m_bid(i1_ext_bid),
	.ext_m_bresp(i1_ext_bresp),
	.ext_m_bvalid(i1_ext_bvalid),
	.ext_m_bready(i1_ext_bready),

	.ext_m_arid(i1_ext_arid),
	.ext_m_araddr(i1_ext_araddr),
	.ext_m_arlen(i1_ext_arlen),
	.ext_m_arsize(i1_ext_arsize),
	.ext_m_arburst(i1_ext_arburst),
	.ext_m_arvalid(i1_ext_arvalid),
	.ext_m_arready(i1_ext_arready),

	.ext_m_rid(i1_ext_rid),
	.ext_m_rdata(i1_ext_rdata),
	.ext_m_rresp(i1_ext_rresp),
	.ext_m_rlast(i1_ext_rlast),
	.ext_m_rvalid(i1_ext_rvalid),
	.ext_m_rready(i1_ext_rready),

	// Internal RAM Access Port
	.int_m_awid(i1_dram_awid),
	.int_m_awaddr(i1_dram_awaddr),
	.int_m_awlen(i1_dram_awlen),
	.int_m_awsize(i1_dram_awsize),
	.int_m_awburst(i1_dram_awburst),
	.int_m_awvalid(i1_dram_awvalid),
	.int_m_awready(i1_dram_awready),

	.int_m_wid(i1_dram_wid),
	.int_m_wdata(i1_dram_wdata),
	.int_m_wstrb(i1_dram_wstrb),
	.int_m_wlast(i1_dram_wlast),
	.int_m_wvalid(i1_dram_wvalid),
	.int_m_wready(i1_dram_wready),

	.int_m_bid(i1_dram_bid),
	.int_m_bresp(i1_dram_bresp),
	.int_m_bvalid(i1_dram_bvalid),
	.int_m_bready(i1_dram_bready),

	.int_m_arid(i1_dram_arid),
	.int_m_araddr(i1_dram_araddr),
	.int_m_arlen(i1_dram_arlen),
	.int_m_arsize(i1_dram_arsize),
	.int_m_arburst(i1_dram_arburst),
	.int_m_arvalid(i1_dram_arvalid),
	.int_m_arready(i1_dram_arready),

	.int_m_rid(i1_dram_rid),
	.int_m_rdata(i1_dram_rdata),
	.int_m_rresp(i1_dram_rresp),
	.int_m_rlast(i1_dram_rlast),
	.int_m_rvalid(i1_dram_rvalid),
	.int_m_rready(i1_dram_rready)
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
	.TIDV(TIDV),
	.TADV(TADV),
	.TXDW_req(TXDW_req),
	.TXQE_req(TXQE_req),
	.TXD_LOW_req(TXD_LOW_req),

	// idma Command Port
	.idma_m_tdata(i0_cmd_tdata),
	.idma_m_tvalid(i0_cmd_tvalid),
	.idma_m_tlast(i0_cmd_tlast),
	.idma_m_tready(i0_cmd_tready),

	// idma Response Port
	.idma_s_tdata(i0_rpt_tdata),
	.idma_s_tvalid(i0_rpt_tvalid),
	.idma_s_tlast(i0_rpt_tlast),
	.idma_s_tready(i0_rpt_tready),

	// TX Engine 
	.teng_m_tdata(te_cmd_tdata),
	.teng_m_tvalid(te_cmd_tvalid),
	.teng_m_tlast(te_cmd_tlast),
	.teng_m_tready(te_cmd_tready),

	.teng_s_tdata(te_rpt_tdata),
	.teng_s_tvalid(te_rpt_tvalid),
	.teng_s_tlast(te_rpt_tlast),
	.teng_s_tready(te_rpt_tready)
);
endmodule
