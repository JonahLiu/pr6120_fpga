module tx_path(
	input aclk,
	input aresetn,

	// Parameters
	input EN, // Transmit Enable
	input PSP, // Pad Short Packets
	input [63:0] TDBA, // Transmit Descriptor Base Address
	input [12:0] TDLEN, // Transmit Descriptor Buffer length=TDLEN*16*8
	input [15:0] TDH, // Transmit Descriptor Head
	input [15:0] TIDV, // Interrupt Delay
	input DPP, // Disable Packet Prefetching
	input [5:0] PTHRESH, // Prefetch Threshold
	input [5:0] HTHRESH, // Host Threshold
	input [5:0] WTHRESH, // Write Back Threshold
	input GRAN, // Granularity
	input [5:0] LWTHRESH, // Tx Desc Low Threshold
	input [15:0] IDV, // Absolute Interrupt Delay
	input [15:0] TSMT, // TCP Segmentation Minimum Transfer
	input [15:0] TSPBP, // TCP Segmentation Packet Buffer Padding

	// Command Port
	// Desc tail send to this port
	input [31:0] cmd_s_tdata,
	input cmd_s_tvalid,
	input cmd_s_tlast,
	input cmd_s_tready,

	// Status Update Port
	// Interrupts, Statistics send from this port
	output [31:0] stat_m_tdata,
	output stat_m_tvalid,
	output stat_m_tlast,
	input stat_m_tready,

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

	// MAC Tx Port
	input [7:0] mac_m_tdata,
	input mac_m_tvalid,
	input mac_m_tlast,
	output mac_m_tready	
);

// Transmitter state machine
tx_ctrl tx_ctrl_i(
	.aclk(aclk),
	.aresetn(aresetn),

	// Parameters
	.EN(EN),
	.PSP(PSP),
	.TDBA(TDBA),
	.TDLEN(TDLEN),
	.TDH(TDH),
	.TIDV(TIDV),
	.DPP(DPP),
	.PTHRESH(PTHRESH),
	.HTHRESH(HTHRESH),
	.WTHRESH(WTHRESH),
	.GRAN(GRAN),
	.LWTHRESH(LWTHRESH),
	.IDV(IDV),
	.TSMT(TSMT),
	.TSPBP(TSPBP),

	// Command Port
	.s_tdata(cmd_s_tdata),
	.s_tvalid(cmd_s_tvalid),
	.s_tlast(cmd_s_tlast),
	.s_tready(cmd_s_tready),

	// Status Port
	.m_tdata(stat_m_tdata),
	.m_tvalid(stat_m_tvalid),
	.m_tlast(stat_m_tlast),
	.m_tready(stat_m_tready),

	// Internal RAM Access Port
	.ram_m_awid(tctl_ram_m_awid),
	.ram_m_awaddr(tctl_ram_m_awaddr),
	.ram_m_awlen(tctl_ram_m_awlen),
	.ram_m_awsize(tctl_ram_m_awsize),
	.ram_m_awburst(tctl_ram_m_awburst),
	.ram_m_awvalid(tctl_ram_m_awvalid),
	.ram_m_awready(tctl_ram_m_awready),

	.ram_m_wid(tctl_ram_m_wid),
	.ram_m_wdata(tctl_ram_m_wdata),
	.ram_m_wstrb(tctl_ram_m_wstrb),
	.ram_m_wlast(tctl_ram_m_wlast),
	.ram_m_wvalid(tctl_ram_m_wvalid),
	.ram_m_wready(tctl_ram_m_wready),

	.ram_m_bid(tctl_ram_m_bid),
	.ram_m_bresp(tctl_ram_m_bresp),
	.ram_m_bvalid(tctl_ram_m_bvalid),
	.ram_m_bready(tctl_ram_m_bready),

	.ram_m_arid(tctl_ram_m_arid),
	.ram_m_araddr(tctl_ram_m_araddr),
	.ram_m_arlen(tctl_ram_m_arlen),
	.ram_m_arsize(tctl_ram_m_arsize),
	.ram_m_arburst(tctl_ram_m_arburst),
	.ram_m_arvalid(tctl_ram_m_arvalid),
	.ram_m_arready(tctl_ram_m_arready),

	.ram_m_rid(tctl_ram_m_rid),
	.ram_m_rdata(tctl_ram_m_rdata),
	.ram_m_rresp(tctl_ram_m_rresp),
	.ram_m_rlast(tctl_ram_m_rlast),
	.ram_m_rvalid(tctl_ram_m_rvalid),
	.ram_m_rready(tctl_ram_m_rready),

	// idma Command Port
	.idma_m_tdata(idma_s_tdata),
	.idma_m_tvalid(idma_s_tvalid),
	.idma_m_tlast(idma_s_tlast),
	.idma_m_tready(idma_s_tready),

	.idma_s_tdata(idma_m_tdata),
	.idma_s_tvalid(idma_m_tvalid),
	.idma_s_tlast(idma_m_tlast),
	.idma_s_tready(idma_m_tready),

	// TCP Segmentation
	.tseg_m_tdata(tseg_s_tdata),
	.tseg_m_tvalid(tseg_s_tvalid),
	.tseg_m_tlast(tseg_s_tlast),
	.tseg_m_tready(tseg_s_tready),

	.tseg_s_tdata(tseg_m_tdata),
	.tseg_s_tvalid(tseg_m_tvalid),
	.tseg_s_tlast(tseg_m_tlast),
	.tseg_s_tready(tseg_m_tready),

	// Tx Encapsulate
	.tenc_m_tdata(tenc_s_tdata),
	.tenc_m_tvalid(tenc_s_tvalid),
	.tenc_m_tlast(tenc_s_tlast),
	.tenc_m_tready(tenc_s_tready),

	.tenc_s_tdata(tenc_m_tdata),
	.tenc_s_tvalid(tenc_m_tvalid),
	.tenc_s_tlast(tenc_m_tlast),
	.tenc_s_tready(tenc_m_tready),

	// Tx checksum 
	.csum_m_tdata(csum_s_tdata),
	.csum_m_tvalid(csum_s_tvalid),
	.csum_m_tlast(csum_s_tlast),
	.csum_m_tready(csum_s_tready),

	.csum_s_tdata(csum_m_tdata),
	.csum_s_tvalid(csum_m_tvalid),
	.csum_s_tlast(csum_m_tlast),
	.csum_s_tready(csum_m_tready),

	// Tx vlan generate
	.vlan_m_tdata(vlan_s_tdata),
	.vlan_m_tvalid(vlan_s_tvalid),
	.vlan_m_tlast(vlan_s_tlast),
	.vlan_m_tready(vlan_s_tready),

	.vlan_s_tdata(vlan_m_tdata),
	.vlan_s_tvalid(vlan_m_tvalid),
	.vlan_s_tlast(vlan_m_tlast),
	.vlan_s_tready(vlan_m_tready),

	// Tx RAM to stream
	.snd_m_tdata(snd_s_tdata),
	.snd_m_tvalid(snd_s_tvalid),
	.snd_m_tlast(snd_s_tlast),
	.snd_m_tready(snd_s_tready),

	.snd_s_tdata(snd_m_tdata),
	.snd_s_tvalid(snd_m_tvalid),
	.snd_s_tlast(snd_m_tlast),
	.snd_s_tready(snd_m_tready)
);

