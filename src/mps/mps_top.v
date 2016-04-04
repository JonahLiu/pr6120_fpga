module mps_top #(
	parameter PORT_NUM = 8,
	parameter CLK_PERIOD_NS = 8,
	parameter BASE_BAUD = 115200
)
(
	input aclk,
	input aresetn,

	// Register Space Access Port
	input [31:0] axi_s_awaddr,
	input axi_s_awvalid,
	output	axi_s_awready,

	input [31:0] axi_s_wdata,
	input [3:0] axi_s_wstrb,
	input axi_s_wvalid,
	output	axi_s_wready,

	output	[1:0] axi_s_bresp,
	output	axi_s_bvalid,
	input axi_s_bready,

	input [31:0] axi_s_araddr,
	input axi_s_arvalid,
	output	axi_s_arready,

	output	[31:0] axi_s_rdata,
	output	[1:0] axi_s_rresp,
	output	axi_s_rvalid,
	input axi_s_rready,

	// Interrupt request
	output intr_request,

	// UART Port
	input	[PORT_NUM-1:0] rxd,
	output	[PORT_NUM-1:0] txd,
	output  [PORT_NUM-1:0] rtsn,
	input   [PORT_NUM-1:0] ctsn,
	output  [PORT_NUM-1:0] dtrn,
	input   [PORT_NUM-1:0] dsrn,
	input   [PORT_NUM-1:0] ri,
	input   [PORT_NUM-1:0] dcdn
);


localparam CLOCK_PRESCALE = ((1_000_000_000/(BASE_BAUD*16))+(CLK_PERIOD_NS/2))/CLK_PERIOD_NS;

multi_serial #(.PORT_NUM(PORT_NUM),.CLOCK_PRESCALE(CLOCK_PRESCALE)) 
multi_serial_i (
	.aclk(aclk),
	.aresetn(aresetn),

	.axi_s_awvalid(axi_s_awvalid),
	.axi_s_awaddr(axi_s_awaddr),
	.axi_s_awready(axi_s_awready),

	.axi_s_wvalid(axi_s_wvalid),
	.axi_s_wdata(axi_s_wdata),
	.axi_s_wstrb(axi_s_wstrb),
	.axi_s_wready(axi_s_wready),
	
	.axi_s_bready(axi_s_bready),
	.axi_s_bresp(axi_s_bresp),
	.axi_s_bvalid(axi_s_bvalid),

	.axi_s_arvalid(axi_s_arvalid),
	.axi_s_araddr(axi_s_araddr),
	.axi_s_arready(axi_s_arready),

	.axi_s_rvalid(axi_s_rvalid),
	.axi_s_rresp(axi_s_rresp),
	.axi_s_rdata(axi_s_rdata),
	.axi_s_rready(axi_s_rready),

	.interrupt(intr_request),

	.rxd(rxd),
	.txd(txd),
	.rtsn(rtsn),
	.ctsn(ctsn),
	.dtrn(dtrn),
	.dsrn(dsrn),
	.ri(ri),
	.dcdn(dcdn)
);


endmodule
