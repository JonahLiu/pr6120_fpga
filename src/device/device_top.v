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
	//input         IDSEL, // not connected on current board
	inout         PERR_N,
	inout         SERR_N,
	output        INTA_N,
	output        INTB_N,
	output        INTC_N,
	output        INTD_N,
	//output        PMEA_N, // not connected on current board
	output        [2:0] REQ_N,
	input         [2:0] GNT_N,
	input         RST_N,
	input         PCLK,
	output	PCI_EN_N, // This signal controls interrupt output on current board

	// Ethernet 0 GMII
	// 88E1111, RGMII mode
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
	// 88E1111, RGMII mode
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
	output  can0_rs, // low-active enable

	// CAN 1
	input	can1_rx,
	output	can1_tx,
	output  can1_rs, // low-active enable

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

parameter NIC_ENABLE="TRUE";
parameter MPC_ENABLE="TRUE";
parameter MPS_ENABLE="TRUE";
parameter DEBUG="TRUE";
parameter UART_PORT_NUM = 4;
parameter CAN_PORT_NUM = 2;
parameter [23:0] MAC_OUI=24'hEC3F05;
parameter [15:0] SUB_PID=16'h6120;
parameter [15:0] SUB_VID=16'hFACE;
parameter [15:0] PID=16'hABCD;
parameter [15:0] VID=16'h8086;

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

pci_multi #(
	.P0_ENABLE(NIC_ENABLE),
	.P1_ENABLE(MPC_ENABLE),
	.P2_ENABLE(MPS_ENABLE)
)pci_multi_i(
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

generate
if(NIC_ENABLE=="TRUE") begin

wire	nic_txclk;

wire	mac_rxclk;
wire	[7:0]	mac_rxdat;
wire	mac_rxdv;
wire	mac_rxer;
wire	mac_txclk;
wire	[7:0]	mac_txdat;
wire	mac_txen;
wire	mac_txer;
wire	mac_crs;
wire	mac_col;

wire	mac_rx_err_flag;
wire	mac_rx_ok_flag;

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

wire	phy0_rxclk_x2;
wire	phy0_rxclk;
wire	[7:0] phy0_rxdat;
wire	phy0_rxdv;
wire	phy0_rxer;
wire 	phy0_txclk_x2;
wire	phy0_txclk;
wire	[7:0] phy0_txdat;
wire 	phy0_txen;
wire	phy0_txer;
wire	phy0_crs;
wire	phy0_col;
wire	phy0_up;
wire	[1:0] phy0_speed;
wire	phy0_duplex;

wire	phy1_rxclk_x2;
wire	phy1_rxclk;
wire	[7:0] phy1_rxdat;
wire	phy1_rxdv;
wire	phy1_rxer;
wire 	phy1_txclk_x2;
wire	phy1_txclk;
wire	[7:0] phy1_txdat;
wire 	phy1_txen;
wire	phy1_txer;
wire	phy1_crs;
wire	phy1_col;
wire	phy1_up;
wire	[1:0] phy1_speed;
wire	phy1_duplex;

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

wire    [1:0] p0_ibs_spd;
wire	p0_ibs_up;
wire	p0_ibs_dplx;
wire    [1:0] p1_ibs_spd;
wire	p1_ibs_up;
wire	p1_ibs_dplx;

wire	[7:0] p0_dbg_data;
wire	p0_dbg_dv;
wire	p0_dbg_er;
wire	[7:0] p1_dbg_data;
wire	p1_dbg_dv;
wire	p1_dbg_er;

wire	sdp6_data;
wire	sdp7_data;

assign	p0_mdio = p0_mdio_oe?p0_mdio_o:1'bz;
assign  p0_mdio_i = p0_mdio;
assign	p0_resetn = !p0_reset_out;
assign	p1_mdio = p1_mdio_oe?p1_mdio_o:1'bz;
assign  p1_mdio_i = p1_mdio;
assign	p1_resetn = !p1_reset_out;

assign  p0_txdat[7:4] = 4'b0;
assign  p0_txer = 1'b0;
assign  p1_txdat[7:4] = 4'b0;
assign  p1_txer = 1'b0;

// RX clock was loop back as TX clock
assign nic_txclk = mac_rxclk;
// so we can use clk_x2 directly.
assign phy0_txclk_x2 = phy0_rxclk_x2;
assign phy1_txclk_x2 = phy1_rxclk_x2;
// If a standalone clock used for TX, connect these
// to a clock that is x2 of mac_gtxclk.
// assign nic_txclk = clkout;
// assign phy0_txclk_x2 = clkout_x2;
// assign phy1_txclk_x2 = clkout_x2;

assign sdp6_data = phy_port;
assign sdp7_data = phy_lsc;

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

	.gtxclk(nic_txclk),

	// GMII interface
	.mac_rxdat(mac_rxdat),
	.mac_rxdv(mac_rxdv),
	.mac_rxer(mac_rxer),
	.mac_rxsclk(mac_rxclk),
	.mac_txdat(mac_txdat),
	.mac_txen(mac_txen),
	.mac_txer(mac_txer),
	.mac_gtxsclk(mac_txclk),
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

	// GPI Input
	.sdp6_data(sdp6_data),
	.sdp7_data(sdp7_data),

	// EEPROM interface
	.eesk(eesk),
	.eecs(eecs),
	.eedo(eedo),
	.eedi(eedi)
);