// DMA controller between external bus and local ram 
axi_idma tx_idma_i(
	.aclk(aclk),
	.aresetn(aresetn),

	// DMA Command Port
	.s_tdata(idma_s_tdata),
	.s_tvalid(idma_s_tvalid),
	.s_tlast(idma_s_tlast),
	.s_tready(idma_s_tready),

	// DMA Status Port
	.m_tdata(idma_m_tdata),
	.m_tvalid(idma_m_tvalid),
	.m_tlast(idma_m_tlast),
	.m_tready(idma_m_tready),

	// External Bus Access Port
	.bus_m_awid(axi_m_awid),
	.bus_m_awaddr(axi_m_awaddr),
	.bus_m_awlen(axi_m_awlen),
	.bus_m_awsize(axi_m_awsize),
	.bus_m_awburst(axi_m_awburst),
	.bus_m_awvalid(axi_m_awvalid),
	.bus_m_awready(axi_m_awready),

	.bus_m_wid(axi_m_wid),
	.bus_m_wdata(axi_m_wdata),
	.bus_m_wstrb(axi_m_wstrb),
	.bus_m_wlast(axi_m_wlast),
	.bus_m_wvalid(axi_m_wvalid),
	.bus_m_wready(axi_m_wready),

	.bus_m_bid(axi_m_bid),
	.bus_m_bresp(axi_m_bresp),
	.bus_m_bvalid(axi_m_bvalid),
	.bus_m_bready(axi_m_bready),

	.bus_m_arid(axi_m_arid),
	.bus_m_araddr(axi_m_araddr),
	.bus_m_arlen(axi_m_arlen),
	.bus_m_arsize(axi_m_arsize),
	.bus_m_arburst(axi_m_arburst),
	.bus_m_arvalid(axi_m_arvalid),
	.bus_m_arready(axi_m_arready),

	.bus_m_rid(axi_m_rid),
	.bus_m_rdata(axi_m_rdata),
	.bus_m_rresp(axi_m_rresp),
	.bus_m_rlast(axi_m_rlast),
	.bus_m_rvalid(axi_m_rvalid),
	.bus_m_rready(axi_m_rready),

	// Internal RAM Access Port
	.ram_m_awid(idma_ram_m_awid),
	.ram_m_awaddr(idma_ram_m_awaddr),
	.ram_m_awlen(idma_ram_m_awlen),
	.ram_m_awsize(idma_ram_m_awsize),
	.ram_m_awburst(idma_ram_m_awburst),
	.ram_m_awvalid(idma_ram_m_awvalid),
	.ram_m_awready(idma_ram_m_awready),

	.ram_m_wid(idma_ram_m_wid),
	.ram_m_wdata(idma_ram_m_wdata),
	.ram_m_wstrb(idma_ram_m_wstrb),
	.ram_m_wlast(idma_ram_m_wlast),
	.ram_m_wvalid(idma_ram_m_wvalid),
	.ram_m_wready(idma_ram_m_wready),

	.ram_m_bid(idma_ram_m_bid),
	.ram_m_bresp(idma_ram_m_bresp),
	.ram_m_bvalid(idma_ram_m_bvalid),
	.ram_m_bready(idma_ram_m_bready),

	.ram_m_arid(idma_ram_m_arid),
	.ram_m_araddr(idma_ram_m_araddr),
	.ram_m_arlen(idma_ram_m_arlen),
	.ram_m_arsize(idma_ram_m_arsize),
	.ram_m_arburst(idma_ram_m_arburst),
	.ram_m_arvalid(idma_ram_m_arvalid),
	.ram_m_arready(idma_ram_m_arready),

	.ram_m_rid(idma_ram_m_rid),
	.ram_m_rdata(idma_ram_m_rdata),
	.ram_m_rresp(idma_ram_m_rresp),
	.ram_m_rlast(idma_ram_m_rlast),
	.ram_m_rvalid(idma_ram_m_rvalid),
	.ram_m_rready(idma_ram_m_rready)
);

