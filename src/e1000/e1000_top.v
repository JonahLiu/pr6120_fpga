module e1000_top(
	input aclk,
	input aresetn,

	// Register Space Access Port
	input [31:0] axi_s_awaddr,
	input axi_s_awvalid,
	output	axi_s_awready,

	input [31:0] axi_s_wdata,
	input [3:0] axi_s_wstrb,
	input axi_s_wvalid,
	output	axi_s_wready,

	output	[1:0] axi_s_bresp,
	output	axi_s_bvalid,
	input axi_s_bready,

	input [31:0] axi_s_araddr,
	input axi_s_arvalid,
	output	axi_s_arready,

	output	[31:0] axi_s_rdata,
	output	[1:0] axi_s_rresp,
	output	axi_s_rvalid,
	input axi_s_rready,

	// Interrupt request
	output intr_request,

	// DMA Port
	output [3:0] axi_m_awid,
	output [63:0] axi_m_awaddr,

	output [7:0] axi_m_awlen,
	output [2:0] axi_m_awsize,
	output [1:0] axi_m_awburst,
	output [3:0] axi_m_awcache,
	output axi_m_awvalid,
	input axi_m_awready,

	output [3:0] axi_m_wid,
	output [31:0] axi_m_wdata,
	output [3:0] axi_m_wstrb,
	output axi_m_wlast,
	output axi_m_wvalid,
	input axi_m_wready,

	input [3:0] axi_m_bid,
	input [1:0] axi_m_bresp,
	input axi_m_bvalid,
	output axi_m_bready,

	output [3:0] axi_m_arid,
	output [63:0] axi_m_araddr,
	output [7:0] axi_m_arlen,
	output [2:0] axi_m_arsize,
	output [1:0] axi_m_arburst,
	output [3:0] axi_m_arcache,
	output axi_m_arvalid,
	input axi_m_arready,

	input [3:0] axi_m_rid,
	input [31:0] axi_m_rdata,
	input [1:0] axi_m_rresp,
	input axi_m_rlast,
	input axi_m_rvalid,
	output axi_m_rready,

	// GMII Port
	input	[7:0]	mac_rxdat,
	input	mac_rxdv,
	input	mac_rxer,
	input	mac_rxsclk,
	output	[7:0]	mac_txdat,
	output	mac_txen,
	output	mac_txer,
	input	mac_txsclk,
	output	mac_gtxsclk,
	input	mac_crs,
	input	mac_col,

	// MDIO Port
	output	phy_mdc,
	input	phy_mdio_i,
	output	phy_mdio_o,
	output	phy_mdio_oe,

	// PHY Misc
	input	phy_int,
	output	phy_reset_out,

	// EEPROM Port
	output	eesk,
	output	eecs,
	input	eedo,
	output	eedi
);

parameter PHY_ADDR=5'b0;
parameter CLK_PERIOD_NS=8;

wire [7:0] mac_tx_s_tdata;
wire mac_tx_s_tvalid;
wire mac_tx_s_tlast;
wire mac_tx_s_tready;

wire [7:0] mac_rx_m_tdata;
wire mac_rx_m_tvalid;
wire mac_rx_m_tlast;
wire mac_rx_m_tready;

wire [31:0] CTRL;

wire [31:0] EECD;
wire [31:0] EERD;
wire EERD_START;

wire ee_busy;
wire [31:0] ee_rdatao;

wire [31:0] MDIC;
wire MDIC_start;
wire [15:0] mm_rdatao;
wire mm_rd_doneo;
wire mm_wr_doneo;

wire [31:0] ICR;
wire [31:0] ICR_fb;
wire ICR_set;
wire ICR_get;

wire [31:0] ITR;
wire ITR_set;

wire [31:0] ICS;
wire ICS_set;

wire [31:0] IMS;
wire IMS_set;

wire [31:0] IMC;
wire IMC_set;

wire TCTL_EN;
wire TCTL_PSP;
wire [63:0] TDBA;
wire [12:0] TDLEN;
wire [15:0] TDH;
wire TDH_set;
wire [15:0] TDH_fb;
wire [15:0] TDT;
wire TDT_set;
wire [15:0] TIDV;
wire DPP;
wire [5:0] TXDCTL_PTHRESH;
wire [5:0] TXDCTL_HTHRESH;
wire [5:0] TXDCTL_WTHRESH;
wire TXDCTL_GRAN;
wire [5:0] TXDCTL_LWTHRESH;
wire [15:0] TADV;
wire [15:0] TSMT;
wire [15:0] TSPBP;
wire TXDW_req;
wire TXQE_req;
wire TXD_LOW_req;

