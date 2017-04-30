module nic_pci_wrapper(
	input clki,
	input rstni,

	input idseli,
	input [31:0] adi,
	output [31:0] ado,
	output adt,
	input [3:0] cbi,
	output [3:0] cbo,
	output cbt,
	input pari,
	output paro,
	output part,
	input framei,
	output frameo,
	output framet,
	input trdyi,
	output trdyo,
	output trdyt,
	input irdyi,
	output irdyo,
	output irdyt,
	input stopi,
	output stopo,
	output stopt,
	input devseli,
	output devselo,
	output devselt,
	input perri,
	output perro,
	output perrt,
	input serri,
	output serro,
	output serrt,
	input locki,
	output locko,
	output lockt,
	input gnti,
	output reqo,
	output reqt,
	input inti,
	output into,
	output intt,
	input pmei,
	output pmeo,
	output pmet,
	input m66eni,

	input [7:0] cacheline_size,

	input	gtxclk,

	// GMII Port
	input	[7:0]	mac_rxdat,
	input	mac_rxdv,
	input	mac_rxer,
	input	mac_rxsclk,
	output	[7:0]	mac_txdat,
	output	mac_txen,
	output	mac_txer,
	output	mac_gtxsclk,
	input	mac_crs,
	input	mac_col,

	output  mac_rx_err_flag,
	output	mac_rx_ok_flag,

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

	// GPI Input
	input  sdp6_data,
	input  sdp7_data,

	// EEPROM Port
	output	eesk,
	output	eecs,
	input	eedo,
	output	eedi
);

parameter VENDORID = 16'h8086; // Intel
parameter DEVICEID = 16'h0050; // 82540
parameter SUBVID = 16'h10EE; 
parameter SUBSYSID = 16'h0050; 
parameter CLASSCODE = 24'h020000;
parameter PHY_ADDR=5'b0;
parameter CLK_PERIOD_NS=8;

wire nic_clk;
wire nic_rst;

wire clk_locked;

(* MARK_DEBUG="TRUE" *) wire intr_request;
(* MARK_DEBUG="TRUE" *) wire rst_request;

wire aclk;
wire aresetn;
(* MARK_DEBUG="TRUE" *) wire nic_s_awvalid;
(* MARK_DEBUG="TRUE" *) wire nic_s_awready;
(* MARK_DEBUG="TRUE" *) wire [31:0] nic_s_awaddr;
(* MARK_DEBUG="TRUE" *) wire nic_s_wvalid;
(* MARK_DEBUG="TRUE" *) wire nic_s_wready;
(* MARK_DEBUG="TRUE" *) wire [31:0] nic_s_wdata;
(* MARK_DEBUG="TRUE" *) wire [3:0] nic_s_wstrb;
(* MARK_DEBUG="TRUE" *) wire nic_s_bvalid;
(* MARK_DEBUG="TRUE" *) wire nic_s_bready;
(* MARK_DEBUG="TRUE" *) wire [1:0] nic_s_bresp;
(* MARK_DEBUG="TRUE" *) wire nic_s_arvalid;
(* MARK_DEBUG="TRUE" *) wire nic_s_arready;
(* MARK_DEBUG="TRUE" *) wire [31:0] nic_s_araddr;
(* MARK_DEBUG="TRUE" *) wire [3:0] nic_s_aruser;
(* MARK_DEBUG="TRUE" *) wire nic_s_rvalid;
(* MARK_DEBUG="TRUE" *) wire nic_s_rready;
(* MARK_DEBUG="TRUE" *) wire [31:0] nic_s_rdata;
(* MARK_DEBUG="TRUE" *) wire [1:0] nic_s_rresp;