// Tx TCP Segmentation
tx_segmentation tx_segmentation_i(
	.aclk(aclk),
	.aresetn(aresetn),

	// Command Port
	.s_tdata(tseg_s_tdata),
	.s_tvalid(tseg_s_tvalid),
	.s_tlast(tseg_s_tlast),
	.s_tready(tseg_s_tready),

	// Status Port
	.m_tdata(tseg_m_tdata),
	.m_tvalid(tseg_m_tvalid),
	.m_tlast(tseg_m_tlast),
	.m_tready(tseg_m_tready),

	// Internal RAM Access Port
	.ram_m_awid(tseg_ram_m_awid),
	.ram_m_awaddr(tseg_ram_m_awaddr),
	.ram_m_awlen(tseg_ram_m_awlen),
	.ram_m_awsize(tseg_ram_m_awsize),
	.ram_m_awburst(tseg_ram_m_awburst),
	.ram_m_awvalid(tseg_ram_m_awvalid),
	.ram_m_awready(tseg_ram_m_awready),

	.ram_m_wid(tseg_ram_m_wid),
	.ram_m_wdata(tseg_ram_m_wdata),
	.ram_m_wstrb(tseg_ram_m_wstrb),
	.ram_m_wlast(tseg_ram_m_wlast),
	.ram_m_wvalid(tseg_ram_m_wvalid),
	.ram_m_wready(tseg_ram_m_wready),

	.ram_m_bid(tseg_ram_m_bid),
	.ram_m_bresp(tseg_ram_m_bresp),
	.ram_m_bvalid(tseg_ram_m_bvalid),
	.ram_m_bready(tseg_ram_m_bready),

	.ram_m_arid(tseg_ram_m_arid),
	.ram_m_araddr(tseg_ram_m_araddr),
	.ram_m_arlen(tseg_ram_m_arlen),
	.ram_m_arsize(tseg_ram_m_arsize),
	.ram_m_arburst(tseg_ram_m_arburst),
	.ram_m_arvalid(tseg_ram_m_arvalid),
	.ram_m_arready(tseg_ram_m_arready),

	.ram_m_rid(tseg_ram_m_rid),
	.ram_m_rdata(tseg_ram_m_rdata),
	.ram_m_rresp(tseg_ram_m_rresp),
	.ram_m_rlast(tseg_ram_m_rlast),
	.ram_m_rvalid(tseg_ram_m_rvalid),
	.ram_m_rready(tseg_ram_m_rready)

);

// Tx TCP Segmentation
tx_encapsulate tx_encapsulate_i(
	.aclk(aclk),
	.aresetn(aresetn),

	// Command Port
	.s_tdata(tenc_s_tdata),
	.s_tvalid(tenc_s_tvalid),
	.s_tlast(tenc_s_tlast),
	.s_tready(tenc_s_tready),

	// Status Port
	.m_tdata(tenc_m_tdata),
	.m_tvalid(tenc_m_tvalid),
	.m_tlast(tenc_m_tlast),
	.m_tready(tenc_m_tready),

	// Internal RAM Access Port
	.ram_m_awid(tenc_ram_m_awid),
	.ram_m_awaddr(tenc_ram_m_awaddr),
	.ram_m_awlen(tenc_ram_m_awlen),
	.ram_m_awsize(tenc_ram_m_awsize),
	.ram_m_awburst(tenc_ram_m_awburst),
	.ram_m_awvalid(tenc_ram_m_awvalid),
	.ram_m_awready(tenc_ram_m_awready),

	.ram_m_wid(tenc_ram_m_wid),
	.ram_m_wdata(tenc_ram_m_wdata),
	.ram_m_wstrb(tenc_ram_m_wstrb),
	.ram_m_wlast(tenc_ram_m_wlast),
	.ram_m_wvalid(tenc_ram_m_wvalid),
	.ram_m_wready(tenc_ram_m_wready),

	.ram_m_bid(tenc_ram_m_bid),
	.ram_m_bresp(tenc_ram_m_bresp),
	.ram_m_bvalid(tenc_ram_m_bvalid),
	.ram_m_bready(tenc_ram_m_bready),

	.ram_m_arid(tenc_ram_m_arid),
	.ram_m_araddr(tenc_ram_m_araddr),
	.ram_m_arlen(tenc_ram_m_arlen),
	.ram_m_arsize(tenc_ram_m_arsize),
	.ram_m_arburst(tenc_ram_m_arburst),
	.ram_m_arvalid(tenc_ram_m_arvalid),
	.ram_m_arready(tenc_ram_m_arready),

	.ram_m_rid(tenc_ram_m_rid),
	.ram_m_rdata(tenc_ram_m_rdata),
	.ram_m_rresp(tenc_ram_m_rresp),
	.ram_m_rlast(tenc_ram_m_rlast),
	.ram_m_rvalid(tenc_ram_m_rvalid),
	.ram_m_rready(tenc_ram_m_rready)

);

// Tx packet checksum generation
tx_checksum tx_checksum_i(
	.aclk(aclk),
	.aresetn(aresetn),

	// Command Port
	.s_tdata(csum_s_tdata),
	.s_tvalid(csum_s_tvalid),
	.s_tlast(csum_s_tlast),
	.s_tready(csum_s_tready),

	// Status Port
	.m_tdata(csum_m_tdata),
	.m_tvalid(csum_m_tvalid),
	.m_tlast(csum_m_tlast),
	.m_tready(csum_m_tready),

	// Internal RAM Access Port
	.ram_m_awid(csum_ram_m_awid),
	.ram_m_awaddr(csum_ram_m_awaddr),
	.ram_m_awlen(csum_ram_m_awlen),
	.ram_m_awsize(csum_ram_m_awsize),
	.ram_m_awburst(csum_ram_m_awburst),
	.ram_m_awvalid(csum_ram_m_awvalid),
	.ram_m_awready(csum_ram_m_awready),

	.ram_m_wid(csum_ram_m_wid),
	.ram_m_wdata(csum_ram_m_wdata),
	.ram_m_wstrb(csum_ram_m_wstrb),
	.ram_m_wlast(csum_ram_m_wlast),
	.ram_m_wvalid(csum_ram_m_wvalid),
	.ram_m_wready(csum_ram_m_wready),

	.ram_m_bid(csum_ram_m_bid),
	.ram_m_bresp(csum_ram_m_bresp),
	.ram_m_bvalid(csum_ram_m_bvalid),
	.ram_m_bready(csum_ram_m_bready),

	.ram_m_arid(csum_ram_m_arid),
	.ram_m_araddr(csum_ram_m_araddr),
	.ram_m_arlen(csum_ram_m_arlen),
	.ram_m_arsize(csum_ram_m_arsize),
	.ram_m_arburst(csum_ram_m_arburst),
	.ram_m_arvalid(csum_ram_m_arvalid),
	.ram_m_arready(csum_ram_m_arready),

	.ram_m_rid(csum_ram_m_rid),
	.ram_m_rdata(csum_ram_m_rdata),
	.ram_m_rresp(csum_ram_m_rresp),
	.ram_m_rlast(csum_ram_m_rlast),
	.ram_m_rvalid(csum_ram_m_rvalid),
	.ram_m_rready(csum_ram_m_rready)

);

