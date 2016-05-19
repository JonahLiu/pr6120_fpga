`timescale 1ns/10ps
`undef TEST_TX
`define TEST_RX

`define REPORT_PCI_FETCH
`define REPORT_PCI_WRITE_BACK
`undef REPORT_FETCH
`undef REPORT_WRITE_BACK
`define REPORT_INTERRUPT

module test_nic_device;
////////////////////////////////////////////////////////////////////////////////
// Parameters
//
// Host Address
parameter HOST_BASE = 32'hE000_0000;
parameter HOST_SIZE = 4*1024*1024;
parameter DESC_BUF_SIZE = HOST_SIZE/4;
parameter DATA_BUF_SIZE = HOST_SIZE/4;
parameter HOST_DESC_BASE = HOST_BASE;
parameter HOST_DATA_BASE = HOST_BASE+DESC_BUF_SIZE*2;

parameter TX_DESC_BASE = HOST_DESC_BASE;
parameter TX_DATA_BASE = HOST_DATA_BASE;
parameter RX_DESC_BASE = HOST_DESC_BASE+DESC_BUF_SIZE;
parameter RX_DATA_BASE = HOST_DATA_BASE+DATA_BUF_SIZE;

parameter HOST_DESC_BATCH = 4;

// Target Addresses
parameter TGT_CONF_ADDR = 32'h0100_0000;
parameter TGT_BAR0_BASE = 32'h8002_0000;
parameter TGT_BAR1_BASE = 32'h8004_0000;
parameter TGT_BAR2_BASE = 32'h0000_0010;

// PCI Configuration Registers
parameter CONF_ID_OFFSET  = 8'h0;
parameter CONF_CTRL_OFFSET  = 8'h4;
parameter CONF_CLINE_OFFSET  = 8'hc;
parameter CONF_MISC_OFFSET  = 8'h3c;
parameter CONF_BAR0_OFFSET  = 8'h10;
parameter CONF_BAR1_OFFSET  = 8'h14;
parameter CONF_BAR2_OFFSET  = 8'h18;

// E1000 Registers
parameter E1000_CTRL			=	16'h0000;
parameter E1000_CTRL_RST		=	(1<<26);
parameter E1000_CTRL_PHY_RST	=	(1<<31);

parameter E1000_ICR				=	16'h00C0;
parameter E1000_ICS				=	16'h00C8;
parameter E1000_IMS				=	16'h00D0;
parameter E1000_IMC				=	16'h00D8;
parameter E1000_INTR_TXDW		=	(1<<0);
parameter E1000_INTR_TXQE		=	(1<<1);
parameter E1000_INTR_LSC		=	(1<<2);
parameter E1000_INTR_RXSEQ		=	(1<<3);
parameter E1000_INTR_RXDMT0		=	(1<<4);
parameter E1000_INTR_RXDO		=	(1<<6);
parameter E1000_INTR_RXT0		=	(1<<7);
parameter E1000_INTR_MDAC		=	(1<<9);
parameter E1000_INTR_RXCFG		=	(1<<10);
parameter E1000_INTR_PHYINT		=	(1<<12);
parameter E1000_INTR_TXD_LOW	=	(1<<15);
parameter E1000_INTR_SPRD		=	(1<<16);

parameter E1000_TCTL			=	16'h0400;
parameter E1000_TCTL_EN		=	(1<<1);

parameter E1000_TXDMAC			=    16'h3000;
parameter E1000_TXDMAC_DPP		=	(1<<0);

parameter E1000_TDBAL			=    16'h3800;
parameter E1000_TDBAH			=    16'h3804;
parameter E1000_TDLEN			=    16'h3808;
parameter E1000_TDH			=    16'h3810;
parameter E1000_TDT			=    16'h3818;
parameter E1000_TIDV			=    16'h3820;

parameter E1000_TXDCTL			=	16'h3828;
parameter E1000_TXDCTL_PTHRESH_SHIFT 	= 0;
parameter E1000_TXDCTL_PTHRESH_MASK 	= 32'h3F;
parameter E1000_TXDCTL_HTHRESH_SHIFT 	= 8;
parameter E1000_TXDCTL_HTHRESH_MASK 	= 32'h3F;
parameter E1000_TXDCTL_WTHRESH_SHIFT 	= 16;
parameter E1000_TXDCTL_WTHRESH_MASK 	= 32'h3F;
parameter E1000_TXDCTL_GRAN 			= (1<<24);
parameter E1000_TXDCTL_LWTHRESH_SHIFT 	= 25;
parameter E1000_TXDCTL_LWTHRESH_MASK 	= 32'h7F;

parameter E1000_TADV				=   16'h382C;

parameter E1000_TSPMT				=	16'h3830;
parameter E1000_TSPMT_TSMT_SHIFT 	= 0;
parameter E1000_TSPMT_TSMT_MASK 	= 32'h3F;
parameter E1000_TSPMT_TSPBP_SHIFT 	= 16;
parameter E1000_TSPMT_TSPBP_MASK 	= 32'hFF;

parameter E1000_RCTL			=	16'h0100;
parameter E1000_RCTL_EN			=	(1<<1);
parameter E1000_RCTL_LPE		=	(1<<5);
parameter E1000_RCTL_BSIZE_SHIFT	=	(16);
parameter E1000_RCTL_BSIZE_MASK		= 2'b11;
parameter E1000_RCTL_BSEX		=	(1<<25);

parameter E1000_RDBAL			=    16'h2800;
parameter E1000_RDBAH			=    16'h2804;
parameter E1000_RDLEN			=    16'h2808;
parameter E1000_RDH				=    16'h2810;
parameter E1000_RDT				=    16'h2818;
parameter E1000_RDTR			=    16'h2820;

parameter E1000_RXDCTL			=	16'h2828;
parameter E1000_RXDCTL_PTHRESH_SHIFT 	= 0;
parameter E1000_RXDCTL_PTHRESH_MASK 	= 32'h3F;
parameter E1000_RXDCTL_HTHRESH_SHIFT 	= 8;
parameter E1000_RXDCTL_HTHRESH_MASK 	= 32'h3F;
parameter E1000_RXDCTL_WTHRESH_SHIFT 	= 16;
parameter E1000_RXDCTL_WTHRESH_MASK 	= 32'h3F;
parameter E1000_RXDCTL_GRAN 			= (1<<24);

