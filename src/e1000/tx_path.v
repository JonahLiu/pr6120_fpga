module tx_path(
	input aclk,
	input aresetn,

	// Parameters
	input EN, // Transmit Enable
	input PSP, // Pad Short Packets
	input [63:0] TDBA, // Transmit Descriptor Base Address
	input [12:0] TDLEN, // Transmit Descriptor Buffer length=TDLEN*16*8
	input [15:0] TDH, // Transmit Descriptor Head
	input [15:0] TDT, // Transmit Descriptor Tail
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

wire [3:0] bram_s_awid;
wire [15:0] bram_s_awaddr;
wire [7:0] bram_s_awlen;
wire [2:0] bram_s_awsize;
wire [1:0] bram_s_awburst;
wire [3:0] bram_s_awcache;
wire bram_s_awvalid;
wire bram_s_awready;
wire [3:0] bram_s_wid;
wire [31:0] bram_s_wdata;
wire [3:0] bram_s_wstrb;
wire bram_s_wlast;
wire bram_s_wvalid;
wire bram_s_wready;
wire [3:0] bram_s_bid;
wire [1:0] bram_s_bresp;
wire bram_s_bvalid;
wire bram_s_bready;
wire [3:0] bram_s_arid;
wire [15:0] bram_s_araddr;
wire [7:0] bram_s_arlen;
wire [2:0] bram_s_arsize;
wire [1:0] bram_s_arburst;
wire [3:0] bram_s_arcache;
wire bram_s_arvalid;
wire bram_s_arready;
wire [3:0] bram_s_rid;
wire [31:0] bram_s_rdata;
wire [1:0] bram_s_rresp;
wire bram_s_rlast;
wire bram_s_rvalid;
wire bram_s_rready;

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

// BRAM for descriptor and packet storage
tx_bram tx_bram_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.s_awid(bram_s_awid),
	.s_awaddr(bram_s_awaddr),
	.s_awlen(bram_s_awlen),
	.s_awsize(bram_s_awsize),
	.s_awburst(bram_s_awburst),
	.s_awvalid(bram_s_awvalid),
	.s_awready(bram_s_awready),

	.s_wid(bram_s_wid),
	.s_wdata(bram_s_wdata),
	.s_wstrb(bram_s_wstrb),
	.s_wlast(bram_s_wlast),
	.s_wvalid(bram_s_wvalid),
	.s_wready(bram_s_wready),

	.s_bid(bram_s_bid),
	.s_bresp(bram_s_bresp),
	.s_bvalid(bram_s_bvalid),
	.s_bready(bram_s_bready),

	.s_arid(bram_s_arid),
	.s_araddr(bram_s_araddr),
	.s_arlen(bram_s_arlen),
	.s_arsize(bram_s_arsize),
	.s_arburst(bram_s_arburst),
	.s_arvalid(bram_s_arvalid),
	.s_arready(bram_s_arready),

	.s_rid(bram_s_rid),
	.s_rdata(bram_s_rdata),
	.s_rresp(bram_s_rresp),
	.s_rlast(bram_s_rlast),
	.s_rvalid(bram_s_rvalid),
	.s_rready(bram_s_rready)
);

