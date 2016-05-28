module e1000_top(
	input aclk,
	input aresetn,

	input clk125,

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
	output reset_request,

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
	output  phy_mdio_req,
	input   phy_mdio_gnt,

	// PHY Misc
	input	phy_int,
	output	phy_reset_out,
	input	[1:0] phy_speed,
	input	phy_duplex,
	input	phy_up,
	input	phy_lsc,

	// EEPROM Port
	output	eesk,
	output	eecs,
	input	eedo,
	output	eedi
);

// Workaround for hardwares with different PHY address 
// Default PHY address in e1000 is 5'b00001
// Change this according to hardware design
parameter PHY_ADDR=5'b0;
parameter CLK_PERIOD_NS=8;
parameter EEPROM_FREQ=400000;
parameter MDIO_FREQ=8000000;
parameter TX_DESC_RAM_DWORDS=256;
parameter TX_DATA_RAM_DWORDS=8192;
parameter RX_DESC_RAM_DWORDS=256;
parameter RX_DATA_RAM_DWORDS=16384;
parameter DEBUG="FALSE";

localparam EEPROM_DIV = (1000000000/EEPROM_FREQ)/CLK_PERIOD_NS+1;
localparam MDIO_DIV = (1000000000/MDIO_FREQ)/CLK_PERIOD_NS+1;

wire [31:0] mac_tx_s_tdata;
wire [3:0] mac_tx_s_tkeep;
wire mac_tx_s_tvalid;
wire mac_tx_s_tlast;
wire mac_tx_s_tready;

wire [31:0] mac_rx_m_tdata;
wire [3:0] mac_rx_m_tkeep;
wire [15:0] mac_rx_m_tuser;
wire mac_rx_m_tvalid;
wire mac_rx_m_tlast;
wire mac_rx_m_tready;

wire [3:0] rx_m_awid;
wire [63:0] rx_m_awaddr;
wire [7:0] rx_m_awlen;
wire [2:0] rx_m_awsize;
wire [1:0] rx_m_awburst;
wire [3:0] rx_m_awcache;
wire rx_m_awvalid;
wire rx_m_awready;
wire [3:0] rx_m_wid;
wire [31:0] rx_m_wdata;
wire [3:0] rx_m_wstrb;
wire rx_m_wlast;
wire rx_m_wvalid;
wire rx_m_wready;
wire [3:0] rx_m_bid;
wire [1:0] rx_m_bresp;
wire rx_m_bvalid;
wire rx_m_bready;
wire [3:0] rx_m_arid;
wire [63:0] rx_m_araddr;
wire [7:0] rx_m_arlen;
wire [2:0] rx_m_arsize;
wire [1:0] rx_m_arburst;
wire [3:0] rx_m_arcache;
wire rx_m_arvalid;
wire rx_m_arready;
wire [3:0] rx_m_rid;
wire [31:0] rx_m_rdata;
wire [1:0] rx_m_rresp;
wire rx_m_rlast;
wire rx_m_rvalid;
wire rx_m_rready;

wire [3:0] tx_m_awid;
wire [63:0] tx_m_awaddr;
wire [7:0] tx_m_awlen;
wire [2:0] tx_m_awsize;
wire [1:0] tx_m_awburst;
wire [3:0] tx_m_awcache;
wire tx_m_awvalid;
wire tx_m_awready;
wire [3:0] tx_m_wid;
wire [31:0] tx_m_wdata;
wire [3:0] tx_m_wstrb;
wire tx_m_wlast;
wire tx_m_wvalid;
wire tx_m_wready;
wire [3:0] tx_m_bid;
wire [1:0] tx_m_bresp;
wire tx_m_bvalid;
wire tx_m_bready;
wire [3:0] tx_m_arid;
wire [63:0] tx_m_araddr;
wire [7:0] tx_m_arlen;
wire [2:0] tx_m_arsize;
wire [1:0] tx_m_arburst;
wire [3:0] tx_m_arcache;
wire tx_m_arvalid;
wire tx_m_arready;
wire [3:0] tx_m_rid;
wire [31:0] tx_m_rdata;
wire [1:0] tx_m_rresp;
wire tx_m_rlast;
wire tx_m_rvalid;
wire tx_m_rready;

