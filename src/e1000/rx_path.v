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
	// RDT will be send by command
	//input [15:0] RDT, // Rx Desc Tail
	input [5:0] PTHRESH, // Prefetch Threshold
	input [5:0] HTHRESH, // Host Threshold 
	input [5:0] WTHRESH, // Write Back Threshold
	input GRAN, // Rx Desc Threshold Granularity
	input [7:0] PCSS, // Packet Checksum Start
	input IPOFLD, // IP Checksum Off-load Enable
	input TUOFLD, // TCP/UDP Checksum Off-load Enable
	input IPV6OFL, // IPv6 Checksum Offload

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
	input [7:0] mac_s_tdata,
	input mac_s_tvalid,
	input mac_s_tlast,
	output mac_s_tready	
);

// Receiver state machine
rx_ctrl rx_ctrl_i(
	.aclk(aclk),
	.aresetn(aresetn),

	// Parameters
	.EN(EN),
	.SBP(SBP),
	.UPE(UPE),
	.MPE(MPE),
	.LPE(LPE),
	.RDMTS(RDMTS),
	.MO(MO),
	.BAM(BAM),
	.BSIZE(BSIZE),
	.VFE(VFE),
	.CFIEN(CFIEN),
	.CFI(CFI),
	.DPF(DPF),
	.PMCF(PMCF),
	.BSEX(BSEX),
	.SECRC(SECRC),
	.RDBA(RDBA),
	.RDLEN(RDLEN),
	.RDH(RDH),
	//.RDT(RDT),
	.PTHRESH(PTHRESH),
	.HTHRESH(HTHRESH),
	.WTHRESH(WTHRESH),
	.GRAN(GRAN),
	.PCSS(PCSS),
	.IPOFLD(IPOFLD),
	.TUOFLD(TUOFLD),
	.IPV6OFL(IPV6OFL),

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
	.ram_m_awid(rctl_ram_m_awid),
	.ram_m_awaddr(rctl_ram_m_awaddr),
	.ram_m_awlen(rctl_ram_m_awlen),
	.ram_m_awsize(rctl_ram_m_awsize),
	.ram_m_awburst(rctl_ram_m_awburst),
	.ram_m_awvalid(rctl_ram_m_awvalid),
	.ram_m_awready(rctl_ram_m_awready),

	.ram_m_wid(rctl_ram_m_wid),
	.ram_m_wdata(rctl_ram_m_wdata),
	.ram_m_wstrb(rctl_ram_m_wstrb),
	.ram_m_wlast(rctl_ram_m_wlast),
	.ram_m_wvalid(rctl_ram_m_wvalid),
	.ram_m_wready(rctl_ram_m_wready),

	.ram_m_bid(rctl_ram_m_bid),
	.ram_m_bresp(rctl_ram_m_bresp),
	.ram_m_bvalid(rctl_ram_m_bvalid),
	.ram_m_bready(rctl_ram_m_bready),

	.ram_m_arid(rctl_ram_m_arid),
	.ram_m_araddr(rctl_ram_m_araddr),
	.ram_m_arlen(rctl_ram_m_arlen),
	.ram_m_arsize(rctl_ram_m_arsize),
	.ram_m_arburst(rctl_ram_m_arburst),
	.ram_m_arvalid(rctl_ram_m_arvalid),
	.ram_m_arready(rctl_ram_m_arready),

	.ram_m_rid(rctl_ram_m_rid),
	.ram_m_rdata(rctl_ram_m_rdata),
	.ram_m_rresp(rctl_ram_m_rresp),
	.ram_m_rlast(rctl_ram_m_rlast),
	.ram_m_rvalid(rctl_ram_m_rvalid),
	.ram_m_rready(rctl_ram_m_rready),

	// idma Command Port
	.idma_m_tdata(idma_s_tdata),
	.idma_m_tvalid(idma_s_tvalid),
	.idma_m_tlast(idma_s_tlast),
	.idma_m_tready(idma_s_tready),

	.idma_s_tdata(idma_m_tdata),
	.idma_s_tvalid(idma_m_tvalid),
	.idma_s_tlast(idma_m_tlast),
	.idma_s_tready(idma_m_tready),

	// rx filter
	.rflt_m_tdata(rflt_s_tdata),
	.rflt_m_tvalid(rflt_s_tvalid),
	.rflt_m_tlast(rflt_s_tlast),
	.rflt_m_tready(rflt_s_tready),

	.rflt_s_tdata(rflt_m_tdata),
	.rflt_s_tvalid(rflt_m_tvalid),
	.rflt_s_tlast(rflt_m_tlast),
	.rflt_s_tready(rflt_m_tready),

	// rx checksum 
	.csum_m_tdata(csum_s_tdata),
	.csum_m_tvalid(csum_s_tvalid),
	.csum_m_tlast(csum_s_tlast),
	.csum_m_tready(csum_s_tready),

	.csum_s_tdata(csum_m_tdata),
	.csum_s_tvalid(csum_m_tvalid),
	.csum_s_tlast(csum_m_tlast),
	.csum_s_tready(csum_m_tready),

	// rx vlan strip
	.vlan_m_tdata(vlan_s_tdata),
	.vlan_m_tvalid(vlan_s_tvalid),
	.vlan_m_tlast(vlan_s_tlast),
	.vlan_m_tready(vlan_s_tready),

	.vlan_s_tdata(vlan_m_tdata),
	.vlan_s_tvalid(vlan_m_tvalid),
	.vlan_s_tlast(vlan_m_tlast),
	.vlan_s_tready(vlan_m_tready),

	// rx stream to ram 
	.rcv_m_tdata(rcv_s_tdata),
	.rcv_m_tvalid(rcv_s_tvalid),
	.rcv_m_tlast(rcv_s_tlast),
	.rcv_m_tready(rcv_s_tready),

	.rcv_s_tdata(rcv_m_tdata),
	.rcv_s_tvalid(rcv_m_tvalid),
	.rcv_s_tlast(rcv_m_tlast),
	.rcv_s_tready(rcv_m_tready)
);