wire PHYINT_req;

reg [1:0] phy_int_sync;

assign phy_reset_out = CTRL[31] || !aresetn;
assign PHYINT_req = phy_int_sync[1];

always @(posedge aclk)
begin
	phy_int_sync <= {phy_int_sync, phy_int};
end

e1000_regs cmd_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.axi_s_awvalid(axi_s_awvalid),
	.axi_s_awready(axi_s_awready),
	.axi_s_awaddr(axi_s_awaddr),

	.axi_s_wvalid(axi_s_wvalid),
	.axi_s_wready(axi_s_wready),
	.axi_s_wdata(axi_s_wdata),
	.axi_s_wstrb(axi_s_wstrb),

	.axi_s_bvalid(axi_s_bvalid),
	.axi_s_bready(axi_s_bready),
	.axi_s_bresp(axi_s_bresp),

	.axi_s_arvalid(axi_s_arvalid),
	.axi_s_arready(axi_s_arready),
	.axi_s_araddr(axi_s_araddr),

	.axi_s_rvalid(axi_s_rvalid),
	.axi_s_rready(axi_s_rready),
	.axi_s_rdata(axi_s_rdata),
	.axi_s_rresp(axi_s_rresp),

	.CTRL(CTRL),

	.EECD(EECD),
	.EECD_DO_i(eedo),
	.EECD_GNT_i(!ee_busy),

	.EERD(EERD),
	.EERD_START(EERD_START),
	.EERD_DONE_i(ee_rdatao[4]),
	.EERD_DATA_i(ee_rdatao[31:16]),

	.MDIC(MDIC),
	.MDIC_start(MDIC_start),
	.MDIC_R_i(mm_rd_doneo&&mm_wr_doneo),
	.MDIC_DATA_i(mm_rdatao),

	.ICR(ICR),
	.ICR_fb_i(ICR_fb),
	.ICR_set(ICR_set),
	.ICR_get(ICR_get),

	.ITR(ITR),
	.ITR_set(ITR_set),
	
	.ICS(ICS),
	.ICS_set(ICS_set),

	.IMS(IMS),
	.IMS_set(IMS_set),
	
	.IMC(IMC),
	.IMC_set(IMC_set),

	.TCTL_EN(TCTL_EN),
	.TCTL_PSP(TCTL_PSP),

	.TDBA(TDBA),
	.TDLEN(TDLEN),

	.TDH(TDH),
	.TDH_set(TDH_set),
	.TDH_fb(TDH_fb),

	.TDT(TDT),
	.TDT_set(TDT_set),

	.TIDV(TIDV),
	.DPP(DPP),
	.TXDCTL_PTHRESH(TXDCTL_PTHRESH),
	.TXDCTL_HTHRESH(TXDCTL_HTHRESH),
	.TXDCTL_WTHRESH(TXDCTL_WTHRESH),
	.TXDCTL_GRAN(TXDCTL_GRAN),
	.TXDCTL_LWTHRESH(TXDCTL_LWTHRESH),
	.TADV(TADV),
	.TSMT(TSMT),
	.TSPBP(TSPBP)
);

shift_eeprom shift_eeprom_i(
	.clk(aclk),
	.rst(!aresetn),
	.sk(eesk),
	.cs(eecs),
	.di(eedi),
	.do(eedo),
	.wdatai(EERD),
	.eni(EERD_START),
	.eerd_busy(ee_busy),
	.sk_eecd(EECD[0]),
	.cs_eecd(EECD[1]),
	.di_eecd(EECD[2]),
	.eecd_busy(EECD[6]),
	.rdatao(ee_rdatao)
);

shift_mdio shift_mdio_i(
	.clk(aclk),
	.rst(!aresetn),
	.mdc_o(phy_mdc),
	.mdio_i(phy_mdio_i),
	.mdio_o(phy_mdio_o),
	.mdio_oe(phy_mdio_oe),
	.rdatao(mm_rdatao),
	.rd_doneo(mm_rd_doneo),
	.eni(MDIC_start),
	.wdatai({2'b01,MDIC[27:26],PHY_ADDR[4:0],MDIC[20:16],2'b10,MDIC[15:0]}),
	.wr_doneo(mm_wr_doneo)
);