// Internal axi crossbar
tx_crossbar tx_crossbar_i(
	.INTERCONNECT_ACLK(aclk),
	.INTERCONNECT_ARESETN(aresetn),

	.S00_AXI_AWID(idma_ram_m_awid),
	.S00_AXI_AWADDR(idma_ram_m_awaddr),
	.S00_AXI_AWLEN(idma_ram_m_awlen),
	.S00_AXI_AWSIZE(idma_ram_m_awsize),
	.S00_AXI_AWBURST(idma_ram_m_awburst),
	.S00_AXI_AWVALID(idma_ram_m_awvalid),
	.S00_AXI_AWREADY(idma_ram_m_awready),

	.S00_AXI_WID(idma_ram_m_wid),
	.S00_AXI_WDATA(idma_ram_m_wdata),
	.S00_AXI_WSTRB(idma_ram_m_wstrb),
	.S00_AXI_WLAST(idma_ram_m_wlast),
	.S00_AXI_WVALID(idma_ram_m_wvalid),
	.S00_AXI_WREADY(idma_ram_m_wready),

	.S00_AXI_BID(idma_ram_m_bid),
	.S00_AXI_BRESP(idma_ram_m_bresp),
	.S00_AXI_BVALID(idma_ram_m_bvalid),
	.S00_AXI_BREADY(idma_ram_m_bready),

	.S00_AXI_ARID(idma_ram_m_arid),
	.S00_AXI_ARADDR(idma_ram_m_araddr),
	.S00_AXI_ARLEN(idma_ram_m_arlen),
	.S00_AXI_ARSIZE(idma_ram_m_arsize),
	.S00_AXI_ARBURST(idma_ram_m_arburst),
	.S00_AXI_ARVALID(idma_ram_m_arvalid),
	.S00_AXI_ARREADY(idma_ram_m_arready),

	.S00_AXI_RID(idma_ram_m_rid),
	.S00_AXI_RDATA(idma_ram_m_rdata),
	.S00_AXI_RRESP(idma_ram_m_rresp),
	.S00_AXI_RLAST(idma_ram_m_rlast),
	.S00_AXI_RVALID(idma_ram_m_rvalid),
	.S00_AXI_RREADY(idma_ram_m_rready),

	.S01_AXI_AWID(tctl_ram_m_awid),
	.S01_AXI_AWADDR(tctl_ram_m_awaddr),
	.S01_AXI_AWLEN(tctl_ram_m_awlen),
	.S01_AXI_AWSIZE(tctl_ram_m_awsize),
	.S01_AXI_AWBURST(tctl_ram_m_awburst),
	.S01_AXI_AWVALID(tctl_ram_m_awvalid),
	.S01_AXI_AWREADY(tctl_ram_m_awready),

	.S01_AXI_WID(tctl_ram_m_wid),
	.S01_AXI_WDATA(tctl_ram_m_wdata),
	.S01_AXI_WSTRB(tctl_ram_m_wstrb),
	.S01_AXI_WLAST(tctl_ram_m_wlast),
	.S01_AXI_WVALID(tctl_ram_m_wvalid),
	.S01_AXI_WREADY(tctl_ram_m_wready),

	.S01_AXI_BID(tctl_ram_m_bid),
	.S01_AXI_BRESP(tctl_ram_m_bresp),
	.S01_AXI_BVALID(tctl_ram_m_bvalid),
	.S01_AXI_BREADY(tctl_ram_m_bready),

	.S01_AXI_ARID(tctl_ram_m_arid),
	.S01_AXI_ARADDR(tctl_ram_m_araddr),
	.S01_AXI_ARLEN(tctl_ram_m_arlen),
	.S01_AXI_ARSIZE(tctl_ram_m_arsize),
	.S01_AXI_ARBURST(tctl_ram_m_arburst),
	.S01_AXI_ARVALID(tctl_ram_m_arvalid),
	.S01_AXI_ARREADY(tctl_ram_m_arready),

	.S01_AXI_RID(tctl_ram_m_rid),
	.S01_AXI_RDATA(tctl_ram_m_rdata),
	.S01_AXI_RRESP(tctl_ram_m_rresp),
	.S01_AXI_RLAST(tctl_ram_m_rlast),
	.S01_AXI_RVALID(tctl_ram_m_rvalid),
	.S01_AXI_RREADY(tctl_ram_m_rready),

	.S02_AXI_AWID(tseg_ram_m_awid),
	.S02_AXI_AWADDR(tseg_ram_m_awaddr),
	.S02_AXI_AWLEN(tseg_ram_m_awlen),
	.S02_AXI_AWSIZE(tseg_ram_m_awsize),
	.S02_AXI_AWBURST(tseg_ram_m_awburst),
	.S02_AXI_AWVALID(tseg_ram_m_awvalid),
	.S02_AXI_AWREADY(tseg_ram_m_awready),

	.S02_AXI_WID(tseg_ram_m_wid),
	.S02_AXI_WDATA(tseg_ram_m_wdata),
	.S02_AXI_WSTRB(tseg_ram_m_wstrb),
	.S02_AXI_WLAST(tseg_ram_m_wlast),
	.S02_AXI_WVALID(tseg_ram_m_wvalid),
	.S02_AXI_WREADY(tseg_ram_m_wready),

	.S02_AXI_BID(tseg_ram_m_bid),
	.S02_AXI_BRESP(tseg_ram_m_bresp),
	.S02_AXI_BVALID(tseg_ram_m_bvalid),
	.S02_AXI_BREADY(tseg_ram_m_bready),

	.S02_AXI_ARID(tseg_ram_m_arid),
	.S02_AXI_ARADDR(tseg_ram_m_araddr),
	.S02_AXI_ARLEN(tseg_ram_m_arlen),
	.S02_AXI_ARSIZE(tseg_ram_m_arsize),
	.S02_AXI_ARBURST(tseg_ram_m_arburst),
	.S02_AXI_ARVALID(tseg_ram_m_arvalid),
	.S02_AXI_ARREADY(tseg_ram_m_arready),

	.S02_AXI_RID(tseg_ram_m_rid),
	.S02_AXI_RDATA(tseg_ram_m_rdata),
	.S02_AXI_RRESP(tseg_ram_m_rresp),
	.S02_AXI_RLAST(tseg_ram_m_rlast),
	.S02_AXI_RVALID(tseg_ram_m_rvalid),
	.S02_AXI_RREADY(tseg_ram_m_rready),

	.S03_AXI_AWID(tenc_ram_m_awid),
	.S03_AXI_AWADDR(tenc_ram_m_awaddr),
	.S03_AXI_AWLEN(tenc_ram_m_awlen),
	.S03_AXI_AWSIZE(tenc_ram_m_awsize),
	.S03_AXI_AWBURST(tenc_ram_m_awburst),
	.S03_AXI_AWVALID(tenc_ram_m_awvalid),
	.S03_AXI_AWREADY(tenc_ram_m_awready),

	.S03_AXI_WID(tenc_ram_m_wid),
	.S03_AXI_WDATA(tenc_ram_m_wdata),
	.S03_AXI_WSTRB(tenc_ram_m_wstrb),
	.S03_AXI_WLAST(tenc_ram_m_wlast),
	.S03_AXI_WVALID(tenc_ram_m_wvalid),
	.S03_AXI_WREADY(tenc_ram_m_wready),

	.S03_AXI_BID(tenc_ram_m_bid),
	.S03_AXI_BRESP(tenc_ram_m_bresp),
	.S03_AXI_BVALID(tenc_ram_m_bvalid),
	.S03_AXI_BREADY(tenc_ram_m_bready),

	.S03_AXI_ARID(tenc_ram_m_arid),
	.S03_AXI_ARADDR(tenc_ram_m_araddr),
	.S03_AXI_ARLEN(tenc_ram_m_arlen),
	.S03_AXI_ARSIZE(tenc_ram_m_arsize),
	.S03_AXI_ARBURST(tenc_ram_m_arburst),
	.S03_AXI_ARVALID(tenc_ram_m_arvalid),
	.S03_AXI_ARREADY(tenc_ram_m_arready),

	.S03_AXI_RID(tenc_ram_m_rid),
	.S03_AXI_RDATA(tenc_ram_m_rdata),
	.S03_AXI_RRESP(tenc_ram_m_rresp),
	.S03_AXI_RLAST(tenc_ram_m_rlast),
	.S03_AXI_RVALID(tenc_ram_m_rvalid),
	.S03_AXI_RREADY(tenc_ram_m_rready),

	.S04_AXI_AWID(csum_ram_m_awid),
	.S04_AXI_AWADDR(csum_ram_m_awaddr),
	.S04_AXI_AWLEN(csum_ram_m_awlen),
	.S04_AXI_AWSIZE(csum_ram_m_awsize),
	.S04_AXI_AWBURST(csum_ram_m_awburst),
	.S04_AXI_AWVALID(csum_ram_m_awvalid),
	.S04_AXI_AWREADY(csum_ram_m_awready),

	.S04_AXI_WID(csum_ram_m_wid),
	.S04_AXI_WDATA(csum_ram_m_wdata),
	.S04_AXI_WSTRB(csum_ram_m_wstrb),
	.S04_AXI_WLAST(csum_ram_m_wlast),
	.S04_AXI_WVALID(csum_ram_m_wvalid),
	.S04_AXI_WREADY(csum_ram_m_wready),

	.S04_AXI_BID(csum_ram_m_bid),
	.S04_AXI_BRESP(csum_ram_m_bresp),
	.S04_AXI_BVALID(csum_ram_m_bvalid),
	.S04_AXI_BREADY(csum_ram_m_bready),

	.S04_AXI_ARID(csum_ram_m_arid),
	.S04_AXI_ARADDR(csum_ram_m_araddr),
	.S04_AXI_ARLEN(csum_ram_m_arlen),
	.S04_AXI_ARSIZE(csum_ram_m_arsize),
	.S04_AXI_ARBURST(csum_ram_m_arburst),
	.S04_AXI_ARVALID(csum_ram_m_arvalid),
	.S04_AXI_ARREADY(csum_ram_m_arready),

	.S04_AXI_RID(csum_ram_m_rid),
	.S04_AXI_RDATA(csum_ram_m_rdata),
	.S04_AXI_RRESP(csum_ram_m_rresp),
	.S04_AXI_RLAST(csum_ram_m_rlast),
	.S04_AXI_RVALID(csum_ram_m_rvalid),
	.S04_AXI_RREADY(csum_ram_m_rready),

	.S05_AXI_AWID(vlan_ram_m_awid),
	.S05_AXI_AWADDR(vlan_ram_m_awaddr),
	.S05_AXI_AWLEN(vlan_ram_m_awlen),
	.S05_AXI_AWSIZE(vlan_ram_m_awsize),
	.S05_AXI_AWBURST(vlan_ram_m_awburst),
	.S05_AXI_AWVALID(vlan_ram_m_awvalid),
	.S05_AXI_AWREADY(vlan_ram_m_awready),

	.S05_AXI_WID(vlan_ram_m_wid),
	.S05_AXI_WDATA(vlan_ram_m_wdata),
	.S05_AXI_WSTRB(vlan_ram_m_wstrb),
	.S05_AXI_WLAST(vlan_ram_m_wlast),
	.S05_AXI_WVALID(vlan_ram_m_wvalid),
	.S05_AXI_WREADY(vlan_ram_m_wready),

	.S05_AXI_BID(vlan_ram_m_bid),
	.S05_AXI_BRESP(vlan_ram_m_bresp),
	.S05_AXI_BVALID(vlan_ram_m_bvalid),
	.S05_AXI_BREADY(vlan_ram_m_bready),

	.S05_AXI_ARID(vlan_ram_m_arid),
	.S05_AXI_ARADDR(vlan_ram_m_araddr),
	.S05_AXI_ARLEN(vlan_ram_m_arlen),
	.S05_AXI_ARSIZE(vlan_ram_m_arsize),
	.S05_AXI_ARBURST(vlan_ram_m_arburst),
	.S05_AXI_ARVALID(vlan_ram_m_arvalid),
	.S05_AXI_ARREADY(vlan_ram_m_arready),

	.S05_AXI_RID(vlan_ram_m_rid),
	.S05_AXI_RDATA(vlan_ram_m_rdata),
	.S05_AXI_RRESP(vlan_ram_m_rresp),
	.S05_AXI_RLAST(vlan_ram_m_rlast),
	.S05_AXI_RVALID(vlan_ram_m_rvalid),
	.S05_AXI_RREADY(vlan_ram_m_rready),

	.S06_AXI_AWID(snd_ram_m_awid),
	.S06_AXI_AWADDR(snd_ram_m_awaddr),
	.S06_AXI_AWLEN(snd_ram_m_awlen),
	.S06_AXI_AWSIZE(snd_ram_m_awsize),
	.S06_AXI_AWBURST(snd_ram_m_awburst),
	.S06_AXI_AWVALID(snd_ram_m_awvalid),
	.S06_AXI_AWREADY(snd_ram_m_awready),

	.S06_AXI_WID(snd_ram_m_wid),
	.S06_AXI_WDATA(snd_ram_m_wdata),
	.S06_AXI_WSTRB(snd_ram_m_wstrb),
	.S06_AXI_WLAST(snd_ram_m_wlast),
	.S06_AXI_WVALID(snd_ram_m_wvalid),
	.S06_AXI_WREADY(snd_ram_m_wready),

	.S06_AXI_BID(snd_ram_m_bid),
	.S06_AXI_BRESP(snd_ram_m_bresp),
	.S06_AXI_BVALID(snd_ram_m_bvalid),
	.S06_AXI_BREADY(snd_ram_m_bready),

	.S06_AXI_ARID(snd_ram_m_arid),
	.S06_AXI_ARADDR(snd_ram_m_araddr),
	.S06_AXI_ARLEN(snd_ram_m_arlen),
	.S06_AXI_ARSIZE(snd_ram_m_arsize),
	.S06_AXI_ARBURST(snd_ram_m_arburst),
	.S06_AXI_ARVALID(snd_ram_m_arvalid),
	.S06_AXI_ARREADY(snd_ram_m_arready),

	.S06_AXI_RID(snd_ram_m_rid),
	.S06_AXI_RDATA(snd_ram_m_rdata),
	.S06_AXI_RRESP(snd_ram_m_rresp),
	.S06_AXI_RLAST(snd_ram_m_rlast),
	.S06_AXI_RVALID(snd_ram_m_rvalid),
	.S06_AXI_RREADY(snd_ram_m_rready),

	.M00_AXI_AWID(bram_s_awid),
	.M00_AXI_AWADDR(bram_s_awaddr),
	.M00_AXI_AWLEN(bram_s_awlen),
	.M00_AXI_AWSIZE(bram_s_awsize),
	.M00_AXI_AWBURST(bram_s_awburst),
	.M00_AXI_AWVALID(bram_s_awvalid),
	.M00_AXI_AWREADY(bram_s_awready),

	.M00_AXI_WID(bram_s_wid),
	.M00_AXI_WDATA(bram_s_wdata),
	.M00_AXI_WSTRB(bram_s_wstrb),
	.M00_AXI_WLAST(bram_s_wlast),
	.M00_AXI_WVALID(bram_s_wvalid),
	.M00_AXI_WREADY(bram_s_wready),

	.M00_AXI_BID(bram_s_bid),
	.M00_AXI_BRESP(bram_s_bresp),
	.M00_AXI_BVALID(bram_s_bvalid),
	.M00_AXI_BREADY(bram_s_bready),

	.M00_AXI_ARID(bram_s_arid),
	.M00_AXI_ARADDR(bram_s_araddr),
	.M00_AXI_ARLEN(bram_s_arlen),
	.M00_AXI_ARSIZE(bram_s_arsize),
	.M00_AXI_ARBURST(bram_s_arburst),
	.M00_AXI_ARVALID(bram_s_arvalid),
	.M00_AXI_ARREADY(bram_s_arready),

	.M00_AXI_RID(bram_s_rid),
	.M00_AXI_RDATA(bram_s_rdata),
	.M00_AXI_RRESP(bram_s_rresp),
	.M00_AXI_RLAST(bram_s_rlast),
	.M00_AXI_RVALID(bram_s_rvalid),
	.M00_AXI_RREADY(bram_s_rready)
);

endmodule