(* MARK_DEBUG="TRUE" *) wire [3:0] nic_m_awid;
(* MARK_DEBUG="TRUE" *) wire [63:0] nic_m_awaddr;
(* MARK_DEBUG="TRUE" *) wire [7:0] nic_m_awlen;
(* MARK_DEBUG="TRUE" *) wire [2:0] nic_m_awsize;
(* MARK_DEBUG="TRUE" *) wire [1:0] nic_m_awburst;
(* MARK_DEBUG="TRUE" *) wire [3:0] nic_m_awcache;
(* MARK_DEBUG="TRUE" *) wire nic_m_awvalid;
(* MARK_DEBUG="TRUE" *) wire nic_m_awready;
(* MARK_DEBUG="TRUE" *) wire [3:0] nic_m_wid;
(* MARK_DEBUG="TRUE" *) wire [31:0] nic_m_wdata;
(* MARK_DEBUG="TRUE" *) wire [3:0] nic_m_wstrb;
(* MARK_DEBUG="TRUE" *) wire nic_m_wlast;
(* MARK_DEBUG="TRUE" *) wire nic_m_wvalid;
(* MARK_DEBUG="TRUE" *) wire nic_m_wready;
(* MARK_DEBUG="TRUE" *) wire [3:0] nic_m_bid;
(* MARK_DEBUG="TRUE" *) wire [1:0] nic_m_bresp;
(* MARK_DEBUG="TRUE" *) wire nic_m_bvalid;
(* MARK_DEBUG="TRUE" *) wire nic_m_bready;
(* MARK_DEBUG="TRUE" *) wire [3:0] nic_m_arid;
(* MARK_DEBUG="TRUE" *) wire [63:0] nic_m_araddr;
(* MARK_DEBUG="TRUE" *) wire [7:0] nic_m_arlen;
(* MARK_DEBUG="TRUE" *) wire [2:0] nic_m_arsize;
(* MARK_DEBUG="TRUE" *) wire [1:0] nic_m_arburst;
(* MARK_DEBUG="TRUE" *) wire [3:0] nic_m_arcache;
(* MARK_DEBUG="TRUE" *) wire nic_m_arvalid;
(* MARK_DEBUG="TRUE" *) wire nic_m_arready;
(* MARK_DEBUG="TRUE" *) wire [3:0] nic_m_rid;
(* MARK_DEBUG="TRUE" *) wire [31:0] nic_m_rdata;
(* MARK_DEBUG="TRUE" *) wire [1:0] nic_m_rresp;
(* MARK_DEBUG="TRUE" *) wire nic_m_rlast;
(* MARK_DEBUG="TRUE" *) wire nic_m_rvalid;
(* MARK_DEBUG="TRUE" *) wire nic_m_rready;

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
wire ahb_slv_hmastlock;
wire ahb_slv_hready;
wire [1:0] ahb_slv_hresp;
wire [31:0] ahb_slv_hrdata;
wire [15:0] ahb_slv_hsplit;

wire intr_req;

wire hclk;
wire hresetn;

reg [6:0] rst_sync;
(* ASYNC_REG = "TRUE" *)
reg [1:0] intr_sync;

reg [1:0] ahb_rst_sync;

assign intr_req = intr_sync[1];

assign aclk = nic_clk;
assign aresetn = rst_sync[6];
assign areset = !aresetn;

assign hclk = nic_clk;
assign hresetn = ahb_rst_sync[1];

always @(posedge aclk, negedge rstni)
begin
	if(!rstni) begin
		rst_sync <= 'b0;
	end
	else if(rst_request || !clk_locked) begin
		rst_sync <= 'b0;
	end
	else if(!rst_sync[6])
		rst_sync <= rst_sync+1;
end

