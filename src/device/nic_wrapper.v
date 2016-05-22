module nic_wrapper(
	input RST,
	input CLK,	
	input [31:0] ADDR,
	input ADDR_VLD,
	input [7:0] BASE_HIT,
	output [31:0] ADIO_IN,
	input [31:0] ADIO_OUT,
	output S_TERM,
	output S_READY,
	output S_ABORT,
	input S_WRDN,
	input S_SRC_EN,
	input S_DATA,
	input S_DATA_VLD,
	input [3:0] S_CBE,
	output INT_N,
	output REQUEST,
	output REQUESTHOLD,
	output [3:0] M_CBE,
	output M_WRDN,
	output COMPLETE,
	output M_READY,
	input M_DATA_VLD,
	input M_SRC_EN,
	input TIME_OUT,
	input M_DATA,
	input M_ADDR_N,
	input STOPQ_N,

	input [7:0] cacheline_size,

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
parameter DEBUG="FALSE";

wire nic_clk;
wire nic_rst;

wire clk_locked;

wire nic_intr_req;
wire nic_rst_req;

wire nic_aclk;
wire nic_aresetn;
wire nic_s_awvalid;
wire nic_s_awready;
wire [31:0] nic_s_awaddr;
wire nic_s_wvalid;
wire nic_s_wready;
wire [31:0] nic_s_wdata;
wire [3:0] nic_s_wstrb;
wire nic_s_bvalid;
wire nic_s_bready;
wire [1:0] nic_s_bresp;
wire nic_s_arvalid;
wire nic_s_arready;
wire [31:0] nic_s_araddr;
wire nic_s_rvalid;
wire nic_s_rready;
wire [31:0] nic_s_rdata;
wire [1:0] nic_s_rresp;

wire [3:0] nic_m_awid;
wire [63:0] nic_m_awaddr;
wire [7:0] nic_m_awlen;
wire [2:0] nic_m_awsize;
wire [1:0] nic_m_awburst;
wire [3:0] nic_m_awcache;
wire nic_m_awvalid;
wire nic_m_awready;
wire [3:0] nic_m_wid;
wire [31:0] nic_m_wdata;
wire [3:0] nic_m_wstrb;
wire nic_m_wlast;
wire nic_m_wvalid;
wire nic_m_wready;
wire [3:0] nic_m_bid;
wire [1:0] nic_m_bresp;
wire nic_m_bvalid;
wire nic_m_bready;
wire [3:0] nic_m_arid;
wire [63:0] nic_m_araddr;
wire [7:0] nic_m_arlen;
wire [2:0] nic_m_arsize;
wire [1:0] nic_m_arburst;
wire [3:0] nic_m_arcache;
wire nic_m_arvalid;
wire nic_m_arready;
wire [3:0] nic_m_rid;
wire [31:0] nic_m_rdata;
wire [1:0] nic_m_rresp;
wire nic_m_rlast;
wire nic_m_rvalid;
wire nic_m_rready;

wire [31:0] S_ADIO_IN;
wire [31:0] M_ADIO_IN;

reg [6:0] nic_rst_sync;
(* ASYNC_REG = "TRUE" *)
reg [1:0] nic_intr_sync;

assign ADIO_IN = S_DATA?S_ADIO_IN:M_ADIO_IN;
assign INT_N = !nic_intr_sync[1];

assign nic_rst = !nic_rst_sync[6];

assign nic_aclk = nic_clk;
assign nic_aresetn = !nic_rst;
assign nic_areset = nic_rst;

always @(posedge nic_clk, posedge RST)
begin
	if(RST) begin
		nic_rst_sync <= 'b0;
	end
	else if(nic_rst_req || !clk_locked) begin
		nic_rst_sync <= 'b0;
	end
	else if(!nic_rst_sync[6])
		nic_rst_sync <= nic_rst_sync+1;
end

always @(posedge CLK)
begin
	nic_intr_sync <= {nic_intr_sync, nic_intr_req};
end

nic_clk_gen nic_clk_gen_i(
	.reset(RST),
	.clk_in1(CLK),
	.clk_out1(nic_clk),
	.locked(clk_locked)
);

pci_target #(
	.ADDR_VALID_BITS(24)
)
pci_target_i(
	.ADDR(ADDR),
	.ADIO_IN(S_ADIO_IN),
	.ADIO_OUT(ADIO_OUT),
	.ADDR_VLD(ADDR_VLD),
	.BASE_HIT(BASE_HIT),
	.S_TERM(S_TERM),
	.S_READY(S_READY),
	.S_ABORT(S_ABORT),
	.S_WRDN(S_WRDN),
	.S_SRC_EN(S_SRC_EN),
	.S_DATA(S_DATA),
	.S_DATA_VLD(S_DATA_VLD),
	.S_CBE(S_CBE),
	.RST(RST),
	.CLK(CLK),

	.tgt_m_aclk(nic_aclk),
	.tgt_m_aresetn(nic_aresetn),

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

pci_master pci_master_i(
	.ADIO_IN(M_ADIO_IN),
	.ADIO_OUT(ADIO_OUT),
	.REQUEST(REQUEST),
	.REQUESTHOLD(REQUESTHOLD),
	.M_CBE(M_CBE),
	.M_WRDN(M_WRDN),
	.COMPLETE(COMPLETE),
	.M_READY(M_READY),
	.M_DATA_VLD(M_DATA_VLD),
	.M_SRC_EN(M_SRC_EN),
	.TIME_OUT(TIME_OUT),
	.M_DATA(M_DATA),
	.M_ADDR_N(M_ADDR_N),
	.STOPQ_N(STOPQ_N),
	.RST(RST),
	.CLK(CLK),

	.cacheline_size(8'd16),

	.mst_s_aclk(nic_aclk),
	.mst_s_aresetn(nic_aresetn),

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
	.CLK_PERIOD_NS(CLK_PERIOD_NS),
	.DEBUG(DEBUG)
) e1000_i(
	.aclk(nic_aclk),
	.aresetn(nic_aresetn),

	.clk125(nic_clk),

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
	.intr_request(nic_intr_req),
	.reset_request(nic_rst_req),

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
	.mac_txsclk(mac_txsclk),
	.mac_gtxsclk(mac_gtxsclk),
	.mac_crs(mac_crs),
	.mac_col(mac_col),

	// MDIO interface
	.phy_mdc(phy_mdc),
	.phy_mdio_i(phy_mdio_i),
	.phy_mdio_o(phy_mdio_o),
	.phy_mdio_oe(phy_mdio_oe),

	// PHY interrupt
	.phy_int(phy_int),
	.phy_reset_out(phy_reset_out),

	// EEPROM interface
	.eesk(eesk),
	.eecs(eecs),
	.eedo(eedo),
	.eedi(eedi)
);

endmodule