wire CTRL_FD; // Full-Duplex;
wire [1:0] CTRL_SPEED; // Speed
wire CTRL_FRCSPD; // Force Speed
wire CTRL_FRCDPLX; // Force Duplex
wire CTRL_RST; // Device Reset
wire CTRL_RFCE; // Receive Flow Control Enable
wire CTRL_TFCE; // Transmit Flow Control Enable
wire CTRL_VME; // VLAN Mode Enable
wire CTRL_PHY_RST; // PHY Reset

wire STATUS_FD_fb; // Full-Duplex: 1 - FD, 2 - HD
wire STATUS_LU_fb; // Link up 1 - up, 0 - down
wire [1:0] STATUS_FID_fb; // Function ID
wire STATUS_TXOFF_fb; // TX off
wire [1:0] STATUS_SPEED_fb; // Link Speed: 00 - 10M, 01 - 100M, 1x - 1000M
wire [1:0] STATUS_ASDV_fb; // Auto-detected Speed

wire STAT_FD_fb;
wire STAT_SPEED_fb;
wire STAT_ASDV_fb;

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

wire RCTL_EN; // Receive Enable
wire LPE; // Long Packet Reciption Enable
wire [1:0] LBM; // Loopback mode
wire [1:0] RDMTS; // Rx Desc Minimum Threshold
wire [1:0] BSIZE; // Rx Buffer Size
wire BSEX; // Buffer Sizse Extension
wire SECRC; // Strip CRC

wire [63:0] RDBA;
wire [12:0] RDLEN;
wire [15:0] RDH;
wire RDH_set;
wire [15:0] RDH_fb;
wire [15:0] RDT;
wire RDT_set;
wire [15:0] RDTR;
wire [15:0] RADV;
wire [5:0] RXDCTL_PTHRESH;
wire [5:0] RXDCTL_HTHRESH;
wire [5:0] RXDCTL_WTHRESH;
wire RXDCTL_GRAN;
wire FPD;
wire FPD_set;
wire [7:0] PCSS; // Packet Checksum Start
wire RXDMT0_req;
wire RXO_req;
wire RXT0_req;

wire PHYINT_req;
wire LSC_req;

wire reset;

reg [1:0] phy_int_sync;
reg [1:0] phy_lsc_sync;

wire [16:0] dbg_rx_dram_available;
wire [3:0] dbg_i0_state;
wire [3:0] dbg_i1_state;
wire [3:0] dbg_i2_state;
wire [3:0] dbg_desc_s1;
wire [2:0] dbg_desc_s2;
wire [3:0] dbg_re_s1;
wire [3:0] dbg_re_s2;
wire [2:0] dbg_frm_state;

assign reset = !aresetn;
assign phy_reset_out = CTRL_PHY_RST || reset;
assign PHYINT_req = phy_int_sync[1];
assign LSC_req = phy_lsc_sync[1];

assign reset_request = CTRL_RST;

assign STATUS_FD_fb = phy_duplex;
assign STATUS_LU_fb = phy_up;
assign STATUS_FID_fb = 2'b0;
assign STATUS_TXOFF_fb = 1'b0; //FIXME
assign STATUS_SPEED_fb = phy_speed;
assign STATUS_ASDV_fb = phy_speed;

always @(posedge aclk)
begin
	phy_int_sync <= {phy_int_sync, phy_int};
	phy_lsc_sync <= {phy_lsc_sync, phy_lsc};
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

	.CTRL_RST(CTRL_RST),
	.CTRL_PHY_RST(CTRL_PHY_RST),

	.STATUS_FD_fb(STATUS_FD_fb),
	.STATUS_LU_fb(STATUS_LU_fb),
	.STATUS_FID_fb(STATUS_FID_fb),
	.STATUS_TXOFF_fb(STATUS_TXOFF_fb),
	.STATUS_SPEED_fb(STATUS_SPEED_fb),
	.STATUS_ASDV_fb(STATUS_ASDV_fb),

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

	.PHYINT_fb_i(PHYINT_req),

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
	.TSPBP(TSPBP),

	.RCTL_EN(RCTL_EN),
	.LPE(LPE),
	.LBM(LBM),
	.RDMTS(RDMTS),
	.BSIZE(BSIZE),
	.BSEX(BSEX),
	.SECRC(SECRC),
	.RDBA(RDBA),
	.RDLEN(RDLEN),
	.RDH(RDH),
	.RDH_set(RDH_set),
	.RDH_fb(RDH_fb),
	.RDT(RDT),
	.RDT_set(RDT_set),
	.RXDCTL_PTHRESH(RXDCTL_PTHRESH),
	.RXDCTL_HTHRESH(RXDCTL_HTHRESH),
	.RXDCTL_WTHRESH(RXDCTL_WTHRESH),
	.RXDCTL_GRAN(RXDCTL_GRAN),
	.PCSS(PCSS),
	.RDTR(RDTR),
	.FPD(FPD),
	.FPD_set(FPD_set),
	.RADV(RADV)
);

