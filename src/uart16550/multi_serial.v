module multi_serial #(
	parameter PORT_NUM=8,
	parameter CLOCK_PRESCALE=1
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

	// UART signals
	input  [PORT_NUM-1:0] rxd  ,
	output [PORT_NUM-1:0] txd  ,
	output [PORT_NUM-1:0] rts ,
	input  [PORT_NUM-1:0] cts ,
	output [PORT_NUM-1:0] dtr ,
	input  [PORT_NUM-1:0] dsr ,
	input  [PORT_NUM-1:0] ri  ,
	input  [PORT_NUM-1:0] dcd ,

	output	interrupt
);

wire [5:0] wb_adr_i;
wire [7:0] wb_dat_i;
wire [7:0] wb_dat_o;
wire wb_we_i;
wire wb_re_i;

wire [7:0] wb_dat_mux [0:PORT_NUM-1];
wire [PORT_NUM-1:0] intr_int;

assign wb_dat_o = wb_dat_mux[wb_adr_i[5:3]];
assign interrupt = |intr_int;

uart_axi uart_axi_i(
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

	.wb_adr_o(wb_adr_i),
	.wb_dat_o(wb_dat_i),
	.wb_dat_i(wb_dat_o),
	.wb_we_o(wb_we_i),
	.wb_re_o(wb_re_i)
);


genvar i;
generate
begin
	for(i=0;i<PORT_NUM;i=i+1) begin:G0
		reg select;
		always @(*) 
			select = wb_adr_i[5:3]==i;
		uart_regs #(.clock_prescale(CLOCK_PRESCALE))	regs(
			.clk(aclk),
			.wb_rst_i(!aresetn),
			.wb_addr_i({3'b0,wb_adr_i[2:0]}),
			.wb_dat_i(wb_dat_i),
			.wb_dat_o(wb_dat_mux[i]),
			.wb_we_i(select&wb_we_i),
			.wb_re_i(select&wb_re_i),
			.modem_inputs({cts[i],dsr[i],ri[i],dcd[i]}),
			.stx_pad_o(txd[i]),
			.srx_pad_i(rxd[i]),
			.rts_pad_o(rts[i]),
			.dtr_pad_o(dtr[i]),
			.int_o(intr_int[i])
		);
	end
end

endgenerate



endmodule