// Dual redundancy fault-tolerant
phy_ft #(.PHY_ADDR(5'b0), .CLK_PERIOD_NS(30), 
	.INIT_EPCR("FALSE")
) phy_ft_i(
	.clk(CLK),
	.rst(RST),

	.speed(phy_speed),
	.full_duplex(phy_duplex),
	.link_up(phy_up),
	.active_port(phy_port),
	.link_change(phy_lsc),
	.phy0_up(phy0_up),
	.phy0_speed(phy0_speed),
	.phy0_duplex(phy0_duplex),
	.phy1_up(phy1_up),
	.phy1_speed(phy1_speed),
	.phy1_duplex(phy1_duplex),

	.rxclk(mac_rxclk),
	.rxdat(mac_rxdat),
	.rxdv(mac_rxdv),
	.rxer(mac_rxer),
	.txclk(mac_txclk),
	.txdat(mac_txdat),
	.txen(mac_txen),
	.txer(mac_txer),
	.crs(mac_crs),
	.col(mac_col),

	.mac_rx_err(mac_rx_err_flag),
	.mac_rx_ok(mac_rx_ok_flag),

	.mdc(phy_mdc),
	.mdio_i(phy_mdio_i),
	.mdio_o(phy_mdio_o),
	.mdio_oe(phy_mdio_oe),
	.mdio_req(phy_mdio_req),
	.mdio_gnt(phy_mdio_gnt),
	.intr_out(phy_int),
	.reset_in(phy_reset_out),

	.phy0_rxclk(phy0_rxclk),
	.phy0_rxdat(phy0_rxdat),
	.phy0_rxdv(phy0_rxdv),
	.phy0_rxer(phy0_rxer),
	.phy0_txclk(phy0_txclk),
	.phy0_txdat(phy0_txdat),
	.phy0_txen(phy0_txen),
	.phy0_txer(phy0_txer),
	.phy0_crs(phy0_crs),
	.phy0_col(phy0_col),
	.phy0_ibs_up(p0_ibs_up),
	.phy0_ibs_spd(p0_ibs_spd),
	.phy0_ibs_dplx(p0_ibs_dplx),
	.phy0_mdc(p0_mdc),
	.phy0_mdio_i(p0_mdio_i),
	.phy0_mdio_o(p0_mdio_o),
	.phy0_mdio_oe(p0_mdio_oe),
	.phy0_int(p0_int),
	.phy0_reset_out(p0_reset_out),

	.phy1_rxclk(phy1_rxclk),
	.phy1_rxdat(phy1_rxdat),
	.phy1_rxdv(phy1_rxdv),
	.phy1_rxer(phy1_rxer),
	.phy1_txclk(phy1_txclk),
	.phy1_txdat(phy1_txdat),
	.phy1_txen(phy1_txen),
	.phy1_txer(phy1_txer),
	.phy1_crs(phy1_crs),
	.phy1_col(phy1_col),
	.phy1_ibs_up(p1_ibs_up),
	.phy1_ibs_spd(p1_ibs_spd),
	.phy1_ibs_dplx(p1_ibs_dplx),
	.phy1_mdc(p1_mdc),
	.phy1_mdio_i(p1_mdio_i),
	.phy1_mdio_o(p1_mdio_o),
	.phy1_mdio_oe(p1_mdio_oe),
	.phy1_int(p1_int),
	.phy1_reset_out(p1_reset_out)
);

rgmii_if #(.DELAY_MODE("INTERNAL")) p0_if_i(
	.reset(p0_reset_out),
	.speed(phy0_speed[1]),

	.ibs_up(p0_ibs_up),
	.ibs_spd(p0_ibs_spd),
	.ibs_dplx(p0_ibs_dplx),

	.rgmii_rxclk(p0_rxsclk),
	.rgmii_rxdat(p0_rxdat[3:0]),
	.rgmii_rxctl(p0_rxdv),
	.rgmii_gtxclk(p0_gtxsclk),
	.rgmii_txdat(p0_txdat[3:0]),
	.rgmii_txctl(p0_txen),
	.rgmii_crs(p0_crs),
	.rgmii_col(p0_col),

	.dbg_data(p0_dbg_data),
	.dbg_dv(p0_dbg_dv),
	.dbg_er(p0_dbg_er),

	.txclk_x2(phy0_txclk_x2),
	.txclk(phy0_txclk),
	.txd(phy0_txdat),
	.txen(phy0_txen),
	.txer(phy0_txer),
	.rxclk_x2(phy0_rxclk_x2),
	.rxclk(phy0_rxclk),
	.rxd(phy0_rxdat),
	.rxdv(phy0_rxdv),
	.rxer(phy0_rxer),
	.crs(phy0_crs),
	.col(phy0_col)
);

