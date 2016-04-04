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
	//  input         IDSEL,
	inout         PERR_N,
	inout         SERR_N,
	output        INTA_N,
	//  output        PMEA_N,
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
parameter CORE_CLK_PERIOD_NS=8;
parameter UART_CLK_PERIOD_NS=7.5;

wire ext_clk;
wire ext_rst;

wire core_clk;
wire core_rst;

wire uart_clk;
wire uart_rst;

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
wire [3:0] tgt_m_aruser;
wire tgt_m_rvalid;
wire tgt_m_rready;
wire [31:0] tgt_m_rdata;
wire [1:0] tgt_m_rresp;

wire intr_request;

wire mst_s_aclk;
wire mst_s_aresetn;
wire [3:0] mst_s_awid;
wire [63:0] mst_s_awaddr;
wire [3:0] mst_s_awlen;
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
wire [3:0] mst_s_arlen;
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

wire mps_s_aclk;
wire mps_s_aresetn;
wire mps_s_awvalid;
wire mps_s_awready;
wire [31:0] mps_s_awaddr;
wire mps_s_wvalid;
wire mps_s_wready;
wire [31:0] mps_s_wdata;
wire [3:0] mps_s_wstrb;
wire mps_s_bvalid;
wire mps_s_bready;
wire [1:0] mps_s_bresp;
wire mps_s_arvalid;
wire mps_s_arready;
wire [31:0] mps_s_araddr;
wire [3:0] mps_s_aruser;
wire mps_s_rvalid;
wire mps_s_rready;
wire [31:0] mps_s_rdata;
wire [1:0] mps_s_rresp;

wire [7:0] mps_rxd;
wire [7:0] mps_txd;
wire [7:0] mps_rtsn;
wire [7:0] mps_ctsn;
wire [7:0] mps_dtrn;
wire [7:0] mps_dsrn;
wire [7:0] mps_ri;
wire [7:0] mps_dcdn;

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

wire	p1_mdio_i;
wire	p1_mdio_o;
wire	p1_mdio_oe;

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

reg core_rst_r;
reg uart_rst_r;

assign PCI_EN_N = 1'b0;

assign can0_tx = 1'b0;
assign can0_rs = 1'b0;
assign can1_tx = 1'b0;
assign can1_rs = 1'b0;

assign uart0_rxen_n = 1'b0;
assign uart0_tx = mps_txd[0];
assign uart0_txen = 1'b1;

assign uart1_rxen_n = 1'b0;
assign uart1_tx = mps_txd[1];
assign uart1_txen = 1'b1;

assign uart2_rxen_n = 1'b0;
assign uart2_tx = mps_txd[2];
assign uart2_txen = 1'b1;

assign uart3_rxen_n = 1'b0;
assign uart3_tx = mps_txd[3];
assign uart3_txen = 1'b1;

assign mps_rxd[0] = uart0_rx;
assign mps_rxd[1] = uart1_rx;
assign mps_rxd[2] = uart2_rx;
assign mps_rxd[3] = uart3_rx;
assign mps_rxd[4] = mps_txd[5];
assign mps_rxd[5] = mps_txd[4];
assign mps_rxd[6] = mps_txd[7];
assign mps_rxd[7] = mps_txd[6];

assign mps_ctsn = 8'hFF;
assign mps_dsrn = 8'hFF;
assign mps_ri = 8'hFF;
assign mps_dcdn = 8'hFF;

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
assign mps_s_awvalid = tgt_m_awvalid;
assign mps_s_awaddr = tgt_m_awaddr;
assign tgt_m_awready = mps_s_awready;

assign mps_s_wvalid = tgt_m_wvalid;
assign mps_s_wdata = tgt_m_wdata;
assign mps_s_wstrb = tgt_m_wstrb;
assign tgt_m_wready = mps_s_wready;

assign tgt_m_bvalid = mps_s_bvalid;
assign tgt_m_bresp = mps_s_bresp;
assign mps_s_bready = tgt_m_bready;

assign mps_s_arvalid = tgt_m_arvalid;
assign mps_s_araddr = tgt_m_araddr;
assign mps_s_aruser = tgt_m_aruser;
assign tgt_m_arready = mps_s_arready;

assign tgt_m_rvalid = mps_s_rvalid;
assign tgt_m_rdata = mps_s_rdata;
assign tgt_m_rresp = mps_s_rresp;
assign mps_s_rready = tgt_m_rready;

assign mst_s_awvalid = 1'b0;
assign mst_s_wvalid = 1'b0;
assign mst_s_bready = 1'b0;
assign mst_s_arvalid = 1'b0;
assign mst_s_rready = 1'b0;