// Tx VLAN tag strip
tx_vlan tx_vlan_i(
	.aclk(aclk),
	.aresetn(aresetn),

	// Command Port
	.s_tdata(vlan_s_tdata),
	.s_tvalid(vlan_s_tvalid),
	.s_tlast(vlan_s_tlast),
	.s_tready(vlan_s_tready),

	// Status Port
	.m_tdata(vlan_m_tdata),
	.m_tvalid(vlan_m_tvalid),
	.m_tlast(vlan_m_tlast),
	.m_tready(vlan_m_tready),

	// Internal RAM Access Port
	.ram_m_awid(vlan_ram_m_awid),
	.ram_m_awaddr(vlan_ram_m_awaddr),
	.ram_m_awlen(vlan_ram_m_awlen),
	.ram_m_awsize(vlan_ram_m_awsize),
	.ram_m_awburst(vlan_ram_m_awburst),
	.ram_m_awvalid(vlan_ram_m_awvalid),
	.ram_m_awready(vlan_ram_m_awready),

	.ram_m_wid(vlan_ram_m_wid),
	.ram_m_wdata(vlan_ram_m_wdata),
	.ram_m_wstrb(vlan_ram_m_wstrb),
	.ram_m_wlast(vlan_ram_m_wlast),
	.ram_m_wvalid(vlan_ram_m_wvalid),
	.ram_m_wready(vlan_ram_m_wready),

	.ram_m_bid(vlan_ram_m_bid),
	.ram_m_bresp(vlan_ram_m_bresp),
	.ram_m_bvalid(vlan_ram_m_bvalid),
	.ram_m_bready(vlan_ram_m_bready),

	.ram_m_arid(vlan_ram_m_arid),
	.ram_m_araddr(vlan_ram_m_araddr),
	.ram_m_arlen(vlan_ram_m_arlen),
	.ram_m_arsize(vlan_ram_m_arsize),
	.ram_m_arburst(vlan_ram_m_arburst),
	.ram_m_arvalid(vlan_ram_m_arvalid),
	.ram_m_arready(vlan_ram_m_arready),

	.ram_m_rid(vlan_ram_m_rid),
	.ram_m_rdata(vlan_ram_m_rdata),
	.ram_m_rresp(vlan_ram_m_rresp),
	.ram_m_rlast(vlan_ram_m_rlast),
	.ram_m_rvalid(vlan_ram_m_rvalid),
	.ram_m_rready(vlan_ram_m_rready)

);

tx_send tx_send_i(
	.aclk(aclk),
	.aresetn(aresetn),

	// Tx Command Port
	// Packet location and length passed in 
	.s_tdata(snd_s_tdata),
	.s_tvalid(snd_s_tvalid),
	.s_tlast(snd_s_tlast),
	.s_tready(snd_s_tready),

	// Tx Status Port
	// RAM recycles passed out
	.m_tdata(snd_m_tdata),
	.m_tvalid(snd_m_tvalid),
	.m_tlast(snd_m_tlast),
	.m_tready(snd_m_tready),

	// Internal RAM Access Port
	// Packet storage
	.ram_m_awid(snd_m_awid),
	.ram_m_awaddr(snd_m_awaddr),
	.ram_m_awlen(snd_m_awlen),
	.ram_m_awsize(snd_m_awsize),
	.ram_m_awburst(snd_m_awburst),
	.ram_m_awcache(snd_m_awcache),
	.ram_m_awvalid(snd_m_awvalid),
	.ram_m_awready(snd_m_awready),

	.ram_m_wid(snd_m_wid),
	.ram_m_wdata(snd_m_wdata),
	.ram_m_wstrb(snd_m_wstrb),
	.ram_m_wlast(snd_m_wlast),
	.ram_m_wvalid(snd_m_wvalid),
	.ram_m_wready(snd_m_wready),

	.ram_m_bid(snd_m_bid),
	.ram_m_bresp(snd_m_bresp),
	.ram_m_bvalid(snd_m_bvalid),
	.ram_m_bready(snd_m_bready),

	.ram_m_arid(snd_m_arid),
	.ram_m_araddr(snd_m_araddr),
	.ram_m_arlen(snd_m_arlen),
	.ram_m_arsize(snd_m_arsize),
	.ram_m_arburst(snd_m_arburst),
	.ram_m_arcache(snd_m_arcache),
	.ram_m_arvalid(snd_m_arvalid),
	.ram_m_arready(snd_m_arready),

	.ram_m_rid(snd_m_rid),
	.ram_m_rdata(snd_m_rdata),
	.ram_m_rresp(snd_m_rresp),
	.ram_m_rlast(snd_m_rlast),
	.ram_m_rvalid(snd_m_rvalid),
	.ram_m_rready(snd_m_rready),

	// MAC Tx Stream Port
	.mac_m_tdata(mac_m_tdata),
	.mac_m_tvalid(mac_m_tvalid),
	.mac_m_tlast(mac_m_tlast),
	.mac_m_tready(mac_m_tready)
);

