module multi_can #(
	parameter PORT_NUM=4
)
(
	input	aclk,
	input	aresetn,

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

	// CAN signals
	input  [PORT_NUM-1:0] rx_i,
	output [PORT_NUM-1:0] tx_o,
	output [PORT_NUM-1:0] bus_off_on,
	output	interrupt
);

wire [9:0] addr_i;
wire [7:0] data_i;
wire [7:0] data_o;
wire wr_i;
wire rd_i;

wire [7:0] data_mux [0:PORT_NUM-1];
wire [PORT_NUM-1:0] intr_int;

assign data_o = data_mux[addr_i[9:8]];
assign interrupt = |(~intr_int);

can_axi can_axi_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.axi_s_awaddr(axi_s_awaddr),
	.axi_s_awvalid(axi_s_awvalid),
	.axi_s_awready(axi_s_awready),

	.axi_s_wdata(axi_s_wdata),
	.axi_s_wstrb(axi_s_wstrb),
	.axi_s_wvalid(axi_s_wvalid),
	.axi_s_wready(axi_s_wready),

	.axi_s_bresp(axi_s_bresp),
	.axi_s_bvalid(axi_s_bvalid),
	.axi_s_bready(axi_s_bready),

	.axi_s_araddr(axi_s_araddr),
	.axi_s_aruser(axi_s_aruser),
	.axi_s_arvalid(axi_s_arvalid),
	.axi_s_arready(axi_s_arready),

	.axi_s_rdata(axi_s_rdata),
	.axi_s_rresp(axi_s_rresp),
	.axi_s_rvalid(axi_s_rvalid),
	.axi_s_rready(axi_s_rready),

	.addr_o(addr_i),
	.data_o(data_i),
	.data_i(data_o),
	.wr_o(wr_i),
	.rd_o(rd_i)
);


genvar i;
generate
begin
	for(i=0;i<PORT_NUM;i=i+1) begin:G0
		reg select;
		always @(*) select = addr_i[9:8]==i;
		can_top can_i(
			.rst_i(!aresetn),
			.clk_i(aclk),
			.addr_i(addr_i[7:0]),
			.data_i(data_i),
			.data_o(data_mux[i]),
			.wr_i(select&wr_i),
			.rd_i(select&rd_i),
			.rx_i(rx_i[i]),
			.tx_o(tx_o[i]),
			.bus_off_on(bus_off_on[i]),
			.irq_on(intr_int[i]),
			.clkout_o()
		);
	end
end

endgenerate



endmodule
