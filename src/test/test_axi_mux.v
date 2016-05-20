`timescale 1ns/1ps
module test_axi_mux;

reg aclk;
reg aresetn;

wire [3:0] axi_m_awid;
wire [31:0] axi_m_awaddr;
wire [7:0] axi_m_awlen;
wire [2:0] axi_m_awsize;
wire [1:0] axi_m_awburst;
wire [3:0] axi_m_awcache;
wire axi_m_awvalid;
wire axi_m_awready;
wire [3:0] axi_m_wid;
wire [31:0] axi_m_wdata;
wire [3:0] axi_m_wstrb;
wire axi_m_wlast;
wire axi_m_wvalid;
wire axi_m_wready;
wire [3:0] axi_m_bid;
wire [1:0] axi_m_bresp;
wire axi_m_bvalid;
wire axi_m_bready;
wire [3:0] axi_m_arid;
wire [31:0] axi_m_araddr;
wire [7:0] axi_m_arlen;
wire [2:0] axi_m_arsize;
wire [1:0] axi_m_arburst;
wire [3:0] axi_m_arcache;
wire axi_m_arvalid;
wire axi_m_arready;
wire [3:0] axi_m_rid;
wire [31:0] axi_m_rdata;
wire [1:0] axi_m_rresp;
wire axi_m_rlast;
wire axi_m_rvalid;
wire axi_m_rready;

wire [3:0] m0_awid;
wire [63:0] m0_awaddr;
wire [7:0] m0_awlen;
wire [2:0] m0_awsize;
wire [1:0] m0_awburst;
wire [3:0] m0_awcache;
wire m0_awvalid;
wire m0_awready;
wire [3:0] m0_wid;
wire [31:0] m0_wdata;
wire [3:0] m0_wstrb;
wire m0_wlast;
wire m0_wvalid;
wire m0_wready;
wire [3:0] m0_bid;
wire [1:0] m0_bresp;
wire m0_bvalid;
wire m0_bready;
wire [3:0] m0_arid;
wire [63:0] m0_araddr;
wire [7:0] m0_arlen;
wire [2:0] m0_arsize;
wire [1:0] m0_arburst;
wire [3:0] m0_arcache;
wire m0_arvalid;
wire m0_arready;
wire [3:0] m0_rid;
wire [31:0] m0_rdata;
wire [1:0] m0_rresp;
wire m0_rlast;
wire m0_rvalid;
wire m0_rready;

wire [3:0] m1_awid;
wire [63:0] m1_awaddr;
wire [7:0] m1_awlen;
wire [2:0] m1_awsize;
wire [1:0] m1_awburst;
wire [3:0] m1_awcache;
wire m1_awvalid;
wire m1_awready;
wire [3:0] m1_wid;
wire [31:0] m1_wdata;
wire [3:0] m1_wstrb;
wire m1_wlast;
wire m1_wvalid;
wire m1_wready;
wire [3:0] m1_bid;
wire [1:0] m1_bresp;
wire m1_bvalid;
wire m1_bready;
wire [3:0] m1_arid;
wire [63:0] m1_araddr;
wire [7:0] m1_arlen;
wire [2:0] m1_arsize;
wire [1:0] m1_arburst;
wire [3:0] m1_arcache;
wire m1_arvalid;
wire m1_arready;
wire [3:0] m1_rid;
wire [31:0] m1_rdata;
wire [1:0] m1_rresp;
wire m1_rlast;
wire m1_rvalid;
wire m1_rready;

axi_mux #(
	.SLAVE_NUM(2),
	.ID_WIDTH(4),
	.ADDR_WIDTH(32),
	.DATA_WIDTH(32),
	.LEN_WIDTH(8)
) dut_i (
	.aclk(aclk),
	.aresetn(aresetn),

	.s_awid({m1_awid,m0_awid}),
	.s_awaddr({m1_awaddr,m0_awaddr}),
	.s_awlen({m1_awlen,m0_awlen}),
	.s_awsize({m1_awsize,m0_awsize}),
	.s_awburst({m1_awburst,m0_awburst}),
	.s_awvalid({m1_awvalid,m0_awvalid}),
	.s_awready({m1_awready,m0_awready}),

	.s_wid({m1_wid,m0_wid}),
	.s_wdata({m1_wdata,m0_wdata}),
	.s_wstrb({m1_wstrb,m0_wstrb}),
	.s_wlast({m1_wlast,m0_wlast}),
	.s_wvalid({m1_wvalid,m0_wvalid}),
	.s_wready({m1_wready,m0_wready}),

	.s_bid({m1_bid,m0_bid}),
	.s_bresp({m1_bresp,m0_bresp}),
	.s_bvalid({m1_bvalid,m0_bvalid}),
	.s_bready({m1_bready,m0_bready}),

	.s_arid({m1_arid,m0_arid}),
	.s_araddr({m1_araddr,m0_araddr}),
	.s_arlen({m1_arlen,m0_arlen}),
	.s_arsize({m1_arsize,m0_arsize}),
	.s_arburst({m1_arburst,m0_arburst}),
	.s_arvalid({m1_arvalid,m0_arvalid}),
	.s_arready({m1_arready,m0_arready}),

	.s_rid({m1_rid,m0_rid}),
	.s_rdata({m1_rdata,m0_rdata}),
	.s_rresp({m1_rresp,m0_rresp}),
	.s_rlast({m1_rlast,m0_rlast}),
	.s_rvalid({m1_rvalid,m0_rvalid}),
	.s_rready({m1_rready,m0_rready}),

	.m_awid(axi_m_awid),
	.m_awaddr(axi_m_awaddr),
	.m_awlen(axi_m_awlen),
	.m_awsize(axi_m_awsize),
	.m_awburst(axi_m_awburst),
	.m_awvalid(axi_m_awvalid),
	.m_awready(axi_m_awready),

	.m_wid(axi_m_wid),
	.m_wdata(axi_m_wdata),
	.m_wstrb(axi_m_wstrb),
	.m_wlast(axi_m_wlast),
	.m_wvalid(axi_m_wvalid),
	.m_wready(axi_m_wready),

	.m_bid(axi_m_bid),
	.m_bresp(axi_m_bresp),
	.m_bvalid(axi_m_bvalid),
	.m_bready(axi_m_bready),

	.m_arid(axi_m_arid),
	.m_araddr(axi_m_araddr),
	.m_arlen(axi_m_arlen),
	.m_arsize(axi_m_arsize),
	.m_arburst(axi_m_arburst),
	.m_arvalid(axi_m_arvalid),
	.m_arready(axi_m_arready),

	.m_rid(axi_m_rid),
	.m_rdata(axi_m_rdata),
	.m_rresp(axi_m_rresp),
	.m_rlast(axi_m_rlast),
	.m_rvalid(axi_m_rvalid),
	.m_rready(axi_m_rready)
);

axi_ram #(
	.MEMORY_DEPTH(16384),
	.DATA_WIDTH(32),
	.ID_WIDTH(4)
) rx_desc_ram_i (
	.aclk(aclk),
	.aresetn(aresetn),

	.s_awid(axi_m_awid),
	.s_awaddr(axi_m_awaddr[15:0]),
	.s_awlen(axi_m_awlen),
	.s_awsize(axi_m_awsize),
	.s_awburst(axi_m_awburst),
	.s_awvalid(axi_m_awvalid),
	.s_awready(axi_m_awready),

	.s_wid(axi_m_wid),
	.s_wdata(axi_m_wdata),
	.s_wstrb(axi_m_wstrb),
	.s_wlast(axi_m_wlast),
	.s_wvalid(axi_m_wvalid),
	.s_wready(axi_m_wready),

	.s_bid(axi_m_bid),
	.s_bresp(axi_m_bresp),
	.s_bvalid(axi_m_bvalid),
	.s_bready(axi_m_bready),

	.s_arid(axi_m_arid),
	.s_araddr(axi_m_araddr[15:0]),
	.s_arlen(axi_m_arlen),
	.s_arsize(axi_m_arsize),
	.s_arburst(axi_m_arburst),
	.s_arvalid(axi_m_arvalid),
	.s_arready(axi_m_arready),

	.s_rid(axi_m_rid),
	.s_rdata(axi_m_rdata),
	.s_rresp(axi_m_rresp),
	.s_rlast(axi_m_rlast),
	.s_rvalid(axi_m_rvalid),
	.s_rready(axi_m_rready)
);

axi_master_model m0 (
	.m_axi_aresetn(aresetn),
	.m_axi_aclk(aclk),
	.m_axi_awid(m0_awid),
	.m_axi_awaddr(m0_awaddr),
	.m_axi_awlen(m0_awlen),
	.m_axi_awsize(m0_awsize),
	.m_axi_awburst(m0_awburst),
	.m_axi_awvalid(m0_awvalid),
	.m_axi_awready(m0_awready),
	.m_axi_wid(m0_wid),
	.m_axi_wdata(m0_wdata),
	.m_axi_wstrb(m0_wstrb),
	.m_axi_wlast(m0_wlast),
	.m_axi_wvalid(m0_wvalid),
	.m_axi_wready(m0_wready),
	.m_axi_bready(m0_bready),
	.m_axi_bid(m0_bid),
	.m_axi_bresp(m0_bresp),
	.m_axi_bvalid(m0_bvalid),
	.m_axi_arid(m0_arid),
	.m_axi_araddr(m0_araddr),
	.m_axi_arlen(m0_arlen),
	.m_axi_arsize(m0_arsize),
	.m_axi_arburst(m0_arburst),
	.m_axi_arvalid(m0_arvalid),
	.m_axi_arready(m0_arready),
	.m_axi_rready(m0_rready),
	.m_axi_rid(m0_rid),
	.m_axi_rdata(m0_rdata),
	.m_axi_rresp(m0_rresp),
	.m_axi_rlast(m0_rlast),
	.m_axi_rvalid(m0_rvalid)
);

axi_master_model m1 (
	.m_axi_aresetn(aresetn),
	.m_axi_aclk(aclk),
	.m_axi_awid(m1_awid),
	.m_axi_awaddr(m1_awaddr),
	.m_axi_awlen(m1_awlen),
	.m_axi_awsize(m1_awsize),
	.m_axi_awburst(m1_awburst),
	.m_axi_awvalid(m1_awvalid),
	.m_axi_awready(m1_awready),
	.m_axi_wid(m1_wid),
	.m_axi_wdata(m1_wdata),
	.m_axi_wstrb(m1_wstrb),
	.m_axi_wlast(m1_wlast),
	.m_axi_wvalid(m1_wvalid),
	.m_axi_wready(m1_wready),
	.m_axi_bready(m1_bready),
	.m_axi_bid(m1_bid),
	.m_axi_bresp(m1_bresp),
	.m_axi_bvalid(m1_bvalid),
	.m_axi_arid(m1_arid),
	.m_axi_araddr(m1_araddr),
	.m_axi_arlen(m1_arlen),
	.m_axi_arsize(m1_arsize),
	.m_axi_arburst(m1_arburst),
	.m_axi_arvalid(m1_arvalid),
	.m_axi_arready(m1_arready),
	.m_axi_rready(m1_rready),
	.m_axi_rid(m1_rid),
	.m_axi_rdata(m1_rdata),
	.m_axi_rresp(m1_rresp),
	.m_axi_rlast(m1_rlast),
	.m_axi_rvalid(m1_rvalid)
);

initial
begin
	aclk = 0;
	forever #10 aclk = !aclk;
end

initial
begin:TEST
	integer i;
	$dumpfile("test_axi_mux.vcd");
	$dumpvars(0);
	aresetn = 0;
	#100 aresetn = 1;

	for(i=0;i<256;i=i+1) begin
		m0.set_write_data(i,{4{i[7:0]}});
		m0.set_write_strb(i,4'hf);
		m1.set_write_data(i,{4{i[7:0]}});
		m1.set_write_strb(i,4'hf);
	end

	fork
		begin:M0_WRITE
			integer j;
			for(j=0;j<1024;j=j+1) begin
				m0.write(j*4,j%256+1);
			end
		end
		begin:M0_READ
			integer j;
			for(j=0;j<1024;j=j+1) begin
				m0.read(j*4,256-(j%256));
			end
		end
		begin:M1_WRITE
			integer k;
			for(k=0;k<1024;k=k+1) begin
				m1.write(k*4,256-(k%256));
			end
		end
		begin:M1_READ
			integer k;
			for(k=0;k<1024;k=k+1) begin
				m1.read(k*4,k%256);
			end
		end
	join
	$finish;
end

endmodule