shift_eeprom #(.div(EEPROM_DIV)) shift_eeprom_i(
	.clk(aclk),
	.rst(reset),
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

shift_mdio #(.div(MDIO_DIV)) shift_mdio_i(
	.clk(aclk),
	.rst(reset),
	.mdc_o(phy_mdc),
	.mdio_i(phy_mdio_i),
	.mdio_o(phy_mdio_o),
	.mdio_oe(phy_mdio_oe),
	.rdatao(mm_rdatao),
	.rd_doneo(mm_rd_doneo),
	.eni(MDIC_start),
	.wdatai({2'b01,MDIC[27:26],PHY_ADDR[4:0],MDIC[20:16],2'b10,MDIC[15:0]}),
	.wr_doneo(mm_wr_doneo),
	.bus_req(phy_mdio_req),
	.bus_gnt(phy_mdio_gnt)
);

intr_ctrl #(.CLK_PERIOD_NS(CLK_PERIOD_NS)) intr_ctrl_i(
	.clk_i(aclk),
	.rst_i(reset),

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
	.LSC_req(LSC_req),
	.RXSEQ_req(1'b0),
	.RXDMT0_req(RXDMT0_req),
	.RXO_req(RXO_req),
	.RXT0_req(RXT0_req),
	.MDAC_req(1'b0),
	.RXCFG_req(1'b0),
	.PHYINT_req(PHYINT_req),
	.TXD_LOW_req(TXD_LOW_req),
	.SRPD_req(1'b0)
);

rx_path #(
	.CLK_PERIOD_NS(CLK_PERIOD_NS),
	.DESC_RAM_DWORDS(RX_DESC_RAM_DWORDS),
	.DATA_RAM_DWORDS(RX_DATA_RAM_DWORDS)
)rx_path_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.dbg_dram_available(dbg_rx_dram_available),
	.dbg_i0_state(dbg_i0_state),
	.dbg_i1_state(dbg_i1_state),
	.dbg_i2_state(dbg_i2_state),
	.dbg_desc_s1(dbg_desc_s1),
	.dbg_desc_s2(dbg_desc_s2),
	.dbg_re_s1(dbg_re_s1),
	.dbg_re_s2(dbg_re_s2),
	.dbg_frm_state(dbg_frm_state),
	.dbg_ext_mux_wr_busy(dbg_rx_ext_mux_wr_busy),
	.dbg_ext_mux_rd_busy(dbg_rx_ext_mux_rd_busy),
	.dbg_desc_mux_wr_busy(dbg_rx_desc_mux_wr_busy),
	.dbg_desc_mux_rd_busy(dbg_rx_desc_mux_rd_busy),

	// Parameters
	.EN(RCTL_EN),
	//.SBP(SBP),
	//.UPE(UPE),
	//.MPE(MPE),
	.RDMTS(RDMTS),
	//.MO(MO),
	//.BAM(BAM),
	.BSIZE(BSIZE),
	.BSEX(BSEX),
	//.VFE(VFE),
	//.CFIEN(CFIEN),
	//.CFI(CFI),
	//.DPF(DPF),
	//.PMCF(PMCF),
	.RDBA(RDBA),
	.RDLEN(RDLEN),
	.RDH(RDH),
	.RDH_set(RDH_set),
	.RDH_fb(RDH_fb),
	.RDT(RDT),
	.RDT_set(RDT_set),
	.PTHRESH(RXDCTL_PTHRESH),
	.HTHRESH(RXDCTL_HTHRESH),
	.WTHRESH(RXDCTL_WTHRESH),
	.GRAN(RXDCTL_GRAN),
	.PCSS(PCSS),
	//.IPOFLD(IPOFLD),
	//.TUOFLD(TUOFLD),
	//.IPV6OFL(IPV6OFL),
	.RDTR(RDTR),
	.FPD(FPD),
	.FPD_set(FPD_set),
	.RADV(RADV),
	.RXDMT0_req(RXDMT0_req),
	.RXO_req(RXO_req),
	.RXT0_req(RXT0_req),

	//.rtbl_index(rtbl_index),
	//.rtbl_data(rtbl_data),
	//.mtbl_index(mtbl_index),
	//.mtbl_data(mtbl_data),
	//.vtbl_index(vtbl_index),
	//.vtbl_data(vtbl_data),

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
	.mac_s_tkeep(mac_rx_m_tkeep),
	.mac_s_tvalid(mac_rx_m_tvalid),
	.mac_s_tuser(mac_rx_m_tuser),
	.mac_s_tlast(mac_rx_m_tlast),
	.mac_s_tready(mac_rx_m_tready)
);

tx_path #(
	.CLK_PERIOD_NS(CLK_PERIOD_NS),
	.DESC_RAM_DWORDS(TX_DESC_RAM_DWORDS),
	.DATA_RAM_DWORDS(TX_DATA_RAM_DWORDS)
) tx_path_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.dbg_te_desc_dext(dbg_te_desc_dext),

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
	.axi_m_awid(tx_m_awid),
	.axi_m_awaddr(tx_m_awaddr),
	.axi_m_awlen(tx_m_awlen),
	.axi_m_awsize(tx_m_awsize),
	.axi_m_awburst(tx_m_awburst),
	.axi_m_awvalid(tx_m_awvalid),
	.axi_m_awready(tx_m_awready),

	.axi_m_wid(tx_m_wid),
	.axi_m_wdata(tx_m_wdata),
	.axi_m_wstrb(tx_m_wstrb),
	.axi_m_wlast(tx_m_wlast),
	.axi_m_wvalid(tx_m_wvalid),
	.axi_m_wready(tx_m_wready),

	.axi_m_bid(tx_m_bid),
	.axi_m_bresp(tx_m_bresp),
	.axi_m_bvalid(tx_m_bvalid),
	.axi_m_bready(tx_m_bready),

	.axi_m_arid(tx_m_arid),
	.axi_m_araddr(tx_m_araddr),
	.axi_m_arlen(tx_m_arlen),
	.axi_m_arsize(tx_m_arsize),
	.axi_m_arburst(tx_m_arburst),
	.axi_m_arvalid(tx_m_arvalid),
	.axi_m_arready(tx_m_arready),

	.axi_m_rid(tx_m_rid),
	.axi_m_rdata(tx_m_rdata),
	.axi_m_rresp(tx_m_rresp),
	.axi_m_rlast(tx_m_rlast),
	.axi_m_rvalid(tx_m_rvalid),
	.axi_m_rready(tx_m_rready),

	// MAC RX Stream Port
	.mac_m_tdata(mac_tx_s_tdata),
	.mac_m_tkeep(mac_tx_s_tkeep),
	.mac_m_tvalid(mac_tx_s_tvalid),
	.mac_m_tlast(mac_tx_s_tlast),
	.mac_m_tready(mac_tx_s_tready)
);