always @(posedge hclk, negedge rstni)
begin
	if(!rstni)
		ahb_rst_sync <= 'b0;
	else if(!clk_locked) 
		ahb_rst_sync <= 'b0;
	else
		ahb_rst_sync <= {ahb_rst_sync, 1'b1};
end

always @(posedge clki)
begin
	intr_sync <= {intr_sync, intr_request};
end

nic_clk_gen nic_clk_gen_i(
	.reset(!rstni),
	.clk_in1(clki),
	.clk_out1(nic_clk),
	.locked(clk_locked)
);

grpci2_device #(
	.oepol(0),
	.vendorid(VENDORID),
	.deviceid(DEVICEID),
	.subsysid(SUBSYSID),
	.subvid(SUBVID),
	.classcode(CLASSCODE),
	.barminsize(6),
	.fifo_depth(4),
	.bar0(17), // 128K Byte memory mapped register space
	.bar1(17), // 128K Byte mempry mapped Flash space
	.bar2(3), // 8 Byte IO mapped indirect register access
	.bar3(0),
	.bar4(0),
	.bar5(0),
	.bar0_map(24'h010000),
	.bar1_map(24'h020000),
	.bar2_map(24'h040000),
	.bar3_map(24'h080000),
	.bar4_map(24'h100000),
	.bar5_map(24'h200000),
	.bartype(14'b00000100_00000000)
)
pci_i (
	.pci_rst(rstni),
	.pci_clk(clki),
	.pci_gnt(gnti),
	.pci_idsel(idseli),
	.pci_lock_i(locki),
	.pci_lock_o(locko),
	.pci_lock_oe(lockt),
	.pci_ad_i(adi),
	.pci_ad_o(ado),
	.pci_ad_oe(adt),
	.pci_cbe_i(cbi),
	.pci_cbe_o(cbo),
	.pci_cbe_oe(cbt),
	.pci_frame_i(framei),
	.pci_frame_o(frameo),
	.pci_frame_oe(framet),
	.pci_irdy_i(irdyi),
	.pci_irdy_o(irdyo),
	.pci_irdy_oe(irdyt),
	.pci_trdy_i(trdyi),
	.pci_trdy_o(trdyo),
	.pci_trdy_oe(trdyt),
	.pci_devsel_i(devseli),
	.pci_devsel_o(devselo),
	.pci_devsel_oe(devselt),
	.pci_stop_i(stopi),
	.pci_stop_o(stopo),
	.pci_stop_oe(stopt),
	.pci_perr_i(perri),
	.pci_perr_o(perro),
	.pci_perr_oe(perrt),
	.pci_par_i(pari),
	.pci_par_o(paro),
	.pci_par_oe(part),
	.pci_req_o(reqo),
	.pci_req_oe(reqt),
	.pci_serr_i(serri),
	.pci_serr_o(serro),
	.pci_serr_oe(serrt),
	.pci_int_i({3'b111,inti}),
	.pci_int_o(into),
	.pci_int_oe(intt),
	.pci_m66en(m66eni),
	.pci_pme_i(pmei),
	.pci_pme_o(pmeo),
	.pci_pme_oe(pmet),

	.ahb_hclk(hclk),
	.ahb_hresetn(hresetn),

	.ahb_mst_hgrant(1'b1),
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
	.ahb_slv_hmaster(4'b0),
	.ahb_slv_hmastlock(ahb_slv_hmastlock),
	.ahb_slv_hready_i(ahb_slv_hready),
	.ahb_slv_hready_o(ahb_slv_hready),
	.ahb_slv_hresp(ahb_slv_hresp),
	.ahb_slv_hrdata(ahb_slv_hrdata),
	.ahb_slv_hsplit(ahb_slv_hsplit),

	.intr_req({3'b000,intr_req})
);

grpci2_axi_lite_tgt tgt_i(
	.aclk(aclk),
	.aresetn(aresetn),

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

	.tgt_m_awvalid(nic_s_awvalid),
	.tgt_m_awready(nic_s_awready),
	.tgt_m_awaddr(nic_s_awaddr),

	.tgt_m_wvalid(nic_s_wvalid),
	.tgt_m_wready(nic_s_wready),
	.tgt_m_wdata(nic_s_wdata),
	.tgt_m_wstrb(nic_s_wstrb),

	.tgt_m_bvalid(nic_s_bvalid),
	.tgt_m_bready(nic_s_bready),
	.tgt_m_bresp(nic_s_bresp),

	.tgt_m_arvalid(nic_s_arvalid),
	.tgt_m_arready(nic_s_arready),
	.tgt_m_araddr(nic_s_araddr),
	.tgt_m_aruser(nic_s_aruser),

	.tgt_m_rvalid(nic_s_rvalid),
	.tgt_m_rready(nic_s_rready),
	.tgt_m_rdata(nic_s_rdata),
	.tgt_m_rresp(nic_s_rresp)
);

grpci2_axi_mst mst_i (
	.ahb_hclk(aclk),
	.ahb_hresetn(aresetn),
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

	.mst_s_aclk(aclk),
	.mst_s_aresetn(aresetn),

	.mst_s_awid(nic_m_awid),
	.mst_s_awaddr(nic_m_awaddr),
	.mst_s_awlen(nic_m_awlen),
	.mst_s_awsize(nic_m_awsize),
	.mst_s_awburst(nic_m_awburst),
	.mst_s_awcache(nic_m_awcache),
	.mst_s_awvalid(nic_m_awvalid),
	.mst_s_awready(nic_m_awready),

	.mst_s_wid(nic_m_wid),
	.mst_s_wdata(nic_m_wdata),
	.mst_s_wstrb(nic_m_wstrb),
	.mst_s_wlast(nic_m_wlast),
	.mst_s_wvalid(nic_m_wvalid),
	.mst_s_wready(nic_m_wready),

	.mst_s_bid(nic_m_bid),
	.mst_s_bresp(nic_m_bresp),
	.mst_s_bvalid(nic_m_bvalid),
	.mst_s_bready(nic_m_bready),

	.mst_s_arid(nic_m_arid),
	.mst_s_araddr(nic_m_araddr),
	.mst_s_arlen(nic_m_arlen),
	.mst_s_arsize(nic_m_arsize),
	.mst_s_arburst(nic_m_arburst),
	.mst_s_arcache(nic_m_arcache),
	.mst_s_arvalid(nic_m_arvalid),
	.mst_s_arready(nic_m_arready),

	.mst_s_rid(nic_m_rid),
	.mst_s_rdata(nic_m_rdata),
	.mst_s_rresp(nic_m_rresp),
	.mst_s_rlast(nic_m_rlast),
	.mst_s_rvalid(nic_m_rvalid),
	.mst_s_rready(nic_m_rready)
);

e1000_top #(
	.PHY_ADDR(PHY_ADDR),
	.CLK_PERIOD_NS(CLK_PERIOD_NS)
) e1000_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.gtxclk(gtxclk),

	// AXI4-lite for memory mapped registers
	.axi_s_awvalid(nic_s_awvalid),
	.axi_s_awready(nic_s_awready),
	.axi_s_awaddr(nic_s_awaddr),

	.axi_s_wvalid(nic_s_wvalid),
	.axi_s_wready(nic_s_wready),
	.axi_s_wdata(nic_s_wdata),
	.axi_s_wstrb(nic_s_wstrb),

	.axi_s_bvalid(nic_s_bvalid),
	.axi_s_bready(nic_s_bready),
	.axi_s_bresp(nic_s_bresp),

	.axi_s_arvalid(nic_s_arvalid),
	.axi_s_arready(nic_s_arready),
	.axi_s_araddr(nic_s_araddr),

	.axi_s_rvalid(nic_s_rvalid),
	.axi_s_rready(nic_s_rready),
	.axi_s_rdata(nic_s_rdata),
	.axi_s_rresp(nic_s_rresp),

	// Interrupt Request
	.intr_request(intr_request),
	.reset_request(rst_request),

	// GPI Input
	.sdp6_data(sdp6_data),
	.sdp7_data(sdp7_data),

	// AXI4 for DMA
	.axi_m_awid(nic_m_awid),
	.axi_m_awaddr(nic_m_awaddr),
	.axi_m_awlen(nic_m_awlen),
	.axi_m_awsize(nic_m_awsize),
	.axi_m_awburst(nic_m_awburst),
	.axi_m_awcache(nic_m_awcache),
	.axi_m_awvalid(nic_m_awvalid),
	.axi_m_awready(nic_m_awready),

	.axi_m_wid(nic_m_wid),
	.axi_m_wdata(nic_m_wdata),
	.axi_m_wstrb(nic_m_wstrb),
	.axi_m_wlast(nic_m_wlast),
	.axi_m_wvalid(nic_m_wvalid),
	.axi_m_wready(nic_m_wready),

	.axi_m_bid(nic_m_bid),
	.axi_m_bresp(nic_m_bresp),
	.axi_m_bvalid(nic_m_bvalid),
	.axi_m_bready(nic_m_bready),

	.axi_m_arid(nic_m_arid),
	.axi_m_araddr(nic_m_araddr),
	.axi_m_arlen(nic_m_arlen),
	.axi_m_arsize(nic_m_arsize),
	.axi_m_arburst(nic_m_arburst),
	.axi_m_arcache(nic_m_arcache),
	.axi_m_arvalid(nic_m_arvalid),
	.axi_m_arready(nic_m_arready),

	.axi_m_rid(nic_m_rid),
	.axi_m_rdata(nic_m_rdata),
	.axi_m_rresp(nic_m_rresp),
	.axi_m_rlast(nic_m_rlast),
	.axi_m_rvalid(nic_m_rvalid),
	.axi_m_rready(nic_m_rready),

	// GMII interface
	.mac_rxdat(mac_rxdat),
	.mac_rxdv(mac_rxdv),
	.mac_rxer(mac_rxer),
	.mac_rxsclk(mac_rxsclk),
	.mac_txdat(mac_txdat),
	.mac_txen(mac_txen),
	.mac_txer(mac_txer),
	.mac_gtxsclk(mac_gtxsclk),
	.mac_crs(mac_crs),
	.mac_col(mac_col),

	.mac_rx_err_flag(mac_rx_err_flag),
	.mac_rx_ok_flag(mac_rx_ok_flag),

	// MDIO interface
	.phy_mdc(phy_mdc),
	.phy_mdio_i(phy_mdio_i),
	.phy_mdio_o(phy_mdio_o),
	.phy_mdio_oe(phy_mdio_oe),
	.phy_mdio_req(phy_mdio_req),
	.phy_mdio_gnt(phy_mdio_gnt),

	// PHY interrupt
	.phy_int(phy_int),
	.phy_reset_out(phy_reset_out),
	.phy_speed(phy_speed),
	.phy_duplex(phy_duplex),
	.phy_up(phy_up),
	.phy_lsc(phy_lsc),

	// EEPROM interface
	.eesk(eesk),
	.eecs(eecs),
	.eedo(eedo),
	.eedi(eedi)
);

endmodule
