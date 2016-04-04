`timescale 1ns/1ps
module test_multi_serial;
parameter CLK_PERIOD_NS = 8;
localparam CLOCK_PRESCALE = ((1_000_000_000/(115200*16))+(CLK_PERIOD_NS/2))/CLK_PERIOD_NS;

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

wire [7:0] rxd;
wire [7:0] txd;
wire [7:0] rtsn;
wire [7:0] ctsn;
wire [7:0] dtrn;
wire [7:0] dsrn;
wire [7:0] ri;
wire [7:0] dcdn;

assign rxd = txd;
assign ctsn = rtsn;
assign dsrn = dtrn;
assign ri = 8'b0;
assign dcdn = 8'b0;


multi_serial #(.PORT_NUM(8),.CLOCK_PRESCALE(CLOCK_PRESCALE)) 
multi_serial (
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
	$dumpfile("test_multi_serial.vcd");
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

	for(i=0;i<8;i=i+1) begin
		master.write(i*8+3,32'h80000000,4'h8);
		master.write(i*8+0,32'h1,4'h1);
		master.write(i*8+1,32'h0,4'h2);
		master.write(i*8+3,32'h00000000,4'h8);
		master.read(i*8+1,data);
		master.read(i*8+2,data);
		master.read(i*8+3,data);
	end
end


endmodule