reg  [2:0] Speed;
wire RX_APPEND_CRC;       
wire CRC_chk_en;       
wire [5:0] RX_IFG_SET;       
wire [15:0] RX_MAX_LENGTH;
wire [6:0] RX_MIN_LENGTH;
wire pause_frame_send_en;       
wire [15:0] pause_quanta_set;       
wire xoff_cpu;       
wire xon_cpu;       
wire FullDuplex;       
wire [3:0] MaxRetry;       
wire [5:0] IFGset;       
wire tx_pause_en;       
wire Line_loop_en;

always @(*)
begin
	case(phy_speed) /* synthesis full_case */
		2'b00: Speed = 3'b001;
		2'b01: Speed = 3'b010;
		2'b10: Speed = 3'b100;
		2'b11: Speed = 3'b100;
	endcase
end

assign	RX_APPEND_CRC = !SECRC;
assign	CRC_chk_en = 1'b1;
assign	RX_IFG_SET = 16'h000c;
assign	RX_MAX_LENGTH = LPE?16'h4000:16'h05F2;// 16384 or 1522
assign	RX_MIN_LENGTH = 16'h40; // 64 minimum
assign	pause_frame_send_en = 1'b0;
assign	pause_quanta_set = 16'h0;
assign	xoff_cpu = 1'b0;
assign	xon_cpu = 1'b0;
assign	FullDuplex = phy_duplex; 
assign	MaxRetry = 16'h0002;
assign	IFGset = 16'h000c;
assign	tx_pause_en = 1'b0;
assign	Line_loop_en = &LBM;// 2'b11 == loopback

