module mpc_wrapper #(
	parameter DEBUG = "FALSE",
	parameter PORT_NUM=4
) 
(
	input RST,
	input CLK,	
	input [31:0] ADDR,
	input ADDR_VLD,
	input [7:0] BASE_HIT,
	output [31:0] ADIO_IN,
	input [31:0] ADIO_OUT,
	output S_TERM,
	output S_READY,
	output S_ABORT,
	input S_WRDN,
	input S_SRC_EN,
	input S_DATA,
	input S_DATA_VLD,
	input [3:0] S_CBE,
	output INT_N,
	output REQUEST,
	output REQUESTHOLD,
	output [3:0] M_CBE,
	output M_WRDN,
	output COMPLETE,
	output M_READY,
	input M_DATA_VLD,
	input M_SRC_EN,
	input TIME_OUT,
	input M_DATA,
	input M_ADDR_N,
	input STOPQ_N,

	// CAN signals
	input  [PORT_NUM-1:0] rx_i,
	output [PORT_NUM-1:0] tx_o,
	output [PORT_NUM-1:0] bus_off_on
);

wire aclk;
wire aresetn;

wire mpc_s_awvalid;
wire mpc_s_awready;
wire [31:0] mpc_s_awaddr;
wire mpc_s_wvalid;
wire mpc_s_wready;
wire [31:0] mpc_s_wdata;
wire [3:0] mpc_s_wstrb;
wire mpc_s_bvalid;
wire mpc_s_bready;
wire [1:0] mpc_s_bresp;
wire mpc_s_arvalid;
wire mpc_s_arready;
wire [31:0] mpc_s_araddr;
wire [3:0] mpc_s_aruser;
wire mpc_s_rvalid;
wire mpc_s_rready;
wire [31:0] mpc_s_rdata;
wire [1:0] mpc_s_rresp;
wire intr_request;

wire can_clk;
wire clk_locked;

reg [6:0] rst_sync;
(* ASYNC_REG = "TRUE" *)
reg [1:0] intr_sync;

assign aclk = can_clk;
assign areset = !rst_sync[6];
assign aresetn = !areset;

assign INT_N = !intr_sync[1];

assign REQUEST = 1'b0;
assign REQUESTHOLD = 1'b0;
assign M_CBE = 4'b0;
assign M_WRDN = 1'b0;
assign COMPLETE = 1'b0;
assign M_READY = 1'b0;

always @(posedge aclk, posedge RST)
begin
	if(RST) begin
		rst_sync <= 'b0;
	end
	else if(!clk_locked) begin
		rst_sync <= 'b0;
	end
	else if(!rst_sync[6])
		rst_sync <= rst_sync+1;
end

always @(posedge CLK)
begin
	intr_sync <= {intr_sync, intr_request};
end

can_clk_gen can_clk_gen_i(
	.reset(RST),
	.clk_in1(CLK),
	.clk_out1(can_clk), // 128MHz 
	.locked(clk_locked)
);

pci_target #(
	.ADDR_VALID_BITS(24)
)
pci_target_i(
	.ADDR(ADDR),
	.ADIO_IN(ADIO_IN),
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

	.tgt_m_aclk(aclk),
	.tgt_m_aresetn(aresetn),

	.tgt_m_awvalid(mpc_s_awvalid),
	.tgt_m_awready(mpc_s_awready),
	.tgt_m_awaddr(mpc_s_awaddr),

	.tgt_m_wvalid(mpc_s_wvalid),
	.tgt_m_wready(mpc_s_wready),
	.tgt_m_wdata(mpc_s_wdata),
	.tgt_m_wstrb(mpc_s_wstrb),

	.tgt_m_bvalid(mpc_s_bvalid),
	.tgt_m_bready(mpc_s_bready),
	.tgt_m_bresp(mpc_s_bresp),

	.tgt_m_arvalid(mpc_s_arvalid),
	.tgt_m_arready(mpc_s_arready),
	.tgt_m_araddr(mpc_s_araddr),
	.tgt_m_aruser(mpc_s_aruser),

	.tgt_m_rvalid(mpc_s_rvalid),
	.tgt_m_rready(mpc_s_rready),
	.tgt_m_rdata(mpc_s_rdata),
	.tgt_m_rresp(mpc_s_rresp)
);

mpc_top #(.PORT_NUM(PORT_NUM)) mpc_top(
	.aclk(aclk),
	.aresetn(aresetn),

	.axi_s_awvalid(mpc_s_awvalid),
	.axi_s_awready(mpc_s_awready),
	.axi_s_awaddr(mpc_s_awaddr),

	.axi_s_wvalid(mpc_s_wvalid),
	.axi_s_wready(mpc_s_wready),
	.axi_s_wdata(mpc_s_wdata),
	.axi_s_wstrb(mpc_s_wstrb),

	.axi_s_bvalid(mpc_s_bvalid),
	.axi_s_bready(mpc_s_bready),
	.axi_s_bresp(mpc_s_bresp),

	.axi_s_arvalid(mpc_s_arvalid),
	.axi_s_arready(mpc_s_arready),
	.axi_s_araddr(mpc_s_araddr),
	.axi_s_aruser(mpc_s_aruser),

	.axi_s_rvalid(mpc_s_rvalid),
	.axi_s_rready(mpc_s_rready),
	.axi_s_rdata(mpc_s_rdata),
	.axi_s_rresp(mpc_s_rresp),

	.intr_request(intr_request),

	.rx_i(rx_i),
	.tx_o(tx_o),
	.bus_off_on(bus_off_on)
);

generate
if(DEBUG == "TRUE") begin
ila_0 ila_i0(
	.clk(aclk), // input wire clk
	.probe0({
		mpc_s_awvalid,
		mpc_s_awready,
		mpc_s_awaddr,

		mpc_s_wvalid,
		mpc_s_wready,
		mpc_s_wdata,
		mpc_s_wstrb,

		mpc_s_bvalid,
		mpc_s_bready,
		mpc_s_bresp,

		mpc_s_arvalid,
		mpc_s_arready,
		mpc_s_araddr,
		mpc_s_aruser,

		mpc_s_rvalid,
		mpc_s_rready,
		mpc_s_rdata,
		mpc_s_rresp,

		intr_request
	})
);
end
endgenerate

endmodule