rgmii_if #(.DELAY_MODE("INTERNAL")) p1_if_i(
	.reset(p1_reset_out),
	.speed(phy1_speed[1]),

	.ibs_up(p1_ibs_up),
	.ibs_spd(p1_ibs_spd),
	.ibs_dplx(p1_ibs_dplx),

	.rgmii_rxclk(p1_rxsclk),
	.rgmii_rxdat(p1_rxdat[3:0]),
	.rgmii_rxctl(p1_rxdv),
	.rgmii_gtxclk(p1_gtxsclk),
	.rgmii_txdat(p1_txdat[3:0]),
	.rgmii_txctl(p1_txen),
	.rgmii_crs(p1_crs),
	.rgmii_col(p1_col),

	.dbg_data(p1_dbg_data),
	.dbg_dv(p1_dbg_dv),
	.dbg_er(p1_dbg_er),

	.txclk_x2(phy1_txclk_x2),
	.txclk(phy1_txclk),
	.txd(phy1_txdat),
	.txen(phy1_txen),
	.txer(phy1_txer),
	.rxclk_x2(phy1_rxclk_x2),
	.rxclk(phy1_rxclk),
	.rxd(phy1_rxdat),
	.rxdv(phy1_rxdv),
	.rxer(phy1_rxer),
	.crs(phy1_crs),
	.col(phy1_col)
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

config_rom #(
	.MAC_OUI(MAC_OUI),
	.SUB_PID(SUB_PID),
	.SUB_VID(SUB_VID),
	.PID(PID),
	.VID(VID)
) rom_i (
	.clk_i(CLK),
	.rst_i(RST),
	.read_addr(eeprom_raddr),
	.read_enable(eeprom_ren),
	.read_data(eeprom_rdata)
);

end
endgenerate

////////////////////////////////////////////////////////////////////////////////
// Multi-Port CAN Controller

generate
if(MPC_ENABLE=="TRUE") begin

wire [CAN_PORT_NUM-1:0] can_rx;
wire [CAN_PORT_NUM-1:0] can_tx;
wire [CAN_PORT_NUM-1:0] can_bus_off_on;

assign can0_tx = can_tx[0];
assign can0_rs = 1'b0;
assign can_rx[0] = can0_rx;

assign can1_tx = can_tx[1];
assign can1_rs = 1'b0;
assign can_rx[1] = can1_rx;

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

end
endgenerate

////////////////////////////////////////////////////////////////////////////////
// Multi-Port Serial Controller
generate
if(MPS_ENABLE=="TRUE") begin

wire [UART_PORT_NUM-1:0] uart_rxd;
wire [UART_PORT_NUM-1:0] uart_txd;
wire [UART_PORT_NUM-1:0] uart_rts;
wire [UART_PORT_NUM-1:0] uart_cts;
wire [UART_PORT_NUM-1:0] uart_dtr;
wire [UART_PORT_NUM-1:0] uart_dsr;
wire [UART_PORT_NUM-1:0] uart_ri;
wire [UART_PORT_NUM-1:0] uart_dcd;

assign uart0_rxen_n = uart_dtr[0];
assign uart0_tx = uart_txd[0];
assign uart0_txen = ~uart_rts[0];
assign uart_rxd[0] = uart0_rx;

assign uart1_rxen_n = uart_dtr[1];
assign uart1_tx = uart_txd[1];
assign uart1_txen = ~uart_rts[1];
assign uart_rxd[1] = uart1_rx;

assign uart2_rxen_n = uart_dtr[2];
assign uart2_tx = uart_txd[2];
assign uart2_txen = ~uart_rts[2];
assign uart_rxd[2] = uart2_rx;

assign uart3_rxen_n = uart_dtr[3];
assign uart3_tx = uart_txd[3];
assign uart3_txen = ~uart_rts[3];
assign uart_rxd[3] = uart3_rx;

assign uart_cts = {UART_PORT_NUM{1'b0}};
assign uart_dsr = {UART_PORT_NUM{1'b0}};
assign uart_ri = {UART_PORT_NUM{1'b1}};
assign uart_dcd = {UART_PORT_NUM{1'b1}};

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
	.rts(uart_rts),
	.cts(uart_cts),
	.dtr(uart_dtr),
	.dsr(uart_dsr),
	.ri(uart_ri),
	.dcd(uart_dcd)
);

end
endgenerate

////////////////////////////////////////////////////////////////////////////////
// Debug probes

generate
if(DEBUG == "TRUE") begin
ila_0 ila_mac_i0(
	.clk(CLK), // input wire clk
	.probe0({
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
		P2_INT_N
	})
);
end
endgenerate

endmodule
