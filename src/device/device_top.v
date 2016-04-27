module device_top(
	// PCI Local Bus
	inout	[31:0] AD,
	inout   [3:0] CBE,
	inout         PAR,
	inout         FRAME_N,
	inout         TRDY_N,
	inout         IRDY_N,
	inout         STOP_N,
	inout         DEVSEL_N,
	input         IDSEL,
	inout         PERR_N,
	inout         SERR_N,
	output        INTA_N,
	output        PMEA_N,
	output        REQ_N,
	input         GNT_N,
	input         RST_N,
	input         PCLK,
	//  output        FPGA_RTR,
	//  output        FPGA_RST,
	output	PCI_EN_N,

	// Ethernet 0 GMII
	input	[7:0]	p0_rxdat,
	input	p0_rxdv,
	input	p0_rxer,
	input	p0_rxsclk,
	output	[7:0]	p0_txdat,
	output	p0_txen,
	output	p0_txer,
	input	p0_txsclk,
	output	p0_gtxsclk,
	input	p0_crs,
	input	p0_col,
	output	p0_mdc,
	inout	p0_mdio,
	input	p0_int,
	output	p0_resetn,

	// Ethernet 1 GMII
	input	[7:0]	p1_rxdat,
	input	p1_rxdv,
	input	p1_rxer,
	input	p1_rxsclk,
	output	[7:0]	p1_txdat,
	output	p1_txen,
	output	p1_txer,
	input	p1_txsclk,
	output	p1_gtxsclk,
	input	p1_crs,
	input	p1_col,
	output	p1_mdc,
	inout	p1_mdio,
	input	p1_int,
	output	p1_resetn,

	// CAN 0
	input	can0_rx,
	output	can0_tx,
	output  can0_rs,

	// CAN 1
	input	can1_rx,
	output	can1_tx,
	output  can1_rs,

	// UART 0
	input	uart0_rx,
	output	uart0_rxen_n,
	output	uart0_tx,
	output	uart0_txen,

	// UART 1
	input	uart1_rx,
	output	uart1_rxen_n,
	output	uart1_tx,
	output	uart1_txen,

	// UART 2
	input	uart2_rx,
	output	uart2_rxen_n,
	output	uart2_tx,
	output	uart2_txen,

	// UART 3
	input	uart3_rx,
	output	uart3_rxen_n,
	output	uart3_tx,
	output	uart3_txen
);

// Workaround for hardwares with no IDSEL fanout
parameter HARDWIRE_IDSEL=24; 
// Workaround for hardwares with different PHY address 
// Default PHY address in e1000 is 5'b00001
// Change this according to hardware design
parameter PHY_ADDR=5'b0;
parameter NIC_CLK_PERIOD_NS=8;
parameter DEBUG="TRUE";

wire ext_clk;
wire ext_rst;

wire nic_clk;
wire nic_rst;

wire clk_locked;

wire cfg_s_aclk;
wire cfg_s_aresetn;
wire cfg_s_awvalid;
wire cfg_s_awready;
wire [31:0] cfg_s_awaddr;
wire cfg_s_wvalid;
wire cfg_s_wready;
wire [31:0] cfg_s_wdata;
wire [3:0] cfg_s_wstrb;
wire cfg_s_bvalid;
wire cfg_s_bready;
wire [1:0] cfg_s_bresp;
wire cfg_s_arvalid;
wire cfg_s_arready;
wire [31:0] cfg_s_araddr;
wire cfg_s_rvalid;
wire cfg_s_rready;
wire [31:0] cfg_s_rdata;
wire [1:0] cfg_s_rresp;

wire tgt_m_aclk;
wire tgt_m_aresetn;
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
wire tgt_m_arready;
wire [31:0] tgt_m_araddr;
wire tgt_m_rvalid;
wire tgt_m_rready;
wire [31:0] tgt_m_rdata;
wire [1:0] tgt_m_rresp;

wire intr_request;

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