parameter E1000_RADV				=   16'h282C;

parameter E1000_RXCSUM			=	16'h5000;
parameter E1000_RXCSUM_PCSS_SHIFT = 0;
parameter E1000_RXCSUM_PCSS_MASK = 32'h000000FF;

parameter E1000_IOADDR			= 16'h0000;
parameter E1000_IODATA			= 16'h0004;

localparam DESC_SIZE=16;
localparam HOST_MASK=HOST_SIZE-1;

localparam 
	CMD_INTR_ACK = 4'h0,
	CMD_SPECIAL = 4'h1,
	CMD_IO_READ = 4'h2,
	CMD_IO_WRITE = 4'h3,
	CMD_MEM_READ = 4'h6,
	CMD_MEM_WRITE = 4'h7,
	CMD_CONF_READ = 4'hA,
	CMD_CONF_WRITE = 4'hB,
	CMD_MEM_READ_MUL = 4'hC,
	CMD_DUAL_ADDR_CYC = 4'hD,
	CMD_MEM_READ_LN = 4'hE,
	CMD_MEM_WRITE_INVAL = 4'hF;
////////////////////////////////////////////////////////////////////////////////
// Local Connections
//
reg clk33;
reg rst;

wire [31:0] AD;
wire [3:0] CBE;
wire PAR;
wire FRAME_N;
wire TRDY_N;
wire IRDY_N;
wire STOP_N;
wire DEVSEL_N;
wire PERR_N;
wire SERR_N;
wire INTA_N;
wire PMEA_N;
wire [3:0] REQ_N;
wire [3:0] GNT_N;
wire RST_N;
wire PCLK;

wire [7:0] p0_rxdat;
wire p0_rxdv;
wire p0_rxer;
wire p0_rxsclk;
wire [7:0] p0_txdat;
wire p0_txen;
wire p0_txer;
wire p0_txsclk;
wire p0_gtxsclk;
wire p0_crs;
wire p0_col;
wire p0_mdc;
wire p0_mdio;
wire p0_int;
wire p0_resetn;

wire [7:0] p1_rxdat;
wire p1_rxdv;
wire p1_rxer;
wire p1_rxsclk;
wire [7:0] p1_txdat;
wire p1_txen;
wire p1_txer;
wire p1_txsclk;
wire p1_gtxsclk;
wire p1_crs;
wire p1_col;
wire p1_mdc;
wire p1_mdio;
wire p1_int;
wire p1_resetn;

pullup (FRAME_N);
pullup (IRDY_N);
pullup (TRDY_N);
pullup (STOP_N);
pullup (LOCK_N);
pullup (DEVSEL_N);
pullup (PERR_N);
pullup (SERR_N);
pullup (INTA_N);
pullup (PMEA_N);
/*
pullup (PAR);
pullup pu_ad [31:0] (AD);
pullup pu_cbe [3:0] (CBE);
*/
pullup pu_req [3:0] (REQ_N);
pullup pu_gnt [3:0] (GNT_N);


assign RST_N = !rst;
assign PCLK = clk33;


pullup (p0_mdio);
pulldown (p0_int);

pullup (p1_mdio);
pulldown (p1_int);

//assign p0_rxsclk = p0_gtxsclk;
//assign p0_rxdat = p0_txdat;
//assign p0_rxdv = p0_txen;
//assign p0_rxer = p0_txer;
assign p0_crs = p0_txen;
assign p0_col = 1'b0;

assign p1_rxsclk = 1'b0;
assign p1_rxdat = 8'b0;
assign p1_rxdv = 1'b0;
assign p1_rxer = 1'b0;
assign p1_crs = 1'b0;
assign p1_col = 1'b0;

