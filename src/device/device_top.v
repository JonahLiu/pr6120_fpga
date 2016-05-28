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
	//input         IDSEL,
	inout         PERR_N,
	inout         SERR_N,
	output        INTA_N,
	output        INTB_N,
	output        INTC_N,
	output        INTD_N,
	//output        PMEA_N,
	output        [2:0] REQ_N,
	input         [2:0] GNT_N,
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

parameter DEBUG="TRUE";
parameter UART_PORT_NUM = 8;
parameter CAN_PORT_NUM = 4;

wire CLK;
wire RST;

////////////////////////////////////////////////////////////////////////////////
// PCI Interface

wire [2:0] INT_N;

wire [2:0] PME_N;

wire [31:0] P0_ADIO_IN;
wire [31:0] P0_ADIO_OUT;

wire [31:0] P0_ADDR;
wire P0_ADDR_VLD;
wire [7:0] P0_BASE_HIT;
wire P0_S_TERM;
wire P0_S_READY;
wire P0_S_ABORT;
wire P0_S_WRDN;
wire P0_S_SRC_EN;
wire P0_S_DATA;
wire P0_S_DATA_VLD;
wire [3:0] P0_S_CBE;
wire P0_INT_N;

wire P0_REQUEST;
wire P0_REQUESTHOLD;
wire [3:0] P0_M_CBE;
wire P0_M_WRDN;
wire P0_COMPLETE;
wire P0_M_READY;
wire P0_M_DATA_VLD;
wire P0_M_SRC_EN;
wire P0_TIME_OUT;
wire P0_M_DATA;
wire P0_M_ADDR_N;
wire P0_STOPQ_N;

wire [31:0] P1_ADIO_IN;
wire [31:0] P1_ADIO_OUT;

wire [31:0] P1_ADDR;
wire P1_ADDR_VLD;
wire [7:0] P1_BASE_HIT;
wire P1_S_TERM;
wire P1_S_READY;
wire P1_S_ABORT;
wire P1_S_WRDN;
wire P1_S_SRC_EN;
wire P1_S_DATA;
wire P1_S_DATA_VLD;
wire [3:0] P1_S_CBE;
wire P1_INT_N;

wire P1_REQUEST;
wire P1_REQUESTHOLD;
wire [3:0] P1_M_CBE;
wire P1_M_WRDN;
wire P1_COMPLETE;
wire P1_M_READY;
wire P1_M_DATA_VLD;
wire P1_M_SRC_EN;
wire P1_TIME_OUT;
wire P1_M_DATA;
wire P1_M_ADDR_N;
wire P1_STOPQ_N;

wire [31:0] P2_ADIO_IN;
wire [31:0] P2_ADIO_OUT;

wire [31:0] P2_ADDR;
wire P2_ADDR_VLD;
wire [7:0] P2_BASE_HIT;
wire P2_S_TERM;
wire P2_S_READY;
wire P2_S_ABORT;
wire P2_S_WRDN;
wire P2_S_SRC_EN;
wire P2_S_DATA;
wire P2_S_DATA_VLD;
wire [3:0] P2_S_CBE;
wire P2_INT_N;

wire P2_REQUEST;
wire P2_REQUESTHOLD;
wire [3:0] P2_M_CBE;
wire P2_M_WRDN;
wire P2_COMPLETE;
wire P2_M_READY;
wire P2_M_DATA_VLD;
wire P2_M_SRC_EN;
wire P2_TIME_OUT;
wire P2_M_DATA;
wire P2_M_ADDR_N;
wire P2_STOPQ_N;

assign PCI_EN_N = 1'b0;
assign INTA_N=INT_N[0];
assign INTB_N=INT_N[1];
assign INTC_N=INT_N[2];
assign INTD_N=1'bz;