wire	[7:0]	mac_rxdat;
wire	mac_rxdv;
wire	mac_rxer;
wire	mac_rxsclk;
wire	[7:0]	mac_txdat;
wire	mac_txen;
wire	mac_txer;
wire	mac_txsclk;
wire	mac_gtxsclk;
wire	mac_crs;
wire	mac_col;

wire	phy_mdc;
wire	phy_mdio_i;
wire	phy_mdio_o;
wire	phy_mdio_oe;
wire	phy_int;
wire	phy_reset_out;

wire	p0_mdio_i;
wire	p0_mdio_o;
wire	p0_mdio_oe;

wire	p0_reset_out;

wire	p1_mdio_i;
wire	p1_mdio_o;
wire	p1_mdio_oe;

wire	p1_reset_out;

wire	eesk;
wire	eecs;
wire	eedo;
wire	eedi;

wire	[7:0] eeprom_raddr;
wire	eeprom_ren;
wire	[15:0] eeprom_rdata;

wire can_s_aclk;
wire can_s_aresetn;
wire can_s_awvalid;
wire can_s_awready;
wire [31:0] can_s_awaddr;
wire can_s_wvalid;
wire can_s_wready;
wire [31:0] can_s_wdata;
wire [3:0] can_s_wstrb;
wire can_s_bvalid;
wire can_s_bready;
wire [1:0] can_s_bresp;
wire can_s_arvalid;
wire can_s_arready;
wire [31:0] can_s_araddr;
wire can_s_rvalid;
wire can_s_rready;
wire [31:0] can_s_rdata;
wire [1:0] can_s_rresp;

wire can0_bus_off_on;
wire can1_bus_off_on;

wire uart_s_aclk;
wire uart_s_aresetn;
wire uart_s_awvalid;
wire uart_s_awready;
wire [31:0] uart_s_awaddr;
wire uart_s_wvalid;
wire uart_s_wready;
wire [31:0] uart_s_wdata;
wire [3:0] uart_s_wstrb;
wire uart_s_bvalid;
wire uart_s_bready;
wire [1:0] uart_s_bresp;
wire uart_s_arvalid;
wire uart_s_arready;
wire [31:0] uart_s_araddr;
wire uart_s_rvalid;
wire uart_s_rready;
wire [31:0] uart_s_rdata;
wire [1:0] uart_s_rresp;

//wire uart0_tx;
//wire uart0_rx;
wire uart0_rts;
wire uart0_cts;
wire uart0_dtr;
wire uart0_dsr;
wire uart0_ri;
wire uart0_dcd;

//wire uart1_tx;
//wire uart1_rx;
wire uart1_rts;
wire uart1_cts;
wire uart1_dtr;
wire uart1_dsr;
wire uart1_ri;
wire uart1_dcd;

//wire uart2_tx;
//wire uart2_rx;
wire uart2_rts;
wire uart2_cts;
wire uart2_dtr;
wire uart2_dsr;
wire uart2_ri;
wire uart2_dcd;

//wire uart3_tx;
//wire uart3_rx;
wire uart3_rts;
wire uart3_cts;
wire uart3_dtr;
wire uart3_dsr;
wire uart3_ri;
wire uart3_dcd;

reg nic_rst_r;

assign PCI_EN_N = 1'b0;

assign can0_tx = 1'b0;
assign can0_rs = 1'b0;
assign can1_tx = 1'b0;
assign can1_rs = 1'b0;

assign uart0_rxen_n = 1'b0;
assign uart0_tx = 1'b1;
assign uart0_txen = 1'b1;

assign uart1_rxen_n = 1'b0;
assign uart1_tx = 1'b1;
assign uart1_txen = 1'b1;

assign uart2_rxen_n = 1'b0;
assign uart2_tx = 1'b1;
assign uart2_txen = 1'b1;

assign uart3_rxen_n = 1'b0;
assign uart3_tx = 1'b1;
assign uart3_txen = 1'b1;

assign	p0_mdio = p0_mdio_oe?p0_mdio_o:1'bz;
assign  p0_mdio_i = p0_mdio;
assign	p0_resetn = !p0_reset_out;
assign	p1_mdio = p1_mdio_oe?p1_mdio_o:1'bz;
assign  p1_mdio_i = p1_mdio;
assign	p1_resetn = !p1_reset_out;

