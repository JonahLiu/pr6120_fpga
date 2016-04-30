`timescale 1ns/10ps
module test_nic_device;
////////////////////////////////////////////////////////////////////////////////
// Parameters
//
// Host Address
parameter HOST_BASE = 32'hE000_0000;
parameter HOST_SIZE = 2*1024*1024;
parameter HOST_DESC_OFFSET = 0;
parameter HOST_DATA_OFFSET = HOST_BASE+HOST_SIZE/2;

parameter HOST_DESC_BATCH = 4;

// Target Addresses
parameter TGT_CONF_ADDR  = 32'h0100_0000;
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

wire p0_mdio;
wire p1_mdio;

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

pullup (p0_mdio);
pullup (p1_mdio);
/*
pullup (PAR);
pullup pu_ad [31:0] (AD);
pullup pu_cbe [3:0] (CBE);
*/
pullup pu_req [3:0] (REQ_N);
pullup pu_gnt [3:0] (GNT_N);

assign RST_N = !rst;
assign PCLK = clk33;

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

	.p0_rxdat(8'b0),
	.p0_rxdv(1'b0),
	.p0_rxer(1'b0),
	.p0_rxsclk(1'b0),
	.p0_txdat(),
	.p0_txen(),
	.p0_txer(),
	.p0_txsclk(1'b0),
	.p0_gtxsclk(),
	.p0_crs(1'b0),
	.p0_col(1'b0),
	.p0_mdc(),
	.p0_mdio(p0_mdio),
	.p0_int(1'b0),
	.p0_resetn(),

	.p1_rxdat(8'b0),
	.p1_rxdv(1'b0),
	.p1_rxer(1'b0),
	.p1_rxsclk(1'b0),
	.p1_txdat(),
	.p1_txen(),
	.p1_txer(),
	.p1_txsclk(1'b0),
	.p1_gtxsclk(),
	.p1_crs(1'b0),
	.p1_col(1'b0),
	.p1_mdc(),
	.p1_mdio(p1_mdio),
	.p1_int(1'b0),
	.p1_resetn(),

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

reg [31:0] host_base;
reg [15:0] host_head;
reg [15:0] host_tail;
reg [15:0] host_len;
reg [31:0] host_dptr;
reg [31:0] intr_state;

reg [0:511] dbg_msg;

integer PARAM_RS;
integer PARAM_IDE;

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


task config_target;
	reg [31:0] data;
	begin
		master.config_read(TGT_CONF_ADDR+CONF_ID_OFFSET, data);
		master.config_read(TGT_CONF_ADDR+CONF_CTRL_OFFSET, data);

		master.config_write(TGT_CONF_ADDR+CONF_BAR0_OFFSET,~0,4'hF);
		master.config_read(TGT_CONF_ADDR+CONF_BAR0_OFFSET, data);
		master.config_write(TGT_CONF_ADDR+CONF_BAR0_OFFSET,TGT_BAR0_BASE,4'hF);

		//master.config_write(TGT_CONF_ADDR+CONF_CLINE_OFFSET,16,4'hF);
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

task initialize_nic(input integer octlen, input integer tidv, input integer tadv,
	input integer pthresh, input integer hthresh, input integer lwthresh);
	integer len;
	reg [31:0] data;
	begin
		host_len=octlen*8;
		host_head=0;
		host_tail=0;

		e1000_write(E1000_CTRL, E1000_CTRL_RST);
		#1000; // Wait 1us

		e1000_write(E1000_TXDMAC, 32'h0000_0000); 

		e1000_write(E1000_IMC, 32'hFFFF_FFFF);
		e1000_write(E1000_ICR, 32'hFFFF_FFFF);
		e1000_write(E1000_IMS, E1000_INTR_TXDW|E1000_INTR_TXQE|E1000_INTR_TXD_LOW);

		e1000_write(E1000_TDBAL, host_base);
		e1000_write(E1000_TDBAH, 32'h0);
		e1000_write(E1000_TDLEN, host_len*DESC_SIZE);
		e1000_write(E1000_TDH, host_head);
		e1000_write(E1000_TDT, host_tail);

		e1000_write(E1000_TIDV, tidv); 
		e1000_write(E1000_TADV, tadv); 
		e1000_write(E1000_TXDCTL,
			((pthresh&E1000_TXDCTL_PTHRESH_MASK)<<E1000_TXDCTL_PTHRESH_SHIFT) |
			((hthresh&E1000_TXDCTL_HTHRESH_MASK)<<E1000_TXDCTL_HTHRESH_SHIFT) |
			((lwthresh&E1000_TXDCTL_LWTHRESH_MASK)<<E1000_TXDCTL_LWTHRESH_SHIFT) |
			E1000_TXDCTL_GRAN
		); 

		e1000_write(E1000_TSPMT, 32'h0000_0000); 

		e1000_read(E1000_TCTL, data);
		e1000_write(E1000_TCTL, data|E1000_TCTL_EN);
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

task add_tx_packet(input integer length, input integer seglen);
	reg [7:0] data;
	begin
		data=0;
		while(length > 0) begin

			while(queue_spare(host_head, host_tail, host_len)==0) begin
				commit_tail();
				check_available(1);
			end

			if(length<seglen)
				seglen = length;
			length = length-seglen;

			desc_daddr = host_dptr;
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
			set_desc(host_base+host_tail*DESC_SIZE, desc_data);

			host_tail = (host_tail+1)%host_len;
			host_dptr = host_dptr+desc_length;
			data = data+desc_length;
		end
	end
endtask

task commit_tail();
	begin
		e1000_write(E1000_TDT, host_tail);
	end
endtask

task update_head();
	begin
		e1000_read(E1000_TDH, host_head);
	end
endtask

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

task check_available(input integer num);
	begin
		while(queue_spare(host_head, host_tail, host_len)<num) begin
			#10_000;
			update_head();
			update_interrupt();
		end
	end
endtask

task check_done();
	begin
		while(queue_pending(host_head, host_tail, host_len)>0) begin
			#10_000;
			update_head();
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
		add_tx_packet(length, seglen);
	end

	commit_tail();
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

	PARAM_RS = REPORT_ALL;
	PARAM_IDE = 0;

	$dumpfile("test_nic_device.vcd");
	$dumpvars(1);
	//$dumpvars(1,dut_i);
	//$dumpvars(0,dut_i.e1000_i.tx_path_i);
	#1_000_000_000;
	$finish;
end

task test_packet_size();
	begin
		dbg_msg = "Test Packet Size";
		host_base = HOST_BASE;

		initialize_nic(1/*octlen*/,0/*tidv*/,0/*tadv*/,0/*pth*/,0/*hth*/,0/*lwth*/);

		PARAM_RS = REPORT_ALL;
		PARAM_IDE = 0;

		host_dptr = HOST_DATA_OFFSET;
		generate_tx_traffic(1, 1, 1); 
		generate_tx_traffic(2, 2, 1); 
		generate_tx_traffic(4, 4, 1); 
		generate_tx_traffic(8, 8, 1); 
		generate_tx_traffic(16384, 16384, 1); 
		check_done();
		#50_000;
	end
endtask

task test_host_queue_size();
	begin
		dbg_msg = "Test Host Queue Size";
		host_base = HOST_BASE;
		PARAM_RS = REPORT_ALL;
		PARAM_IDE = 0;

		initialize_nic(1/*octlen*/,0/*tidv*/,0/*tadv*/,0/*pth*/,0/*hth*/,0/*lwth*/);
		host_dptr = HOST_DATA_OFFSET;
		generate_tx_traffic(1, 1, 7); 
		check_done();
		generate_tx_traffic(1, 1, 8); 
		check_done();
		generate_tx_traffic(1, 1, 15); 
		check_done();
		generate_tx_traffic(1, 1, 16); 
		check_done();
		generate_tx_traffic(1, 1, 24); 
		check_done();

		initialize_nic(2/*octlen*/,0/*tidv*/,0/*tadv*/,0/*pth*/,0/*hth*/,0/*lwth*/);
		host_dptr = HOST_DATA_OFFSET;
		generate_tx_traffic(1, 1, 15); 
		check_done();
		generate_tx_traffic(1, 1, 16); 
		check_done();
		generate_tx_traffic(1, 1, 32); 
		check_done();
		generate_tx_traffic(1, 1, 48); 
		check_done();
	end
endtask

task test_multi_desc();
	begin
		dbg_msg = "Test Multi-Desc Packet";
		host_base = HOST_BASE;
		PARAM_RS = REPORT_EOP;
		PARAM_IDE = 0;

		initialize_nic(1/*octlen*/,0/*tidv*/,0/*tadv*/,0/*pth*/,0/*hth*/,0/*lwth*/);

		host_dptr = HOST_DATA_OFFSET;
		generate_tx_traffic(2, 1, 1); 
		generate_tx_traffic(16384, 4096, 1); 
		check_done();
	end
endtask

task test_disable_prefetch();
	begin
		dbg_msg = "Test Disalbe Prefetch";
		host_base = HOST_BASE;
		PARAM_RS = REPORT_ALL;
		PARAM_IDE = 0;

		initialize_nic(2/*octlen*/,0/*tidv*/,0/*tadv*/,0/*pth*/,0/*hth*/,0/*lwth*/);
		e1000_write(E1000_TXDMAC, E1000_TXDMAC_DPP);

		host_dptr = HOST_DATA_OFFSET;
		generate_tx_traffic(1, 1, 16); 
		check_done();
	end
endtask

task test_non_aligned_desc();
	begin
		dbg_msg = "Test Non-aligned Desc Queue";
		host_base = HOST_BASE+'h10;
		PARAM_RS = REPORT_ALL;
		PARAM_IDE = 0;

		initialize_nic(1/*octlen*/,0/*tidv*/,0/*tadv*/,0/*pth*/,0/*hth*/,0/*lwth*/);

		host_dptr = HOST_DATA_OFFSET;
		generate_tx_traffic(1, 1, 16); 
		check_done();
	end
endtask

task test_interrupt_delay();
	begin
		dbg_msg = "Test Interrupt Delay";
		host_base = HOST_BASE;
		PARAM_RS = REPORT_ALL;
		PARAM_IDE = 1;

		initialize_nic(16/*octlen*/,16/*tidv*/,32/*tadv*/,0/*pth*/,0/*hth*/,0/*lwth*/);

		host_dptr = HOST_DATA_OFFSET;
		generate_tx_traffic(1, 1, 64); 
		check_done();
		#16_000;
	end
endtask

task test_prefetch();
	begin
		dbg_msg = "Test Prefetch";
		host_base = HOST_BASE;
		PARAM_RS = REPORT_ALL;
		PARAM_IDE = 0;

		initialize_nic(2/*octlen*/,0/*tidv*/,0/*tadv*/,8/*pth*/,4/*hth*/,8/*lwth*/);

		host_dptr = HOST_DATA_OFFSET;
		repeat(64) generate_tx_traffic(1, 1, 1); 
		check_done();
	end
endtask

task test_large_queue();
	begin
		dbg_msg = "Test Large_queue";
		host_base = HOST_BASE;
		PARAM_RS = REPORT_NONE;
		PARAM_IDE = 0;

		initialize_nic(8191/*octlen*/,0/*tidv*/,0/*tadv*/,8/*pth*/,4/*hth*/,8/*lwth*/);

		host_dptr = HOST_DATA_OFFSET;
		//generate_tx_traffic(1, 1, 65536); 
		// Break into multiple to avoid reaching iteration limit
		repeat(64) generate_tx_traffic(1, 1, 1024); 
		check_done();
	end
endtask

initial
begin:T0
	#1000;

	dbg_msg = "Config Target";

	config_target();

	test_host_queue_size();
	test_non_aligned_desc();
	test_packet_size();
	test_multi_desc();
	test_disable_prefetch();
	test_interrupt_delay();
	test_prefetch();

`define TEST_LARGE_QUEUE
`ifdef TEST_LARGE_QUEUE
	test_large_queue();
`endif

	#100_000;
	$finish;