assign mps_m_awready = 1'b0;
assign mps_m_wready = 1'b0;
assign mps_m_bready = 1'b0;
assign mps_m_arready = 1'b0;
assign mps_m_rready = 1'b0;

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

assign core_rst = core_rst_r;
assign uart_rst = uart_rst_r;

assign cfg_s_aclk = core_clk;
assign cfg_s_aresetn = !core_rst;

assign tgt_m_aclk = uart_clk;
assign tgt_m_aresetn = !uart_rst;

assign mps_s_aclk = uart_clk;
assign mps_s_aresetn = !uart_rst;

assign mst_s_aclk = core_clk;
assign mst_s_aresetn = !core_rst;

always @(posedge core_clk, posedge ext_rst)
begin
	if(ext_rst) begin
		core_rst_r <= 1'b1;
	end
	else if(clk_locked) begin
		core_rst_r <= 1'b0;
	end
end

always @(posedge uart_clk, posedge ext_rst)
begin
	if(ext_rst) begin
		uart_rst_r <= 1'b1;
	end
	else if(clk_locked) begin
		uart_rst_r <= 1'b0;
	end
end

clock_generation clk_gen_i(
	.reset(ext_rst),
	.clk_in1(ext_clk),
	.clk_out1(uart_clk), // 133.333MHz
	.clk_out2(core_clk), // 125MHz 
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
	//.IDSEL(IDSEL),
	.IDSEL(1'b0),
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
	.tgt_m_aruser(tgt_m_aruser),

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

mps_top #(.BASE_BAUD(460800),.CLK_PERIOD_NS(UART_CLK_PERIOD_NS))mps_top(
	.aclk(mps_s_aclk),
	.aresetn(mps_s_aresetn),

	.axi_s_awvalid(mps_s_awvalid),
	.axi_s_awready(mps_s_awready),
	.axi_s_awaddr(mps_s_awaddr),

	.axi_s_wvalid(mps_s_wvalid),
	.axi_s_wready(mps_s_wready),
	.axi_s_wdata(mps_s_wdata),
	.axi_s_wstrb(mps_s_wstrb),

	.axi_s_bvalid(mps_s_bvalid),
	.axi_s_bready(mps_s_bready),
	.axi_s_bresp(mps_s_bresp),

	.axi_s_arvalid(mps_s_arvalid),
	.axi_s_arready(mps_s_arready),
	.axi_s_araddr(mps_s_araddr),
	.axi_s_aruser(mps_s_aruser),

	.axi_s_rvalid(mps_s_rvalid),
	.axi_s_rready(mps_s_rready),
	.axi_s_rdata(mps_s_rdata),
	.axi_s_rresp(mps_s_rresp),

	.intr_request(intr_request),

	.rxd(mps_rxd),
	.txd(mps_txd),
	.rtsn(mps_rtsn),
	.ctsn(mps_ctsn),
	.dtrn(mps_dtrn),
	.dsrn(mps_dsrn),
	.ri(mps_ri),
	.dcdn(mps_dcdn)
);

ila_axi_0 ila_axi_0_i(
	.clk(tgt_m_aclk), // input wire clk


	.probe0(tgt_m_awvalid), // input wire [0:0] probe0  
	.probe1(tgt_m_awaddr), // input wire [31:0]  probe1 
	.probe2(tgt_m_bresp), // input wire [1:0]  probe2 
	.probe3(tgt_m_awready), // input wire [0:0]  probe3 
	.probe4(tgt_m_wvalid), // input wire [0:0]  probe4 
	.probe5(tgt_m_wdata), // input wire [31:0]  probe5 
	.probe6(tgt_m_wready), // input wire [0:0]  probe6 
	.probe7(tgt_m_bvalid), // input wire [0:0]  probe7 
	.probe8(tgt_m_bready), // input wire [0:0]  probe8 
	.probe9(tgt_m_arvalid), // input wire [0:0]  probe9 
	.probe10(tgt_m_araddr), // input wire [31:0]  probe10 
	.probe11(tgt_m_arready), // input wire [0:0]  probe11 
	.probe12(tgt_m_rvalid), // input wire [0:0]  probe12 
	.probe13(tgt_m_rresp), // input wire [1:0]  probe13 
	.probe14(tgt_m_rdata), // input wire [31:0]  probe14 
	.probe15(tgt_m_wstrb), // input wire [3:0]  probe15 
	.probe16(tgt_m_rready), // input wire [0:0]  probe16 
	.probe17({2'b0,intr_request}), // input wire [2:0]  probe17  
	.probe18(3'b0) // input wire [2:0]  probe18
);
endmodule