//FIXIT: Only P0 implemented currently
assign p0_mdc = phy_mdc;
assign p0_mdio_o = phy_mdio_o;
assign p0_mdio_oe = phy_mdio_oe;
assign p0_reset_out = phy_reset_out;
assign phy_mdio_i = p0_mdio_i;
assign phy_int = p0_int;

assign p1_mdc = 1'b0;
assign p1_mdio_o = 1'b0;
assign p1_mdio_oe = 1'b0;
assign p1_reset_out = 1'b1;

//FIXIT: Configuration access not implemented
assign cfg_s_awvalid = 1'b0;
assign cfg_s_wvalid = 1'b0;
assign cfg_s_bready = 1'b0;
assign cfg_s_arvalid = 1'b0;
assign cfg_s_rready = 1'b0;

// Wire PCI Target to NIC
assign nic_s_awvalid = tgt_m_awvalid;
assign nic_s_awaddr = tgt_m_awaddr;
assign tgt_m_awready = nic_s_awready;

assign nic_s_wvalid = tgt_m_wvalid;
assign nic_s_wdata = tgt_m_wdata;
assign nic_s_wstrb = tgt_m_wstrb;
assign tgt_m_wready = nic_s_wready;

assign tgt_m_bvalid = nic_s_bvalid;
assign tgt_m_bresp = nic_s_bresp;
assign nic_s_bready = tgt_m_bready;

assign nic_s_arvalid = tgt_m_arvalid;
assign nic_s_araddr = tgt_m_araddr;
assign tgt_m_arready = nic_s_arready;

assign tgt_m_rvalid = nic_s_rvalid;
assign tgt_m_rdata = nic_s_rdata;
assign tgt_m_rresp = nic_s_rresp;
assign nic_s_rready = tgt_m_rready;

assign mst_s_awid = nic_m_awid;
assign mst_s_awaddr = nic_m_awaddr;
assign mst_s_awlen = nic_m_awlen;
assign mst_s_awsize = nic_m_awsize;
assign mst_s_awburst = nic_m_awburst;
assign mst_s_awcache = nic_m_awcache;
assign mst_s_awvalid = nic_m_awvalid;
assign nic_m_awready = mst_s_awready;

assign mst_s_wid = nic_m_wid;
assign mst_s_wdata = nic_m_wdata;
assign mst_s_wstrb = nic_m_wstrb;
assign mst_s_wlast = nic_m_wlast;
assign mst_s_wvalid = nic_m_wvalid;
assign nic_m_wready = mst_s_wready;

assign nic_m_bid = mst_s_bid;
assign nic_m_bresp = mst_s_bresp;
assign nic_m_bvalid = mst_s_bvalid;
assign mst_s_bready = nic_m_bready;

assign mst_s_arid = nic_m_arid;
assign mst_s_araddr = nic_m_araddr;
assign mst_s_arlen = nic_m_arlen;
assign mst_s_arsize = nic_m_arsize;
assign mst_s_arburst = nic_m_arburst;
assign mst_s_arcache = nic_m_arcache;
assign mst_s_arvalid = nic_m_arvalid;
assign nic_m_arready = mst_s_arready;

assign nic_m_rid = mst_s_rid;
assign nic_m_rdata = mst_s_rdata;
assign nic_m_rresp = mst_s_rresp;
assign nic_m_rlast = mst_s_rlast;
assign nic_m_rvalid = mst_s_rvalid;
assign mst_s_rready = nic_m_rready;

assign mac_rxdat = p0_rxdat;
assign mac_rxdv = p0_rxdv;
assign mac_rxer = p0_rxer;
assign mac_rxsclk = p0_rxsclk;
assign mac_txsclk = p0_txsclk;
assign mac_crs = p0_crs;
assign mac_col = p0_col;
assign p0_txdat = mac_txdat;
assign p0_txen = mac_txen;
assign p0_txer = mac_txer;
assign p0_gtxsclk = mac_gtxsclk;

