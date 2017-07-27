module multi_top(
	// PCI Local Bus
	inout	[31:0] AD,
	inout   [3:0] CBE,
	inout   PAR,
	inout   FRAME_N,
	inout   TRDY_N,
	inout   IRDY_N,
	inout   STOP_N,
	inout   DEVSEL_N,
	//input   IDSEL, // not connected on current board
	inout   PERR_N,
	inout   SERR_N,
	inout   INTA_N,
	inout   INTB_N,
	inout   INTC_N,
	inout   INTD_N,
	//output  [2:0] PME_N, // not connected on current board
	inout   [2:0] REQ_N,
	inout   [2:0] GNT_N,
	input   RST_N,
	input   PCLK,
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

parameter [23:0] NIC_MAC_OUI=24'hEC3F05;
//parameter [15:0] NIC_SUBSYSID=16'h0050;
//parameter [15:0] NIC_SUBVID=16'h10EE;
//parameter [15:0] NIC_DEVICEID=16'h0050;
//parameter [15:0] NIC_VENDORID=16'h8086;
parameter [15:0] NIC_VENDORID=16'h0706;
parameter [15:0] NIC_DEVICEID=16'h3B00;
parameter [15:0] NIC_SUBVID=16'h8086;
parameter [15:0] NIC_SUBSYSID=16'h100E;
parameter [23:0] NIC_CLASSCODE=24'h020000;

//parameter [15:0] CAN_SUBSYSID=16'hC202;
//parameter [15:0] CAN_SUBVID=16'h13FE;
//parameter [15:0] CAN_DEVICEID=16'hC202;
//parameter [15:0] CAN_VENDORID=16'h13FE;
parameter [15:0] CAN_VENDORID=16'h0706;
parameter [15:0] CAN_DEVICEID=16'h3B02;
parameter [15:0] CAN_SUBVID=16'h13FE;
parameter [15:0] CAN_SUBSYSID=16'hC202;
parameter [23:0] CAN_CLASSCODE=24'h0C0900;
parameter CAN_PORT_NUM = 2;

//parameter [15:0] UART_SUBSYSID=16'h0031;
//parameter [15:0] UART_SUBVID=16'h12E0;
//parameter [15:0] UART_DEVICEID=16'h9050;
//parameter [15:0] UART_VENDORID=16'h10B5;
parameter [15:0] UART_VENDORID=16'h0706;
parameter [15:0] UART_DEVICEID=16'h3B01;
parameter [15:0] UART_SUBVID=16'h12E0;
parameter [15:0] UART_SUBSYSID=16'h0031;
parameter [23:0] UART_CLASSCODE=24'h070200;
parameter UART_PORT_NUM = 4;

wire pci_clk;
wire pci_rst_n;
wire pci_rst;
assign pci_rst = !pci_rst_n;

////////////////////////////////////////////////////////////////////////////////
// VIO test control
wire uart_test_en;
wire can_test_en;
wire nic_test_en;
wire nouse;
wire [35:0] vio_probe_in;
vio_debug vio_debug_i(
	.clk(pci_clk),
	.probe_in0(vio_probe_in),
	.probe_out0({
		nouse,
		can_test_en, 
		uart_test_en, 
		nic_test_en
	})
);

////////////////////////////////////////////////////////////////////////////////
// PCI Interface

assign PCI_EN_N = 1'b0;

wire p0_idseli;
wire [31:0] p0_adi;
wire [31:0] p0_ado;
wire p0_adt;
wire [3:0] p0_cbi;
wire [3:0] p0_cbo;
wire p0_cbt;
wire p0_pari;
wire p0_paro;
wire p0_part;
wire p0_framei;
wire p0_frameo;
wire p0_framet;
wire p0_trdyi;
wire p0_trdyo;
wire p0_trdyt;
wire p0_irdyi;
wire p0_irdyo;
wire p0_irdyt;
wire p0_stopi;
wire p0_stopo;
wire p0_stopt;
wire p0_devseli;
wire p0_devselo;
wire p0_devselt;
wire p0_perri;
wire p0_perro;
wire p0_perrt;
wire p0_serri;
wire p0_serro;
wire p0_serrt;
wire p0_gnti;
wire p0_reqo;
wire p0_reqt;
wire p0_into;
wire p0_intt;
wire p0_pmeo;
wire p0_pmet;

wire p1_idseli;
wire [31:0] p1_adi;
wire [31:0] p1_ado;
wire p1_adt;
wire [3:0] p1_cbi;
wire [3:0] p1_cbo;
wire p1_cbt;
wire p1_pari;
wire p1_paro;
wire p1_part;
wire p1_framei;
wire p1_frameo;
wire p1_framet;
wire p1_trdyi;
wire p1_trdyo;
wire p1_trdyt;
wire p1_irdyi;
wire p1_irdyo;
wire p1_irdyt;
wire p1_stopi;
wire p1_stopo;
wire p1_stopt;
wire p1_devseli;
wire p1_devselo;
wire p1_devselt;
wire p1_perri;
wire p1_perro;
wire p1_perrt;
wire p1_serri;
wire p1_serro;
wire p1_serrt;
wire p1_gnti;
wire p1_reqo;
wire p1_reqt;
wire p1_into;
wire p1_intt;
wire p1_pmeo;
wire p1_pmet;

wire p2_idseli;
wire [31:0] p2_adi;
wire [31:0] p2_ado;
wire p2_adt;
wire [3:0] p2_cbi;
wire [3:0] p2_cbo;
wire p2_cbt;
wire p2_pari;
wire p2_paro;
wire p2_part;
wire p2_framei;
wire p2_frameo;
wire p2_framet;
wire p2_trdyi;
wire p2_trdyo;
wire p2_trdyt;
wire p2_irdyi;
wire p2_irdyo;
wire p2_irdyt;
wire p2_stopi;
wire p2_stopo;
wire p2_stopt;
wire p2_devseli;
wire p2_devselo;
wire p2_devselt;
wire p2_perri;
wire p2_perro;
wire p2_perrt;
wire p2_serri;
wire p2_serro;
wire p2_serrt;
wire p2_gnti;
wire p2_reqo;
wire p2_reqt;
wire p2_into;
wire p2_intt;
wire p2_pmeo;
wire p2_pmet;

pci_mux pci_mux_i(
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
	.INTA_IO(INTA_N),
	.INTB_IO(INTB_N),
	.INTC_IO(INTC_N),
	.INTD_IO(INTD_N),
//	.PME_IO(PME_N),
	.REQ_IO(REQ_N),
	.GNT_IO(GNT_N),
	.RST_I(RST_N),
	.CLK_I(PCLK),

	.clk_o(pci_clk),
	.rstn_o(pci_rst_n),

    .p0_idseli(p0_idseli),
    .p0_adi(p0_adi),
    .p0_ado(p0_ado),
    .p0_adt(p0_adt),
    .p0_cbi(p0_cbi),
    .p0_cbo(p0_cbo),
    .p0_cbt(p0_cbt),
    .p0_pari(p0_pari),
    .p0_paro(p0_paro),
    .p0_part(p0_part),
    .p0_framei(p0_framei),
    .p0_frameo(p0_frameo),
    .p0_framet(p0_framet),
    .p0_trdyi(p0_trdyi),
    .p0_trdyo(p0_trdyo),
    .p0_trdyt(p0_trdyt),
    .p0_irdyi(p0_irdyi),
    .p0_irdyo(p0_irdyo),
    .p0_irdyt(p0_irdyt),
    .p0_stopi(p0_stopi),
    .p0_stopo(p0_stopo),
    .p0_stopt(p0_stopt),
    .p0_devseli(p0_devseli),
    .p0_devselo(p0_devselo),
    .p0_devselt(p0_devselt),
    .p0_perri(p0_perri),
    .p0_perro(p0_perro),
    .p0_perrt(p0_perrt),
    .p0_serri(p0_serri),
    .p0_serro(p0_serro),
    .p0_serrt(p0_serrt),
    .p0_gnti(p0_gnti),
    .p0_reqo(p0_reqo),
    .p0_reqt(p0_reqt),
    .p0_into(p0_into),
    .p0_intt(p0_intt),
    .p0_pmeo(p0_pmeo),
    .p0_pmet(p0_pmet),

    .p1_idseli(p1_idseli),
    .p1_adi(p1_adi),
    .p1_ado(p1_ado),
    .p1_adt(p1_adt),
    .p1_cbi(p1_cbi),
    .p1_cbo(p1_cbo),
    .p1_cbt(p1_cbt),
    .p1_pari(p1_pari),
    .p1_paro(p1_paro),
    .p1_part(p1_part),
    .p1_framei(p1_framei),
    .p1_frameo(p1_frameo),
    .p1_framet(p1_framet),
    .p1_trdyi(p1_trdyi),
    .p1_trdyo(p1_trdyo),
    .p1_trdyt(p1_trdyt),
    .p1_irdyi(p1_irdyi),
    .p1_irdyo(p1_irdyo),
    .p1_irdyt(p1_irdyt),
    .p1_stopi(p1_stopi),
    .p1_stopo(p1_stopo),
    .p1_stopt(p1_stopt),
    .p1_devseli(p1_devseli),
    .p1_devselo(p1_devselo),
    .p1_devselt(p1_devselt),
    .p1_perri(p1_perri),
    .p1_perro(p1_perro),
    .p1_perrt(p1_perrt),
    .p1_serri(p1_serri),
    .p1_serro(p1_serro),
    .p1_serrt(p1_serrt),
    .p1_gnti(p1_gnti),
    .p1_reqo(p1_reqo),
    .p1_reqt(p1_reqt),
    .p1_into(p1_into),
    .p1_intt(p1_intt),
    .p1_pmeo(p1_pmeo),
    .p1_pmet(p1_pmet),

    .p2_idseli(p2_idseli),
    .p2_adi(p2_adi),
    .p2_ado(p2_ado),
    .p2_adt(p2_adt),
    .p2_cbi(p2_cbi),
    .p2_cbo(p2_cbo),
    .p2_cbt(p2_cbt),
    .p2_pari(p2_pari),
    .p2_paro(p2_paro),
    .p2_part(p2_part),
    .p2_framei(p2_framei),
    .p2_frameo(p2_frameo),
    .p2_framet(p2_framet),
    .p2_trdyi(p2_trdyi),
    .p2_trdyo(p2_trdyo),
    .p2_trdyt(p2_trdyt),
    .p2_irdyi(p2_irdyi),
    .p2_irdyo(p2_irdyo),
    .p2_irdyt(p2_irdyt),
    .p2_stopi(p2_stopi),
    .p2_stopo(p2_stopo),
    .p2_stopt(p2_stopt),
    .p2_devseli(p2_devseli),
    .p2_devselo(p2_devselo),
    .p2_devselt(p2_devselt),
    .p2_perri(p2_perri),
    .p2_perro(p2_perro),
    .p2_perrt(p2_perrt),
    .p2_serri(p2_serri),
    .p2_serro(p2_serro),
    .p2_serrt(p2_serrt),
    .p2_gnti(p2_gnti),
    .p2_reqo(p2_reqo),
    .p2_reqt(p2_reqt),
    .p2_into(p2_into),
    .p2_intt(p2_intt),
    .p2_pmeo(p2_pmeo),
    .p2_pmet(p2_pmet)
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

wire	[47:0] mac_address;
wire	mac_valid;

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

assign vio_probe_in[0] = phy_port;
assign vio_probe_in[1] = phy_lsc;
assign vio_probe_in[2] = phy_up;
assign vio_probe_in[3] = phy_duplex;
assign vio_probe_in[5:4] = phy_speed;
assign vio_probe_in[6] = p0_ibs_up;
assign vio_probe_in[7] = p0_ibs_dplx;
assign vio_probe_in[9:8] = p0_ibs_spd;
assign vio_probe_in[10] = p1_ibs_up;
assign vio_probe_in[11] = p1_ibs_dplx;
assign vio_probe_in[13:12] = p1_ibs_spd;

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

assign sdp6_data = phy_up && phy_port==1'b0;
assign sdp7_data = phy_up && phy_port==1'b1;

nic_pci_wrapper #(
	.VENDORID(NIC_VENDORID),
	.DEVICEID(NIC_DEVICEID),
	.SUBVID(NIC_SUBVID),
	.SUBSYSID(NIC_SUBSYSID),
	.CLASSCODE(NIC_CLASSCODE)
)nic_wrapper_i(
	.clki(pci_clk),
	.rstni(pci_rst_n),

    .idseli(p0_idseli),
    .adi(p0_adi),
    .ado(p0_ado),
    .adt(p0_adt),
    .cbi(p0_cbi),
    .cbo(p0_cbo),
    .cbt(p0_cbt),
    .pari(p0_pari),
    .paro(p0_paro),
    .part(p0_part),
    .framei(p0_framei),
    .frameo(p0_frameo),
    .framet(p0_framet),
    .trdyi(p0_trdyi),
    .trdyo(p0_trdyo),
    .trdyt(p0_trdyt),
    .irdyi(p0_irdyi),
    .irdyo(p0_irdyo),
    .irdyt(p0_irdyt),
    .stopi(p0_stopi),
    .stopo(p0_stopo),
    .stopt(p0_stopt),
    .devseli(p0_devseli),
    .devselo(p0_devselo),
    .devselt(p0_devselt),
    .perri(p0_perri),
    .perro(p0_perro),
    .perrt(p0_perrt),
    .serri(p0_serri),
    .serro(p0_serro),
    .serrt(p0_serrt),
	.locki(1'b1),
	.locko(),
	.lockt(),
    .gnti(p0_gnti),
    .reqo(p0_reqo),
    .reqt(p0_reqt),
	.inti(1'b1),
    .into(p0_into),
    .intt(p0_intt),
	.pmei(1'b1),
    .pmeo(p0_pmeo),
    .pmet(p0_pmet),
	.m66eni(1'b0),

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
	.clk(pci_clk),
	.rst(pci_rst),
	
	.mac_address(mac_address),
	.mac_valid(mac_valid),

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
	.clk_i(pci_clk),
	.rst_i(pci_rst),
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
	.MAC_OUI(NIC_MAC_OUI),
	.SUB_PID(NIC_SUBSYSID),
	.SUB_VID(NIC_SUBVID),
	.PID(NIC_DEVICEID),
	.VID(NIC_VENDORID)
) rom_i (
	.clk_i(pci_clk),
	.rst_i(pci_rst),
	.read_addr(eeprom_raddr),
	.read_enable(eeprom_ren),
	.read_data(eeprom_rdata),
	.mac_address(mac_address),
	.mac_valid(mac_valid)
);

end
else begin
	assign p0_adt = 1'b1;
	assign p0_cbt = 1'b1;
	assign p0_part = 1'b1;
	assign p0_framet = 1'b1;
	assign p0_trdyt = 1'b1;
	assign p0_irdyt = 1'b1;
	assign p0_stopt = 1'b1;
	assign p0_devselt = 1'b1;
	assign p0_perrt = 1'b1;
	assign p0_serrt = 1'b1;
	assign p0_reqt = 1'b1;
	assign p0_intt = 1'b1;
	assign p0_pmet = 1'b1;

	assign p0_txdat = 8'bz;
	assign p0_txen = 1'bz;
	assign p0_txer = 1'bz;
	assign p0_gtxsclk = 1'bz;
	assign p0_mdc =  1'bz;
	assign p0_resetn = 1'bz;

	assign p1_txdat = 8'bz;
	assign p1_txen = 1'bz;
	assign p1_txer = 1'bz;
	assign p1_gtxsclk = 1'bz;
	assign p1_mdc =  1'bz;
	assign p1_resetn = 1'bz;
end
endgenerate

////////////////////////////////////////////////////////////////////////////////
// Multi-Port CAN Controller

generate
if(MPC_ENABLE=="TRUE") begin

wire [CAN_PORT_NUM-1:0] can_rx;
wire [CAN_PORT_NUM-1:0] can_tx;
wire [CAN_PORT_NUM-1:0] can_bus_on;

assign can0_tx = can_tx[0];
assign can0_rs = !can_bus_on[0];
assign can_rx[0] = can_test_en ? (&can_tx) : can0_rx;

assign can1_tx = can_tx[1];
assign can1_rs = !can_bus_on[1];
assign can_rx[1] = can_test_en ? (&can_tx) : can1_rx;

assign vio_probe_in[17:16] = can_rx;
assign vio_probe_in[19:18] = can_tx;
assign vio_probe_in[21:20] = can_bus_on;

mpc_pci_wrapper #(
	.VENDORID(CAN_VENDORID),
	.DEVICEID(CAN_DEVICEID),
	.SUBVID(CAN_SUBVID),
	.SUBSYSID(CAN_SUBSYSID),
	.CLASSCODE(CAN_CLASSCODE),
	.PORT_NUM(CAN_PORT_NUM)
)mpc_wrapper_i(
	.clki(pci_clk),
	.rstni(pci_rst_n),

    .idseli(p1_idseli),
    .adi(p1_adi),
    .ado(p1_ado),
    .adt(p1_adt),
    .cbi(p1_cbi),
    .cbo(p1_cbo),
    .cbt(p1_cbt),
    .pari(p1_pari),
    .paro(p1_paro),
    .part(p1_part),
    .framei(p1_framei),
    .frameo(p1_frameo),
    .framet(p1_framet),
    .trdyi(p1_trdyi),
    .trdyo(p1_trdyo),
    .trdyt(p1_trdyt),
    .irdyi(p1_irdyi),
    .irdyo(p1_irdyo),
    .irdyt(p1_irdyt),
    .stopi(p1_stopi),
    .stopo(p1_stopo),
    .stopt(p1_stopt),
    .devseli(p1_devseli),
    .devselo(p1_devselo),
    .devselt(p1_devselt),
    .perri(p1_perri),
    .perro(p1_perro),
    .perrt(p1_perrt),
    .serri(p1_serri),
    .serro(p1_serro),
    .serrt(p1_serrt),
	.locki(1'b1),
	.locko(),
	.lockt(),
    .gnti(p1_gnti),
    .reqo(p1_reqo),
    .reqt(p1_reqt),
	.inti(1'b1),
    .into(p1_into),
    .intt(p1_intt),
	.pmei(1'b1),
    .pmeo(p1_pmeo),
    .pmet(p1_pmet),
	.m66eni(1'b0),

	.rx_i(can_rx),
	.tx_o(can_tx),
	.bus_off_on(can_bus_on)
);

end
else begin
	assign p1_adt = 1'b1;
	assign p1_cbt = 1'b1;
	assign p1_part = 1'b1;
	assign p1_framet = 1'b1;
	assign p1_trdyt = 1'b1;
	assign p1_irdyt = 1'b1;
	assign p1_stopt = 1'b1;
	assign p1_devselt = 1'b1;
	assign p1_perrt = 1'b1;
	assign p1_serrt = 1'b1;
	assign p1_reqt = 1'b1;
	assign p1_intt = 1'b1;
	assign p1_pmet = 1'b1;

	assign can0_tx = 1'bz;
	assign can0_rs = 1'bz;

	assign can1_tx = 1'bz;
	assign can1_rs = 1'bz;
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
assign uart_rxd[0] = uart_test_en ? uart_txd[1] : uart0_rx;

assign uart1_rxen_n = uart_dtr[1];
assign uart1_tx = uart_txd[1];
assign uart1_txen = ~uart_rts[1];
assign uart_rxd[1] = uart_test_en ? uart_txd[0] : uart1_rx;

assign uart2_rxen_n = uart_dtr[2];
assign uart2_tx = uart_txd[2];
assign uart2_txen = ~uart_rts[2];
assign uart_rxd[2] = uart_test_en ? uart_txd[3] : uart2_rx;

assign uart3_rxen_n = uart_dtr[3];
assign uart3_tx = uart_txd[3];
assign uart3_txen = ~uart_rts[3];
assign uart_rxd[3] = uart_test_en ? uart_txd[2] : uart3_rx;

assign uart_cts = {UART_PORT_NUM{1'b0}};
assign uart_dsr = {UART_PORT_NUM{1'b0}};
assign uart_ri = {UART_PORT_NUM{1'b1}};
assign uart_dcd = {UART_PORT_NUM{1'b1}};

assign vio_probe_in[27:24] = uart_rxd;
assign vio_probe_in[31:28] = uart_txd;
assign vio_probe_in[35:32] = uart_dtr;

mps_pci_wrapper #(
	.VENDORID(UART_VENDORID),
	.DEVICEID(UART_DEVICEID),
	.SUBVID(UART_SUBVID),
	.SUBSYSID(UART_SUBSYSID),
	.CLASSCODE(UART_CLASSCODE),
	.PORT_NUM(UART_PORT_NUM)
)mps_wrapper_i(
	.clki(pci_clk),
	.rstni(pci_rst_n),

    .idseli(p2_idseli),
    .adi(p2_adi),
    .ado(p2_ado),
    .adt(p2_adt),
    .cbi(p2_cbi),
    .cbo(p2_cbo),
    .cbt(p2_cbt),
    .pari(p2_pari),
    .paro(p2_paro),
    .part(p2_part),
    .framei(p2_framei),
    .frameo(p2_frameo),
    .framet(p2_framet),
    .trdyi(p2_trdyi),
    .trdyo(p2_trdyo),
    .trdyt(p2_trdyt),
    .irdyi(p2_irdyi),
    .irdyo(p2_irdyo),
    .irdyt(p2_irdyt),
    .stopi(p2_stopi),
    .stopo(p2_stopo),
    .stopt(p2_stopt),
    .devseli(p2_devseli),
    .devselo(p2_devselo),
    .devselt(p2_devselt),
    .perri(p2_perri),
    .perro(p2_perro),
    .perrt(p2_perrt),
    .serri(p2_serri),
    .serro(p2_serro),
    .serrt(p2_serrt),
	.locki(1'b1),
	.locko(),
	.lockt(),
    .gnti(p2_gnti),
    .reqo(p2_reqo),
    .reqt(p2_reqt),
	.inti(1'b1),
    .into(p2_into),
    .intt(p2_intt),
	.pmei(1'b1),
    .pmeo(p2_pmeo),
    .pmet(p2_pmet),
	.m66eni(1'b0),

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
else begin
	assign p2_adt = 1'b1;
	assign p2_cbt = 1'b1;
	assign p2_part = 1'b1;
	assign p2_framet = 1'b1;
	assign p2_trdyt = 1'b1;
	assign p2_irdyt = 1'b1;
	assign p2_stopt = 1'b1;
	assign p2_devselt = 1'b1;
	assign p2_perrt = 1'b1;
	assign p2_serrt = 1'b1;
	assign p2_reqt = 1'b1;
	assign p2_intt = 1'b1;
	assign p2_pmet = 1'b1;

	assign uart0_rxen_n = 1'bz;
	assign uart0_tx = 1'bz;
	assign uart0_txen = 1'bz;
	assign uart1_rxen_n = 1'bz;
	assign uart1_tx = 1'bz;
	assign uart1_txen = 1'bz;
	assign uart2_rxen_n = 1'bz;
	assign uart2_tx = 1'bz;
	assign uart2_txen = 1'bz;
	assign uart3_rxen_n = 1'bz;
	assign uart3_tx = 1'bz;
	assign uart3_txen = 1'bz;
end
endgenerate

endmodule