// Tx descriptor storage
// This is a block ram about 4kB size
tx_rdram tx_rdram_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.s_awid(tdram_s_awid),
	.s_awaddr(tdram_s_awaddr),
	.s_awlen(tdram_s_awlen),
	.s_awsize(tdram_s_awsize),
	.s_awburst(tdram_s_awburst),
	.s_awvalid(tdram_s_awvalid),
	.s_awready(tdram_s_awready),

	.s_wid(tdram_s_wid),
	.s_wdata(tdram_s_wdata),
	.s_wstrb(tdram_s_wstrb),
	.s_wlast(tdram_s_wlast),
	.s_wvalid(tdram_s_wvalid),
	.s_wready(tdram_s_wready),

	.s_bid(tdram_s_bid),
	.s_bresp(tdram_s_bresp),
	.s_bvalid(tdram_s_bvalid),
	.s_bready(tdram_s_bready),

	.s_arid(tdram_s_arid),
	.s_araddr(tdram_s_araddr),
	.s_arlen(tdram_s_arlen),
	.s_arsize(tdram_s_arsize),
	.s_arburst(tdram_s_arburst),
	.s_arvalid(tdram_s_arvalid),
	.s_arready(tdram_s_arready),

	.s_rid(tdram_s_rid),
	.s_rdata(tdram_s_rdata),
	.s_rresp(tdram_s_rresp),
	.s_rlast(tdram_s_rlast),
	.s_rvalid(tdram_s_rvalid),
	.s_rready(tdram_s_rready)
);

// Tx data storage
// This is a block ram about 16kB size
tx_dbram tx_dbram_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.s_awid(dbram_s_awid),
	.s_awaddr(dbram_s_awaddr),
	.s_awlen(dbram_s_awlen),
	.s_awsize(dbram_s_awsize),
	.s_awburst(dbram_s_awburst),
	.s_awvalid(dbram_s_awvalid),
	.s_awready(dbram_s_awready),

	.s_wid(dbram_s_wid),
	.s_wdata(dbram_s_wdata),
	.s_wstrb(dbram_s_wstrb),
	.s_wlast(dbram_s_wlast),
	.s_wvalid(dbram_s_wvalid),
	.s_wready(dbram_s_wready),

	.s_bid(dbram_s_bid),
	.s_bresp(dbram_s_bresp),
	.s_bvalid(dbram_s_bvalid),
	.s_bready(dbram_s_bready),

	.s_arid(dbram_s_arid),
	.s_araddr(dbram_s_araddr),
	.s_arlen(dbram_s_arlen),
	.s_arsize(dbram_s_arsize),
	.s_arburst(dbram_s_arburst),
	.s_arvalid(dbram_s_arvalid),
	.s_arready(dbram_s_arready),

	.s_rid(dbram_s_rid),
	.s_rdata(dbram_s_rdata),
	.s_rresp(dbram_s_rresp),
	.s_rlast(dbram_s_rlast),
	.s_rvalid(dbram_s_rvalid),
	.s_rready(dbram_s_rready)
);

// Tx packet storage
// This is a block ram about 16kB size
tx_pbram tx_pbram_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.s_awid(pbram_s_awid),
	.s_awaddr(pbram_s_awaddr),
	.s_awlen(pbram_s_awlen),
	.s_awsize(pbram_s_awsize),
	.s_awburst(pbram_s_awburst),
	.s_awvalid(pbram_s_awvalid),
	.s_awready(pbram_s_awready),

	.s_wid(pbram_s_wid),
	.s_wdata(pbram_s_wdata),
	.s_wstrb(pbram_s_wstrb),
	.s_wlast(pbram_s_wlast),
	.s_wvalid(pbram_s_wvalid),
	.s_wready(pbram_s_wready),

	.s_bid(pbram_s_bid),
	.s_bresp(pbram_s_bresp),
	.s_bvalid(pbram_s_bvalid),
	.s_bready(pbram_s_bready),

	.s_arid(pbram_s_arid),
	.s_araddr(pbram_s_araddr),
	.s_arlen(pbram_s_arlen),
	.s_arsize(pbram_s_arsize),
	.s_arburst(pbram_s_arburst),
	.s_arvalid(pbram_s_arvalid),
	.s_arready(pbram_s_arready),

	.s_rid(pbram_s_rid),
	.s_rdata(pbram_s_rdata),
	.s_rresp(pbram_s_rresp),
	.s_rlast(pbram_s_rlast),
	.s_rvalid(pbram_s_rvalid),
	.s_rready(pbram_s_rready)
);