intr_ctrl #(.CLK_PERIOD_NS(CLK_PERIOD_NS)) intr_ctrl_i(
	.clk_i(aclk),
	.rst_i(!aresetn),

	.ICR(ICR),
	.ICR_fb_o(ICR_fb),
	.ICR_set(ICR_set),
	.ICR_get(ICR_get),

	.ITR(ITR),
	.ITR_set(ITR_set),

	.ICS(ICS),
	.ICS_set(ICS_set),
	
	.IMS(IMS),
	.IMS_set(IMS_set),

	.IMC(IMC),
	.IMC_set(IMC_set),

	.intr_request(intr_request),

	.TXDW_req(TXDW_req),
	.TXQE_req(TXQE_req),
	.LSC_req(1'b0),
	.RXSEQ_req(1'b0),
	.RXDMT0_req(1'b0),
	.RXO_req(1'b0),
	.RXT0_req(1'b0),
	.MDAC_req(1'b0),
	.RXCFG_req(1'b0),
	.PHYINT_req(PHYINT_req),
	.TXD_LOW_req(TXD_LOW_req),
	.SRPD_req(1'b0)
);


/*
rx_path rx_path_i(
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
	.PTHRESH(PTHRESH),
	.HTHRESH(HTHRESH),
	.WTHRESH(WTHRESH),
	.GRAN(GRAN),
	.PCSS(PCSS),
	.IPOFLD(IPOFLD),
	.TUOFLD(TUOFLD),
	.IPV6OFL(IPV6OFL),

	// Command Port
	.cmd_s_tdata(rx_cmd_s_tdata),
	.cmd_s_tvalid(rx_cmd_s_tvalid),
	.cmd_s_tlast(rx_cmd_s_tlast),
	.cmd_s_tready(rx_cmd_s_tready),

	// Status Port
	.stat_m_tdata(rx_stat_m_tdata),
	.stat_m_tvalid(rx_stat_m_tvalid),
	.stat_m_tlast(rx_stat_m_tlast),
	.stat_m_tready(rx_stat_m_tready),

	.rtbl_index(rtbl_index),
	.rtbl_data(rtbl_data),
	.mtbl_index(mtbl_index),
	.mtbl_data(mtbl_data),
	.vtbl_index(vtbl_index),
	.vtbl_data(vtbl_data),

	// External Bus Access Port
	.axi_m_awid(rx_m_awid),
	.axi_m_awaddr(rx_m_awaddr),
	.axi_m_awlen(rx_m_awlen),
	.axi_m_awsize(rx_m_awsize),
	.axi_m_awburst(rx_m_awburst),
	.axi_m_awvalid(rx_m_awvalid),
	.axi_m_awready(rx_m_awready),

	.axi_m_wid(rx_m_wid),
	.axi_m_wdata(rx_m_wdata),
	.axi_m_wstrb(rx_m_wstrb),
	.axi_m_wlast(rx_m_wlast),
	.axi_m_wvalid(rx_m_wvalid),
	.axi_m_wready(rx_m_wready),

	.axi_m_bid(rx_m_bid),
	.axi_m_bresp(rx_m_bresp),
	.axi_m_bvalid(rx_m_bvalid),
	.axi_m_bready(rx_m_bready),

	.axi_m_arid(rx_m_arid),
	.axi_m_araddr(rx_m_araddr),
	.axi_m_arlen(rx_m_arlen),
	.axi_m_arsize(rx_m_arsize),
	.axi_m_arburst(rx_m_arburst),
	.axi_m_arvalid(rx_m_arvalid),
	.axi_m_arready(rx_m_arready),

	.axi_m_rid(rx_m_rid),
	.axi_m_rdata(rx_m_rdata),
	.axi_m_rresp(rx_m_rresp),
	.axi_m_rlast(rx_m_rlast),
	.axi_m_rvalid(rx_m_rvalid),
	.axi_m_rready(rx_m_rready),

	// MAC RX Stream Port
	.mac_s_tdata(mac_rx_m_tdata),
	.mac_s_tvalid(mac_rx_m_tvalid),
	.mac_s_tlast(mac_rx_m_tlast),
	.mac_s_tready(mac_rx_m_tready)
);
*/

tx_path #(.CLK_PERIOD_NS(CLK_PERIOD_NS)) tx_path_i(
	.aclk(aclk),
	.aresetn(aresetn),

	// Parameters
	.EN(TCTL_EN),
	.PSP(TCTL_PSP),
	.TDBA(TDBA),
	.TDLEN(TDLEN),
	.TDH(TDH),
	.TDH_set(TDH_set),
	.TDH_fb(TDH_fb),
	.TDT(TDT),
	.TDT_set(TDT_set),
	.TIDV(TIDV),
	.DPP(DPP),
	.PTHRESH(TXDCTL_PTHRESH),
	.HTHRESH(TXDCTL_HTHRESH),
	.WTHRESH(TXDCTL_WTHRESH),
	.GRAN(TXDCTL_GRAN),
	.LWTHRESH(TXDCTL_LWTHRESH),
	.TADV(TADV),
	.TSMT(TSMT),
	.TSPBP(TSPBP),
	.TXDW_req(TXDW_req),
	.TXQE_req(TXQE_req),
	.TXD_LOW_req(TXD_LOW_req),

	// External Bus Access Port
	.axi_m_awid(axi_m_awid),
	.axi_m_awaddr(axi_m_awaddr),
	.axi_m_awlen(axi_m_awlen),
	.axi_m_awsize(axi_m_awsize),
	.axi_m_awburst(axi_m_awburst),
	.axi_m_awvalid(axi_m_awvalid),
	.axi_m_awready(axi_m_awready),

	.axi_m_wid(axi_m_wid),
	.axi_m_wdata(axi_m_wdata),
	.axi_m_wstrb(axi_m_wstrb),
	.axi_m_wlast(axi_m_wlast),
	.axi_m_wvalid(axi_m_wvalid),
	.axi_m_wready(axi_m_wready),

	.axi_m_bid(axi_m_bid),
	.axi_m_bresp(axi_m_bresp),
	.axi_m_bvalid(axi_m_bvalid),
	.axi_m_bready(axi_m_bready),

	.axi_m_arid(axi_m_arid),
	.axi_m_araddr(axi_m_araddr),
	.axi_m_arlen(axi_m_arlen),
	.axi_m_arsize(axi_m_arsize),
	.axi_m_arburst(axi_m_arburst),
	.axi_m_arvalid(axi_m_arvalid),
	.axi_m_arready(axi_m_arready),

	.axi_m_rid(axi_m_rid),
	.axi_m_rdata(axi_m_rdata),
	.axi_m_rresp(axi_m_rresp),
	.axi_m_rlast(axi_m_rlast),
	.axi_m_rvalid(axi_m_rvalid),
	.axi_m_rready(axi_m_rready),

	// MAC RX Stream Port
	.mac_m_tdata(mac_tx_s_tdata),
	.mac_m_tvalid(mac_tx_s_tvalid),
	.mac_m_tlast(mac_tx_s_tlast),
	.mac_m_tready(mac_tx_s_tready)
);
/*

ext_crossbar ext_crossbar(
	.aclk(aclk),
	.aresetn(aresetn),

	.s0_axi_awid(rx_m_awid),
	.s0_axi_awaddr(rx_m_awaddr),
	.s0_axi_awlen(rx_m_awlen),
	.s0_axi_awsize(rx_m_awsize),
	.s0_axi_awburst(rx_m_awburst),
	.s0_axi_awvalid(rx_m_awvalid),
	.s0_axi_awready(rx_m_awready),

	.s0_axi_wid(rx_m_wid),
	.s0_axi_wdata(rx_m_wdata),
	.s0_axi_wstrb(rx_m_wstrb),
	.s0_axi_wlast(rx_m_wlast),
	.s0_axi_wvalid(rx_m_wvalid),
	.s0_axi_wready(rx_m_wready),

	.s0_axi_bid(rx_m_bid),
	.s0_axi_bresp(rx_m_bresp),
	.s0_axi_bvalid(rx_m_bvalid),
	.s0_axi_bready(rx_m_bready),

	.s0_axi_arid(rx_m_arid),
	.s0_axi_araddr(rx_m_araddr),
	.s0_axi_arlen(rx_m_arlen),
	.s0_axi_arsize(rx_m_arsize),
	.s0_axi_arburst(rx_m_arburst),
	.s0_axi_arvalid(rx_m_arvalid),
	.s0_axi_arready(rx_m_arready),

	.s0_axi_rid(rx_m_rid),
	.s0_axi_rdata(rx_m_rdata),
	.s0_axi_rresp(rx_m_rresp),
	.s0_axi_rlast(rx_m_rlast),
	.s0_axi_rvalid(rx_m_rvalid),
	.s0_axi_rready(rx_m_rready),

	.s1_axi_awid(tx_m_awid),
	.s1_axi_awaddr(tx_m_awaddr),
	.s1_axi_awlen(tx_m_awlen),
	.s1_axi_awsize(tx_m_awsize),
	.s1_axi_awburst(tx_m_awburst),
	.s1_axi_awvalid(tx_m_awvalid),
	.s1_axi_awready(tx_m_awready),

	.s1_axi_wid(tx_m_wid),
	.s1_axi_wdata(tx_m_wdata),
	.s1_axi_wstrb(tx_m_wstrb),
	.s1_axi_wlast(tx_m_wlast),
	.s1_axi_wvalid(tx_m_wvalid),
	.s1_axi_wready(tx_m_wready),

	.s1_axi_bid(tx_m_bid),
	.s1_axi_bresp(tx_m_bresp),
	.s1_axi_bvalid(tx_m_bvalid),
	.s1_axi_bready(tx_m_bready),

	.s1_axi_arid(tx_m_arid),
	.s1_axi_araddr(tx_m_araddr),
	.s1_axi_arlen(tx_m_arlen),
	.s1_axi_arsize(tx_m_arsize),
	.s1_axi_arburst(tx_m_arburst),
	.s1_axi_arvalid(tx_m_arvalid),
	.s1_axi_arready(tx_m_arready),

	.s1_axi_rid(tx_m_rid),
	.s1_axi_rdata(tx_m_rdata),
	.s1_axi_rresp(tx_m_rresp),
	.s1_axi_rlast(tx_m_rlast),
	.s1_axi_rvalid(tx_m_rvalid),
	.s1_axi_rready(tx_m_rready),

	.m0_axi_awid(axi_m_awid),
	.m0_axi_awaddr(axi_m_awaddr),
	.m0_axi_awlen(axi_m_awlen),
	.m0_axi_awsize(axi_m_awsize),
	.m0_axi_awburst(axi_m_awburst),
	.m0_axi_awvalid(axi_m_awvalid),
	.m0_axi_awready(axi_m_awready),

	.m0_axi_wid(axi_m_wid),
	.m0_axi_wdata(axi_m_wdata),
	.m0_axi_wstrb(axi_m_wstrb),
	.m0_axi_wlast(axi_m_wlast),
	.m0_axi_wvalid(axi_m_wvalid),
	.m0_axi_wready(axi_m_wready),

	.m0_axi_bid(axi_m_bid),
	.m0_axi_bresp(axi_m_bresp),
	.m0_axi_bvalid(axi_m_bvalid),
	.m0_axi_bready(axi_m_bready),

	.m0_axi_arid(axi_m_arid),
	.m0_axi_araddr(axi_m_araddr),
	.m0_axi_arlen(axi_m_arlen),
	.m0_axi_arsize(axi_m_arsize),
	.m0_axi_arburst(axi_m_arburst),
	.m0_axi_arvalid(axi_m_arvalid),
	.m0_axi_arready(axi_m_arready),

	.m0_axi_rid(axi_m_rid),
	.m0_axi_rdata(axi_m_rdata),
	.m0_axi_rresp(axi_m_rresp),
	.m0_axi_rlast(axi_m_rlast),
	.m0_axi_rvalid(axi_m_rvalid),
	.m0_axi_rready(axi_m_rready)
);

mac_axi mac_i(
	.aclk(axi_s_aclk),
	.aresetn(axi_s_aresetn),

	.tx_s_tdata(mac_tx_s_tdata),
	.tx_s_tvalid(mac_tx_s_tvalid),
	.tx_s_tlast(mac_tx_s_tlast),
	.tx_s_tready(mac_tx_s_tready)

	.rx_m_tdata(mac_rx_m_tdata),
	.rx_m_tvalid(mac_rx_m_tvalid),
	.rx_m_tlast(mac_rx_m_tlast),
	.rx_m_tready(mac_rx_m_tready),

	.mac_rxdat(mac_rxdat),
	.mac_rxdv(mac_rxdv),
	.mac_rxer(mac_rxer),
	.mac_rxsclk(mac_rxsclk),
	.mac_txdat(mac_txdat),
	.mac_txen(mac_txen),
	.mac_txer(mac_txer),
	.mac_txsclk(mac_txsclk),
	.mac_gtxsclk(mac_gtxsclk),
	.mac_crs(mac_crs),
	.mac_col(mac_col)
);
*/

endmodule