mac_axis mac_i(
	.Clk_125M(mac_rxsclk),
	.aclk(aclk),
	.aresetn(aresetn),

	.Speed(Speed),
	.RX_APPEND_CRC(RX_APPEND_CRC),
	.CRC_chk_en(CRC_chk_en),
	.RX_IFG_SET(RX_IFG_SET),
	.RX_MAX_LENGTH(RX_MAX_LENGTH),
	.RX_MIN_LENGTH(RX_MIN_LENGTH),
	.pause_frame_send_en(pause_frame_send_en),
	.pause_quanta_set(pause_quanta_set),
	.xoff_cpu(xoff_cpu),
	.xon_cpu(xon_cpu),
	.FullDuplex(FullDuplex),
	.MaxRetry(MaxRetry),
	.IFGset(IFGset),
	.tx_pause_en(tx_pause_en),
	.Line_loop_en(Line_loop_en),

	.rx_mac_tdata(mac_rx_m_tdata),
	.rx_mac_tkeep(mac_rx_m_tkeep),
	.rx_mac_tuser(mac_rx_m_tuser),
	.rx_mac_tlast(mac_rx_m_tlast),
	.rx_mac_tvalid(mac_rx_m_tvalid),
	.rx_mac_tready(mac_rx_m_tready),

	.tx_mac_tdata(mac_tx_s_tdata),
	.tx_mac_tkeep(mac_tx_s_tkeep),
	.tx_mac_tlast(mac_tx_s_tlast),
	.tx_mac_tvalid(mac_tx_s_tvalid),
	.tx_mac_tready(mac_tx_s_tready),

	.Rxd(mac_rxdat),
	.Rx_dv(mac_rxdv),
	.Rx_er(mac_rxer),
	.Rx_clk(mac_rxsclk),
	.Txd(mac_txdat),
	.Tx_en(mac_txen),
	.Tx_er(mac_txer),
	.Tx_clk(mac_txsclk),
	.Gtx_clk(mac_gtxsclk),
	.Crs(mac_crs),
	.Col(mac_col)
);

wire [1:0] dbg_ext_mux_wr_stage;

