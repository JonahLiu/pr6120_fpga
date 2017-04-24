`timescale 1ns/1ps
module test_grpci2_device;

parameter HOST_BASE = 32'hE000_0000;
parameter HOST_SIZE = 4*1024*1024;

wire PCI_CLK;
wire PCI_RST;
wire PCI_LOCK;
wire [31:0] PCI_AD;
wire [3:0] PCI_CBE;
wire PCI_FRAME;
wire PCI_IRDY;
wire PCI_TRDY;
wire PCI_DEVSEL;
wire PCI_STOP;
wire PCI_PERR;
wire PCI_PAR;
wire [3:0] PCI_REQ;
wire [3:0] PCI_GNT;
wire PCI_SERR;
wire [3:0] PCI_INT;
wire PCI_M66EN;
wire PCI_PME;

wire pci_lock_o;
wire pci_lock_oe;
wire [31:0] pci_ad_o;
wire [31:0] pci_ad_oe;
wire [3:0] pci_cbe_o;
wire [3:0] pci_cbe_oe;
wire pci_frame_o;
wire pci_frame_oe;
wire pci_irdy_o;
wire pci_irdy_oe;
wire pci_trdy_o;
wire pci_trdy_oe;
wire pci_devsel_o;
wire pci_devsel_oe;
wire pci_stop_o;
wire pci_stop_oe;
wire pci_perr_o;
wire pci_perr_oe;
wire pci_par_o;
wire pci_par_oe;
wire pci_req_o;
wire pci_req_oe;
wire pci_serr_o;
wire pci_serr_oe;
wire [3:0] pci_int_o;
wire [3:0] pci_int_oe;
wire pci_pme_o;
wire pci_pme_oe;

wire ahb_clk;
wire ahb_rstn;

wire [15:0] ahb_mst_hgrant;
wire ahb_mst_hready;
wire [1:0] ahb_mst_hresp;
wire [31:0] ahb_mst_hrdata;
wire ahb_mst_hbusreq;
wire ahb_mst_hlock;
wire [1:0] ahb_mst_htrans;
wire [31:0] ahb_mst_haddr;
wire ahb_mst_hwrite;
wire [2:0] ahb_mst_hsize;
wire [2:0] ahb_mst_hburst;
wire [3:0] ahb_mst_hprot;
wire [31:0] ahb_mst_hwdata;

wire [15:0] ahb_slv_hsel;
wire [31:0] ahb_slv_haddr;
wire ahb_slv_hwrite;
wire [1:0] ahb_slv_htrans;
wire [2:0] ahb_slv_hsize;
wire [2:0] ahb_slv_hburst;
wire [31:0] ahb_slv_hwdata;
wire [3:0] ahb_slv_hprot;
wire [3:0] ahb_slv_hmaster;
wire ahb_slv_hmastlock;
wire [0:3] ahb_slv_hmbsel;
wire ahb_slv_hready;
wire [1:0] ahb_slv_hresp;
wire [31:0] ahb_slv_hrdata;
wire [15:0] ahb_slv_hsplit;

wire [3:0] intr_req;

assign PCI_LOCK = pci_lock_oe ? pci_lock_o : 1'bz;
assign PCI_FRAME = pci_frame_oe ? pci_frame_o : 1'bz;
assign PCI_IRDY = pci_irdy_oe ? pci_irdy_o : 1'bz;
assign PCI_TRDY = pci_trdy_oe ? pci_trdy_o : 1'bz;
assign PCI_DEVSEL = pci_devsel_oe ? pci_devsel_o : 1'bz;
assign PCI_STOP = pci_stop_oe ? pci_stop_o : 1'bz;
assign PCI_PERR = pci_perr_oe ? pci_perr_o : 1'bz;
assign PCI_PAR = pci_par_oe ? pci_par_o : 1'bz;
assign PCI_REQ[1] = pci_req_oe ? pci_req_o : 1'bz;
assign PCI_SERR = pci_serr_oe ? pci_serr_o : 1'bz;
assign PCI_PME = pci_pme_oe ? pci_pme_o : 1'bz;

genvar i;
generate
for(i=0;i<32;i=i+1)
begin:AD
	assign PCI_AD[i] = pci_ad_oe[i] ? pci_ad_o : 1'bz;
end
for(i=0;i<4;i=i+1)
begin:CBE
	assign PCI_CBE[i] = pci_cbe_oe[i] ? pci_cbe_o : 1'bz;
end
for(i=0;i<4;i=i+1)
begin:INT
	assign PCI_INT[i] = pci_int_oe[i] ? pci_int_o : 1'bz;
end
endgenerate

pullup (PCI_LOCK);
pullup (PCI_FRAME);
pullup (PCI_IRDY);
pullup (PCI_TRDY);
pullup (PCI_DEVSEL);
pullup (PCI_STOP);
pullup (PCI_PERR);
pullup (PCI_PAR);
pullup (PCI_SERR);
pullup (PCI_PME);
pullup (PCI_M66EN);

pullup pu_req [3:0] (PCI_REQ);
pullup pu_gnt [3:0] (PCI_GNT);
pullup pu_int [3:0] (PCI_INT);

grpci2_device 
dut(
	.pci_rst(PCI_RST),
	.pci_clk(PCI_CLK),
	.pci_gnt(PCI_GNT[1]),
	.pci_idsel(PCI_AD[24]),
	.pci_lock_i(PCI_LOCK),
	.pci_lock_o(pci_lock_o),
	.pci_lock_oe(pci_lock_oe),
	.pci_ad_i(PCI_AD),
	.pci_ad_o(pci_ad_o),
	.pci_ad_oe(pci_ad_oe),
	.pci_cbe_i(PCI_CBE),
	.pci_cbe_o(pci_cbe_o),
	.pci_cbe_oe(pci_cbe_oe),
	.pci_frame_i(PCI_FRAME),
	.pci_frame_o(pci_frame_o),
	.pci_frame_oe(pci_frame_oe),
	.pci_irdy_i(PCI_IRDY),
	.pci_irdy_o(pci_irdy_o),
	.pci_irdy_oe(pci_irdy_oe),
	.pci_trdy_i(PCI_TRDY),
	.pci_trdy_o(pci_trdy_o),
	.pci_trdy_oe(pci_trdy_oe),
	.pci_devsel_i(PCI_DEVSEL),
	.pci_devsel_o(pci_devsel_o),
	.pci_devsel_oe(pci_devsel_oe),
	.pci_stop_i(PCI_STOP),
	.pci_stop_o(pci_stop_o),
	.pci_stop_oe(pci_stop_oe),
	.pci_perr_i(PCI_PERR),
	.pci_perr_o(pci_perr_o),
	.pci_perr_oe(pci_perr_oe),
	.pci_par_i(PCI_PAR),
	.pci_par_o(pci_par_o),
	.pci_par_oe(pci_par_oe),
	.pci_req_o(pci_req_o),
	.pci_req_oe(pci_req_oe),
	.pci_serr_i(PCI_SERR),
	.pci_serr_o(pci_serr_o),
	.pci_serr_oe(pci_serr_oe),
	.pci_int_i(PCI_INT),
	.pci_int_o(pci_int_o),
	.pci_int_oe(pci_int_oe),
	.pci_m66en(PCI_M66EN),
	.pci_pme_i(PCI_PME),
	.pci_pme_o(pci_pme_o),
	.pci_pme_oe(pci_pme_oe),

	.ahb_clk(ahb_clk),
	.ahb_rstn(ahb_rstn),

	.ahb_mst_hgrant(ahb_mst_hgrant),
	.ahb_mst_hready(ahb_mst_hready),
	.ahb_mst_hresp(ahb_mst_hresp),
	.ahb_mst_hrdata(ahb_mst_hrdata),
	.ahb_mst_hbusreq(ahb_mst_hbusreq),
	.ahb_mst_hlock(ahb_mst_hlock),
	.ahb_mst_htrans(ahb_mst_htrans),
	.ahb_mst_haddr(ahb_mst_haddr),
	.ahb_mst_hwrite(ahb_mst_hwrite),
	.ahb_mst_hsize(ahb_mst_hsize),
	.ahb_mst_hburst(ahb_mst_hburst),
	.ahb_mst_hprot(ahb_mst_hprot),
	.ahb_mst_hwdata(ahb_mst_hwdata),

	.ahb_slv_hsel(ahb_slv_hsel),
	.ahb_slv_haddr(ahb_slv_haddr),
	.ahb_slv_hwrite(ahb_slv_hwrite),
	.ahb_slv_htrans(ahb_slv_htrans),
	.ahb_slv_hsize(ahb_slv_hsize),
	.ahb_slv_hburst(ahb_slv_hburst),
	.ahb_slv_hwdata(ahb_slv_hwdata),
	.ahb_slv_hprot(ahb_slv_hprot),
	.ahb_slv_hmaster(ahb_slv_hmaster),
	.ahb_slv_hmastlock(ahb_slv_hmastlock),
	.ahb_slv_hmbsel(ahb_slv_hmbsel),
	.ahb_slv_hready(ahb_slv_hready),
	.ahb_slv_hresp(ahb_slv_hresp),
	.ahb_slv_hrdata(ahb_slv_hrdata),
	.ahb_slv_hsplit(ahb_slv_hsplit),

	.intr_req(intr_req)
);

////////////////////////////////////////////////////////////////////////////////
// PCI stub models
pci_behavioral_master master(
	.AD(PCI_AD),
	.CBE(PCI_CBE),
	.PAR(PCI_PAR),
	.FRAME_N(PCI_FRAME),
	.TRDY_N(PCI_TRDY),
	.IRDY_N(PCI_IRDY),
	.STOP_N(PCI_STOP),
	.DEVSEL_N(PCI_DEVSEL),
	.IDSEL(1'b0),
	.PERR_N(PCI_PERR),
	.SERR_N(PCI_SERR),
	.INTA_N(PCI_INTA),
	.REQ_N(PCI_REQ[0]),
	.GNT_N(PCI_GNT[0]),
	.RST_N(PCI_RST),
	.PCLK(PCI_CLK)
);

pci_behavioral_target #(
	.BAR0_BASE(HOST_BASE), 
	.BAR0_SIZE(HOST_SIZE),
	.DATA_LATENCY(0)
) host(
	.AD(PCI_AD),
	.CBE(PCI_CBE),
	.PAR(PCI_PAR),
	.FRAME_N(PCI_FRAME),
	.TRDY_N(PCI_TRDY),
	.IRDY_N(PCI_IRDY),
	.STOP_N(PCI_STOP),
	.DEVSEL_N(PCI_DEVSEL),
	.IDSEL(1'b0),
	.PERR_N(PCI_PERR),
	.SERR_N(PCI_SERR),
	.RST_N(PCI_RST),
	.PCLK(PCI_CLK)
);

// PCI Arbiter
wire	[3:0]	arb_ext_gnt;
reg [3:0]   arb_ext_req_prev;
reg arb_frame_prev;
reg arb_irdy_prev;
assign	PCI_GNT = ~arb_ext_gnt;

always @(posedge PCI_CLK)
    arb_ext_req_prev <= ~PCI_REQ;
always @(posedge PCI_CLK)
    arb_frame_prev <= ~PCI_FRAME;
always @(posedge PCI_CLK)
    arb_irdy_prev <= ~PCI_IRDY;

pci_blue_arbiter arbiter(
    //.pci_int_req_direct(pci_int_req_n),
    .pci_int_req_direct(1'b0),
    .pci_ext_req_prev(arb_ext_req_prev),
    .pci_int_gnt_direct_out(),
    .pci_ext_gnt_direct_out(arb_ext_gnt),
    .pci_frame_prev(arb_frame_prev),
    .pci_irdy_prev(arb_irdy_prev),
    .pci_irdy_now(~PCI_IRDY),
    .arbitration_enable(1'b1),
    .pci_clk(PCI_CLK),
    .pci_reset_comb(!PCI_RST)
);
////////////////////////////////////////////////////////////////////////////////

reg pci_clk_i;
initial
begin
	pci_clk_i = 0;
	forever #15.151 pci_clk_i = ~pci_clk_i;
end
assign PCI_CLK = pci_clk_i;

reg ahb_clk_i;
initial
begin
	ahb_clk_i = 0;
	forever #5.000 ahb_clk_i = ~ahb_clk_i;
end
assign ahb_clk = ahb_clk_i;

reg pci_rst_i;
initial
begin
	pci_rst_i = 0;
	repeat(16) @(posedge PCI_CLK);
   	pci_rst_i <= 1;
end
assign PCI_RST = pci_rst_i;

reg ahb_rst_i;
initial
begin
	ahb_rst_i = 0;
	repeat(16) @(posedge ahb_clk);
   	ahb_rst_i <= 1;
end

assign ahb_rstn = ahb_rst_i;

reg [3:0] intr_req_i;
assign intr_req = intr_req_i;

initial
begin
	intr_req_i = 4'h0;
end

endmodule