// Internal axi crossbar
tx_crossbar tx_crossbar_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.s0_axi_awid(idma_ram_m_awid),
	.s0_axi_awaddr(idma_ram_m_awaddr),
	.s0_axi_awlen(idma_ram_m_awlen),
	.s0_axi_awsize(idma_ram_m_awsize),
	.s0_axi_awburst(idma_ram_m_awburst),
	.s0_axi_awvalid(idma_ram_m_awvalid),
	.s0_axi_awready(idma_ram_m_awready),

	.s0_axi_wid(idma_ram_m_wid),
	.s0_axi_wdata(idma_ram_m_wdata),
	.s0_axi_wstrb(idma_ram_m_wstrb),
	.s0_axi_wlast(idma_ram_m_wlast),
	.s0_axi_wvalid(idma_ram_m_wvalid),
	.s0_axi_wready(idma_ram_m_wready),

	.s0_axi_bid(idma_ram_m_bid),
	.s0_axi_bresp(idma_ram_m_bresp),
	.s0_axi_bvalid(idma_ram_m_bvalid),
	.s0_axi_bready(idma_ram_m_bready),

	.s0_axi_arid(idma_ram_m_arid),
	.s0_axi_araddr(idma_ram_m_araddr),
	.s0_axi_arlen(idma_ram_m_arlen),
	.s0_axi_arsize(idma_ram_m_arsize),
	.s0_axi_arburst(idma_ram_m_arburst),
	.s0_axi_arvalid(idma_ram_m_arvalid),
	.s0_axi_arready(idma_ram_m_arready),

	.s0_axi_rid(idma_ram_m_rid),
	.s0_axi_rdata(idma_ram_m_rdata),
	.s0_axi_rresp(idma_ram_m_rresp),
	.s0_axi_rlast(idma_ram_m_rlast),
	.s0_axi_rvalid(idma_ram_m_rvalid),
	.s0_axi_rready(idma_ram_m_rready),

	.s1_axi_awid(tctl_ram_m_awid),
	.s1_axi_awaddr(tctl_ram_m_awaddr),
	.s1_axi_awlen(tctl_ram_m_awlen),
	.s1_axi_awsize(tctl_ram_m_awsize),
	.s1_axi_awburst(tctl_ram_m_awburst),
	.s1_axi_awvalid(tctl_ram_m_awvalid),
	.s1_axi_awready(tctl_ram_m_awready),

	.s1_axi_wid(tctl_ram_m_wid),
	.s1_axi_wdata(tctl_ram_m_wdata),
	.s1_axi_wstrb(tctl_ram_m_wstrb),
	.s1_axi_wlast(tctl_ram_m_wlast),
	.s1_axi_wvalid(tctl_ram_m_wvalid),
	.s1_axi_wready(tctl_ram_m_wready),

	.s1_axi_bid(tctl_ram_m_bid),
	.s1_axi_bresp(tctl_ram_m_bresp),
	.s1_axi_bvalid(tctl_ram_m_bvalid),
	.s1_axi_bready(tctl_ram_m_bready),

	.s1_axi_arid(tctl_ram_m_arid),
	.s1_axi_araddr(tctl_ram_m_araddr),
	.s1_axi_arlen(tctl_ram_m_arlen),
	.s1_axi_arsize(tctl_ram_m_arsize),
	.s1_axi_arburst(tctl_ram_m_arburst),
	.s1_axi_arvalid(tctl_ram_m_arvalid),
	.s1_axi_arready(tctl_ram_m_arready),

	.s1_axi_rid(tctl_ram_m_rid),
	.s1_axi_rdata(tctl_ram_m_rdata),
	.s1_axi_rresp(tctl_ram_m_rresp),
	.s1_axi_rlast(tctl_ram_m_rlast),
	.s1_axi_rvalid(tctl_ram_m_rvalid),
	.s1_axi_rready(tctl_ram_m_rready),

	.s2_axi_awid(tseg_ram_m_awid),
	.s2_axi_awaddr(tseg_ram_m_awaddr),
	.s2_axi_awlen(tseg_ram_m_awlen),
	.s2_axi_awsize(tseg_ram_m_awsize),
	.s2_axi_awburst(tseg_ram_m_awburst),
	.s2_axi_awvalid(tseg_ram_m_awvalid),
	.s2_axi_awready(tseg_ram_m_awready),

	.s2_axi_wid(tseg_ram_m_wid),
	.s2_axi_wdata(tseg_ram_m_wdata),
	.s2_axi_wstrb(tseg_ram_m_wstrb),
	.s2_axi_wlast(tseg_ram_m_wlast),
	.s2_axi_wvalid(tseg_ram_m_wvalid),
	.s2_axi_wready(tseg_ram_m_wready),

	.s2_axi_bid(tseg_ram_m_bid),
	.s2_axi_bresp(tseg_ram_m_bresp),
	.s2_axi_bvalid(tseg_ram_m_bvalid),
	.s2_axi_bready(tseg_ram_m_bready),

	.s2_axi_arid(tseg_ram_m_arid),
	.s2_axi_araddr(tseg_ram_m_araddr),
	.s2_axi_arlen(tseg_ram_m_arlen),
	.s2_axi_arsize(tseg_ram_m_arsize),
	.s2_axi_arburst(tseg_ram_m_arburst),
	.s2_axi_arvalid(tseg_ram_m_arvalid),
	.s2_axi_arready(tseg_ram_m_arready),

	.s2_axi_rid(tseg_ram_m_rid),
	.s2_axi_rdata(tseg_ram_m_rdata),
	.s2_axi_rresp(tseg_ram_m_rresp),
	.s2_axi_rlast(tseg_ram_m_rlast),
	.s2_axi_rvalid(tseg_ram_m_rvalid),
	.s2_axi_rready(tseg_ram_m_rready),

	.s3_axi_awid(tenc_ram_m_awid),
	.s3_axi_awaddr(tenc_ram_m_awaddr),
	.s3_axi_awlen(tenc_ram_m_awlen),
	.s3_axi_awsize(tenc_ram_m_awsize),
	.s3_axi_awburst(tenc_ram_m_awburst),
	.s3_axi_awvalid(tenc_ram_m_awvalid),
	.s3_axi_awready(tenc_ram_m_awready),

	.s3_axi_wid(tenc_ram_m_wid),
	.s3_axi_wdata(tenc_ram_m_wdata),
	.s3_axi_wstrb(tenc_ram_m_wstrb),
	.s3_axi_wlast(tenc_ram_m_wlast),
	.s3_axi_wvalid(tenc_ram_m_wvalid),
	.s3_axi_wready(tenc_ram_m_wready),

	.s3_axi_bid(tenc_ram_m_bid),
	.s3_axi_bresp(tenc_ram_m_bresp),
	.s3_axi_bvalid(tenc_ram_m_bvalid),
	.s3_axi_bready(tenc_ram_m_bready),

	.s3_axi_arid(tenc_ram_m_arid),
	.s3_axi_araddr(tenc_ram_m_araddr),
	.s3_axi_arlen(tenc_ram_m_arlen),
	.s3_axi_arsize(tenc_ram_m_arsize),
	.s3_axi_arburst(tenc_ram_m_arburst),
	.s3_axi_arvalid(tenc_ram_m_arvalid),
	.s3_axi_arready(tenc_ram_m_arready),

	.s3_axi_rid(tenc_ram_m_rid),
	.s3_axi_rdata(tenc_ram_m_rdata),
	.s3_axi_rresp(tenc_ram_m_rresp),
	.s3_axi_rlast(tenc_ram_m_rlast),
	.s3_axi_rvalid(tenc_ram_m_rvalid),
	.s3_axi_rready(tenc_ram_m_rready),

	.s4_axi_awid(csum_ram_m_awid),
	.s4_axi_awaddr(csum_ram_m_awaddr),
	.s4_axi_awlen(csum_ram_m_awlen),
	.s4_axi_awsize(csum_ram_m_awsize),
	.s4_axi_awburst(csum_ram_m_awburst),
	.s4_axi_awvalid(csum_ram_m_awvalid),
	.s4_axi_awready(csum_ram_m_awready),

	.s4_axi_wid(csum_ram_m_wid),
	.s4_axi_wdata(csum_ram_m_wdata),
	.s4_axi_wstrb(csum_ram_m_wstrb),
	.s4_axi_wlast(csum_ram_m_wlast),
	.s4_axi_wvalid(csum_ram_m_wvalid),
	.s4_axi_wready(csum_ram_m_wready),

	.s4_axi_bid(csum_ram_m_bid),
	.s4_axi_bresp(csum_ram_m_bresp),
	.s4_axi_bvalid(csum_ram_m_bvalid),
	.s4_axi_bready(csum_ram_m_bready),

	.s4_axi_arid(csum_ram_m_arid),
	.s4_axi_araddr(csum_ram_m_araddr),
	.s4_axi_arlen(csum_ram_m_arlen),
	.s4_axi_arsize(csum_ram_m_arsize),
	.s4_axi_arburst(csum_ram_m_arburst),
	.s4_axi_arvalid(csum_ram_m_arvalid),
	.s4_axi_arready(csum_ram_m_arready),

	.s4_axi_rid(csum_ram_m_rid),
	.s4_axi_rdata(csum_ram_m_rdata),
	.s4_axi_rresp(csum_ram_m_rresp),
	.s4_axi_rlast(csum_ram_m_rlast),
	.s4_axi_rvalid(csum_ram_m_rvalid),
	.s4_axi_rready(csum_ram_m_rready),

	.s5_axi_awid(vlan_ram_m_awid),
	.s5_axi_awaddr(vlan_ram_m_awaddr),
	.s5_axi_awlen(vlan_ram_m_awlen),
	.s5_axi_awsize(vlan_ram_m_awsize),
	.s5_axi_awburst(vlan_ram_m_awburst),
	.s5_axi_awvalid(vlan_ram_m_awvalid),
	.s5_axi_awready(vlan_ram_m_awready),

	.s5_axi_wid(vlan_ram_m_wid),
	.s5_axi_wdata(vlan_ram_m_wdata),
	.s5_axi_wstrb(vlan_ram_m_wstrb),
	.s5_axi_wlast(vlan_ram_m_wlast),
	.s5_axi_wvalid(vlan_ram_m_wvalid),
	.s5_axi_wready(vlan_ram_m_wready),

	.s5_axi_bid(vlan_ram_m_bid),
	.s5_axi_bresp(vlan_ram_m_bresp),
	.s5_axi_bvalid(vlan_ram_m_bvalid),
	.s5_axi_bready(vlan_ram_m_bready),

	.s5_axi_arid(vlan_ram_m_arid),
	.s5_axi_araddr(vlan_ram_m_araddr),
	.s5_axi_arlen(vlan_ram_m_arlen),
	.s5_axi_arsize(vlan_ram_m_arsize),
	.s5_axi_arburst(vlan_ram_m_arburst),
	.s5_axi_arvalid(vlan_ram_m_arvalid),
	.s5_axi_arready(vlan_ram_m_arready),

	.s5_axi_rid(vlan_ram_m_rid),
	.s5_axi_rdata(vlan_ram_m_rdata),
	.s5_axi_rresp(vlan_ram_m_rresp),
	.s5_axi_rlast(vlan_ram_m_rlast),
	.s5_axi_rvalid(vlan_ram_m_rvalid),
	.s5_axi_rready(vlan_ram_m_rready),

	.s6_axi_awid(snd_ram_m_awid),
	.s6_axi_awaddr(snd_ram_m_awaddr),
	.s6_axi_awlen(snd_ram_m_awlen),
	.s6_axi_awsize(snd_ram_m_awsize),
	.s6_axi_awburst(snd_ram_m_awburst),
	.s6_axi_awvalid(snd_ram_m_awvalid),
	.s6_axi_awready(snd_ram_m_awready),

	.s6_axi_wid(snd_ram_m_wid),
	.s6_axi_wdata(snd_ram_m_wdata),
	.s6_axi_wstrb(snd_ram_m_wstrb),
	.s6_axi_wlast(snd_ram_m_wlast),
	.s6_axi_wvalid(snd_ram_m_wvalid),
	.s6_axi_wready(snd_ram_m_wready),

	.s6_axi_bid(snd_ram_m_bid),
	.s6_axi_bresp(snd_ram_m_bresp),
	.s6_axi_bvalid(snd_ram_m_bvalid),
	.s6_axi_bready(snd_ram_m_bready),

	.s6_axi_arid(snd_ram_m_arid),
	.s6_axi_araddr(snd_ram_m_araddr),
	.s6_axi_arlen(snd_ram_m_arlen),
	.s6_axi_arsize(snd_ram_m_arsize),
	.s6_axi_arburst(snd_ram_m_arburst),
	.s6_axi_arvalid(snd_ram_m_arvalid),
	.s6_axi_arready(snd_ram_m_arready),

	.s6_axi_rid(snd_ram_m_rid),
	.s6_axi_rdata(snd_ram_m_rdata),
	.s6_axi_rresp(snd_ram_m_rresp),
	.s6_axi_rlast(snd_ram_m_rlast),
	.s6_axi_rvalid(snd_ram_m_rvalid),
	.s6_axi_rready(snd_ram_m_rready),

	.m0_axi_awid(rdram_s_awid),
	.m0_axi_awaddr(rdram_s_awaddr),
	.m0_axi_awlen(rdram_s_awlen),
	.m0_axi_awsize(rdram_s_awsize),
	.m0_axi_awburst(rdram_s_awburst),
	.m0_axi_awvalid(rdram_s_awvalid),
	.m0_axi_awready(rdram_s_awready),

	.m0_axi_wid(rdram_s_wid),
	.m0_axi_wdata(rdram_s_wdata),
	.m0_axi_wstrb(rdram_s_wstrb),
	.m0_axi_wlast(rdram_s_wlast),
	.m0_axi_wvalid(rdram_s_wvalid),
	.m0_axi_wready(rdram_s_wready),

	.m0_axi_bid(rdram_s_bid),
	.m0_axi_bresp(rdram_s_bresp),
	.m0_axi_bvalid(rdram_s_bvalid),
	.m0_axi_bready(rdram_s_bready),

	.m0_axi_arid(rdram_s_arid),
	.m0_axi_araddr(rdram_s_araddr),
	.m0_axi_arlen(rdram_s_arlen),
	.m0_axi_arsize(rdram_s_arsize),
	.m0_axi_arburst(rdram_s_arburst),
	.m0_axi_arvalid(rdram_s_arvalid),
	.m0_axi_arready(rdram_s_arready),

	.m0_axi_rid(rdram_s_rid),
	.m0_axi_rdata(rdram_s_rdata),
	.m0_axi_rresp(rdram_s_rresp),
	.m0_axi_rlast(rdram_s_rlast),
	.m0_axi_rvalid(rdram_s_rvalid),
	.m0_axi_rready(rdram_s_rready),

	.m1_axi_awid(dbram_s_awid),
	.m1_axi_awaddr(dbram_s_awaddr),
	.m1_axi_awlen(dbram_s_awlen),
	.m1_axi_awsize(dbram_s_awsize),
	.m1_axi_awburst(dbram_s_awburst),
	.m1_axi_awvalid(dbram_s_awvalid),
	.m1_axi_awready(dbram_s_awready),

	.m1_axi_wid(dbram_s_wid),
	.m1_axi_wdata(dbram_s_wdata),
	.m1_axi_wstrb(dbram_s_wstrb),
	.m1_axi_wlast(dbram_s_wlast),
	.m1_axi_wvalid(dbram_s_wvalid),
	.m1_axi_wready(dbram_s_wready),

	.m1_axi_bid(dbram_s_bid),
	.m1_axi_bresp(dbram_s_bresp),
	.m1_axi_bvalid(dbram_s_bvalid),
	.m1_axi_bready(dbram_s_bready),

	.m1_axi_arid(dbram_s_arid),
	.m1_axi_araddr(dbram_s_araddr),
	.m1_axi_arlen(dbram_s_arlen),
	.m1_axi_arsize(dbram_s_arsize),
	.m1_axi_arburst(dbram_s_arburst),
	.m1_axi_arvalid(dbram_s_arvalid),
	.m1_axi_arready(dbram_s_arready),

	.m1_axi_rid(dbram_s_rid),
	.m1_axi_rdata(dbram_s_rdata),
	.m1_axi_rresp(dbram_s_rresp),
	.m1_axi_rlast(dbram_s_rlast),
	.m1_axi_rvalid(dbram_s_rvalid),
	.m1_axi_rready(dbram_s_rready),

	.m2_axi_awid(pbram_s_awid),
	.m2_axi_awaddr(pbram_s_awaddr),
	.m2_axi_awlen(pbram_s_awlen),
	.m2_axi_awsize(pbram_s_awsize),
	.m2_axi_awburst(pbram_s_awburst),
	.m2_axi_awvalid(pbram_s_awvalid),
	.m2_axi_awready(pbram_s_awready),

	.m2_axi_wid(pbram_s_wid),
	.m2_axi_wdata(pbram_s_wdata),
	.m2_axi_wstrb(pbram_s_wstrb),
	.m2_axi_wlast(pbram_s_wlast),
	.m2_axi_wvalid(pbram_s_wvalid),
	.m2_axi_wready(pbram_s_wready),

	.m2_axi_bid(pbram_s_bid),
	.m2_axi_bresp(pbram_s_bresp),
	.m2_axi_bvalid(pbram_s_bvalid),
	.m2_axi_bready(pbram_s_bready),

	.m2_axi_arid(pbram_s_arid),
	.m2_axi_araddr(pbram_s_araddr),
	.m2_axi_arlen(pbram_s_arlen),
	.m2_axi_arsize(pbram_s_arsize),
	.m2_axi_arburst(pbram_s_arburst),
	.m2_axi_arvalid(pbram_s_arvalid),
	.m2_axi_arready(pbram_s_arready),

	.m2_axi_rid(pbram_s_rid),
	.m2_axi_rdata(pbram_s_rdata),
	.m2_axi_rresp(pbram_s_rresp),
	.m2_axi_rlast(pbram_s_rlast),
	.m2_axi_rvalid(pbram_s_rvalid),
	.m2_axi_rready(pbram_s_rready)

);

endmodule