// DMA controller between external bus and local ram 
axi_idma rx_idma_i(
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

// Rx packet filter
rx_filter rx_filter_i(
	.aclk(aclk),
	.aresetn(aresetn),

	// Command Port
	.s_tdata(rflt_s_tdata),
	.s_tvalid(rflt_s_tvalid),
	.s_tlast(rflt_s_tlast),
	.s_tready(rflt_s_tready),

	// Status Port
	.m_tdata(rflt_m_tdata),
	.m_tvalid(rflt_m_tvalid),
	.m_tlast(rflt_m_tlast),
	.m_tready(rflt_m_tready),

	.rtbl_index(rtbl_index),
	.rtbl_data(rtbl_data),
	.mtbl_index(mtbl_index),
	.mtbl_data(mtbl_data),
	.vtbl_index(vtbl_index),
	.vtbl_data(vtbl_data),

	// Internal RAM Access Port
	.ram_m_awid(rflt_ram_m_awid),
	.ram_m_awaddr(rflt_ram_m_awaddr),
	.ram_m_awlen(rflt_ram_m_awlen),
	.ram_m_awsize(rflt_ram_m_awsize),
	.ram_m_awburst(rflt_ram_m_awburst),
	.ram_m_awvalid(rflt_ram_m_awvalid),
	.ram_m_awready(rflt_ram_m_awready),

	.ram_m_wid(rflt_ram_m_wid),
	.ram_m_wdata(rflt_ram_m_wdata),
	.ram_m_wstrb(rflt_ram_m_wstrb),
	.ram_m_wlast(rflt_ram_m_wlast),
	.ram_m_wvalid(rflt_ram_m_wvalid),
	.ram_m_wready(rflt_ram_m_wready),

	.ram_m_bid(rflt_ram_m_bid),
	.ram_m_bresp(rflt_ram_m_bresp),
	.ram_m_bvalid(rflt_ram_m_bvalid),
	.ram_m_bready(rflt_ram_m_bready),

	.ram_m_arid(rflt_ram_m_arid),
	.ram_m_araddr(rflt_ram_m_araddr),
	.ram_m_arlen(rflt_ram_m_arlen),
	.ram_m_arsize(rflt_ram_m_arsize),
	.ram_m_arburst(rflt_ram_m_arburst),
	.ram_m_arvalid(rflt_ram_m_arvalid),
	.ram_m_arready(rflt_ram_m_arready),

	.ram_m_rid(rflt_ram_m_rid),
	.ram_m_rdata(rflt_ram_m_rdata),
	.ram_m_rresp(rflt_ram_m_rresp),
	.ram_m_rlast(rflt_ram_m_rlast),
	.ram_m_rvalid(rflt_ram_m_rvalid),
	.ram_m_rready(rflt_ram_m_rready)

);

// Rx packet checksum validate
rx_checksum rx_checksum_i(
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

// Rx VLAN tag strip
rx_vlan rx_vlan_i(
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

// Rx packet receive
rx_receive rx_receive_i(
	.aclk(aclk),
	.aresetn(aresetn),

	// Rx Command Port
	// RAM allocations passed in
	.s_tdata(rcv_s_tdata),
	.s_tvalid(rcv_s_tvalid),
	.s_tlast(rcv_s_tlast),
	.s_tready(rcv_s_tready),

	// Rx Status Port
	// Packet location and length passed out
	.m_tdata(rcv_m_tdata),
	.m_tvalid(rcv_m_tvalid),
	.m_tlast(rcv_m_tlast),
	.m_tready(rcv_m_tready),

	// Internal RAM Access Port
	// Packet storage
	.ram_m_awid(rcv_m_awid),
	.ram_m_awaddr(rcv_m_awaddr),
	.ram_m_awlen(rcv_m_awlen),
	.ram_m_awsize(rcv_m_awsize),
	.ram_m_awburst(rcv_m_awburst),
	.ram_m_awvalid(rcv_m_awvalid),
	.ram_m_awready(rcv_m_awready),

	.ram_m_wid(rcv_m_wid),
	.ram_m_wdata(rcv_m_wdata),
	.ram_m_wstrb(rcv_m_wstrb),
	.ram_m_wlast(rcv_m_wlast),
	.ram_m_wvalid(rcv_m_wvalid),
	.ram_m_wready(rcv_m_wready),

	.ram_m_bid(rcv_m_bid),
	.ram_m_bresp(rcv_m_bresp),
	.ram_m_bvalid(rcv_m_bvalid),
	.ram_m_bready(rcv_m_bready),

	.ram_m_arid(rcv_m_arid),
	.ram_m_araddr(rcv_m_araddr),
	.ram_m_arlen(rcv_m_arlen),
	.ram_m_arsize(rcv_m_arsize),
	.ram_m_arburst(rcv_m_arburst),
	.ram_m_arvalid(rcv_m_arvalid),
	.ram_m_arready(rcv_m_arready),

	.ram_m_rid(rcv_m_rid),
	.ram_m_rdata(rcv_m_rdata),
	.ram_m_rresp(rcv_m_rresp),
	.ram_m_rlast(rcv_m_rlast),
	.ram_m_rvalid(rcv_m_rvalid),
	.ram_m_rready(rcv_m_rready),

	// MAC RX Stream Port
	.mac_s_tdata(mac_s_tdata),
	.mac_s_tvalid(mac_s_tvalid),
	.mac_s_tlast(mac_s_tlast),
	.mac_s_tready(mac_s_tready)
);

// Rx descriptor storage
// This is a block ram about 4kB size
rx_rdram rx_rdram_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.s_awid(rdram_s_awid),
	.s_awaddr(rdram_s_awaddr),
	.s_awlen(rdram_s_awlen),
	.s_awsize(rdram_s_awsize),
	.s_awburst(rdram_s_awburst),
	.s_awvalid(rdram_s_awvalid),
	.s_awready(rdram_s_awready),

	.s_wid(rdram_s_wid),
	.s_wdata(rdram_s_wdata),
	.s_wstrb(rdram_s_wstrb),
	.s_wlast(rdram_s_wlast),
	.s_wvalid(rdram_s_wvalid),
	.s_wready(rdram_s_wready),

	.s_bid(rdram_s_bid),
	.s_bresp(rdram_s_bresp),
	.s_bvalid(rdram_s_bvalid),
	.s_bready(rdram_s_bready),

	.s_arid(rdram_s_arid),
	.s_araddr(rdram_s_araddr),
	.s_arlen(rdram_s_arlen),
	.s_arsize(rdram_s_arsize),
	.s_arburst(rdram_s_arburst),
	.s_arvalid(rdram_s_arvalid),
	.s_arready(rdram_s_arready),

	.s_rid(rdram_s_rid),
	.s_rdata(rdram_s_rdata),
	.s_rresp(rdram_s_rresp),
	.s_rlast(rdram_s_rlast),
	.s_rvalid(rdram_s_rvalid),
	.s_rready(rdram_s_rready)
);

// Rx data storage
// This is a block ram about 64kB size
rx_dbram rx_dbram_i(
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

// Internal axi crossbar
rx_crossbar rx_crossbar_i(
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

	.s1_axi_awid(rctl_ram_m_awid),
	.s1_axi_awaddr(rctl_ram_m_awaddr),
	.s1_axi_awlen(rctl_ram_m_awlen),
	.s1_axi_awsize(rctl_ram_m_awsize),
	.s1_axi_awburst(rctl_ram_m_awburst),
	.s1_axi_awvalid(rctl_ram_m_awvalid),
	.s1_axi_awready(rctl_ram_m_awready),

	.s1_axi_wid(rctl_ram_m_wid),
	.s1_axi_wdata(rctl_ram_m_wdata),
	.s1_axi_wstrb(rctl_ram_m_wstrb),
	.s1_axi_wlast(rctl_ram_m_wlast),
	.s1_axi_wvalid(rctl_ram_m_wvalid),
	.s1_axi_wready(rctl_ram_m_wready),

	.s1_axi_bid(rctl_ram_m_bid),
	.s1_axi_bresp(rctl_ram_m_bresp),
	.s1_axi_bvalid(rctl_ram_m_bvalid),
	.s1_axi_bready(rctl_ram_m_bready),

	.s1_axi_arid(rctl_ram_m_arid),
	.s1_axi_araddr(rctl_ram_m_araddr),
	.s1_axi_arlen(rctl_ram_m_arlen),
	.s1_axi_arsize(rctl_ram_m_arsize),
	.s1_axi_arburst(rctl_ram_m_arburst),
	.s1_axi_arvalid(rctl_ram_m_arvalid),
	.s1_axi_arready(rctl_ram_m_arready),

	.s1_axi_rid(rctl_ram_m_rid),
	.s1_axi_rdata(rctl_ram_m_rdata),
	.s1_axi_rresp(rctl_ram_m_rresp),
	.s1_axi_rlast(rctl_ram_m_rlast),
	.s1_axi_rvalid(rctl_ram_m_rvalid),
	.s1_axi_rready(rctl_ram_m_rready),

	.s2_axi_awid(rflt_ram_m_awid),
	.s2_axi_awaddr(rflt_ram_m_awaddr),
	.s2_axi_awlen(rflt_ram_m_awlen),
	.s2_axi_awsize(rflt_ram_m_awsize),
	.s2_axi_awburst(rflt_ram_m_awburst),
	.s2_axi_awvalid(rflt_ram_m_awvalid),
	.s2_axi_awready(rflt_ram_m_awready),

	.s2_axi_wid(rflt_ram_m_wid),
	.s2_axi_wdata(rflt_ram_m_wdata),
	.s2_axi_wstrb(rflt_ram_m_wstrb),
	.s2_axi_wlast(rflt_ram_m_wlast),
	.s2_axi_wvalid(rflt_ram_m_wvalid),
	.s2_axi_wready(rflt_ram_m_wready),

	.s2_axi_bid(rflt_ram_m_bid),
	.s2_axi_bresp(rflt_ram_m_bresp),
	.s2_axi_bvalid(rflt_ram_m_bvalid),
	.s2_axi_bready(rflt_ram_m_bready),

	.s2_axi_arid(rflt_ram_m_arid),
	.s2_axi_araddr(rflt_ram_m_araddr),
	.s2_axi_arlen(rflt_ram_m_arlen),
	.s2_axi_arsize(rflt_ram_m_arsize),
	.s2_axi_arburst(rflt_ram_m_arburst),
	.s2_axi_arvalid(rflt_ram_m_arvalid),
	.s2_axi_arready(rflt_ram_m_arready),

	.s2_axi_rid(rflt_ram_m_rid),
	.s2_axi_rdata(rflt_ram_m_rdata),
	.s2_axi_rresp(rflt_ram_m_rresp),
	.s2_axi_rlast(rflt_ram_m_rlast),
	.s2_axi_rvalid(rflt_ram_m_rvalid),
	.s2_axi_rready(rflt_ram_m_rready),

	.s3_axi_awid(csum_ram_m_awid),
	.s3_axi_awaddr(csum_ram_m_awaddr),
	.s3_axi_awlen(csum_ram_m_awlen),
	.s3_axi_awsize(csum_ram_m_awsize),
	.s3_axi_awburst(csum_ram_m_awburst),
	.s3_axi_awvalid(csum_ram_m_awvalid),
	.s3_axi_awready(csum_ram_m_awready),

	.s3_axi_wid(csum_ram_m_wid),
	.s3_axi_wdata(csum_ram_m_wdata),
	.s3_axi_wstrb(csum_ram_m_wstrb),
	.s3_axi_wlast(csum_ram_m_wlast),
	.s3_axi_wvalid(csum_ram_m_wvalid),
	.s3_axi_wready(csum_ram_m_wready),

	.s3_axi_bid(csum_ram_m_bid),
	.s3_axi_bresp(csum_ram_m_bresp),
	.s3_axi_bvalid(csum_ram_m_bvalid),
	.s3_axi_bready(csum_ram_m_bready),

	.s3_axi_arid(csum_ram_m_arid),
	.s3_axi_araddr(csum_ram_m_araddr),
	.s3_axi_arlen(csum_ram_m_arlen),
	.s3_axi_arsize(csum_ram_m_arsize),
	.s3_axi_arburst(csum_ram_m_arburst),
	.s3_axi_arvalid(csum_ram_m_arvalid),
	.s3_axi_arready(csum_ram_m_arready),

	.s3_axi_rid(csum_ram_m_rid),
	.s3_axi_rdata(csum_ram_m_rdata),
	.s3_axi_rresp(csum_ram_m_rresp),
	.s3_axi_rlast(csum_ram_m_rlast),
	.s3_axi_rvalid(csum_ram_m_rvalid),
	.s3_axi_rready(csum_ram_m_rready),

	.s4_axi_awid(vlan_ram_m_awid),
	.s4_axi_awaddr(vlan_ram_m_awaddr),
	.s4_axi_awlen(vlan_ram_m_awlen),
	.s4_axi_awsize(vlan_ram_m_awsize),
	.s4_axi_awburst(vlan_ram_m_awburst),
	.s4_axi_awvalid(vlan_ram_m_awvalid),
	.s4_axi_awready(vlan_ram_m_awready),

	.s4_axi_wid(vlan_ram_m_wid),
	.s4_axi_wdata(vlan_ram_m_wdata),
	.s4_axi_wstrb(vlan_ram_m_wstrb),
	.s4_axi_wlast(vlan_ram_m_wlast),
	.s4_axi_wvalid(vlan_ram_m_wvalid),
	.s4_axi_wready(vlan_ram_m_wready),

	.s4_axi_bid(vlan_ram_m_bid),
	.s4_axi_bresp(vlan_ram_m_bresp),
	.s4_axi_bvalid(vlan_ram_m_bvalid),
	.s4_axi_bready(vlan_ram_m_bready),

	.s4_axi_arid(vlan_ram_m_arid),
	.s4_axi_araddr(vlan_ram_m_araddr),
	.s4_axi_arlen(vlan_ram_m_arlen),
	.s4_axi_arsize(vlan_ram_m_arsize),
	.s4_axi_arburst(vlan_ram_m_arburst),
	.s4_axi_arvalid(vlan_ram_m_arvalid),
	.s4_axi_arready(vlan_ram_m_arready),

	.s4_axi_rid(vlan_ram_m_rid),
	.s4_axi_rdata(vlan_ram_m_rdata),
	.s4_axi_rresp(vlan_ram_m_rresp),
	.s4_axi_rlast(vlan_ram_m_rlast),
	.s4_axi_rvalid(vlan_ram_m_rvalid),
	.s4_axi_rready(vlan_ram_m_rready),

	.s5_axi_awid(rcv_ram_m_awid),
	.s5_axi_awaddr(rcv_ram_m_awaddr),
	.s5_axi_awlen(rcv_ram_m_awlen),
	.s5_axi_awsize(rcv_ram_m_awsize),
	.s5_axi_awburst(rcv_ram_m_awburst),
	.s5_axi_awvalid(rcv_ram_m_awvalid),
	.s5_axi_awready(rcv_ram_m_awready),

	.s5_axi_wid(rcv_ram_m_wid),
	.s5_axi_wdata(rcv_ram_m_wdata),
	.s5_axi_wstrb(rcv_ram_m_wstrb),
	.s5_axi_wlast(rcv_ram_m_wlast),
	.s5_axi_wvalid(rcv_ram_m_wvalid),
	.s5_axi_wready(rcv_ram_m_wready),

	.s5_axi_bid(rcv_ram_m_bid),
	.s5_axi_bresp(rcv_ram_m_bresp),
	.s5_axi_bvalid(rcv_ram_m_bvalid),
	.s5_axi_bready(rcv_ram_m_bready),

	.s5_axi_arid(rcv_ram_m_arid),
	.s5_axi_araddr(rcv_ram_m_araddr),
	.s5_axi_arlen(rcv_ram_m_arlen),
	.s5_axi_arsize(rcv_ram_m_arsize),
	.s5_axi_arburst(rcv_ram_m_arburst),
	.s5_axi_arvalid(rcv_ram_m_arvalid),
	.s5_axi_arready(rcv_ram_m_arready),

	.s5_axi_rid(rcv_ram_m_rid),
	.s5_axi_rdata(rcv_ram_m_rdata),
	.s5_axi_rresp(rcv_ram_m_rresp),
	.s5_axi_rlast(rcv_ram_m_rlast),
	.s5_axi_rvalid(rcv_ram_m_rvalid),
	.s5_axi_rready(rcv_ram_m_rready),

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
	.m1_axi_rready(dbram_s_rready)

);


endmodule