pci_multi pci_multi_i(
	.AD_IO(AD),
	.CBE_IO(CBE),
	.PAR_IO(PAR),
	.FRAME_IO(FRAME_N),
	.TRDY_IO(TRDY_N),
	.IRDY_IO(IRDY_N),
	.STOP_IO(STOP_N),
	.DEVSEL_IO(DEVSEL_N),
	.PERR_IO(PERR_N),
	.SERR_IO(SERR_N),
	.INT_O(INT_N),
	.PME_O(PME_N),
	.REQ_O(REQ_N),
	.GNT_I(GNT_N),
	.RST_I(RST_N),
	.CLK_I(PCLK),

	.CLK(CLK),
	.RST(RST),

	.P0_ADIO_IN(P0_ADIO_IN),
	.P0_ADIO_OUT(P0_ADIO_OUT),

	.P0_ADDR(P0_ADDR),
	.P0_ADDR_VLD(P0_ADDR_VLD),
	.P0_BASE_HIT(P0_BASE_HIT),
	.P0_S_TERM(P0_S_TERM),
	.P0_S_READY(P0_S_READY),
	.P0_S_ABORT(P0_S_ABORT),
	.P0_S_WRDN(P0_S_WRDN),
	.P0_S_SRC_EN(P0_S_SRC_EN),
	.P0_S_DATA(P0_S_DATA),
	.P0_S_DATA_VLD(P0_S_DATA_VLD),
	.P0_S_CBE(P0_S_CBE),
	.P0_INT_N(P0_INT_N),

	.P0_REQUEST(P0_REQUEST),
	.P0_REQUESTHOLD(P0_REQUESTHOLD),
	.P0_M_CBE(P0_M_CBE),
	.P0_M_WRDN(P0_M_WRDN),
	.P0_COMPLETE(P0_COMPLETE),
	.P0_M_READY(P0_M_READY),
	.P0_M_DATA_VLD(P0_M_DATA_VLD),
	.P0_M_SRC_EN(P0_M_SRC_EN),
	.P0_TIME_OUT(P0_TIME_OUT),
	.P0_M_DATA(P0_M_DATA),
	.P0_M_ADDR_N(P0_M_ADDR_N),
	.P0_STOPQ_N(P0_STOPQ_N),

	.P1_ADIO_IN(P1_ADIO_IN),
	.P1_ADIO_OUT(P1_ADIO_OUT),

	.P1_ADDR(P1_ADDR),
	.P1_ADDR_VLD(P1_ADDR_VLD),
	.P1_BASE_HIT(P1_BASE_HIT),
	.P1_S_TERM(P1_S_TERM),
	.P1_S_READY(P1_S_READY),
	.P1_S_ABORT(P1_S_ABORT),
	.P1_S_WRDN(P1_S_WRDN),
	.P1_S_SRC_EN(P1_S_SRC_EN),
	.P1_S_DATA(P1_S_DATA),
	.P1_S_DATA_VLD(P1_S_DATA_VLD),
	.P1_S_CBE(P1_S_CBE),
	.P1_INT_N(P1_INT_N),

	.P1_REQUEST(P1_REQUEST),
	.P1_REQUESTHOLD(P1_REQUESTHOLD),
	.P1_M_CBE(P1_M_CBE),
	.P1_M_WRDN(P1_M_WRDN),
	.P1_COMPLETE(P1_COMPLETE),
	.P1_M_READY(P1_M_READY),
	.P1_M_DATA_VLD(P1_M_DATA_VLD),
	.P1_M_SRC_EN(P1_M_SRC_EN),
	.P1_TIME_OUT(P1_TIME_OUT),
	.P1_M_DATA(P1_M_DATA),
	.P1_M_ADDR_N(P1_M_ADDR_N),
	.P1_STOPQ_N(P1_STOPQ_N),

	.P2_ADIO_IN(P2_ADIO_IN),
	.P2_ADIO_OUT(P2_ADIO_OUT),

	.P2_ADDR(P2_ADDR),
	.P2_ADDR_VLD(P2_ADDR_VLD),
	.P2_BASE_HIT(P2_BASE_HIT),
	.P2_S_TERM(P2_S_TERM),
	.P2_S_READY(P2_S_READY),
	.P2_S_ABORT(P2_S_ABORT),
	.P2_S_WRDN(P2_S_WRDN),
	.P2_S_SRC_EN(P2_S_SRC_EN),
	.P2_S_DATA(P2_S_DATA),
	.P2_S_DATA_VLD(P2_S_DATA_VLD),
	.P2_S_CBE(P2_S_CBE),
	.P2_INT_N(P2_INT_N),

	.P2_REQUEST(P2_REQUEST),
	.P2_REQUESTHOLD(P2_REQUESTHOLD),
	.P2_M_CBE(P2_M_CBE),
	.P2_M_WRDN(P2_M_WRDN),
	.P2_COMPLETE(P2_COMPLETE),
	.P2_M_READY(P2_M_READY),
	.P2_M_DATA_VLD(P2_M_DATA_VLD),
	.P2_M_SRC_EN(P2_M_SRC_EN),
	.P2_TIME_OUT(P2_TIME_OUT),
	.P2_M_DATA(P2_M_DATA),
	.P2_M_ADDR_N(P2_M_ADDR_N),
	.P2_STOPQ_N(P2_STOPQ_N)
);

