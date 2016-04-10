module pci_axi_top #(
	parameter TARGET_ADDR_BITS=24,
	parameter HARDWIRE_IDSEL=0
)
(
	// PCI Bus Signals
	inout  [31:0] AD,
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

	// Clock and reset output
	output clock_out,
	output reset_out,

	// Configuration Space Access Port
	input cfg_s_aclk,
	input cfg_s_aresetn,

	input [31:0] cfg_s_awaddr,
	input cfg_s_awvalid,
	output	cfg_s_awready,

	input [31:0] cfg_s_wdata,
	input [3:0] cfg_s_wstrb,
	input cfg_s_wvalid,
	output	cfg_s_wready,

	output	[1:0] cfg_s_bresp,
	output	cfg_s_bvalid,
	input cfg_s_bready,

	input [31:0] cfg_s_araddr,
	input cfg_s_arvalid,
	output	cfg_s_arready,

	output	[31:0] cfg_s_rdata,
	output	[1:0] cfg_s_rresp,
	output	cfg_s_rvalid,
	input cfg_s_rready,

	// Register Space Access Port
	input tgt_m_aclk,
	input tgt_m_aresetn,

	output [31:0] tgt_m_awaddr,
	output tgt_m_awvalid,
	input	tgt_m_awready,

	output [31:0] tgt_m_wdata,
	output [3:0] tgt_m_wstrb,
	output tgt_m_wvalid,
	input	tgt_m_wready,

	input	[1:0] tgt_m_bresp,
	input	tgt_m_bvalid,
	output tgt_m_bready,

	output [31:0] tgt_m_araddr,
	output [3:0] tgt_m_aruser, // Pass byte enables for IO space
	output tgt_m_arvalid,
	input	tgt_m_arready,

	input	[31:0] tgt_m_rdata,
	input	[1:0] tgt_m_rresp,
	input	tgt_m_rvalid,
	output tgt_m_rready,

	// DMA Port
	input mst_s_aclk,
	input mst_s_aresetn,

	input [3:0] mst_s_awid,
	input [63:0] mst_s_awaddr,
	input [3:0] mst_s_awlen,
	input [2:0] mst_s_awsize,
	input [1:0] mst_s_awburst,
	input [3:0] mst_s_awcache,
	input mst_s_awvalid,
	output mst_s_awready,

	input [3:0] mst_s_wid,
	input [31:0] mst_s_wdata,
	input [3:0] mst_s_wstrb,
	input mst_s_wlast,
	input mst_s_wvalid,
	output mst_s_wready,

	output [3:0] mst_s_bid,
	output [1:0] mst_s_bresp,
	output mst_s_bvalid,
	input mst_s_bready,

	input [3:0] mst_s_arid,
	input [63:0] mst_s_araddr,
	input [3:0] mst_s_arlen,
	input [2:0] mst_s_arsize,
	input [1:0] mst_s_arburst,
	input [3:0] mst_s_arcache,
	input mst_s_arvalid,
	output mst_s_arready,

	output [3:0] mst_s_rid,
	output [31:0] mst_s_rdata,
	output [1:0] mst_s_rresp,
	output mst_s_rlast,
	output mst_s_rvalid,
	input mst_s_rready,

	// Interrupt Request
	input intr_request
);
// Internal wiring to connect instances

wire          FRAMEQ_N;
wire          TRDYQ_N;
wire          IRDYQ_N;
wire          STOPQ_N;
wire          DEVSELQ_N;
wire   [31:0] ADDR;
wire   [31:0] ADIO_IN;
wire   [31:0] ADIO_OUT;
wire          CFG_VLD;
wire          CFG_HIT;
wire          C_TERM;
wire          C_READY;
wire          ADDR_VLD;
wire    [7:0] BASE_HIT;
wire          S_TERM;
wire          S_READY;
wire          S_ABORT;
wire          S_WRDN;
wire          S_SRC_EN;
wire          S_DATA_VLD;
wire    [3:0] S_CBE;
wire   [15:0] PCI_CMD;
wire          REQUEST;
wire          REQUESTHOLD;
wire          COMPLETE;
wire          M_WRDN;
wire          M_READY;
wire          M_SRC_EN;
wire          M_DATA_VLD;
wire    [3:0] M_CBE;
wire          TIME_OUT;
wire          CFG_SELF;
wire          M_DATA;
wire          DR_BUS;
wire          I_IDLE;
wire          M_ADDR_N;
wire          IDLE;
wire          B_BUSY;
wire          S_DATA;
wire          BACKOFF;
wire          INT_N;
wire          PME_N;
wire          PERRQ_N;
wire          SERRQ_N;
wire          KEEPOUT;
wire   [39:0] CSR;
wire          PCIW_EN;
wire          BW_DETECT_DIS;
wire          BW_MANUAL_32B;
wire          PCIX_EN;
wire          RTR;
wire  [511:0] CFG_BUS;
wire          RST;
wire          CLK;
wire   [31:0] M_ADIO_IN;
wire   [31:0] S_ADIO_IN;

reg intr_n_sync;

assign ADIO_IN = S_DATA?S_ADIO_IN:M_ADIO_IN;

