module mpc_top #(
	parameter PORT_NUM = 4
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
	input [3:0] axi_s_aruser,
	input axi_s_arvalid,
	output	axi_s_arready,

	output	[31:0] axi_s_rdata,
	output	[1:0] axi_s_rresp,
	output	axi_s_rvalid,
	input axi_s_rready,

	// Interrupt request
	output intr_request,

	// CAN signals
	input  [PORT_NUM-1:0] rx_i,
	output [PORT_NUM-1:0] tx_o,
	output [PORT_NUM-1:0] bus_off_on,
	output	interrupt
);

multi_can #(.PORT_NUM(PORT_NUM)) 
multi_can_i (
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
	.axi_s_aruser(axi_s_aruser),
	.axi_s_arready(axi_s_arready),

	.axi_s_rvalid(axi_s_rvalid),
	.axi_s_rresp(axi_s_rresp),
	.axi_s_rdata(axi_s_rdata),
	.axi_s_rready(axi_s_rready),

	.interrupt(intr_request),

	.rx_i(rx_i),
	.tx_o(tx_o),
	.bus_off_on(bus_off_on)
);


endmodule