////////////////////////////////////////////////////////////////////////////////
// E1000 NIC Controller

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

wire    phy_mdio_req;
wire    phy_mdio_gnt;

wire [1:0]	phy_speed;
wire	phy_duplex;
wire	phy_up;
wire	phy_lsc;
wire 	phy_port;

wire	p0_gtxsclk_o;
wire	p1_gtxsclk_o;

assign	p0_mdio = p0_mdio_oe?p0_mdio_o:1'bz;
assign  p0_mdio_i = p0_mdio;
assign	p0_resetn = !p0_reset_out;
assign	p1_mdio = p1_mdio_oe?p1_mdio_o:1'bz;
assign  p1_mdio_i = p1_mdio;
assign	p1_resetn = !p1_reset_out;

// Setup & hold time given by 88E1111 is (2.5ns, 0ns), 
// so edge aligned clock and output is OK.
ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) p0_gtxsclk_oddr_i(.D1(1'b1),.D2(1'b0),.CE(1'b1),.C(mac_gtxsclk),.S(1'b0),.R(1'b0),.Q(p0_gtxsclk));
ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) p1_gtxsclk_oddr_i(.D1(1'b1),.D2(1'b0),.CE(1'b1),.C(mac_gtxsclk),.S(1'b0),.R(1'b0),.Q(p1_gtxsclk));

nic_wrapper #(
	.DEBUG(DEBUG)
)nic_wrapper_i(
	.RST(RST),
	.CLK(CLK),
	.ADDR(P0_ADDR),
	.ADDR_VLD(P0_ADDR_VLD),
	.BASE_HIT(P0_BASE_HIT),
	.ADIO_IN(P0_ADIO_IN),
	.ADIO_OUT(P0_ADIO_OUT),
	.S_TERM(P0_S_TERM),
	.S_READY(P0_S_READY),
	.S_ABORT(P0_S_ABORT),
	.S_WRDN(P0_S_WRDN),
	.S_SRC_EN(P0_S_SRC_EN),
	.S_DATA(P0_S_DATA),
	.S_DATA_VLD(P0_S_DATA_VLD),
	.S_CBE(P0_S_CBE),
	.INT_N(P0_INT_N),
	.REQUEST(P0_REQUEST),
	.REQUESTHOLD(P0_REQUESTHOLD),
	.M_CBE(P0_M_CBE),
	.M_WRDN(P0_M_WRDN),
	.COMPLETE(P0_COMPLETE),
	.M_READY(P0_M_READY),
	.M_DATA_VLD(P0_M_DATA_VLD),
	.M_SRC_EN(P0_M_SRC_EN),
	.TIME_OUT(P0_TIME_OUT),
	.M_DATA(P0_M_DATA),
	.M_ADDR_N(P0_M_ADDR_N),
	.STOPQ_N(P0_STOPQ_N),

	.cacheline_size(8'd16),

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

// Dual redundancy fault-tolerant
phy_ft #(.PHY_ADDR(5'b0), .CLK_PERIOD_NS(30)) phy_ft_i(
	.clk(CLK),
	.rst(RST),

	.speed(phy_speed),
	.full_duplex(phy_duplex),
	.link_up(phy_up),
	.active_port(phy_port),
	.link_change(phy_lsc),

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
	.mdio_req(phy_mdio_req),
	.mdio_gnt(phy_mdio_gnt),
	.intr_out(phy_int),
	.reset_in(phy_reset_out),

	.phy0_rxdat(p0_rxdat),
	.phy0_rxdv(p0_rxdv),
	.phy0_rxer(p0_rxer),
	.phy0_rxsclk(p0_rxsclk),
	.phy0_txdat(p0_txdat),
	.phy0_txen(p0_txen),
	.phy0_txer(p0_txer),
	.phy0_txsclk(p0_txsclk),
	.phy0_gtxsclk(p0_gtxsclk_o),
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
	.phy1_gtxsclk(p1_gtxsclk_o),
	.phy1_crs(p1_crs),
	.phy1_col(p1_col),
	.phy1_mdc(p1_mdc),
	.phy1_mdio_i(p1_mdio_i),
	.phy1_mdio_o(p1_mdio_o),
	.phy1_mdio_oe(p1_mdio_oe),
	.phy1_int(p1_int),
	.phy1_reset_out(p1_reset_out)
);

eeprom_emu eeprom_emu_i(
	.clk_i(CLK),
	.rst_i(RST),
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
	.clk_i(CLK),
	.rst_i(RST),
	.read_addr(eeprom_raddr),
	.read_enable(eeprom_ren),
	.read_data(eeprom_rdata)
);

////////////////////////////////////////////////////////////////////////////////
// Multi-Port CAN Controller

wire [CAN_PORT_NUM-1:0] can_rx;
wire [CAN_PORT_NUM-1:0] can_tx;
wire [CAN_PORT_NUM-1:0] can_bus_off_on;

assign can0_tx = can_tx[0];
assign can0_rs = 1'b0;
assign can_rx[0] = can0_rx;

assign can1_tx = can_tx[1];
assign can1_rs = 1'b0;
assign can_rx[1] = can1_rx;

// Connect CAN2 and CAN3 for testing
assign can_rx[2] = can_tx[2]&can_tx[3];
assign can_rx[3] = can_tx[2]&can_tx[3];

mpc_wrapper #(
	.PORT_NUM(CAN_PORT_NUM),
	.DEBUG(DEBUG)
)mpc_wrapper_i(
	.RST(RST),
	.CLK(CLK),
	.ADDR(P1_ADDR),
	.ADDR_VLD(P1_ADDR_VLD),
	.BASE_HIT(P1_BASE_HIT),
	.ADIO_IN(P1_ADIO_IN),
	.ADIO_OUT(P1_ADIO_OUT),
	.S_TERM(P1_S_TERM),
	.S_READY(P1_S_READY),
	.S_ABORT(P1_S_ABORT),
	.S_WRDN(P1_S_WRDN),
	.S_SRC_EN(P1_S_SRC_EN),
	.S_DATA(P1_S_DATA),
	.S_DATA_VLD(P1_S_DATA_VLD),
	.S_CBE(P1_S_CBE),
	.INT_N(P1_INT_N),
	.REQUEST(P1_REQUEST),
	.REQUESTHOLD(P1_REQUESTHOLD),
	.M_CBE(P1_M_CBE),
	.M_WRDN(P1_M_WRDN),
	.COMPLETE(P1_COMPLETE),
	.M_READY(P1_M_READY),
	.M_DATA_VLD(P1_M_DATA_VLD),
	.M_SRC_EN(P1_M_SRC_EN),
	.TIME_OUT(P1_TIME_OUT),
	.M_DATA(P1_M_DATA),
	.M_ADDR_N(P1_M_ADDR_N),
	.STOPQ_N(P1_STOPQ_N),

	.rx_i(can_rx),
	.tx_o(can_tx),
	.bus_off_on(can_bus_off_on)
);

////////////////////////////////////////////////////////////////////////////////
// Multi-Port Serial Controller

wire [UART_PORT_NUM-1:0] uart_rxd;
wire [UART_PORT_NUM-1:0] uart_txd;
wire [UART_PORT_NUM-1:0] uart_rtsn;
wire [UART_PORT_NUM-1:0] uart_ctsn;
wire [UART_PORT_NUM-1:0] uart_dtrn;
wire [UART_PORT_NUM-1:0] uart_dsrn;
wire [UART_PORT_NUM-1:0] uart_ri;
wire [UART_PORT_NUM-1:0] uart_dcdn;

assign uart0_rxen_n = 1'b0;
assign uart0_tx = uart_txd[0];
assign uart0_txen = 1'b1;
assign uart_rxd[0] = uart0_rx;

assign uart1_rxen_n = 1'b0;
assign uart1_tx = uart_txd[1];
assign uart1_txen = 1'b1;
assign uart_rxd[1] = uart1_rx;

assign uart2_rxen_n = 1'b0;
assign uart2_tx = uart_txd[2];
assign uart2_txen = 1'b1;
assign uart_rxd[2] = uart2_rx;

assign uart3_rxen_n = 1'b0;
assign uart3_tx = uart_txd[3];
assign uart3_txen = 1'b1;
assign uart_rxd[3] = uart3_rx;

// Connect UART4 with UART5 and UART6 with UART7 for testing
assign uart_rxd[4] = uart_txd[5];
assign uart_rxd[5] = uart_txd[4];
assign uart_rxd[6] = uart_txd[7];
assign uart_rxd[7] = uart_txd[6];

assign uart_ctsn = 8'hFF;
assign uart_dsrn = 8'hFF;
assign uart_ri = 8'hFF;
assign uart_dcdn = 8'hFF;

mps_wrapper #(
	.PORT_NUM(UART_PORT_NUM),
	.DEBUG(DEBUG)
)mps_wrapper_i(
	.RST(RST),
	.CLK(CLK),
	.ADDR(P2_ADDR),
	.ADDR_VLD(P2_ADDR_VLD),
	.BASE_HIT(P2_BASE_HIT),
	.ADIO_IN(P2_ADIO_IN),
	.ADIO_OUT(P2_ADIO_OUT),
	.S_TERM(P2_S_TERM),
	.S_READY(P2_S_READY),
	.S_ABORT(P2_S_ABORT),
	.S_WRDN(P2_S_WRDN),
	.S_SRC_EN(P2_S_SRC_EN),
	.S_DATA(P2_S_DATA),
	.S_DATA_VLD(P2_S_DATA_VLD),
	.S_CBE(P2_S_CBE),
	.INT_N(P2_INT_N),
	.REQUEST(P2_REQUEST),
	.REQUESTHOLD(P2_REQUESTHOLD),
	.M_CBE(P2_M_CBE),
	.M_WRDN(P2_M_WRDN),
	.COMPLETE(P2_COMPLETE),
	.M_READY(P2_M_READY),
	.M_DATA_VLD(P2_M_DATA_VLD),
	.M_SRC_EN(P2_M_SRC_EN),
	.TIME_OUT(P2_TIME_OUT),
	.M_DATA(P2_M_DATA),
	.M_ADDR_N(P2_M_ADDR_N),
	.STOPQ_N(P2_STOPQ_N),

	.rxd(uart_rxd),
	.txd(uart_txd),
	.rtsn(uart_rtsn),
	.ctsn(uart_ctsn),
	.dtrn(uart_dtrn),
	.dsrn(uart_dsrn),
	.ri(uart_ri),
	.dcdn(uart_dcdn)
);

generate
if(DEBUG == "TRUE") begin
ila_0 ila_mac_i0(
	.clk(CLK), // input wire clk
	.probe0({
		phy_speed,
		phy_duplex,
		phy_up,
		phy_lsc,
		phy_port,

		P0_ADDR,
		P0_ADDR_VLD,
		P0_BASE_HIT,
		P0_S_TERM,
		P0_S_READY,
		P0_S_ABORT,
		P0_S_WRDN,
		P0_S_SRC_EN,
		P0_S_DATA,
		P0_S_DATA_VLD,
		P0_S_CBE,
		P0_INT_N,
		P0_REQUEST,
		P0_REQUESTHOLD,
		P0_M_CBE,
		P0_M_WRDN,
		P0_COMPLETE,
		P0_M_READY,
		P0_M_DATA_VLD,
		P0_M_SRC_EN,
		P0_TIME_OUT,
		P0_M_DATA,
		P0_M_ADDR_N,
		P0_STOPQ_N,
		P1_ADDR,
		P1_ADDR_VLD,
		P1_BASE_HIT,
		P1_S_TERM,
		P1_S_READY,
		P1_S_ABORT,
		P1_S_WRDN,
		P1_S_SRC_EN,
		P1_S_DATA,
		P1_S_DATA_VLD,
		P1_S_CBE,
		P1_INT_N,
		P1_REQUEST,
		P1_REQUESTHOLD,
		P1_M_CBE,
		P1_M_WRDN,
		P1_COMPLETE,
		P1_M_READY,
		P1_M_DATA_VLD,
		P1_M_SRC_EN,
		P1_TIME_OUT,
		P1_M_DATA,
		P1_M_ADDR_N,
		P1_STOPQ_N,
		P2_ADDR,
		P2_ADDR_VLD,
		P2_BASE_HIT,
		P2_S_TERM,
		P2_S_READY,
		P2_S_ABORT,
		P2_S_WRDN,
		P2_S_SRC_EN,
		P2_S_DATA,
		P2_S_DATA_VLD,
		P2_S_CBE,
		P2_INT_N,
		P2_REQUEST,
		P2_REQUESTHOLD,
		P2_M_CBE,
		P2_M_WRDN,
		P2_COMPLETE,
		P2_M_READY,
		P2_M_DATA_VLD,
		P2_M_SRC_EN,
		P2_TIME_OUT,
		P2_M_DATA,
		P2_M_ADDR_N,
		P2_STOPQ_N
	})
);
end
endgenerate

endmodule