assign p1_txdat = 'b0;
assign p1_txen = 1'b0;
assign p1_txer = 1'b0;
assign p1_gtxsclk = 1'b0;

assign nic_rst = nic_rst_r;

assign cfg_s_aclk = nic_clk;
assign cfg_s_aresetn = !nic_rst;

assign tgt_m_aclk = nic_clk;
assign tgt_m_aresetn = !nic_rst;

assign nic_aclk = nic_clk;
assign nic_aresetn = !nic_rst;
assign nic_areset = nic_rst;

assign mst_s_aclk = nic_clk;
assign mst_s_aresetn = !nic_rst;

always @(posedge nic_clk, posedge ext_rst)
begin
	if(ext_rst) begin
		nic_rst_r <= 1'b1;
	end
	else if(clk_locked) begin
		nic_rst_r <= 1'b0;
	end
end

nic_clk_gen nic_clk_gen_i(
	.reset(ext_rst),
	.clk_in1(ext_clk),
	.clk_out1(nic_clk),
	.locked(clk_locked)
);

// PCI to AXI interface controller
pci_axi_top #(.HARDWIRE_IDSEL(HARDWIRE_IDSEL))pci_axi_i(
	// PCI Local Bus
	.AD(AD),
	.CBE(CBE),
	.PAR(PAR),
	.FRAME_N(FRAME_N),
	.TRDY_N(TRDY_N),
	.IRDY_N(IRDY_N),
	.STOP_N(STOP_N),
	.DEVSEL_N(DEVSEL_N),
	.IDSEL(IDSEL),
	.PERR_N(PERR_N),
	.SERR_N(SERR_N),
	.INTA_N(INTA_N),
	.PMEA_N(PMEA_N),
	.REQ_N(REQ_N),
	.GNT_N(GNT_N),
	.RST_N(RST_N),
	.PCLK(PCLK),

	// Misc
	.clock_out(ext_clk),
	.reset_out(ext_rst),

	// AXI4-Lite for extended configuration space
	.cfg_s_aclk(cfg_s_aclk),
	.cfg_s_aresetn(cfg_s_aresetn),

	.cfg_s_awvalid(cfg_s_awvalid),
	.cfg_s_awready(cfg_s_awready),
	.cfg_s_awaddr(cfg_s_awaddr),

	.cfg_s_wvalid(cfg_s_wvalid),
	.cfg_s_wready(cfg_s_wready),
	.cfg_s_wdata(cfg_s_wdata),
	.cfg_s_wstrb(cfg_s_wstrb),

	.cfg_s_bvalid(cfg_s_bvalid),
	.cfg_s_bready(cfg_s_bready),
	.cfg_s_bresp(cfg_s_bresp),

	.cfg_s_arvalid(cfg_s_arvalid),
	.cfg_s_arready(cfg_s_arready),
	.cfg_s_araddr(cfg_s_araddr),

	.cfg_s_rvalid(cfg_s_rvalid),
	.cfg_s_rready(cfg_s_rready),
	.cfg_s_rdata(cfg_s_rdata),
	.cfg_s_rresp(cfg_s_rresp),

	// AXI4-lite for Target access
	.tgt_m_aclk(tgt_m_aclk),
	.tgt_m_aresetn(tgt_m_aresetn),

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
	.tgt_m_arready(tgt_m_arready),
	.tgt_m_araddr(tgt_m_araddr),
	.tgt_m_aruser(),

	.tgt_m_rvalid(tgt_m_rvalid),
	.tgt_m_rready(tgt_m_rready),
	.tgt_m_rdata(tgt_m_rdata),
	.tgt_m_rresp(tgt_m_rresp),

	// AXI4 for Initiater access
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
	.mst_s_rready(mst_s_rready),

	.intr_request(intr_request)

);

