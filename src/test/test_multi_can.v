`timescale 1ns/1ps
module test_multi_can;
parameter CLK_PERIOD_NS = 8;

reg aclk;
wire aresetn;
wire axi_s_awvalid;
wire axi_s_awready;
wire [31:0] axi_s_awaddr;
wire axi_s_wvalid;
wire axi_s_wready;
wire [31:0] axi_s_wdata;
wire [3:0] axi_s_wstrb;
wire axi_s_bvalid;
wire axi_s_bready;
wire [1:0] axi_s_bresp;
wire axi_s_arvalid;
wire axi_s_arready;
wire [31:0] axi_s_araddr;
wire axi_s_rvalid;
wire axi_s_rready;
wire [31:0] axi_s_rdata;
wire [1:0] axi_s_rresp;

wire [1:0] rx;
wire [1:0] tx;
wire [1:0] bus_off_n;

assign rx = tx;

multi_can #(.PORT_NUM(2)) 
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
	.axi_s_aruser(4'hf),
	.axi_s_araddr(axi_s_araddr),
	.axi_s_arready(axi_s_arready),

	.axi_s_rvalid(axi_s_rvalid),
	.axi_s_rresp(axi_s_rresp),
	.axi_s_rdata(axi_s_rdata),
	.axi_s_rready(axi_s_rready),

	.interrupt(intr_request),

	.rx_i(rx),
	.tx_o(tx),
	.bus_off_on(bus_off_n)
);

axi_lite_model master(
	.m_axi_aresetn(aresetn),
	.m_axi_aclk(aclk),
	.m_axi_awaddr(axi_s_awaddr),
	.m_axi_awvalid(axi_s_awvalid),
	.m_axi_awready(axi_s_awready),
	.m_axi_wdata(axi_s_wdata),
	.m_axi_wstrb(axi_s_wstrb),
	.m_axi_wvalid(axi_s_wvalid),
	.m_axi_wready(axi_s_wready),
	.m_axi_bready(axi_s_bready),
	.m_axi_bresp(axi_s_bresp),
	.m_axi_bvalid(axi_s_bvalid),
	.m_axi_araddr(axi_s_araddr),
	.m_axi_arvalid(axi_s_arvalid),
	.m_axi_arready(axi_s_arready),
	.m_axi_rready(axi_s_rready),
	.m_axi_rdata(axi_s_rdata),
	.m_axi_rresp(axi_s_rresp),
	.m_axi_rvalid(axi_s_rvalid)
);

initial
begin
	aclk = 0;
	forever #(CLK_PERIOD_NS/2) aclk = !aclk;
end

initial
begin
	$dumpfile("test_multi_can.vcd");
	$dumpvars(0);

	#1000000;
	$finish;
end

initial
begin:T0
	reg [31:0] data;
	integer i;
	#100;
	master.reset();
	#1000;

	master.read(0,data);
	#10000;
	master.write(0,32'h0e,4'h1);
	#10000;
	master.read(0,data);

end


endmodule