axi_mux #(
	.SLAVE_NUM(2),
	.ID_WIDTH(4),
	.ADDR_WIDTH(64),
	.DATA_WIDTH(32),
	.LEN_WIDTH(8)
) ext_mux_i (
	.aclk(aclk),
	.aresetn(aresetn),

	.dbg_wr_busy(dbg_ext_mux_wr_busy),
	.dbg_rd_busy(dbg_ext_mux_rd_busy),
	.dbg_wr_tmo(dbg_ext_mux_wr_tmo),
	.dbg_rd_tmo(dbg_ext_mux_rd_tmo),
	.dbg_wr_stage(dbg_ext_mux_wr_stage),

	.s_awid({rx_m_awid,tx_m_awid}),
	.s_awaddr({rx_m_awaddr,tx_m_awaddr}),
	.s_awlen({rx_m_awlen,tx_m_awlen}),
	.s_awsize({rx_m_awsize,tx_m_awsize}),
	.s_awburst({rx_m_awburst,tx_m_awburst}),
	.s_awvalid({rx_m_awvalid,tx_m_awvalid}),
	.s_awready({rx_m_awready,tx_m_awready}),

	.s_wid({rx_m_wid,tx_m_wid}),
	.s_wdata({rx_m_wdata,tx_m_wdata}),
	.s_wstrb({rx_m_wstrb,tx_m_wstrb}),
	.s_wlast({rx_m_wlast,tx_m_wlast}),
	.s_wvalid({rx_m_wvalid,tx_m_wvalid}),
	.s_wready({rx_m_wready,tx_m_wready}),

	.s_bid({rx_m_bid,tx_m_bid}),
	.s_bresp({rx_m_bresp,tx_m_bresp}),
	.s_bvalid({rx_m_bvalid,tx_m_bvalid}),
	.s_bready({rx_m_bready,tx_m_bready}),

	.s_arid({rx_m_arid,tx_m_arid}),
	.s_araddr({rx_m_araddr,tx_m_araddr}),
	.s_arlen({rx_m_arlen,tx_m_arlen}),
	.s_arsize({rx_m_arsize,tx_m_arsize}),
	.s_arburst({rx_m_arburst,tx_m_arburst}),
	.s_arvalid({rx_m_arvalid,tx_m_arvalid}),
	.s_arready({rx_m_arready,tx_m_arready}),

	.s_rid({rx_m_rid,tx_m_rid}),
	.s_rdata({rx_m_rdata,tx_m_rdata}),
	.s_rresp({rx_m_rresp,tx_m_rresp}),
	.s_rlast({rx_m_rlast,tx_m_rlast}),
	.s_rvalid({rx_m_rvalid,tx_m_rvalid}),
	.s_rready({rx_m_rready,tx_m_rready}),

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

generate
if(DEBUG == "TRUE") begin
ila_0 ila_mac_i0(
	.clk(aclk), // input wire clk
	.probe0({
		CTRL_RST,
		CTRL_PHY_RST,

		TCTL_EN,
		TDLEN,
		TDT_set,
		DPP,
		TXDW_req,
		TXQE_req,
		TXD_LOW_req,

		RCTL_EN,
		RDLEN,
		RDT_set,
		BSIZE,
		BSEX,
		SECRC,
		FPD,
		FPD_set,
		RXDMT0_req,
		RXO_req,
		RXT0_req,

		dbg_te_desc_dext,

		dbg_rx_dram_available,
		dbg_i0_state,
		dbg_i1_state,
		dbg_i2_state,
		dbg_desc_s1,
		dbg_desc_s2,
		dbg_re_s1,
		dbg_re_s2,
		dbg_frm_state,
		dbg_ext_mux_wr_busy,
		dbg_ext_mux_rd_busy,
		dbg_ext_mux_wr_tmo,
		dbg_ext_mux_rd_tmo,
		dbg_ext_mux_wr_stage,
		dbg_rx_ext_mux_wr_busy,
		dbg_rx_ext_mux_rd_busy,
		dbg_rx_desc_mux_wr_busy,
		dbg_rx_desc_mux_rd_busy,

		TDH_fb,
		TDT,
		RDH_fb,
		RDT,

		mac_txdat,
		mac_txen,
		mac_txer,
		mac_crs,
		mac_col,
		
		mac_rx_m_tdata,
		mac_rx_m_tuser,
		mac_rx_m_tkeep,
		mac_rx_m_tlast,
		mac_rx_m_tvalid,
		mac_rx_m_tready,

		mac_tx_s_tdata,
		mac_tx_s_tkeep,
		mac_tx_s_tlast,
		mac_tx_s_tvalid,
		mac_tx_s_tready
	})
);
ila_0 ila_mac_i1(
	.clk(aclk), // input wire clk
	.probe0({
		dbg_rx_ext_mux_wr_busy,
		dbg_ext_mux_wr_busy,
		dbg_ext_mux_wr_tmo,
		dbg_ext_mux_wr_stage,
		axi_m_awaddr[31:0],
		axi_m_awlen,
		axi_m_awvalid,
		axi_m_awready,
		axi_m_wstrb,
		axi_m_wlast,
		axi_m_wvalid,
		axi_m_wready,
		axi_m_bvalid,
		axi_m_bready,

		rx_m_awaddr[31:0],
		rx_m_awlen,
		rx_m_awvalid,
		rx_m_awready,
		rx_m_wstrb,
		rx_m_wlast,
		rx_m_wvalid,
		rx_m_wready,
		rx_m_bvalid,
		rx_m_bready,

		tx_m_awaddr[31:0],
		tx_m_awlen,
		tx_m_awvalid,
		tx_m_awready,
		tx_m_wstrb,
		tx_m_wlast,
		tx_m_wvalid,
		tx_m_wready,
		tx_m_bvalid,
		tx_m_bready
	})
);
end
endgenerate

endmodule