end

`define REPORT_PCI_FETCH
`undef REPORT_FETCH
`define REPORT_WRITE_BACK
`define REPORT_INTERRUPT

reg dbg_frame_0;
reg dbg_host_rd;
reg [31:0] dbg_host_addr;
reg [8:0] dbg_host_dcnt;
always @(posedge PCLK) dbg_frame_0 <= FRAME_N;
always @(posedge PCLK)
begin
	if(dbg_frame_0 && !FRAME_N && pci_cmd_is_mm_rd(CBE) &&
		((AD&(~HOST_MASK))==HOST_BASE)) begin
		dbg_host_rd <= 1'b1;
		dbg_host_addr <= AD;
	end
	else if(FRAME_N && IRDY_N && TRDY_N && STOP_N)
		dbg_host_rd <= 1'b0;
end
always @(posedge PCLK)
begin
	if(!dbg_host_rd) begin
		dbg_host_dcnt <= 0;
	end
	else if(dbg_host_rd && !IRDY_N && !TRDY_N) begin
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
		if(dbg_host_addr < HOST_DATA_OFFSET)
			$display($time,,,"FETCH DESC @%X, %d DW", dbg_host_addr, dbg_host_dcnt);
		else
			$display($time,,,"FETCH DATA @%X, %d DW", dbg_host_addr, dbg_host_dcnt);
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
		get_desc(host.write_addr/DESC_SIZE*DESC_SIZE, resp_data);
		#0;
		$display($time,,,"WRITE BACK @%x PDATA=%x STA=%x", host.write_addr, resp_data[31:0], host.wdata[3:0]);
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
