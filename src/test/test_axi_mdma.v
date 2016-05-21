`timescale 1ns/1ps
module test_axi_mdma;

reg aclk;
reg aresetn;

reg [31:0] cmd_src_addr;
reg [31:0] cmd_dst_addr;
reg [15:0] cmd_bytes;
reg cmd_valid;
wire cmd_ready;

wire [31:0] rpt_src_addr;
wire [31:0] rpt_dst_addr;
wire [15:0] rpt_bytes;
wire [1:0] rpt_status;
wire rpt_valid;
wire rpt_ready;

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

assign rpt_ready = 1'b1;

reg awready_gate;
reg [7:0] awready_cnt;

axi_mdma #(
	.SRC_ADDRESS_BITS(32), 
	.SRC_BIG_ENDIAN("FALSE"),
	.DST_ADDRESS_BITS(32), 
	.DST_BIG_ENDIAN("FALSE"),
	.LENGTH_BITS(16)
) mdma_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.cmd_src_addr(cmd_src_addr),
	.cmd_dst_addr(cmd_dst_addr),
	.cmd_bytes(cmd_bytes),
	.cmd_valid(cmd_valid),
	.cmd_ready(cmd_ready),

	.rpt_src_addr(rpt_src_addr),
	.rpt_dst_addr(rpt_dst_addr),
	.rpt_status(rpt_status),
	.rpt_bytes(rpt_bytes),
	.rpt_valid(rpt_valid),
	.rpt_ready(rpt_ready),

	.src_m_arid(ram_s_arid),
	.src_m_araddr(ram_s_araddr),
	.src_m_arlen(ram_s_arlen),
	.src_m_arsize(ram_s_arsize),
	.src_m_arburst(ram_s_arburst),
	.src_m_arvalid(ram_s_arvalid),
	.src_m_arready(ram_s_arready),

	.src_m_rid(ram_s_rid),
	.src_m_rdata(ram_s_rdata),
	.src_m_rresp(ram_s_rresp),
	.src_m_rlast(ram_s_rlast),
	.src_m_rvalid(ram_s_rvalid),
	.src_m_rready(ram_s_rready),

	.dst_m_awid(ram_s_awid),
	.dst_m_awaddr(ram_s_awaddr),
	.dst_m_awlen(ram_s_awlen),
	.dst_m_awsize(ram_s_awsize),
	.dst_m_awburst(ram_s_awburst),
	.dst_m_awvalid(ram_s_awvalid),
	.dst_m_awready(ram_s_awready&awready_gate),

	.dst_m_wid(ram_s_wid),
	.dst_m_wdata(ram_s_wdata),
	.dst_m_wstrb(ram_s_wstrb),
	.dst_m_wlast(ram_s_wlast),
	.dst_m_wvalid(ram_s_wvalid),
	.dst_m_wready(ram_s_wready),

	.dst_m_bid(ram_s_bid),
	.dst_m_bresp(ram_s_bresp),
	.dst_m_bvalid(ram_s_bvalid),
	.dst_m_bready(ram_s_bready)
);

axi_ram #(.MEMORY_DEPTH(8192)) mem_i(
	.aresetn(aresetn),
	.aclk(aclk),

	.s_awid(ram_s_awid),
	.s_awaddr(ram_s_awaddr),
	.s_awlen(ram_s_awlen),
	.s_awsize(ram_s_awsize),
	.s_awburst(ram_s_awburst),
	.s_awvalid(ram_s_awvalid&awready_gate),
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


always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		awready_gate <= 1'b0;
		awready_cnt <= 'b0;
	end
	else if(!awready_gate && ram_s_awvalid) begin
		if(awready_cnt == 128)
			awready_gate <= 1'b1;
		awready_cnt <= awready_cnt+1;
	end
	else if(awready_gate && ram_s_awready) begin
		awready_gate <= 1'b0;
		awready_cnt <= 'b0;
	end
end

initial
begin
	aclk = 0;
	forever #10 aclk = ~aclk;
end

initial begin
	$dumpfile("test_axi_mdma.vcd");
	$dumpvars(0);
	aresetn = 0;
	@(posedge aclk) aresetn <= 1;

	//#200000;
	//$finish();
end

task initialize;
	reg [31:0] data;
	integer i;
	begin
		for(i=0;i<16'h4000;i=i+4) begin
			data[7:0] = i;
			data[15:8] = i+1;
			data[23:16] = i+2;
			data[31:24] = i+3;
			mem_i.write(i,data);
		end
	end
endtask

task test_dma(input [31:0] src, input [31:0] dst, input [15:0] bytes);
	begin
		cmd_src_addr <= src;
		cmd_dst_addr <= dst;
		cmd_bytes <= bytes;
		cmd_valid <= 1'b1;
		@(posedge aclk);
		while(!cmd_ready) @(posedge aclk);
		cmd_valid <= 1'b0;
		@(posedge aclk);
	end
endtask

task test_offset(input integer len1, input integer len2);
	begin
		test_dma(16'h0000,16'h0000,len1);
		test_dma(16'h0000,16'h0000,len2);
	end
endtask

task test_fault;
	integer i;
	begin
		for(i=0;i<128;i=i+1) begin
			aresetn <= 0;
			@(posedge aclk);
			aresetn <= 1;
			test_offset(i+1,70);
			#10000;
		end
	end
endtask

initial begin
	aresetn = 0;
	cmd_valid = 1'b0;
	cmd_valid = 1'b0;

	initialize();

	#100;
	//repeat(16) test_dma(16'h0000,16'h0000, 70);
	//test_fault();
	test_dma(16'h0000,16'h0000, 70);
	test_dma(16'h0001,16'h0000, 70);
	test_dma(16'h0002,16'h0000, 70);
	test_dma(16'h0003,16'h0000, 70);
	test_dma(16'h0000,16'h0001, 70);
	test_dma(16'h0001,16'h0001, 70);
	test_dma(16'h0002,16'h0001, 70);
	test_dma(16'h0003,16'h0001, 70);
	test_dma(16'h0000,16'h0002, 70);
	test_dma(16'h0001,16'h0002, 70);
	test_dma(16'h0002,16'h0002, 70);
	test_dma(16'h0003,16'h0002, 70);
	test_dma(16'h0000,16'h0003, 70);
	test_dma(16'h0001,16'h0003, 70);
	test_dma(16'h0002,16'h0003, 70);
	test_dma(16'h0003,16'h0003, 70);

	test_dma(16'h0000,16'h0000, 66);
	test_dma(16'h0001,16'h0000, 66);
	test_dma(16'h0002,16'h0000, 66);
	test_dma(16'h0003,16'h0000, 66);
	test_dma(16'h0000,16'h0001, 66);
	test_dma(16'h0001,16'h0001, 66);
	test_dma(16'h0002,16'h0001, 66);
	test_dma(16'h0003,16'h0001, 66);
	test_dma(16'h0000,16'h0002, 66);
	test_dma(16'h0001,16'h0002, 66);
	test_dma(16'h0002,16'h0002, 66);
	test_dma(16'h0003,16'h0002, 66);
	test_dma(16'h0000,16'h0003, 66);
	test_dma(16'h0001,16'h0003, 66);
	test_dma(16'h0002,16'h0003, 66);
	test_dma(16'h0003,16'h0003, 66);

	#10000;
	/*
	test_dma(16'h0000,16'h1000, 1);
	test_dma(16'h0000,16'h1000, 3);
	test_dma(16'h0000,16'h1000, 4);
	test_dma(16'h0000,16'h1000, 5);

	test_dma(16'h0001,16'h1000, 1);
	test_dma(16'h0001,16'h1000, 3);
	test_dma(16'h0001,16'h1000, 4);
	test_dma(16'h0001,16'h1000, 5);
	
	test_dma(16'h0002,16'h1000, 1);
	test_dma(16'h0002,16'h1000, 3);
	test_dma(16'h0002,16'h1000, 4);
	test_dma(16'h0002,16'h1000, 5);
	
	test_dma(16'h0003,16'h1000, 1);
	test_dma(16'h0003,16'h1000, 3);
	test_dma(16'h0003,16'h1000, 4);
	test_dma(16'h0003,16'h1000, 5);

	test_dma(16'h0000,16'h1001, 4);
	test_dma(16'h0000,16'h1002, 4);
	test_dma(16'h0000,16'h1003, 4);
	test_dma(16'h0000,16'h1004, 4);

	test_dma(16'h0001,16'h1001, 4);
	test_dma(16'h0001,16'h1002, 4);
	test_dma(16'h0001,16'h1003, 4);
	test_dma(16'h0001,16'h1004, 4);
	
	test_dma(16'h0002,16'h1001, 4);
	test_dma(16'h0002,16'h1002, 4);
	test_dma(16'h0002,16'h1003, 4);
	test_dma(16'h0002,16'h1004, 4);
	
	test_dma(16'h0003,16'h1001, 4);
	test_dma(16'h0003,16'h1002, 4);
	test_dma(16'h0003,16'h1003, 4);
	test_dma(16'h0003,16'h1004, 4);

	test_dma(16'h0000,16'h1000, 1023);
	test_dma(16'h0000,16'h1000, 1024);
	test_dma(16'h0000,16'h1000, 1025);
	test_dma(16'h0000,16'h1000, 16384);

	test_dma(16'h0000,16'h1001, 16);
	test_dma(16'h0000,16'h1002, 16);
	test_dma(16'h0000,16'h1003, 16);
	test_dma(16'h0000,16'h1004, 16);

	test_dma(16'h0001,16'h1001, 16);
	test_dma(16'h0001,16'h1002, 16);
	test_dma(16'h0001,16'h1003, 16);
	test_dma(16'h0001,16'h1004, 16);

	test_dma(16'h0002,16'h1001, 16);
	test_dma(16'h0002,16'h1002, 16);
	test_dma(16'h0002,16'h1003, 16);
	test_dma(16'h0002,16'h1004, 16);

	test_dma(16'h0003,16'h1001, 16);
	test_dma(16'h0003,16'h1002, 16);
	test_dma(16'h0003,16'h1003, 16);
	test_dma(16'h0003,16'h1004, 16);
	*/

	#100000;
	$finish();
end
endmodule
