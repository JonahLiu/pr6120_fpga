`timescale 1ns/10ps
`define TGT_CONF_ADDR  (32'h0100_0000)
`define CONF_ID_OFFSET  (8'h0)
`define CONF_CTRL_OFFSET  (8'h4)
`define CONF_BAR0_OFFSET  (8'h10)
`define CONF_BAR1_OFFSET  (8'h14)
`define CONF_BAR2_OFFSET  (8'h18)
`define TGT_BAR0_BASE (32'h8002_0000)
`define TGT_BAR1_BASE (32'h8003_0000)
`define TGT_BAR2_BASE (32'h0000_0010)
module test_pci_axi_top;

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

assign cfg_s_aclk = clk125;
assign cfg_s_aresetn = !rst;
assign tgt_m_aclk = clk125;
assign tgt_m_aresetn = !rst;
assign mst_s_aclk = clk125;
assign mst_s_aresetn = !rst;

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
	clk125=0;
	forever #4 clk125=!clk125;
end

initial
begin
	rst <= 1;
	repeat(8) @(posedge clk33);
	rst <= 0;
end

assign RST_N = !rst;
assign PCLK = clk33;

// PCI to AXI interface controller
pci_axi_top pci_axi_i(
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
	.mst_s_rready(mst_s_rready)

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

axi_memory_model axi_memory_model_i(
	.s_axi_aresetn(tgt_m_aresetn),
	.s_axi_aclk(tgt_m_aclk),
	.s_axi_awid('b0),
	.s_axi_awaddr(tgt_m_awaddr),
	.s_axi_awlen('b0),
	.s_axi_awsize('b0),
	.s_axi_awburst('b0),
	.s_axi_awvalid(tgt_m_awvalid),
	.s_axi_awready(tgt_m_awready),
	.s_axi_wdata(tgt_m_wdata),
	.s_axi_wstrb(tgt_m_wstrb),
	.s_axi_wlast(1'b1),
	.s_axi_wvalid(tgt_m_wvalid),
	.s_axi_wready(tgt_m_wready),
	.s_axi_bready(tgt_m_bready),
	.s_axi_bid(),
	.s_axi_bresp(tgt_m_bresp),
	.s_axi_bvalid(tgt_m_bvalid),
	.s_axi_arid('b0),
	.s_axi_araddr(tgt_m_araddr),
	.s_axi_arlen('b0),
	.s_axi_arsize('b0),
	.s_axi_arburst('b0),
	.s_axi_arvalid(tgt_m_arvalid),
	.s_axi_arready(tgt_m_arready),
	.s_axi_rready(tgt_m_rready),
	.s_axi_rid(),
	.s_axi_rdata(tgt_m_rdata),
	.s_axi_rresp(tgt_m_rresp),
	.s_axi_rlast(),
	.s_axi_rvalid(tgt_m_rvalid)
);


initial
begin
	$dumpfile("test_pci_axi_top.vcd");
	$dumpvars(1);
	$dumpvars(1,pci_axi_i);
	$dumpvars(1,pci_axi_i.pci_target_i);
	$dumpvars(1,master);
	#1000000;
	$finish;
end

initial
begin:T0
	reg [31:0] data;
	#1000;
	master.config_read(`TGT_CONF_ADDR+`CONF_ID_OFFSET, data);
	master.config_read(`TGT_CONF_ADDR+`CONF_CTRL_OFFSET, data);

	master.config_write(`TGT_CONF_ADDR+`CONF_BAR0_OFFSET,~0,4'hF);
	master.config_read(`TGT_CONF_ADDR+`CONF_BAR0_OFFSET, data);
	master.config_write(`TGT_CONF_ADDR+`CONF_BAR0_OFFSET,`TGT_BAR0_BASE,4'hF);

	master.config_write(`TGT_CONF_ADDR+`CONF_BAR1_OFFSET,~0,4'hF);
	master.config_read(`TGT_CONF_ADDR+`CONF_BAR1_OFFSET, data);
	master.config_write(`TGT_CONF_ADDR+`CONF_BAR1_OFFSET,`TGT_BAR1_BASE,4'hF);

	master.config_write(`TGT_CONF_ADDR+`CONF_BAR2_OFFSET,~0,4'hF);
	master.config_read(`TGT_CONF_ADDR+`CONF_BAR2_OFFSET, data);
	master.config_write(`TGT_CONF_ADDR+`CONF_BAR2_OFFSET,`TGT_BAR2_BASE,4'hF);

	master.config_write(`TGT_CONF_ADDR+`CONF_CTRL_OFFSET, 32'h35F, 4'h3);

	master.memory_write(`TGT_BAR0_BASE, 32'hDEADBEEF, 4'hF);

	master.memory_read(`TGT_BAR0_BASE, data);

	#100000;
	$finish;
end

/*
assign tgt_m_awready = 1'b1;
assign tgt_m_wready = 1'b1;
assign tgt_m_bvalid = 1'b1;
assign tgt_m_bresp = 'b0;
assign tgt_m_arready = 1'b1;
assign tgt_m_rdata = 32'h0aceface;
assign tgt_m_rresp = 'b0;
assign tgt_m_rvalid = 1'b1;
*/
endmodule
