`timescale 1ns/10ps
`define TGT_CONF_ADDR  (32'h0100_0000)
`define CONF_ID_OFFSET  (8'h0)
`define CONF_CTRL_OFFSET  (8'h4)
`define CONF_BAR0_OFFSET  (8'h10)
`define CONF_BAR1_OFFSET  (8'h14)
`define CONF_BAR2_OFFSET  (8'h18)
`define TGT_BAR0_BASE (32'h8002_0000)
`define TGT_BAR1_BASE (32'h8004_0000)
`define TGT_BAR2_BASE (32'h0000_0010)
module test_pci_behavioral;

reg clk33;
reg clk125;
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

assign RST_N = !rst;
assign PCLK = clk33;

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

pci_behavioral_target target(
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

wire	pci_int_req_n;
wire	pci_int_gnt_n;
wire	arb_int_gnt;
wire	arb_irdy_now;
wire	arb_int_req;
wire	[3:0]	arb_ext_gnt;
reg [3:0]   arb_ext_req_prev;
reg arb_frame_prev;
reg arb_irdy_prev;
assign	arb_int_req = ~pci_int_req_n;
assign	pci_int_gnt_n = ~arb_int_gnt;
assign	arb_irdy_now = ~IRDY_N;
assign	GNT_N = ~arb_ext_gnt;

pullup (pci_int_req_n);

always @(posedge PCLK)
    arb_ext_req_prev <= ~REQ_N;
always @(posedge PCLK)
    arb_frame_prev <= ~FRAME_N;
always @(posedge PCLK)
    arb_irdy_prev <= ~IRDY_N;

pci_blue_arbiter arbiter(
    .pci_int_req_direct(pci_int_req_n),
    .pci_ext_req_prev(arb_ext_req_prev),
    .pci_int_gnt_direct_out(arb_int_gnt),
    .pci_ext_gnt_direct_out(arb_ext_gnt),
    .pci_frame_prev(arb_frame_prev),
    .pci_irdy_prev(arb_irdy_prev),
    .pci_irdy_now(~IRDY_N),
    .arbitration_enable(1'b1),
    .pci_clk(PCLK),
    .pci_reset_comb(!RST_N)
);



initial
begin
	$dumpfile("test_pci_behavioral.vcd");
	$dumpvars(0);
	#1000000;
	$finish;
end

initial
begin:T0
	reg [31:0] data;
	reg [31:0] bdata [0:15];
	reg [31:0] be [0:15];
	integer i;
	reg [4:0] rc;
	#1000;
	target.address_base=`TGT_BAR0_BASE;
	target.address_mask=32'hffff_0000;

	target.decode_latency=0;
	target.initial_latency=0;
	target.data_latency=0;

	master.memory_write(`TGT_BAR0_BASE, 32'hDEADBEEF, 4'hF);
	master.memory_read(`TGT_BAR0_BASE, data);

	target.decode_latency=1;
	target.initial_latency=0;
	target.data_latency=0;

	master.memory_write(`TGT_BAR0_BASE, 32'h0ACEFACE, 4'hF);
	master.memory_read(`TGT_BAR0_BASE, data);

	target.decode_latency=0;
	target.initial_latency=1;
	target.data_latency=0;

	master.memory_write(`TGT_BAR0_BASE, 32'hDEADBEEF, 4'hF);
	master.memory_read(`TGT_BAR0_BASE, data);

	target.decode_latency=0;
	target.initial_latency=0;
	target.data_latency=1;

	master.memory_write(`TGT_BAR0_BASE, 32'hDEADBEEF, 4'hF);
	master.memory_read(`TGT_BAR0_BASE, data);

	master.io_write(`TGT_BAR0_BASE, 32'h12345678, 4'hF);
	master.io_read(`TGT_BAR0_BASE, data);


	for(i=0;i<16;i=i+1) begin
		master.write_data[i]=i;
		master.write_be[i]=0;
		master.read_be[i]=0;
	end

	target.decode_latency=0;
	target.initial_latency=0;
	target.data_latency=0;

	master.low_level_write(master.CMD_MEM_WRITE, `TGT_BAR0_BASE,16,rc);

	master.low_level_read(master.CMD_MEM_READ, `TGT_BAR0_BASE,16,rc);

	target.decode_latency=1;
	target.initial_latency=1;
	target.data_latency=1;

	master.low_level_write(master.CMD_MEM_WRITE, `TGT_BAR0_BASE,16,rc);

	master.low_level_read(master.CMD_MEM_READ, `TGT_BAR0_BASE,16,rc);

	target.decode_latency=2;
	target.initial_latency=1;
	target.data_latency=2;

	master.low_level_write(master.CMD_MEM_WRITE, `TGT_BAR0_BASE,16,rc);

	master.low_level_read(master.CMD_MEM_READ, `TGT_BAR0_BASE,16,rc);

	target.disconnect=8;

	target.decode_latency=1;
	target.initial_latency=0;
	target.data_latency=0;

	master.low_level_write(master.CMD_MEM_WRITE, `TGT_BAR0_BASE,16,rc);

	master.low_level_read(master.CMD_MEM_READ, `TGT_BAR0_BASE,16,rc);

	#100000;
	$finish;
end

endmodule