////////////////////////////////////////////////////////////////////////////////
// Modules
// PCI to AXI interface controller
device_top #(.DEBUG("FALSE")) dut_i(
	// PCI Local Bus
	.AD(AD),
	.CBE(CBE),
	.PAR(PAR),
	.FRAME_N(FRAME_N),
	.TRDY_N(TRDY_N),
	.IRDY_N(IRDY_N),
	.STOP_N(STOP_N),
	.DEVSEL_N(DEVSEL_N),
	.IDSEL(AD[24]),
	.PERR_N(PERR_N),
	.SERR_N(SERR_N),
	.INTA_N(INTA_N),
	.PMEA_N(PMEA_N),
	.REQ_N(REQ_N[1]),
	.GNT_N(GNT_N[1]),
	.RST_N(RST_N),
	.PCLK(PCLK),

	.PCI_EN_N(),

	.p0_rxdat(p0_rxdat),
	.p0_rxdv(p0_rxdv),
	.p0_rxer(p0_rxer),
	.p0_rxsclk(p0_rxsclk),
	.p0_txdat(p0_txdat),
	.p0_txen(p0_txen),
	.p0_txer(p0_txer),
	.p0_txsclk(p0_txsclk),
	.p0_gtxsclk(p0_gtxsclk),
	.p0_crs(p0_crs),
	.p0_col(p0_col),
	.p0_mdc(p0_mdc),
	.p0_mdio(p0_mdio),
	.p0_int(p0_int),
	.p0_resetn(p0_resetn),

	.p1_rxdat(p1_rxdat),
	.p1_rxdv(p1_rxdv),
	.p1_rxer(p1_rxer),
	.p1_rxsclk(p1_rxsclk),
	.p1_txdat(p1_txdat),
	.p1_txen(p1_txen),
	.p1_txer(p1_txer),
	.p1_txsclk(p1_txsclk),
	.p1_gtxsclk(p1_gtxsclk),
	.p1_crs(p1_crs),
	.p1_col(p1_col),
	.p1_mdc(p1_mdc),
	.p1_mdio(p1_mdio),
	.p1_int(p1_int),
	.p1_resetn(p1_resetn),

	.can0_rx(1'b1),
	.can0_tx(),
	.can0_rs(),

	.can1_rx(1'b1),
	.can1_tx(),
	.can1_rs(),

	.uart0_rx(1'b1),
	.uart0_rxen_n(),
	.uart0_tx(),
	.uart0_txen(),

	.uart1_rx(1'b1),
	.uart1_rxen_n(),
	.uart1_tx(),
	.uart1_txen(),
	
	.uart2_rx(1'b1),
	.uart2_rxen_n(),
	.uart2_tx(),
	.uart2_txen(),

	.uart3_rx(1'b1),
	.uart3_rxen_n(),
	.uart3_tx(),
	.uart3_txen()
);

pci_behavioral_master master(
	.AD(AD),
	.CBE(CBE),
	.PAR(PAR),
	.FRAME_N(FRAME_N),
	.TRDY_N(TRDY_N),
	.IRDY_N(IRDY_N),
	.STOP_N(STOP_N),
	.DEVSEL_N(DEVSEL_N),
	.IDSEL(1'b0),
	.PERR_N(PERR_N),
	.SERR_N(SERR_N),
	.INTA_N(INTA_N),
	.REQ_N(REQ_N[0]),
	.GNT_N(GNT_N[0]),
	.RST_N(RST_N),
	.PCLK(PCLK)
);

pci_behavioral_target #(
	.BAR0_BASE(HOST_BASE), 
	.BAR0_SIZE(HOST_SIZE),
	.DATA_LATENCY(0)
) host(
	.AD(AD),
	.CBE(CBE),
	.PAR(PAR),
	.FRAME_N(FRAME_N),
	.TRDY_N(TRDY_N),
	.IRDY_N(IRDY_N),
	.STOP_N(STOP_N),
	.DEVSEL_N(DEVSEL_N),
	.IDSEL(1'b0),
	.PERR_N(PERR_N),
	.SERR_N(SERR_N),
	.RST_N(RST_N),
	.PCLK(PCLK)
);

////////////////////////////////////////////////////////////////////////////////
// PCI Arbiter

wire	[3:0]	arb_ext_gnt;
reg [3:0]   arb_ext_req_prev;
reg arb_frame_prev;
reg arb_irdy_prev;
assign	GNT_N = ~arb_ext_gnt;

always @(posedge PCLK)
    arb_ext_req_prev <= ~REQ_N;
always @(posedge PCLK)
    arb_frame_prev <= ~FRAME_N;
always @(posedge PCLK)
    arb_irdy_prev <= ~IRDY_N;

pci_blue_arbiter arbiter(
    //.pci_int_req_direct(pci_int_req_n),
    .pci_int_req_direct(1'b0),
    .pci_ext_req_prev(arb_ext_req_prev),
    .pci_int_gnt_direct_out(),
    .pci_ext_gnt_direct_out(arb_ext_gnt),
    .pci_frame_prev(arb_frame_prev),
    .pci_irdy_prev(arb_irdy_prev),
    .pci_irdy_now(~IRDY_N),
    .arbitration_enable(1'b1),
    .pci_clk(PCLK),
    .pci_reset_comb(!RST_N)
);
////////////////////////////////////////////////////////////////////////////////

eth_pkt_gen pkt_gen(
	.clk(p0_gtxsclk),
	.tx_clk(p0_rxsclk),
	.tx_dat(p0_rxdat),
	.tx_en(p0_rxdv),
	.tx_er(p0_rxer)
);

////////////////////////////////////////////////////////////////////////////////
// Utilities

wire [127:0] desc_data;
reg [63:0] desc_daddr;
reg [15:0] desc_length;
reg [7:0] desc_cso;
reg desc_eop;
reg desc_ifcs;
reg desc_ic;
reg desc_rs;
reg desc_dext;
reg desc_vle;
reg desc_ide;
reg [3:0] desc_sta;
reg [7:0] desc_css;
reg [15:0] desc_special;

assign desc_data[63:0] = desc_daddr;
assign desc_data[79:64] = desc_length;
assign desc_data[87:80] = desc_cso;
assign desc_data[88] = desc_eop;
assign desc_data[89] = desc_ifcs;
assign desc_data[90] = desc_ic;
assign desc_data[91] = desc_rs;
assign desc_data[92] = 1'b0;
assign desc_data[93] = desc_dext;
assign desc_data[94] = desc_vle;
assign desc_data[95] = desc_ide;
assign desc_data[99:96] = desc_sta;
assign desc_data[103:100] = 4'b0;
assign desc_data[111:104] = desc_css;
assign desc_data[127:112] = desc_special;

reg [127:0] resp_data;
wire [3:0] resp_sta;
wire resp_dd;

assign resp_sta = resp_data[99:96];
assign resp_dd = resp_sta[0];

reg [31:0] tx_host_base;
reg [15:0] tx_host_head;
reg [15:0] tx_host_tail;
reg [15:0] tx_host_len;
reg [31:0] tx_host_dptr;

reg [31:0] rx_host_base;
reg [15:0] rx_host_head;
reg [15:0] rx_host_tail;
reg [15:0] rx_host_len;
reg [31:0] rx_host_dptr;

reg [31:0] intr_state;

reg [0:511] dbg_msg;

reg PARAM_RS;
reg PARAM_IDE;
reg [1:0] PARAM_BSIZE;
reg PARAM_BSEX;
reg [7:0] PARAM_PCSS;

localparam REPORT_NONE=0, REPORT_ALL=1, REPORT_EOP=2;

function pci_cmd_is_mm_rd(input [3:0] cmd);
begin
	case(cmd)
		CMD_MEM_READ, CMD_MEM_READ_MUL, CMD_MEM_READ_LN:
			pci_cmd_is_mm_rd = 1;
		default:
			pci_cmd_is_mm_rd = 0;
	endcase
end
endfunction

function pci_cmd_is_mm_wr(input [3:0] cmd);
begin
	case(cmd)
		CMD_MEM_WRITE, CMD_MEM_WRITE_INVAL:
			pci_cmd_is_mm_wr = 1;
		default:
			pci_cmd_is_mm_wr = 0;
	endcase
end
endfunction

function integer queue_spare(input integer head, input integer tail, input integer len);
	integer n;
	begin
		n=0;
		n = head-tail-1;
		if(n<0) n=n+len;
		queue_spare=n;
	end
endfunction

function integer queue_pending(input integer head, input integer tail, input integer len);
	integer n;
	begin
		n=tail-head;
		if(n<0) n=n+len;
		queue_pending=n;
	end
endfunction

task config_target;
	reg [31:0] data;
	begin
		master.config_read(TGT_CONF_ADDR+CONF_ID_OFFSET, data);
		master.config_read(TGT_CONF_ADDR+CONF_CTRL_OFFSET, data);

		master.config_write(TGT_CONF_ADDR+CONF_BAR0_OFFSET,~0,4'hF);
		master.config_read(TGT_CONF_ADDR+CONF_BAR0_OFFSET, data);
		master.config_write(TGT_CONF_ADDR+CONF_BAR0_OFFSET,TGT_BAR0_BASE,4'hF);

		master.config_write(TGT_CONF_ADDR+CONF_CLINE_OFFSET,32'h0000_4010,4'h3);
		//master.config_read(TGT_CONF_ADDR+CONF_CLINE_OFFSET, data);

		master.config_read(TGT_CONF_ADDR+CONF_MISC_OFFSET, data);

		master.config_write(TGT_CONF_ADDR+CONF_BAR1_OFFSET,~0,4'hF);
		master.config_read(TGT_CONF_ADDR+CONF_BAR1_OFFSET, data);
		master.config_write(TGT_CONF_ADDR+CONF_BAR1_OFFSET,TGT_BAR1_BASE,4'hF);

		master.config_write(TGT_CONF_ADDR+CONF_BAR2_OFFSET,~0,4'hF);
		master.config_read(TGT_CONF_ADDR+CONF_BAR2_OFFSET, data);
		master.config_write(TGT_CONF_ADDR+CONF_BAR2_OFFSET,TGT_BAR2_BASE,4'hF);

		master.config_write(TGT_CONF_ADDR+CONF_CTRL_OFFSET, 32'h35F, 4'h3);
	end
endtask

task e1000_write(input [15:0] reg_offset, input [31:0] data);
begin
	master.memory_write(TGT_BAR0_BASE+reg_offset, data, 4'hF);
end
endtask

task e1000_read(input [15:0] reg_offset, output [31:0] data);
begin
	master.memory_read(TGT_BAR0_BASE+reg_offset, data);
end
endtask

task e1000_write_io(input [15:0] reg_offset, input [31:0] data);
begin
	master.io_write(TGT_BAR2_BASE+E1000_IOADDR, {16'b0,reg_offset}, 4'hF);
	master.io_write(TGT_BAR2_BASE+E1000_IODATA, data, 4'hF);
end
endtask

task e1000_read_io(input [15:0] reg_offset, output [31:0] data);
begin
	master.io_write(TGT_BAR2_BASE+E1000_IOADDR, {16'b0,reg_offset}, 4'hF);
	master.io_read(TGT_BAR2_BASE+E1000_IODATA, data);
end
endtask

task initialize_nic(input integer octlen, input integer tidv, input integer tadv,
	input integer pthresh, input integer hthresh, input integer wthresh, input integer lwthresh);
	integer len;
	reg [31:0] data;
	begin
		tx_host_len=octlen*8;
		tx_host_head=0;
		tx_host_tail=0;

		rx_host_len=octlen*8;
		rx_host_head=0;
		rx_host_tail=0;

		//e1000_write(E1000_CTRL, E1000_CTRL_RST);
		e1000_read_io(E1000_CTRL, data);
		e1000_write_io(E1000_CTRL, data|E1000_CTRL_RST);
		#1000; // Wait 1us

		e1000_write(E1000_TXDMAC, 32'h0000_0000); 

		e1000_write(E1000_IMC, 32'hFFFF_FFFF);
		e1000_write(E1000_ICR, 32'hFFFF_FFFF);
		e1000_write(E1000_IMS, E1000_INTR_TXDW|E1000_INTR_TXQE|E1000_INTR_TXD_LOW
			|E1000_INTR_RXDMT0|E1000_INTR_RXDO|E1000_INTR_RXT0);

		e1000_write(E1000_TDBAL, tx_host_base);
		e1000_write(E1000_TDBAH, 32'h0);
		e1000_write(E1000_TDLEN, tx_host_len*DESC_SIZE);
		e1000_write(E1000_TDH, tx_host_head);
		e1000_write(E1000_TDT, tx_host_tail);

		e1000_write(E1000_TIDV, tidv); 
		e1000_write(E1000_TADV, tadv); 
		e1000_write(E1000_TXDCTL,
			((pthresh&E1000_TXDCTL_PTHRESH_MASK)<<E1000_TXDCTL_PTHRESH_SHIFT) |
			((hthresh&E1000_TXDCTL_HTHRESH_MASK)<<E1000_TXDCTL_HTHRESH_SHIFT) |
			((wthresh&E1000_TXDCTL_WTHRESH_MASK)<<E1000_TXDCTL_WTHRESH_SHIFT) |
			((lwthresh&E1000_TXDCTL_LWTHRESH_MASK)<<E1000_TXDCTL_LWTHRESH_SHIFT) |
			E1000_TXDCTL_GRAN
		); 

		e1000_write(E1000_TSPMT, 32'h0000_0000); 

		e1000_read(E1000_TCTL, data);
		e1000_write(E1000_TCTL, data|E1000_TCTL_EN);

		e1000_write(E1000_RDBAL, rx_host_base);
		e1000_write(E1000_RDBAH, 32'h0);
		e1000_write(E1000_RDLEN, rx_host_len*DESC_SIZE);
		e1000_write(E1000_RDH, rx_host_head);
		e1000_write(E1000_RDT, rx_host_tail);

		e1000_write(E1000_RDTR, tidv); 
		e1000_write(E1000_RADV, tadv); 
		e1000_write(E1000_RXDCTL,
			((pthresh&E1000_RXDCTL_PTHRESH_MASK)<<E1000_RXDCTL_PTHRESH_SHIFT) |
			((hthresh&E1000_RXDCTL_HTHRESH_MASK)<<E1000_RXDCTL_HTHRESH_SHIFT) |
			((wthresh&E1000_RXDCTL_WTHRESH_MASK)<<E1000_RXDCTL_WTHRESH_SHIFT) |
			E1000_RXDCTL_GRAN
		); 

		e1000_write(E1000_RXCSUM, ((PARAM_PCSS&E1000_RXCSUM_PCSS_MASK)<<E1000_RXCSUM_PCSS_SHIFT));

		e1000_read(E1000_RCTL, data);

		data=data|E1000_RCTL_LPE|E1000_RCTL_EN;
		if(PARAM_BSEX)
			data=data|E1000_RCTL_BSEX;
		else
			data=data&(~E1000_RCTL_BSEX);

		data=data|((PARAM_BSIZE&E1000_RCTL_BSIZE_MASK)<<E1000_RCTL_BSIZE_SHIFT);

		e1000_write(E1000_RCTL, data);
	end
endtask

task set_data(input [31:0] addr, input [15:0] length, input [7:0] data);
	reg [31:0] dword;
	integer i;
	reg [31:0] idx;
begin
	idx = addr%HOST_SIZE;
	dword = host.read({idx[31:2],2'b0});
	for(i=0;i<length;i=i+1) begin
		if(idx[1:0]==0)
			dword = host.read({idx[31:2],2'b0});
		case(idx[1:0])
			0: dword[7:0] = data; 
			1: dword[15:8] = data;
			2: dword[23:16] = data;
			3: dword[31:24] = data;
		endcase
		if(idx[1:0]==3)
			host.write({idx[31:2],2'b0},dword);
		idx = idx+1;
		data = data+1;
	end
	if(idx[1:0]) // last bytes remain
		host.write({idx[31:2],2'b0},dword);
end
endtask

task set_desc(input [31:0] addr, input [127:0] data);
begin
	host.write(addr,data[31:0]); 
	host.write(addr+4,data[63:32]);
	host.write(addr+8,data[95:64]);
	host.write(addr+12,data[127:96]);
end
endtask

task get_desc(input [31:0] addr, output [127:0] data);
begin
	data[31:0] = host.read(addr); 
	data[63:32] = host.read(addr+4);
	data[95:64] = host.read(addr+8);
	data[127:96] = host.read(addr+12);
end
endtask

task tx_add_packet(input integer length, input integer seglen);
	reg [7:0] data;
	begin
		data=0;
		while(length > 0) begin

			while(queue_spare(tx_host_head, tx_host_tail, tx_host_len)==0) begin
				tx_commit_tail();
				tx_wait_available(1);
			end

			if(length<seglen)
				seglen = length;
			length = length-seglen;

			desc_daddr = tx_host_dptr;
			desc_length = seglen;
			case(PARAM_RS)
				REPORT_ALL: desc_rs = 1;
				REPORT_EOP: desc_rs = (length==0);
				REPORT_NONE: desc_rs = 0;
			endcase
			desc_ide = PARAM_IDE;
			desc_eop = (length==0);

			#0; // desc_data need a delta time to update

			set_data(desc_daddr, desc_length, data);
			set_desc(tx_host_base+tx_host_tail*DESC_SIZE, desc_data);

			tx_host_tail = (tx_host_tail+1)%tx_host_len;
			tx_host_dptr = tx_host_dptr+desc_length;
			if(tx_host_dptr>(TX_DATA_BASE+DATA_BUF_SIZE))
				tx_host_dptr = tx_host_dptr-DATA_BUF_SIZE;
			data = data+desc_length;
		end
	end
endtask

task tx_commit_tail();
	begin
		e1000_write(E1000_TDT, tx_host_tail);
	end
endtask

task tx_update_head();
	begin
		e1000_read(E1000_TDH, tx_host_head);
	end
endtask

task tx_wait_available(input integer num);
	begin
		while(queue_spare(tx_host_head, tx_host_tail, tx_host_len)<num) begin
			#10_000;
			tx_update_head();
			update_interrupt();
		end
	end
endtask

task tx_check_done();
	begin
		while(queue_pending(tx_host_head, tx_host_tail, tx_host_len)>0) begin
			#10_000;
			tx_update_head();
			update_interrupt();
		end
	end
endtask

task rx_add_desc(input integer num);
	integer i;
	begin
		for(i=0;i<num;i=i+1) begin

			while(queue_spare(rx_host_head, rx_host_tail, rx_host_len)==0) begin
				rx_commit_tail();
				rx_wait_available(1);
			end

			desc_daddr = rx_host_dptr;
			case({PARAM_BSEX,PARAM_BSIZE})
				3'b000: desc_length = 2048;
				3'b001: desc_length = 1024;
				3'b010: desc_length = 512;
				3'b011: desc_length = 256;
				3'b100: desc_length = 32768; // illegal
				3'b101: desc_length = 16384;
				3'b110: desc_length = 8192;
				3'b111: desc_length = 4096;
			endcase
			desc_rs = 0;
			desc_ide = 0;
			desc_eop = 0;

			#0; // desc_data need a delta time to update

			set_data(desc_daddr, desc_length, 0);
			set_desc(rx_host_base+rx_host_tail*DESC_SIZE, desc_data);

			rx_host_tail = (rx_host_tail+1)%rx_host_len;
			rx_host_dptr = rx_host_dptr+desc_length;
			if(rx_host_dptr>(RX_DATA_BASE+DATA_BUF_SIZE))
				rx_host_dptr=rx_host_dptr-DATA_BUF_SIZE;
		end
		rx_commit_tail();
	end
endtask

task rx_commit_tail();
	begin
		e1000_write(E1000_RDT, rx_host_tail);
	end
endtask

task rx_update_head();
	begin
		e1000_read(E1000_RDH, rx_host_head);
	end
endtask

task rx_wait_available(input integer num);
	begin
		while(queue_spare(rx_host_head, rx_host_tail, rx_host_len)<num) begin
			#10_000;
			rx_update_head();
			update_interrupt();
		end
	end
endtask

task rx_check_done();
	begin
		while(queue_pending(rx_host_head, rx_host_tail, rx_host_len)>0) begin
			#10_000;
			rx_update_head();
			update_interrupt();
		end
	end
endtask

task update_interrupt();
	begin
		if(!INTA_N) // Clear Interrupt
			e1000_read(E1000_ICR, intr_state);
	end
endtask

//% Generate transmit requests
//%
//% @length: packet length
//% @seglen: length of each segment. A packet may consist of several data
//%  segment and descriptors
//% @num: number of packets to generate
task generate_tx_traffic(input integer length, input integer seglen, input integer num);
	integer i;
	reg [31:0] data;
begin

	for(i=0;i<num;i=i+1) begin
		tx_add_packet(length, seglen);
	end

	tx_commit_tail();
end
endtask

//% Generate Receive requests
//%
//% @num: number of descriptors to generate
task generate_rx_traffic(input integer length, input integer num);
	reg stop;
begin
	stop=0;
	fork
		begin:DESC
			reg [15:0] prev_head;
			integer diff;
			integer trans;
			reg [15:0] desc_length;
			integer expected;
			case({PARAM_BSEX,PARAM_BSIZE})
				3'b000: desc_length = 2048;
				3'b001: desc_length = 1024;
				3'b010: desc_length = 512;
				3'b011: desc_length = 256;
				3'b100: desc_length = 32768; // illegal
				3'b101: desc_length = 16384;
				3'b110: desc_length = 8192;
				3'b111: desc_length = 4096;
			endcase
			expected = length/desc_length;
			if(length%desc_length)
				expected = expected+1;
			expected=expected*num;
			rx_update_head();
			prev_head=rx_host_head;
			trans=0;
			while(!stop) begin
				update_interrupt();
				rx_update_head();
				@(posedge PCLK);
				diff = rx_host_head-prev_head;
				prev_head = rx_host_head;
				if(diff<0) diff=diff+rx_host_len;

				trans=trans+diff;
				if(trans==expected) begin
					$display($time,,,"OK - All %d packet in %d desc received",
						num, expected);
					stop=1;
				end
				else if(trans>expected) begin
					$display($time,,,"ERROR - redundant packet received, expect %d desc, got %d",
						expected, trans);
					stop=1;
				end
				else begin
					rx_add_desc(queue_spare(rx_host_head, rx_host_tail, rx_host_len));
					repeat(128) @(posedge PCLK);
				end
			end
		end
		begin:DATA
			integer i;
			for(i=0;i<num;i=i+1) begin
				pkt_gen.send(length);
			end
		end
	join
end
endtask

////////////////////////////////////////////////////////////////////////////////
// Test Cases
initial
begin
	clk33=0;
	forever #15.1515 clk33=!clk33;
end

initial
begin
	rst <= 1;
	repeat(8) @(posedge clk33);
	rst <= 0;
end

initial
begin
	desc_daddr = 0;
	desc_length = 0;
	desc_cso = 0;
	desc_eop = 0;
	desc_ifcs = 0;
	desc_ic = 0;
	desc_rs = 0;
	desc_dext = 0;
	desc_vle = 0;
	desc_ide = 0;
	desc_sta = 0;
	desc_css = 0;
	desc_special = 0;

	tx_host_base = 0;
	tx_host_head = 0;
	tx_host_tail = 0;
	tx_host_len = 0;
	tx_host_dptr = 0;

	rx_host_base = 0;
	rx_host_head = 0;
	rx_host_tail = 0;
	rx_host_len = 0;
	rx_host_dptr = 0;

	PARAM_RS = REPORT_ALL;
	PARAM_IDE = 0;
	PARAM_PCSS = 0;

	$dumpfile("test_nic_device.vcd");
	$dumpvars(1);
	$dumpvars(0,dut_i);
	//$dumpvars(1,dut_i.pci_axi_i);
	//$dumpvars(0,dut_i.pci_axi_i.pci_master_i);
	//$dumpvars(1,dut_i.e1000_i);
	//$dumpvars(0,dut_i.e1000_i.rx_path_i);
	//$dumpvars(0,dut_i.e1000_i.tx_path_i);
	//$dumpvars(1,dut_i.e1000_i.tx_path_i.tx_frame_i);
	//$dumpvars(0,dut_i.e1000_i.mac_i);
	#1_000_000_000;
	$finish;
end

task test_packet_size();
	begin
		dbg_msg = "Test Packet Size";
		tx_host_base = TX_DESC_BASE;

		initialize_nic(1/*octlen*/,0/*tidv*/,0/*tadv*/,0/*pth*/,0/*hth*/,0/*wth*/,0/*lwth*/);

		PARAM_RS = REPORT_ALL;
		PARAM_IDE = 0;

		tx_host_dptr = HOST_DATA_BASE;
		// Invalid packet sizes just for testing DMA functionality
		generate_tx_traffic(1, 1, 1); 
		generate_tx_traffic(2, 2, 1); 
		generate_tx_traffic(3, 3, 1); 
		generate_tx_traffic(4, 4, 1); 
		generate_tx_traffic(5, 5, 1); 
		generate_tx_traffic(6, 6, 1); 
		generate_tx_traffic(7, 7, 1); 
		generate_tx_traffic(8, 8, 1); 

		// Valid packets
		generate_tx_traffic(12, 12, 1); // with padding
		generate_tx_traffic(60, 60, 1); // without padding
		generate_tx_traffic(1518, 1518, 1); // 1522 Bytes plus FCS
		generate_tx_traffic(16380, 16380, 1); // 16384 Bytes plus FCS
		tx_check_done();
		#50_000;
	end
endtask

task test_throughput();
	begin
		dbg_msg = "Test throughput";
		tx_host_base = TX_DESC_BASE;

		initialize_nic(16/*octlen*/,0/*tidv*/,0/*tadv*/,8/*pth*/,4/*hth*/,0/*wth*/,8/*lwth*/);

		PARAM_RS = REPORT_ALL;
		PARAM_IDE = 0;

		tx_host_dptr = HOST_DATA_BASE;
		
		generate_tx_traffic(1518, 1518, 64); 
		generate_tx_traffic(9596, 9596, 8); 
		generate_tx_traffic(16380, 16380, 2); 

		tx_check_done();
		#50_000;
	end
endtask

task test_host_queue_size();
	begin
		dbg_msg = "Test Host Queue Size";
		tx_host_base = TX_DESC_BASE;
		PARAM_RS = REPORT_ALL;
		PARAM_IDE = 0;

		initialize_nic(1/*octlen*/,0/*tidv*/,0/*tadv*/,0/*pth*/,0/*hth*/,0/*wth*/,0/*lwth*/);
		tx_host_dptr = HOST_DATA_BASE;
		generate_tx_traffic(12, 12, 7); 
		tx_check_done();
		generate_tx_traffic(12, 12, 8); 
		tx_check_done();
		generate_tx_traffic(12, 12, 15); 
		tx_check_done();
		generate_tx_traffic(12, 12, 16); 
		tx_check_done();
		generate_tx_traffic(12, 12, 24); 
		tx_check_done();

		initialize_nic(2/*octlen*/,0/*tidv*/,0/*tadv*/,0/*pth*/,0/*hth*/,0/*wth*/,0/*lwth*/);
		tx_host_dptr = HOST_DATA_BASE;
		generate_tx_traffic(12, 12, 15); 
		tx_check_done();
		generate_tx_traffic(12, 12, 16); 
		tx_check_done();
		generate_tx_traffic(12, 12, 32); 
		tx_check_done();
		generate_tx_traffic(12, 12, 48); 
		tx_check_done();
	end
endtask

task test_multi_desc();
	begin
		dbg_msg = "Test Multi-Desc Packet";
		tx_host_base = TX_DESC_BASE;
		PARAM_RS = REPORT_EOP;
		PARAM_IDE = 0;

		initialize_nic(8/*octlen*/,0/*tidv*/,0/*tadv*/,0/*pth*/,0/*hth*/,0/*wth*/,0/*lwth*/);

		tx_host_dptr = HOST_DATA_BASE;
		generate_tx_traffic(12, 1, 1); 
		generate_tx_traffic(12, 3, 1); 
		generate_tx_traffic(12, 4, 1); 
		generate_tx_traffic(12, 5, 1); 
		//generate_tx_traffic(16380, 8192, 1); // 16384 Bytes plus FCS
		//generate_tx_traffic(16380, 4096, 1); // 16384 Bytes plus FCS
		generate_tx_traffic(16380, 512, 1); // 16384 Bytes plus FCS
		tx_check_done();
	end
endtask

task test_disable_prefetch();
	begin
		dbg_msg = "Test Disalbe Prefetch";
		tx_host_base = TX_DESC_BASE;
		PARAM_RS = REPORT_ALL;
		PARAM_IDE = 0;

		initialize_nic(2/*octlen*/,0/*tidv*/,0/*tadv*/,0/*pth*/,0/*hth*/,0/*wth*/,0/*lwth*/);
		e1000_write(E1000_TXDMAC, E1000_TXDMAC_DPP);

		tx_host_dptr = HOST_DATA_BASE;
		generate_tx_traffic(12, 12, 16); 
		tx_check_done();
	end
endtask

task test_non_aligned_desc();
	begin
		dbg_msg = "Test Non-aligned Desc Queue";
		tx_host_base = TX_DESC_BASE+'h10;
		PARAM_RS = REPORT_ALL;
		PARAM_IDE = 0;

		initialize_nic(1/*octlen*/,0/*tidv*/,0/*tadv*/,0/*pth*/,0/*hth*/,0/*wth*/,0/*lwth*/);

		tx_host_dptr = HOST_DATA_BASE;
		generate_tx_traffic(12, 12, 16); 
		tx_check_done();
	end
endtask

task test_interrupt_delay();
	begin
		dbg_msg = "Test Interrupt Delay";
		tx_host_base = TX_DESC_BASE;
		PARAM_RS = REPORT_ALL;
		PARAM_IDE = 1;

		initialize_nic(16/*octlen*/,16/*tidv*/,32/*tadv*/,0/*pth*/,0/*hth*/,0/*wth*/,0/*lwth*/);

		tx_host_dptr = HOST_DATA_BASE;
		generate_tx_traffic(12, 12, 64); 
		tx_check_done();
		#16_000;
	end
endtask

task test_prefetch();
	begin
		dbg_msg = "Test Prefetch";
		tx_host_base = TX_DESC_BASE;
		PARAM_RS = REPORT_ALL;
		PARAM_IDE = 0;

		initialize_nic(2/*octlen*/,0/*tidv*/,0/*tadv*/,8/*pth*/,4/*hth*/,0/*wth*/,8/*lwth*/);

		tx_host_dptr = HOST_DATA_BASE;
		repeat(64) generate_tx_traffic(12, 12, 1); 
		tx_check_done();
	end
endtask

task test_large_queue();
	begin
		dbg_msg = "Test Large_queue";
		tx_host_base = TX_DESC_BASE;
		PARAM_RS = REPORT_NONE;
		PARAM_IDE = 0;

		initialize_nic(8191/*octlen*/,0/*tidv*/,0/*tadv*/,8/*pth*/,4/*hth*/,0/*wth*/,8/*lwth*/);

		tx_host_dptr = HOST_DATA_BASE;
		//generate_tx_traffic(1, 1, 65536); 
		// Break into multiple to avoid reaching iteration limit
		repeat(64) generate_tx_traffic(12, 12, 1024); 
		tx_check_done();
	end
endtask

task test_rx_desc_queue();
	begin
		dbg_msg = "Test RX Desc Quque";
		rx_host_base = RX_DESC_BASE;
		rx_host_dptr = RX_DATA_BASE;

		PARAM_BSEX = 0;
		PARAM_BSIZE = 3'b011;
		PARAM_PCSS = 14;


		initialize_nic(1/*octlen*/,0/*tidv*/,0/*tadv*/,0/*pth*/,0/*hth*/,0/*wth*/,0/*lwth*/);

		generate_rx_traffic(60,16);

		initialize_nic(32/*octlen*/,8/*tidv*/,8/*tadv*/,8/*pth*/,4/*hth*/,4/*wth*/,8/*lwth*/);

		generate_rx_traffic(60,512);

		#10000;
	end
endtask

task test_rx_packet_size();
	begin
		dbg_msg = "Test RX Packet Size";
		rx_host_base = RX_DESC_BASE;
		rx_host_dptr = RX_DATA_BASE;

		PARAM_BSEX = 0;
		PARAM_BSIZE = 3'b011;
		PARAM_PCSS = 14;


		initialize_nic(1/*octlen*/,0/*tidv*/,0/*tadv*/,8/*pth*/,4/*hth*/,0/*wth*/,8/*lwth*/);

		generate_rx_traffic(60,16);
		generate_rx_traffic(61,1);
		generate_rx_traffic(1500,1);
		generate_rx_traffic(9596,1);
		generate_rx_traffic(16368,1);
		generate_rx_traffic(60,1);

		#10000;
	end
endtask

initial
begin:T0
	#1000;

	dbg_msg = "Config Target";

	config_target();

`ifdef TEST_TX
	test_host_queue_size();
	#100_000;
	test_non_aligned_desc();
	#100_000;
	test_packet_size();
	#100_000;
	test_multi_desc();
	#100_000;
	test_disable_prefetch();
	#100_000;
	test_interrupt_delay();
	#100_000;
	test_prefetch();
	#100_000;
	test_throughput();
	#100_000;

`undef TEST_LARGE_QUEUE
`ifdef TEST_LARGE_QUEUE
	test_large_queue();
`endif
`endif

`ifdef TEST_RX
	test_rx_desc_queue();
	//test_rx_packet_size();
	#100_000;
`endif

	#100_000;
	$finish;
end

task report_desc(input [31:0] addr, input [31:0] length);
	integer i;
	begin
		for(i=0;i<length;i=i+DESC_SIZE) begin
			#0
			get_desc(addr/DESC_SIZE*DESC_SIZE, resp_data);
			#0;
			$display($time,,," @%x PDATA=%x STA=%x", addr/DESC_SIZE*DESC_SIZE, resp_data[31:0], resp_sta);
			addr=addr+DESC_SIZE;
		end
	end
endtask

reg dbg_frame_0;
reg dbg_host_rd;
reg dbg_host_wr;
reg [31:0] dbg_host_addr;
reg [8:0] dbg_host_dcnt;
always @(posedge PCLK) dbg_frame_0 <= FRAME_N;
always @(posedge PCLK)
begin
	if(dbg_frame_0 && !FRAME_N && pci_cmd_is_mm_rd(CBE) &&
		((AD&(~HOST_MASK))==HOST_BASE)) begin
		dbg_host_rd <= 1'b1;
	end
	else if(FRAME_N && IRDY_N && TRDY_N && STOP_N)
		dbg_host_rd <= 1'b0;

	if(dbg_frame_0 && !FRAME_N && pci_cmd_is_mm_wr(CBE) &&
		((AD&(~HOST_MASK))==HOST_BASE)) begin
		dbg_host_wr <= 1'b1;
	end
	else if(FRAME_N && IRDY_N && TRDY_N && STOP_N)
		dbg_host_wr <= 1'b0;

	if(dbg_frame_0 && !FRAME_N &&
		((AD&(~HOST_MASK))==HOST_BASE)) begin
		dbg_host_addr <= AD;
	end
end
always @(posedge PCLK)
begin
	if(!dbg_host_rd && !dbg_host_wr) begin
		dbg_host_dcnt <= 0;
	end
	else if((dbg_host_rd||dbg_host_wr) && !IRDY_N && !TRDY_N) begin
		dbg_host_dcnt <= dbg_host_dcnt+1;
	end
end

integer dbg_mac_tx_dcnt;
integer dbg_mac_tx_pkt;
reg dbg_mac_tx_eop;
initial 
begin
	dbg_mac_tx_dcnt = 0;
	dbg_mac_tx_eop = 0;
	dbg_mac_tx_pkt = 0;
end
always @(posedge dut_i.e1000_i.aclk)
begin
	if(!dbg_mac_tx_eop && dut_i.e1000_i.mac_tx_s_tvalid && dut_i.e1000_i.mac_tx_s_tlast 
		&& dut_i.e1000_i.mac_tx_s_tready) begin
			dbg_mac_tx_eop <= 1'b1;
			dbg_mac_tx_pkt <= dbg_mac_tx_pkt+1;
	end
	else begin
			dbg_mac_tx_eop <= 1'b0;
	end
	if(dbg_mac_tx_eop) begin
		dbg_mac_tx_dcnt <= 0;
		$display($time,,, "MAC TX PACKET %d, %d DW", dbg_mac_tx_pkt, dbg_mac_tx_dcnt);
	end
	else if(dut_i.e1000_i.mac_tx_s_tvalid && dut_i.e1000_i.mac_tx_s_tready) begin
		dbg_mac_tx_dcnt <= dbg_mac_tx_dcnt+1;
	end
end

`ifdef REPORT_PCI_FETCH
always @(posedge PCLK)
begin
	if(dbg_host_rd && FRAME_N && IRDY_N && TRDY_N) begin
		if(dbg_host_addr < HOST_DATA_BASE)
			$display($time,,,"FETCH DESC @%X, %d DW", dbg_host_addr, dbg_host_dcnt);
		else
			$display($time,,,"FETCH DATA @%X, %d DW", dbg_host_addr, dbg_host_dcnt);
	end
end
`endif

`ifdef REPORT_PCI_WRITE_BACK
always @(posedge PCLK)
begin
	if(dbg_host_wr && FRAME_N && IRDY_N && TRDY_N) begin
		if(dbg_host_addr < HOST_DATA_BASE) begin
			$display($time,,,"WRITE DESC @%X, %d DW", dbg_host_addr, dbg_host_dcnt);
			report_desc(dbg_host_addr, dbg_host_dcnt*4);
		end
		else begin
			$display($time,,,"WRITE DATA @%X, %d DW", dbg_host_addr, dbg_host_dcnt);
		end
	end
end
`endif

`ifdef REPORT_FETCH
always @(posedge PCLK)
begin
	/*
	if(dbg_frame_0 && !FRAME_N && pci_cmd_is_mm_rd(CBE) &&
		((AD&(~HOST_MASK))==HOST_BASE))
		$display($time,,,"FETCH ADDR=%x", AD);
		*/
	if(host.rstrobe && host.read_addr[3:0]==0) begin
		$display($time,,,"FETCH ADDR=%x", host.read_addr);
	end
end
`endif

`ifdef REPORT_WRITE_BACK
always @(posedge PCLK)
begin
	if(host.wstrobe) begin
		report_desc(host.write_addr, DESC_SIZE);
		/*
		get_desc(host.write_addr/DESC_SIZE*DESC_SIZE, resp_data);
		#0;
		$display($time,,,"WRITE BACK @%x PDATA=%x STA=%x", host.write_addr, resp_data[31:0], host.wdata[3:0]);
		*/
	end
end
`endif

`ifdef REPORT_INTERRUPT
always @(negedge INTA_N, posedge INTA_N)
begin
	if(!INTA_N) begin
		$display($time,,,"INTR Set");
	end
	else begin
		$display($time,,,"INTR Clear");
	end
end
/*
wire TXDW_req = ((intr_state>>0)&32'b1) && !INTA_N;
wire TXQE_req = ((intr_state>>1)&32'b1) && !INTA_N;
wire TXD_LOW_req = ((intr_state>>15)&32'b1) && !INTA_N;

always @(posedge TXDW_req)
		$display($time,,,"INTR TXDW SET");

always @(negedge TXDW_req)
		$display($time,,,"INTR TXDW CLEAR");

always @(posedge TXQE_req)
		$display($time,,,"INTR TXQE SET");

always @(negedge TXQE_req)
		$display($time,,,"INTR TXQE CLEAR");

always @(posedge TXD_LOW_req)
		$display($time,,,"INTR TXD_LOW SET");

always @(negedge TXD_LOW_req)
		$display($time,,,"INTR TXD_LOW CLEAR");
*/
`endif


endmodule
