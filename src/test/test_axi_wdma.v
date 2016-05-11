`timescale 1ns/1ps
module test_axi_wdma;

reg aclk;
reg aresetn;

reg [31:0] wcmd_address;
reg [15:0] wcmd_bytes;
reg wcmd_valid;
wire wcmd_ready;

reg [31:0] rcmd_address;
reg [15:0] rcmd_bytes;
reg rcmd_valid;
wire rcmd_ready;

wire [3:0] ram_s_awid;
wire [31:0] ram_s_awaddr;
wire [7:0] ram_s_awlen;
wire [2:0] ram_s_awsize;
wire [1:0] ram_s_awburst;
wire [3:0] ram_s_awcache;
wire ram_s_awvalid;
wire ram_s_awready;
wire [3:0] ram_s_wid;
wire [31:0] ram_s_wdata;
wire [3:0] ram_s_wstrb;
wire ram_s_wlast;
wire ram_s_wvalid;
wire ram_s_wready;
wire [3:0] ram_s_bid;
wire [1:0] ram_s_bresp;
wire ram_s_bvalid;
wire ram_s_bready;
wire [3:0] ram_s_arid;
wire [31:0] ram_s_araddr;
wire [7:0] ram_s_arlen;
wire [2:0] ram_s_arsize;
wire [1:0] ram_s_arburst;
wire [3:0] ram_s_arcache;
wire ram_s_arvalid;
wire ram_s_arready;
wire [3:0] ram_s_rid;
wire [31:0] ram_s_rdata;
wire [1:0] ram_s_rresp;
wire ram_s_rlast;
wire ram_s_rvalid;
wire ram_s_rready;

reg [31:0] din_tdata;
reg [3:0] din_tkeep;
reg din_tlast;
reg din_tvalid;
wire din_tready;

wire [31:0] dout_tdata;
wire [3:0] dout_tkeep;
wire dout_tlast;
wire dout_tvalid;
wire dout_tready;

assign dout_tready = 1'b1;

axi_wdma #(
	.ADDRESS_BITS(32), 
	.LENGTH_BITS(16),
	.STREAM_BIG_ENDIAN("TRUE"),
	.MEM_BIG_ENDIAN("FALSE")
) wdma_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.cmd_address(wcmd_address),
	.cmd_bytes(wcmd_bytes),
	.cmd_valid(wcmd_valid),
	.cmd_ready(wcmd_ready),

	.axi_m_awid(ram_s_awid),
	.axi_m_awaddr(ram_s_awaddr),
	.axi_m_awlen(ram_s_awlen),
	.axi_m_awsize(ram_s_awsize),
	.axi_m_awburst(ram_s_awburst),
	.axi_m_awvalid(ram_s_awvalid),
	.axi_m_awready(ram_s_awready),

	.axi_m_wid(ram_s_wid),
	.axi_m_wdata(ram_s_wdata),
	.axi_m_wstrb(ram_s_wstrb),
	.axi_m_wlast(ram_s_wlast),
	.axi_m_wvalid(ram_s_wvalid),
	.axi_m_wready(ram_s_wready),

	.axi_m_bid(ram_s_bid),
	.axi_m_bresp(ram_s_bresp),
	.axi_m_bvalid(ram_s_bvalid),
	.axi_m_bready(ram_s_bready),

	.din_tdata(din_tdata),
	.din_tkeep(din_tkeep),
	.din_tlast(din_tlast),
	.din_tvalid(din_tvalid),
	.din_tready(din_tready)
);

axi_rdma #(
	.ADDRESS_BITS(32), 
	.LENGTH_BITS(16),
	.STREAM_BIG_ENDIAN("TRUE"),
	.MEM_BIG_ENDIAN("FALSE")
) rdma_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.cmd_address(rcmd_address),
	.cmd_bytes(rcmd_bytes),
	.cmd_valid(rcmd_valid),
	.cmd_ready(rcmd_ready),

	.axi_m_arid(ram_s_arid),
	.axi_m_araddr(ram_s_araddr),
	.axi_m_arlen(ram_s_arlen),
	.axi_m_arsize(ram_s_arsize),
	.axi_m_arburst(ram_s_arburst),
	.axi_m_arvalid(ram_s_arvalid),
	.axi_m_arready(ram_s_arready),

	.axi_m_rid(ram_s_rid),
	.axi_m_rdata(ram_s_rdata),
	.axi_m_rresp(ram_s_rresp),
	.axi_m_rlast(ram_s_rlast),
	.axi_m_rvalid(ram_s_rvalid),
	.axi_m_rready(ram_s_rready),

	.dout_tdata(dout_tdata),
	.dout_tkeep(dout_tkeep),
	.dout_tlast(dout_tlast),
	.dout_tvalid(dout_tvalid),
	.dout_tready(dout_tready)
);

axi_ram #(.MEMORY_DEPTH(4096)) mem_i(
	.aresetn(aresetn),
	.aclk(aclk),

	.s_awid(ram_s_awid),
	.s_awaddr(ram_s_awaddr),
	.s_awlen(ram_s_awlen),
	.s_awsize(ram_s_awsize),
	.s_awburst(ram_s_awburst),
	.s_awvalid(ram_s_awvalid),
	.s_awready(ram_s_awready),

	.s_wid(ram_s_wid),
	.s_wdata(ram_s_wdata),
	.s_wstrb(ram_s_wstrb),
	.s_wlast(ram_s_wlast),
	.s_wvalid(ram_s_wvalid),
	.s_wready(ram_s_wready),

	.s_bid(ram_s_bid),
	.s_bresp(ram_s_bresp),
	.s_bvalid(ram_s_bvalid),
	.s_bready(ram_s_bready),

	.s_arid(ram_s_arid),
	.s_araddr(ram_s_araddr),
	.s_arlen(ram_s_arlen),
	.s_arsize(ram_s_arsize),
	.s_arburst(ram_s_arburst),
	.s_arvalid(ram_s_arvalid),
	.s_arready(ram_s_arready),

	.s_rid(ram_s_rid),
	.s_rresp(ram_s_rresp),
	.s_rdata(ram_s_rdata),
	.s_rlast(ram_s_rlast),
	.s_rvalid(ram_s_rvalid),
	.s_rready(ram_s_rready)
);

initial
begin
	aclk = 0;
	forever #10 aclk = ~aclk;
end

initial begin
	$dumpfile("test_axi_wdma.vcd");
	$dumpvars(0);
	aresetn = 0;
	@(posedge aclk) aresetn <= 1;

	#200000;
	$finish();
end

task generate_stream(input integer bytes);
	integer i;
	begin
		i<=0;
		@(posedge aclk);
		while(i<bytes) begin
			din_tvalid <= 1'b1;
			din_tlast <= (i+4)>=bytes;
			din_tkeep <= ((i+4)>=bytes)?(4'b1111<<(i+4-bytes)):4'b1111;
			din_tdata[31:24] <= i;
			din_tdata[23:16] <= i+1;
			din_tdata[15:8] <= i+2;
			din_tdata[7:0] <= i+3;
			i <= i+4;
			@(posedge aclk);
			while(!din_tready) @(posedge aclk);
		end
		din_tvalid <= 1'b0;
	end
endtask

task test_wdma(input integer address, input integer bytes);
	begin
		wcmd_address <= address;
		wcmd_bytes <= bytes;
		wcmd_valid <= 1'b1;
		@(posedge aclk);
		while(!wcmd_ready) @(posedge aclk);
		wcmd_valid <= 1'b0;
		generate_stream(bytes);
		while(!wcmd_ready) @(posedge aclk);
	end
endtask

task test_rdma(input integer address, input integer bytes);
	begin
		rcmd_address <= address;
		rcmd_bytes <= bytes;
		rcmd_valid <= 1'b1;
		@(posedge aclk);
		while(!rcmd_ready) @(posedge aclk);
		rcmd_valid <= 1'b0;
		while(!rcmd_ready) @(posedge aclk);
	end
endtask

initial begin
	aresetn = 0;
	wcmd_valid = 1'b0;
	rcmd_valid = 1'b0;
	din_tvalid = 1'b0;

	#100;

	test_wdma(0,1);
	test_wdma(1,3);
	test_wdma(4,4);
	test_wdma(8,15);
	test_wdma(23,16);
	test_wdma(39,1024);
	test_wdma(1063,2047);

	test_rdma(0,1);
	test_rdma(1,3);
	test_rdma(4,4);
	test_rdma(8,15);
	test_rdma(23,16);
	test_rdma(39,1024);
	test_rdma(1063,2047);

	#100000;
	$finish();
end
endmodule
