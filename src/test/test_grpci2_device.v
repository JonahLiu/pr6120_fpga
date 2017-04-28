`timescale 1ns/1ps
module test_grpci2_device;

parameter HOST_BASE = 32'h0000_0000;
parameter HOST_SIZE = 33'h8000_0000;

// Target Addresses
parameter TGT_CONF_ADDR = 32'h0100_0000;
parameter TGT_BAR0_BASE = 32'h8001_0000;
parameter TGT_BAR1_BASE = 32'h8002_0000;
parameter TGT_BAR2_BASE = 32'h8004_0000;

// PCI Configuration Registers
parameter CONF_ID_OFFSET  = 8'h0;
parameter CONF_CTRL_OFFSET  = 8'h4;
parameter CONF_CLINE_OFFSET  = 8'hc;
parameter CONF_MISC_OFFSET  = 8'h3c;
parameter CONF_BAR0_OFFSET  = 8'h10;
parameter CONF_BAR1_OFFSET  = 8'h14;
parameter CONF_BAR2_OFFSET  = 8'h18;

wire PCI_CLK;
wire PCI_RST;
wire PCI_LOCK;
wire [31:0] PCI_AD;
wire [3:0] PCI_CBE;
wire PCI_FRAME;
wire PCI_IRDY;
wire PCI_TRDY;
wire PCI_DEVSEL;
wire PCI_STOP;
wire PCI_PERR;
wire PCI_PAR;
wire [3:0] PCI_REQ;
wire [3:0] PCI_GNT;
wire PCI_SERR;
wire [3:0] PCI_INT;
wire PCI_M66EN;
wire PCI_PME;

wire pci_lock_o;
wire pci_lock_oe;
wire [31:0] pci_ad_o;
wire [31:0] pci_ad_oe;
wire [3:0] pci_cbe_o;
wire [3:0] pci_cbe_oe;
wire pci_frame_o;
wire pci_frame_oe;
wire pci_irdy_o;
wire pci_irdy_oe;
wire pci_trdy_o;
wire pci_trdy_oe;
wire pci_devsel_o;
wire pci_devsel_oe;
wire pci_stop_o;
wire pci_stop_oe;
wire pci_perr_o;
wire pci_perr_oe;
wire pci_par_o;
wire pci_par_oe;
wire pci_req_o;
wire pci_req_oe;
wire pci_serr_o;
wire pci_serr_oe;
wire [3:0] pci_int_o;
wire [3:0] pci_int_oe;
wire pci_pme_o;
wire pci_pme_oe;

wire ahb_hclk;
wire ahb_hresetn;

wire ahb_mst_hgrant;
wire ahb_mst_hready;
wire [1:0] ahb_mst_hresp;
wire [31:0] ahb_mst_hrdata;
wire ahb_mst_hbusreq;
wire ahb_mst_hlock;
wire [1:0] ahb_mst_htrans;
wire [31:0] ahb_mst_haddr;
wire ahb_mst_hwrite;
wire [2:0] ahb_mst_hsize;
wire [2:0] ahb_mst_hburst;
wire [3:0] ahb_mst_hprot;
wire [31:0] ahb_mst_hwdata;

wire ahb_slv_hsel;
wire [31:0] ahb_slv_haddr;
wire ahb_slv_hwrite;
wire [1:0] ahb_slv_htrans;
wire [2:0] ahb_slv_hsize;
wire [2:0] ahb_slv_hburst;
wire [31:0] ahb_slv_hwdata;
wire [3:0] ahb_slv_hprot;
wire [3:0] ahb_slv_hmaster;
wire ahb_slv_hmastlock;
wire ahb_slv_hready;
wire [1:0] ahb_slv_hresp;
wire [31:0] ahb_slv_hrdata;
wire [15:0] ahb_slv_hsplit;

wire [3:0] intr_req;

wire tgt_m_awvalid;
wire tgt_m_awready;
wire [31:0] tgt_m_awaddr;
wire tgt_m_wvalid;
wire tgt_m_wready;
wire [31:0] tgt_m_wdata;
wire [3:0] tgt_m_wstrb;
wire tgt_m_bvalid;
wire tgt_m_bready;
wire [1:0] tgt_m_bresp;
wire tgt_m_arvalid;
wire [3:0] tgt_m_aruser;
wire tgt_m_arready;
wire [31:0] tgt_m_araddr;
wire tgt_m_rvalid;
wire tgt_m_rready;
wire [31:0] tgt_m_rdata;
wire [1:0] tgt_m_rresp;

assign PCI_LOCK = pci_lock_oe ? pci_lock_o : 1'bz;
assign PCI_FRAME = pci_frame_oe ? pci_frame_o : 1'bz;
assign PCI_IRDY = pci_irdy_oe ? pci_irdy_o : 1'bz;
assign PCI_TRDY = pci_trdy_oe ? pci_trdy_o : 1'bz;
assign PCI_DEVSEL = pci_devsel_oe ? pci_devsel_o : 1'bz;
assign PCI_STOP = pci_stop_oe ? pci_stop_o : 1'bz;
assign PCI_PERR = pci_perr_oe ? pci_perr_o : 1'bz;
assign PCI_PAR = pci_par_oe ? pci_par_o : 1'bz;
assign PCI_REQ[1] = pci_req_oe ? pci_req_o : 1'bz;
assign PCI_SERR = pci_serr_oe ? pci_serr_o : 1'bz;
assign PCI_PME = pci_pme_oe ? pci_pme_o : 1'bz;

genvar i;
generate
for(i=0;i<32;i=i+1)
begin:AD
	assign PCI_AD[i] = pci_ad_oe[i] ? pci_ad_o[i] : 1'bz;
end
for(i=0;i<4;i=i+1)
begin:CBE
	assign PCI_CBE[i] = pci_cbe_oe[i] ? pci_cbe_o[i] : 1'bz;
end
for(i=0;i<4;i=i+1)
begin:INT
	assign PCI_INT[i] = pci_int_oe[i] ? pci_int_o[i] : 1'bz;
end
endgenerate

pullup (PCI_LOCK);
pullup (PCI_FRAME);
pullup (PCI_IRDY);
pullup (PCI_TRDY);
pullup (PCI_DEVSEL);
pullup (PCI_STOP);
pullup (PCI_PERR);
pullup (PCI_PAR);
pullup (PCI_SERR);
pullup (PCI_PME);
pullup (PCI_M66EN);

pullup pu_req [3:0] (PCI_REQ);
pullup pu_gnt [3:0] (PCI_GNT);
pullup pu_int [3:0] (PCI_INT);

grpci2_device #(
	.oepol(1),
	.vendorid(16'h10EE),
	.deviceid(16'h0701),
	.haddr(12'h000),
	.hmask(12'h000),
	.ioaddr(12'hFFF),
	//.bar0(7),
	//.bar1(7),
	//.bar2(3),
	.bar0(10),
	.bar1(10),
	.bar2(10),
	.bar3(0),
	.bar4(0),
	.bar5(0),
	.bar0_map(24'h000100),
	.bar1_map(24'h000200),
	.bar2_map(24'h000300),
	.bar3_map(24'h000400),
	.bar4_map(24'h000500),
	.bar5_map(24'h000600),
	.bartype(14'b00000100_00000000)
)
dut(
	.pci_rst(PCI_RST),
	.pci_clk(PCI_CLK),
	.pci_gnt(PCI_GNT[1]),
	.pci_idsel(PCI_AD[24]),
	.pci_lock_i(PCI_LOCK),
	.pci_lock_o(pci_lock_o),
	.pci_lock_oe(pci_lock_oe),
	.pci_ad_i(PCI_AD),
	.pci_ad_o(pci_ad_o),
	.pci_ad_oe(pci_ad_oe),
	.pci_cbe_i(PCI_CBE),
	.pci_cbe_o(pci_cbe_o),
	.pci_cbe_oe(pci_cbe_oe),
	.pci_frame_i(PCI_FRAME),
	.pci_frame_o(pci_frame_o),
	.pci_frame_oe(pci_frame_oe),
	.pci_irdy_i(PCI_IRDY),
	.pci_irdy_o(pci_irdy_o),
	.pci_irdy_oe(pci_irdy_oe),
	.pci_trdy_i(PCI_TRDY),
	.pci_trdy_o(pci_trdy_o),
	.pci_trdy_oe(pci_trdy_oe),
	.pci_devsel_i(PCI_DEVSEL),
	.pci_devsel_o(pci_devsel_o),
	.pci_devsel_oe(pci_devsel_oe),
	.pci_stop_i(PCI_STOP),
	.pci_stop_o(pci_stop_o),
	.pci_stop_oe(pci_stop_oe),
	.pci_perr_i(PCI_PERR),
	.pci_perr_o(pci_perr_o),
	.pci_perr_oe(pci_perr_oe),
	.pci_par_i(PCI_PAR),
	.pci_par_o(pci_par_o),
	.pci_par_oe(pci_par_oe),
	.pci_req_o(pci_req_o),
	.pci_req_oe(pci_req_oe),
	.pci_serr_i(PCI_SERR),
	.pci_serr_o(pci_serr_o),
	.pci_serr_oe(pci_serr_oe),
	.pci_int_i(PCI_INT),
	.pci_int_o(pci_int_o),
	.pci_int_oe(pci_int_oe),
	.pci_m66en(PCI_M66EN),
	.pci_pme_i(PCI_PME),
	.pci_pme_o(pci_pme_o),
	.pci_pme_oe(pci_pme_oe),

	.ahb_hclk(ahb_hclk),
	.ahb_hresetn(ahb_hresetn),

	.ahb_mst_hgrant(ahb_mst_hgrant),
	.ahb_mst_hready(ahb_mst_hready),
	.ahb_mst_hresp(ahb_mst_hresp),
	.ahb_mst_hrdata(ahb_mst_hrdata),
	.ahb_mst_hbusreq(ahb_mst_hbusreq),
	.ahb_mst_hlock(ahb_mst_hlock),
	.ahb_mst_htrans(ahb_mst_htrans),
	.ahb_mst_haddr(ahb_mst_haddr),
	.ahb_mst_hwrite(ahb_mst_hwrite),
	.ahb_mst_hsize(ahb_mst_hsize),
	.ahb_mst_hburst(ahb_mst_hburst),
	.ahb_mst_hprot(ahb_mst_hprot),
	.ahb_mst_hwdata(ahb_mst_hwdata),

	.ahb_slv_hsel(ahb_slv_hsel),
	.ahb_slv_haddr(ahb_slv_haddr),
	.ahb_slv_hwrite(ahb_slv_hwrite),
	.ahb_slv_htrans(ahb_slv_htrans),
	.ahb_slv_hsize(ahb_slv_hsize),
	.ahb_slv_hburst(ahb_slv_hburst),
	.ahb_slv_hwdata(ahb_slv_hwdata),
	.ahb_slv_hprot(ahb_slv_hprot),
	.ahb_slv_hmaster(ahb_slv_hmaster),
	.ahb_slv_hmastlock(ahb_slv_hmastlock),
	.ahb_slv_hready_i(ahb_slv_hready),
	.ahb_slv_hready_o(ahb_slv_hready),
	.ahb_slv_hresp(ahb_slv_hresp),
	.ahb_slv_hrdata(ahb_slv_hrdata),
	.ahb_slv_hsplit(ahb_slv_hsplit),

	.intr_req(intr_req)
);

assign ahb_mst_hgrant = 1'b1;

////////////////////////////////////////////////////////////////////////////////
// PCI stub models
pci_behavioral_master master(
	.AD(PCI_AD),
	.CBE(PCI_CBE),
	.PAR(PCI_PAR),
	.FRAME_N(PCI_FRAME),
	.TRDY_N(PCI_TRDY),
	.IRDY_N(PCI_IRDY),
	.STOP_N(PCI_STOP),
	.DEVSEL_N(PCI_DEVSEL),
	.IDSEL(1'b0),
	.PERR_N(PCI_PERR),
	.SERR_N(PCI_SERR),
	.INTA_N(PCI_INT[0]),
	.REQ_N(PCI_REQ[0]),
	.GNT_N(PCI_GNT[0]),
	.RST_N(PCI_RST),
	.PCLK(PCI_CLK)
);

pci_behavioral_target #(
	.BAR0_BASE(HOST_BASE), 
	.BAR0_SIZE(HOST_SIZE),
	.DATA_LATENCY(0)
) host(
	.AD(PCI_AD),
	.CBE(PCI_CBE),
	.PAR(PCI_PAR),
	.FRAME_N(PCI_FRAME),
	.TRDY_N(PCI_TRDY),
	.IRDY_N(PCI_IRDY),
	.STOP_N(PCI_STOP),
	.DEVSEL_N(PCI_DEVSEL),
	.IDSEL(1'b0),
	.PERR_N(PCI_PERR),
	.SERR_N(PCI_SERR),
	.RST_N(PCI_RST),
	.PCLK(PCI_CLK)
);

// PCI Arbiter
wire	[3:0]	arb_ext_gnt;
reg [3:0]   arb_ext_req_prev;
reg arb_frame_prev;
reg arb_irdy_prev;
assign	PCI_GNT = ~arb_ext_gnt;

always @(posedge PCI_CLK)
    arb_ext_req_prev <= ~PCI_REQ;
always @(posedge PCI_CLK)
    arb_frame_prev <= ~PCI_FRAME;
always @(posedge PCI_CLK)
    arb_irdy_prev <= ~PCI_IRDY;

pci_blue_arbiter arbiter(
    //.pci_int_req_direct(pci_int_req_n),
    .pci_int_req_direct(1'b0),
    .pci_ext_req_prev(arb_ext_req_prev),
    .pci_int_gnt_direct_out(),
    .pci_ext_gnt_direct_out(arb_ext_gnt),
    .pci_frame_prev(arb_frame_prev),
    .pci_irdy_prev(arb_irdy_prev),
    .pci_irdy_now(~PCI_IRDY),
    .arbitration_enable(1'b1),
    .pci_clk(PCI_CLK),
    .pci_reset_comb(!PCI_RST)
);

////////////////////////////////////////////////////////////////////////////////
// Target stub
grpci2_axi_lite_tgt target_i(
	.aclk(ahb_hclk),
	.aresetn(ahb_hresetn),

	.ahb_s_hsel(1'b1),
	.ahb_s_haddr(ahb_mst_haddr),
	.ahb_s_hwrite(ahb_mst_hwrite),
	.ahb_s_htrans(ahb_mst_htrans),
	.ahb_s_hsize(ahb_mst_hsize),
	.ahb_s_hburst(ahb_mst_hburst),
	.ahb_s_hprot(ahb_mst_hprot),
	.ahb_s_hmaster(4'b0),
	.ahb_s_hmastlock(ahb_mst_hlock),
	.ahb_s_hwdata(ahb_mst_hwdata),
	.ahb_s_hready_i(ahb_mst_hready),
	.ahb_s_hready_o(ahb_mst_hready),
	.ahb_s_hresp(ahb_mst_hresp),
	.ahb_s_hrdata(ahb_mst_hrdata),
	.ahb_s_hsplit(),

	.tgt_m_awvalid(tgt_m_awvalid),
	.tgt_m_awready(tgt_m_awready),
	.tgt_m_awaddr(tgt_m_awaddr),

	.tgt_m_wvalid(tgt_m_wvalid),
	.tgt_m_wready(tgt_m_wready),
	.tgt_m_wdata(tgt_m_wdata),
	.tgt_m_wstrb(tgt_m_wstrb),

	.tgt_m_bvalid(tgt_m_bvalid),
	.tgt_m_bready(tgt_m_bready),
	.tgt_m_bresp(tgt_m_bresp),

	.tgt_m_arvalid(tgt_m_arvalid),
	.tgt_m_aruser(tgt_m_aruser),
	.tgt_m_arready(tgt_m_arready),
	.tgt_m_araddr(tgt_m_araddr),

	.tgt_m_rvalid(tgt_m_rvalid),
	.tgt_m_rready(tgt_m_rready),
	.tgt_m_rdata(tgt_m_rdata),
	.tgt_m_rresp(tgt_m_rresp)
);

axi_memory_model axi_memory_model_i(
	.s_axi_aresetn(ahb_hresetn),
	.s_axi_aclk(ahb_hclk),
	.s_axi_awid(4'b0),
	.s_axi_awaddr(tgt_m_awaddr),
	.s_axi_awlen(8'b0),
	.s_axi_awsize(3'b0),
	.s_axi_awburst(2'b0),
	.s_axi_awvalid(tgt_m_awvalid),
	.s_axi_awready(tgt_m_awready),
	.s_axi_wdata(tgt_m_wdata),
	.s_axi_wstrb(tgt_m_wstrb),
	.s_axi_wlast(1'b1),
	.s_axi_wvalid(tgt_m_wvalid),
	.s_axi_wready(tgt_m_wready),
	.s_axi_bready(tgt_m_bready),
	.s_axi_bid(),
	.s_axi_bresp(tgt_m_bresp),
	.s_axi_bvalid(tgt_m_bvalid),
	.s_axi_arid(4'b0),
	.s_axi_araddr(tgt_m_araddr),
	.s_axi_arlen(8'b0),
	.s_axi_arsize(3'b0),
	.s_axi_arburst(2'b0),
	.s_axi_arvalid(tgt_m_arvalid),
	.s_axi_arready(tgt_m_arready),
	.s_axi_rready(tgt_m_rready),
	.s_axi_rid(),
	.s_axi_rdata(tgt_m_rdata),
	.s_axi_rresp(tgt_m_rresp),
	.s_axi_rlast(),
	.s_axi_rvalid(tgt_m_rvalid)
);
////////////////////////////////////////////////////////////////////////////////
//
wire mst_s_aclk;
wire mst_s_aresetn;
wire [3:0] mst_s_awid;
wire [63:0] mst_s_awaddr;
wire [7:0] mst_s_awlen;
wire [2:0] mst_s_awsize;
wire [1:0] mst_s_awburst;
wire [3:0] mst_s_awcache;
wire mst_s_awvalid;
wire mst_s_awready;
wire [3:0] mst_s_wid;
wire [31:0] mst_s_wdata;
wire [3:0] mst_s_wstrb;
wire mst_s_wlast;
wire mst_s_wvalid;
wire mst_s_wready;
wire [3:0] mst_s_bid;
wire [1:0] mst_s_bresp;
wire mst_s_bvalid;
wire mst_s_bready;
wire [3:0] mst_s_arid;
wire [63:0] mst_s_araddr;
wire [7:0] mst_s_arlen;
wire [2:0] mst_s_arsize;
wire [1:0] mst_s_arburst;
wire [3:0] mst_s_arcache;
wire mst_s_arvalid;
wire mst_s_arready;
wire [3:0] mst_s_rid;
wire [31:0] mst_s_rdata;
wire [1:0] mst_s_rresp;
wire mst_s_rlast;
wire mst_s_rvalid;
wire mst_s_rready;

assign mst_s_aclk = ahb_hclk;
assign mst_s_aresetn = ahb_hresetn;
assign ahb_slv_hmaster = 'b0;

grpci2_axi_mst master_i(
	.ahb_hclk(ahb_hclk),
	.ahb_hresetn(ahb_hresetn),
	.ahb_m_hgrant(1'b1),
	.ahb_m_hready(ahb_slv_hready),
	.ahb_m_hresp(ahb_slv_hresp),
	.ahb_m_hrdata(ahb_slv_hrdata),
	.ahb_m_hbusreq(ahb_slv_hsel),
	.ahb_m_hlock(ahb_slv_hmastlock),
	.ahb_m_htrans(ahb_slv_htrans),
	.ahb_m_haddr(ahb_slv_haddr),
	.ahb_m_hwrite(ahb_slv_hwrite),
	.ahb_m_hsize(ahb_slv_hsize),
	.ahb_m_hburst(ahb_slv_hburst),
	.ahb_m_hprot(ahb_slv_hprot),
	.ahb_m_hwdata(ahb_slv_hwdata),

	.cacheline_size(8'd16),

	.mst_s_aclk(mst_s_aclk),
	.mst_s_aresetn(mst_s_aresetn),

	.mst_s_awid(mst_s_awid),
	.mst_s_awaddr(mst_s_awaddr),
	.mst_s_awlen(mst_s_awlen),
	.mst_s_awsize(mst_s_awsize),
	.mst_s_awburst(mst_s_awburst),
	.mst_s_awcache(mst_s_awcache),
	.mst_s_awvalid(mst_s_awvalid),
	.mst_s_awready(mst_s_awready),

	.mst_s_wid(mst_s_wid),
	.mst_s_wdata(mst_s_wdata),
	.mst_s_wstrb(mst_s_wstrb),
	.mst_s_wlast(mst_s_wlast),
	.mst_s_wvalid(mst_s_wvalid),
	.mst_s_wready(mst_s_wready),

	.mst_s_bid(mst_s_bid),
	.mst_s_bresp(mst_s_bresp),
	.mst_s_bvalid(mst_s_bvalid),
	.mst_s_bready(mst_s_bready),

	.mst_s_arid(mst_s_arid),
	.mst_s_araddr(mst_s_araddr),
	.mst_s_arlen(mst_s_arlen),
	.mst_s_arsize(mst_s_arsize),
	.mst_s_arburst(mst_s_arburst),
	.mst_s_arcache(mst_s_arcache),
	.mst_s_arvalid(mst_s_arvalid),
	.mst_s_arready(mst_s_arready),

	.mst_s_rid(mst_s_rid),
	.mst_s_rdata(mst_s_rdata),
	.mst_s_rresp(mst_s_rresp),
	.mst_s_rlast(mst_s_rlast),
	.mst_s_rvalid(mst_s_rvalid),
	.mst_s_rready(mst_s_rready)
);

axi_master_model aximaster(
	.m_axi_aresetn(mst_s_aresetn),
	.m_axi_aclk(mst_s_aclk),
	.m_axi_awid(mst_s_awid),
	.m_axi_awaddr(mst_s_awaddr),
	.m_axi_awlen(mst_s_awlen),
	.m_axi_awsize(mst_s_awsize),
	.m_axi_awburst(mst_s_awburst),
	.m_axi_awvalid(mst_s_awvalid),
	.m_axi_awready(mst_s_awready),
	.m_axi_wid(mst_s_wid),
	.m_axi_wdata(mst_s_wdata),
	.m_axi_wstrb(mst_s_wstrb),
	.m_axi_wlast(mst_s_wlast),
	.m_axi_wvalid(mst_s_wvalid),
	.m_axi_wready(mst_s_wready),
	.m_axi_bready(mst_s_bready),
	.m_axi_bid(mst_s_bid),
	.m_axi_bresp(mst_s_bresp),
	.m_axi_bvalid(mst_s_bvalid),
	.m_axi_arid(mst_s_arid),
	.m_axi_araddr(mst_s_araddr),
	.m_axi_arlen(mst_s_arlen),
	.m_axi_arsize(mst_s_arsize),
	.m_axi_arburst(mst_s_arburst),
	.m_axi_arvalid(mst_s_arvalid),
	.m_axi_arready(mst_s_arready),
	.m_axi_rready(mst_s_rready),
	.m_axi_rid(mst_s_rid),
	.m_axi_rdata(mst_s_rdata),
	.m_axi_rresp(mst_s_rresp),
	.m_axi_rlast(mst_s_rlast),
	.m_axi_rvalid(mst_s_rvalid)
);

////////////////////////////////////////////////////////////////////////////////
//
reg pci_clk_i;
initial
begin
	pci_clk_i = 0;
	forever #15.151 pci_clk_i = ~pci_clk_i;
end
assign PCI_CLK = pci_clk_i;

reg ahb_hclk_i;
initial
begin
	ahb_hclk_i = 0;
	forever #5.000 ahb_hclk_i = ~ahb_hclk_i;
end
assign ahb_hclk = ahb_hclk_i;

reg pci_rst_i;
initial
begin
	pci_rst_i = 0;
	repeat(16) @(posedge PCI_CLK);
   	pci_rst_i <= 1;
end
assign PCI_RST = pci_rst_i;

reg ahb_rst_i;
initial
begin
	ahb_rst_i = 0;
	repeat(16) @(posedge ahb_hclk);
   	ahb_rst_i <= 1;
end

assign ahb_hresetn = ahb_rst_i;

reg [3:0] intr_req_i;
assign intr_req = intr_req_i;

task config_target;
	reg [31:0] data;
	begin
		master.config_read(TGT_CONF_ADDR+CONF_ID_OFFSET, 4'hf, data);
		master.config_read(TGT_CONF_ADDR+CONF_CTRL_OFFSET, 4'hf, data);

		master.config_write(TGT_CONF_ADDR+CONF_BAR0_OFFSET,~0,4'hF);
		master.config_read(TGT_CONF_ADDR+CONF_BAR0_OFFSET, 4'hf, data);
		master.config_write(TGT_CONF_ADDR+CONF_BAR0_OFFSET,TGT_BAR0_BASE,4'hF);

		master.config_write(TGT_CONF_ADDR+CONF_BAR1_OFFSET,~0,4'hF);
		master.config_read(TGT_CONF_ADDR+CONF_BAR1_OFFSET, 4'hf, data);
		master.config_write(TGT_CONF_ADDR+CONF_BAR1_OFFSET,TGT_BAR1_BASE,4'hF);

		master.config_write(TGT_CONF_ADDR+CONF_BAR2_OFFSET,~0,4'hF);
		master.config_read(TGT_CONF_ADDR+CONF_BAR2_OFFSET, 4'hf, data);
		master.config_write(TGT_CONF_ADDR+CONF_BAR2_OFFSET,TGT_BAR2_BASE,4'hF);

		master.config_write(TGT_CONF_ADDR+CONF_CLINE_OFFSET,32'h0000_4010,4'h3);
		//master.config_read(TGT_CONF_ADDR+CONF_CLINE_OFFSET, 4'hf, data);

		master.config_read(TGT_CONF_ADDR+CONF_MISC_OFFSET, 4'hf, data);

		master.config_write(TGT_CONF_ADDR+CONF_CTRL_OFFSET, 32'h35F, 4'h3);
	end
endtask

initial
begin:TEST
	integer i;
	reg [31:0] data;

	intr_req_i = 4'h0;

	#1000;

	config_target();

	#10_000;

	master.memory_write(TGT_BAR0_BASE, 32'hdeadbeef, 4'hF);

	master.memory_read(TGT_BAR0_BASE, 4'hf, data); 

	master.memory_write(TGT_BAR0_BASE, 32'h000000dd, 4'b0001);
	master.memory_write(TGT_BAR0_BASE, 32'h0000cc00, 4'b0010);
	master.memory_write(TGT_BAR0_BASE, 32'h00bb0000, 4'b0100);
	master.memory_write(TGT_BAR0_BASE, 32'haa000000, 4'b1000);

	master.memory_read(TGT_BAR0_BASE, 4'b0001, data); 
	master.memory_read(TGT_BAR0_BASE, 4'b0010, data); 
	master.memory_read(TGT_BAR0_BASE, 4'b0100, data); 
	master.memory_read(TGT_BAR0_BASE, 4'b1000, data); 

	master.memory_write(TGT_BAR0_BASE, 32'h0000face, 4'b0011);
	master.memory_write(TGT_BAR0_BASE, 32'h0ace0000, 4'b1100);

	master.memory_read(TGT_BAR0_BASE, 4'b0011, data); 
	master.memory_read(TGT_BAR0_BASE, 4'b1100, data); 

	master.io_write(TGT_BAR2_BASE, 32'h11223344, 4'hF);

	master.io_read(TGT_BAR2_BASE, 4'hf, data); 

	master.io_write(TGT_BAR2_BASE, 32'h000000dd, 4'b0001);
	master.io_write(TGT_BAR2_BASE, 32'h0000cc00, 4'b0010);
	master.io_write(TGT_BAR2_BASE, 32'h00bb0000, 4'b0100);
	master.io_write(TGT_BAR2_BASE, 32'haa000000, 4'b1000);

	master.io_read(TGT_BAR2_BASE, 4'b0001, data); 
	master.io_read(TGT_BAR2_BASE, 4'b0010, data); 
	master.io_read(TGT_BAR2_BASE, 4'b0100, data); 
	master.io_read(TGT_BAR2_BASE, 4'b1000, data); 

	master.io_write(TGT_BAR2_BASE, 32'h0000face, 4'b0011);
	master.io_write(TGT_BAR2_BASE, 32'h0ace0000, 4'b1100);

	master.io_read(TGT_BAR2_BASE, 4'b0011, data); 
	master.io_read(TGT_BAR2_BASE, 4'b1100, data); 

	#10_000;

	aximaster.set_id(0);
	for(i=0;i<256;i=i+1) begin
		aximaster.set_write_data(i,i);
		aximaster.set_write_strb(i,4'b1111);
	end

	aximaster.write(32'h0000_0000, 1);
	aximaster.write(32'h0100_0000, 2);
	aximaster.write(32'h0200_0000, 4);
	aximaster.write(32'h0400_0000, 7);
	aximaster.write(32'h0800_0000, 8);
	aximaster.write(32'h0B00_0000, 15);
	aximaster.write(32'h0C00_0000, 16);
	aximaster.write(32'h0D00_0000, 32);
	aximaster.write(32'h0E00_0000, 64);
	aximaster.write(32'h0F00_0000, 128);
	aximaster.wait_for_write();
	#10_000;
	host.disconnect=16;
	aximaster.write(32'h0000_0000, 128);
	aximaster.wait_for_write();

	#20_000;

	//host.disconnect=8'hFF;

	aximaster.read(32'h0000_0000, 1);
	#10_000;
	aximaster.read(32'h0100_0000, 2);
	#10_000;
	aximaster.read(32'h0200_0000, 3);
	#10_000;
	aximaster.read(32'h0300_0000, 8);
	#10_000;
	aximaster.read(32'h0400_0000, 16);
	#10_000;
	aximaster.read(32'h0500_0000, 32);
	#10_000;
	aximaster.read(32'h0600_0000, 64);
	#10_000;
	aximaster.read(32'h0700_0000, 128);
	#10_000;

	$stop;
end

endmodule