// Reserved for master
assign C_TERM = 1'b1;
assign C_READY = 1'b1;
assign CFG_SELF = 1'b0;
assign INT_N = intr_n_sync;
assign PME_N = 1'b1;
assign KEEPOUT = 1'b0;
assign BW_DETECT_DIS = 1'b1;
assign BW_MANUAL_32B = 1'b1;


assign clock_out = CLK;
assign reset_out = RST;

// Instantiation of the PCI interface

PCI_LC #(.HARDWIRE_IDSEL(HARDWIRE_IDSEL)) XPCI_WRAP (
	.AD_IO(AD),
	.CBE_IO(CBE),
	.PAR_IO(PAR),
	.FRAME_IO(FRAME_N),
	.TRDY_IO(TRDY_N),
	.IRDY_IO(IRDY_N),
	.STOP_IO(STOP_N),
	.DEVSEL_IO(DEVSEL_N),
	.IDSEL_I(IDSEL),
	.PERR_IO(PERR_N),
	.SERR_IO(SERR_N),
	.INT_O(INTA_N),
	.PME_O(PMEA_N),
	.REQ_O(REQ_N),
	.GNT_I(GNT_N),
	.RST_I(RST_N),
	.CLK_I(PCLK),

	.FRAMEQ_N(FRAMEQ_N),
	.TRDYQ_N(TRDYQ_N),
	.IRDYQ_N(IRDYQ_N),
	.STOPQ_N(STOPQ_N),
	.DEVSELQ_N(DEVSELQ_N),
	.ADDR(ADDR),
	.ADIO_IN(ADIO_IN),
	.ADIO_OUT(ADIO_OUT),
	.CFG_VLD(CFG_VLD),
	.CFG_HIT(CFG_HIT),
	.C_TERM(C_TERM),
	.C_READY(C_READY),
	.ADDR_VLD(ADDR_VLD),
	.BASE_HIT(BASE_HIT),
	.S_TERM(S_TERM),
	.S_READY(S_READY),
	.S_ABORT(S_ABORT),
	.S_WRDN(S_WRDN),
	.S_SRC_EN(S_SRC_EN),
	.S_DATA_VLD(S_DATA_VLD),
	.S_CBE(S_CBE),
	.PCI_CMD(PCI_CMD),
	.REQUEST(REQUEST),
	.REQUESTHOLD(REQUESTHOLD),
	.COMPLETE(COMPLETE),
	.M_WRDN(M_WRDN),
	.M_READY(M_READY),
	.M_SRC_EN(M_SRC_EN),
	.M_DATA_VLD(M_DATA_VLD),
	.M_CBE(M_CBE),
	.TIME_OUT(TIME_OUT),
	.CFG_SELF(CFG_SELF),
	.M_DATA(M_DATA),
	.DR_BUS(DR_BUS),
	.I_IDLE(I_IDLE),
	.M_ADDR_N(M_ADDR_N),
	.IDLE(IDLE),
	.B_BUSY(B_BUSY),
	.S_DATA(S_DATA),
	.BACKOFF(BACKOFF),
	.INT_N(INT_N),
	.PME_N(PME_N),
	.PERRQ_N(PERRQ_N),
	.SERRQ_N(SERRQ_N),
	.KEEPOUT(KEEPOUT),
	.CSR(CSR),
	.PCIW_EN(PCIW_EN),
	.BW_DETECT_DIS(BW_DETECT_DIS),
	.BW_MANUAL_32B(BW_MANUAL_32B),
	.PCIX_EN(PCIX_EN),
	.RTR(RTR),
	.CFG(CFG_BUS),
	.RST(RST),
	.CLK(CLK)
);

pci_target #(
	.ADDR_VALID_BITS(TARGET_ADDR_BITS)
)
pci_target_i(
	.ADDR(ADDR),
	.ADIO_IN(S_ADIO_IN),
	.ADIO_OUT(ADIO_OUT),
	.ADDR_VLD(ADDR_VLD),
	.BASE_HIT(BASE_HIT),
	.S_TERM(S_TERM),
	.S_READY(S_READY),
	.S_ABORT(S_ABORT),
	.S_WRDN(S_WRDN),
	.S_SRC_EN(S_SRC_EN),
	.S_DATA(S_DATA),
	.S_DATA_VLD(S_DATA_VLD),
	.S_CBE(S_CBE),
	.RST(RST),
	.CLK(CLK),

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
	.tgt_m_rresp(tgt_m_rresp)
);

pci_master pci_master_i(
	.ADIO_IN(M_ADIO_IN),
	.ADIO_OUT(ADIO_OUT),
	.REQUEST(REQUEST),
	.REQUESTHOLD(REQUESTHOLD),
	.M_CBE(M_CBE),
	.M_WRDN(M_WRDN),
	.COMPLETE(COMPLETE),
	.M_READY(M_READY),
	.M_DATA_VLD(M_DATA_VLD),
	.M_SRC_EN(M_SRC_EN),
	.TIME_OUT(TIME_OUT),
	.M_DATA(M_DATA),
	.M_ADDR_N(M_ADDR_N),
	.STOPQ_N(STOP_N),
	.RST(RST),
	.CLK(CLK),

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

always @(posedge CLK)
begin
	intr_n_sync <= !intr_request;
end

endmodule