e1000_top #(
	.PHY_ADDR(PHY_ADDR),
	.CLK_PERIOD_NS(NIC_CLK_PERIOD_NS)

) e1000_i(
	.aclk(nic_aclk),
	.aresetn(nic_aresetn),

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

// Dual redundancy fault-tolerant
/*
phy_ft phy_ft_i(
	.clk_i(nic_clk),
	.rst_i(nic_rst),

	.rxdat(mac_rxdat),
	.rxdv(mac_rxdv),
	.rxer(mac_rxer),
	.rxsclk(mac_rxsclk),
	.txdat(mac_txdat),
	.txen(mac_txen),
	.txer(mac_txer),
	.txsclk(mac_txsclk),
	.gtxsclk(mac_gtxsclk),
	.crs(mac_crs),
	.col(mac_col),
	.mdc(phy_mdc),
	.mdio_i(phy_mdio_o),
	.mdio_o(phy_mdio_i),
	.mdio_oe(phy_mdio_oe),
	.int(phy_int),
	.reset_in(phy_reset_out),

	.phy0_rxdat(p0_rxdat),
	.phy0_rxdv(p0_rxdv),
	.phy0_rxer(p0_rxer),
	.phy0_rxsclk(p0_rxsclk),
	.phy0_txdat(p0_txdat),
	.phy0_txen(p0_txen),
	.phy0_txer(p0_txer),
	.phy0_txsclk(p0_txsclk),
	.phy0_gtxsclk(p0_gtxsclk),
	.phy0_crs(p0_crs),
	.phy0_col(p0_col),
	.phy0_mdc(p0_mdc),
	.phy0_mdio_i(p0_mdio_i),
	.phy0_mdio_o(p0_mdio_o),
	.phy0_mdio_oe(p0_mdio_oe),
	.phy0_int(p0_int),
	.phy0_reset_out(p0_reset_out),

	.phy1_rxdat(p1_rxdat),
	.phy1_rxdv(p1_rxdv),
	.phy1_rxer(p1_rxer),
	.phy1_rxsclk(p1_rxsclk),
	.phy1_txdat(p1_txdat),
	.phy1_txen(p1_txen),
	.phy1_txer(p1_txer),
	.phy1_txsclk(p1_txsclk),
	.phy1_gtxsclk(p1_gtxsclk),
	.phy1_crs(p1_crs),
	.phy1_col(p1_col),
	.phy1_mdc(p1_mdc),
	.phy1_mdio_i(p1_mdio_i),
	.phy1_mdio_o(p1_mdio_o),
	.phy1_mdio_oe(p1_mdio_oe),
	.phy1_int(p1_int),
	.phy1_reset_out(p1_reset_out),
);
*/

eeprom_emu eeprom_emu_i(
	.clk_i(nic_aclk),
	.rst_i(nic_areset),
	.sk_i(eesk),
	.cs_i(eecs),
	.di_i(eedi),
	.do_o(eedo),
	.do_oe_o(),
	.read_addr(eeprom_raddr),
	.read_enable(eeprom_ren),
	.read_data(eeprom_rdata)
);

config_rom rom_i(
	.clk_i(nic_aclk),
	.rst_i(nic_areset),
	.read_addr(eeprom_raddr),
	.read_enable(eeprom_ren),
	.read_data(eeprom_rdata)
);

/*
// EMS CPC-PCI SJA1000 Emulation
ems_cpc_top emc_cpc_i(
	// AXI4-Lite for memory mapped registers
	.axi_s_aclk(can_s_aclk),
	.axi_s_aresetn(can_s_aresetn),

	.axi_s_awvalid(can_s_awvalid),
	.axi_s_awready(can_s_awready),
	.axi_s_awaddr(can_s_awaddr),

	.axi_s_wvalid(can_s_wvalid),
	.axi_s_wready(can_s_wready),
	.axi_s_wdata(can_s_wdata),
	.axi_s_wstrb(can_s_wstrb),

	.axi_s_bvalid(can_s_bvalid),
	.axi_s_bready(can_s_bready),
	.axi_s_bresp(can_s_bresp),

	.axi_s_arvalid(can_s_arvalid),
	.axi_s_arready(can_s_arready),
	.axi_s_araddr(can_s_araddr),

	.axi_s_rvalid(can_s_rvalid),
	.axi_s_rready(can_s_rready),
	.axi_s_rdata(can_s_rdata),
	.axi_s_rresp(can_s_rresp),

	// CAN Ports to export
	.can0_rx_i(can0_rx),
	.can0_tx_o(can0_tx),
	.can0_bus_off_on(can0_bus_off_on),

	.can1_rx_i(can1_rx),
	.can1_tx_o(can1_tx),
	.can1_bus_off_on(can1_bus_off_on)
);

// EXAR XR17C154 Quad 16550 Emulation
xr17c154_top xr17c154_i(
	// AXI4-Lite for memory mapped registers
	.axi_s_aclk(uart_s_aclk),
	.axi_s_aresetn(uart_s_aresetn),

	.axi_s_awvalid(uart_s_awvalid),
	.axi_s_awready(uart_s_awready),
	.axi_s_awaddr(uart_s_awaddr),

	.axi_s_wvalid(uart_s_wvalid),
	.axi_s_wready(uart_s_wready),
	.axi_s_wdata(uart_s_wdata),
	.axi_s_wstrb(uart_s_wstrb),

	.axi_s_bvalid(uart_s_bvalid),
	.axi_s_bready(uart_s_bready),
	.axi_s_bresp(uart_s_bresp),

	.axi_s_arvalid(uart_s_arvalid),
	.axi_s_arready(uart_s_arready),
	.axi_s_araddr(uart_s_araddr),

	.axi_s_rvalid(uart_s_rvalid),
	.axi_s_rready(uart_s_rready),
	.axi_s_rdata(uart_s_rdata),
	.axi_s_rresp(uart_s_rresp),

	.s0_txd_o(uart0_tx),
	.s0_rxd_i(uart0_rx),
	.s0_rts_o(uart0_rts),
	.s0_cts_i(uart0_cts),
	.s0_dtr_o(uart0_dtr),
	.s0_dsr_i(uart0_dsr),
	.s0_ri_i(uart0_ri),
	.s0_dcd_i(uart0_dcd),

	.s1_txd_o(uart1_tx),
	.s1_rxd_i(uart1_rx),
	.s1_rts_o(uart1_rts),
	.s1_cts_i(uart1_cts),
	.s1_dtr_o(uart1_dtr),
	.s1_dsr_i(uart1_dsr),
	.s1_ri_i(uart1_ri),
	.s1_dcd_i(uart1_dcd),

	.s2_txd_o(uart2_tx),
	.s2_rxd_i(uart2_rx),
	.s2_rts_o(uart2_rts),
	.s2_cts_i(uart2_cts),
	.s2_dtr_o(uart2_dtr),
	.s2_dsr_i(uart2_dsr),
	.s2_ri_i(uart2_ri),
	.s2_dcd_i(uart2_dcd),

	.s3_txd_o(uart3_tx),
	.s3_rxd_i(uart3_rx),
	.s3_rts_o(uart3_rts),
	.s3_cts_i(uart3_cts),
	.s3_dtr_o(uart3_dtr),
	.s3_dsr_i(uart3_dsr),
	.s3_ri_i(uart3_ri),
	.s3_dcd_i(uart3_dcd)
);

target_crossbar target_crossbar_i(
	.aclk(nic_aclk),
	.aresetn(nic_aresetn),

	.s0_axi_awvalid(tgt_m_awvalid),
	.s0_axi_awready(tgt_m_awready),
	.s0_axi_awaddr(tgt_m_awaddr),

	.s0_axi_wvalid(tgt_m_wvalid),
	.s0_axi_wready(tgt_m_wready),
	.s0_axi_wdata(tgt_m_wdata),
	.s0_axi_wstrb(tgt_m_wstrb),

	.s0_axi_bvalid(tgt_m_bvalid),
	.s0_axi_bready(tgt_m_bready),
	.s0_axi_bresp(tgt_m_bresp),

	.s0_axi_arvalid(tgt_m_arvalid),
	.s0_axi_arready(tgt_m_arready),
	.s0_axi_araddr(tgt_m_araddr),

	.s0_axi_rvalid(tgt_m_rvalid),
	.s0_axi_rready(tgt_m_rready),
	.s0_axi_rdata(tgt_m_rdata),
	.s0_axi_rresp(tgt_m_rresp),

	.m0_axi_awvalid(nic_s_awvalid),
	.m0_axi_awready(nic_s_awready),
	.m0_axi_awaddr(nic_s_awaddr),

	.m0_axi_wvalid(nic_s_wvalid),
	.m0_axi_wready(nic_s_wready),
	.m0_axi_wdata(nic_s_wdata),
	.m0_axi_wstrb(nic_s_wstrb),

	.m0_axi_bvalid(nic_s_bvalid),
	.m0_axi_bready(nic_s_bready),
	.m0_axi_bresp(nic_s_bresp),

	.m0_axi_arvalid(nic_s_arvalid),
	.m0_axi_arready(nic_s_arready),
	.m0_axi_araddr(nic_s_araddr),

	.m0_axi_rvalid(nic_s_rvalid),
	.m0_axi_rready(nic_s_rready),
	.m0_axi_rdata(nic_s_rdata),
	.m0_axi_rresp(nic_s_rresp),

	.m1_axi_awvalid(can_s_awvalid),
	.m1_axi_awready(can_s_awready),
	.m1_axi_awaddr(can_s_awaddr),

	.m1_axi_wvalid(can_s_wvalid),
	.m1_axi_wready(can_s_wready),
	.m1_axi_wdata(can_s_wdata),
	.m1_axi_wstrb(can_s_wstrb),

	.m1_axi_bvalid(can_s_bvalid),
	.m1_axi_bready(can_s_bready),
	.m1_axi_bresp(can_s_bresp),

	.m1_axi_arvalid(can_s_arvalid),
	.m1_axi_arready(can_s_arready),
	.m1_axi_araddr(can_s_araddr),

	.m1_axi_rvalid(can_s_rvalid),
	.m1_axi_rready(can_s_rready),
	.m1_axi_rdata(can_s_rdata),
	.m1_axi_rresp(can_s_rresp),

	.m2_axi_awvalid(uart_s_awvalid),
	.m2_axi_awready(uart_s_awready),
	.m2_axi_awaddr(uart_s_awaddr),

	.m2_axi_wvalid(uart_s_wvalid),
	.m2_axi_wready(uart_s_wready),
	.m2_axi_wdata(uart_s_wdata),
	.m2_axi_wstrb(uart_s_wstrb),

	.m2_axi_bvalid(uart_s_bvalid),
	.m2_axi_bready(uart_s_bready),
	.m2_axi_bresp(uart_s_bresp),

	.m2_axi_arvalid(uart_s_arvalid),
	.m2_axi_arready(uart_s_arready),
	.m2_axi_araddr(uart_s_araddr),

	.m2_axi_rvalid(uart_s_rvalid),
	.m2_axi_rready(uart_s_rready),
	.m2_axi_rdata(uart_s_rdata),
	.m2_axi_rresp(uart_s_rresp)
);

master_crossbar master_crossbar_i(
	.aclk(nic_aclk),
	.aresetn(nic_aresetn),

	.m0_axi_awid(mst_s_awid),
	.m0_axi_awaddr(mst_s_awaddr),
	.m0_axi_awlen(mst_s_awlen),
	.m0_axi_awsize(mst_s_awsize),
	.m0_axi_awburst(mst_s_awburst),
	.m0_axi_awcache(mst_s_awcache),
	.m0_axi_awvalid(mst_s_awvalid),
	.m0_axi_awready(mst_s_awready),

	.m0_axi_wid(mst_s_wid),
	.m0_axi_wdata(mst_s_wdata),
	.m0_axi_wstrb(mst_s_wstrb),
	.m0_axi_wlast(mst_s_wlast),
	.m0_axi_wvalid(mst_s_wvalid),
	.m0_axi_wready(mst_s_wready),

	.m0_axi_bid(mst_s_bid),
	.m0_axi_bresp(mst_s_bresp),
	.m0_axi_bvalid(mst_s_bvalid),
	.m0_axi_bready(mst_s_bready),

	.m0_axi_arid(mst_s_arid),
	.m0_axi_araddr(mst_s_araddr),
	.m0_axi_arlen(mst_s_arlen),
	.m0_axi_arsize(mst_s_arsize),
	.m0_axi_arburst(mst_s_arburst),
	.m0_axi_arcache(mst_s_arcache),
	.m0_axi_arvalid(mst_s_arvalid),
	.m0_axi_arready(mst_s_arready),

	.m0_axi_rid(mst_s_rid),
	.m0_axi_rdata(mst_s_rdata),
	.m0_axi_rresp(mst_s_rresp),
	.m0_axi_rlast(mst_s_rlast),
	.m0_axi_rvalid(mst_s_rvalid),
	.m0_axi_rready(mst_s_rready)

	.s0_axi_awid(nic_m_awid),
	.s0_axi_awaddr(nic_m_awaddr),
	.s0_axi_awlen(nic_m_awlen),
	.s0_axi_awsize(nic_m_awsize),
	.s0_axi_awburst(nic_m_awburst),
	.s0_axi_awcache(nic_m_awcache),
	.s0_axi_awvalid(nic_m_awvalid),
	.s0_axi_awready(nic_m_awready),

	.s0_axi_wid(nic_m_wid),
	.s0_axi_wdata(nic_m_wdata),
	.s0_axi_wstrb(nic_m_wstrb),
	.s0_axi_wlast(nic_m_wlast),
	.s0_axi_wvalid(nic_m_wvalid),
	.s0_axi_wready(nic_m_wready),

	.s0_axi_bid(nic_m_bid),
	.s0_axi_bresp(nic_m_bresp),
	.s0_axi_bvalid(nic_m_bvalid),
	.s0_axi_bready(nic_m_bready),

	.s0_axi_arid(nic_m_arid),
	.s0_axi_araddr(nic_m_araddr),
	.s0_axi_arlen(nic_m_arlen),
	.s0_axi_arsize(nic_m_arsize),
	.s0_axi_arburst(nic_m_arburst),
	.s0_axi_arcache(nic_m_arcache),
	.s0_axi_arvalid(nic_m_arvalid),
	.s0_axi_arready(nic_m_arready),

	.s0_axi_rid(nic_m_rid),
	.s0_axi_rdata(nic_m_rdata),
	.s0_axi_rresp(nic_m_rresp),
	.s0_axi_rlast(nic_m_rlast),
	.s0_axi_rvalid(nic_m_rvalid),
	.s0_axi_rready(nic_m_rready)

);
*/

generate
if(DEBUG=="TRUE") begin
ila_0 ila_mst_i0(
	.clk(mst_s_aclk), // input wire clk
	.probe0({
		mst_s_awaddr,
		mst_s_awlen,
		mst_s_awvalid,
		mst_s_awready,

		mst_s_wdata,
		mst_s_wstrb,
		mst_s_wlast,
		mst_s_wvalid,
		mst_s_wready,

		mst_s_bresp,
		mst_s_bvalid,
		mst_s_bready,

		mst_s_araddr,
		mst_s_arlen,
		mst_s_arvalid,
		mst_s_arready,

		mst_s_rdata,
		mst_s_rresp,
		mst_s_rlast,
		mst_s_rvalid,
		mst_s_rready
	})
);

ila_0 ila_tgt_i1(
	.clk(tgt_m_aclk), // input wire clk
	.probe0({
		tgt_m_awaddr,
		tgt_m_awvalid,
		tgt_m_awready,

		tgt_m_wdata,
		tgt_m_wstrb,
		tgt_m_wvalid,
		tgt_m_wready,

		tgt_m_bresp,
		tgt_m_bvalid,
		tgt_m_bready,

		tgt_m_araddr,
		tgt_m_arvalid,
		tgt_m_arready,

		tgt_m_rdata,
		tgt_m_rresp,
		tgt_m_rvalid,
		tgt_m_rready,

		intr_request
	})
);
end
endgenerate

endmodule
