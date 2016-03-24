`timescale 1ns/1ps
module axi_lite_model
#(
	parameter	M_AXI_DATA_WIDTH = 32,
	parameter	M_AXI_STRB_WIDTH = M_AXI_DATA_WIDTH/8
)
(
	// AXI Clock & Reset
	output reg	m_axi_aresetn,
	input	m_axi_aclk,

	// AXI Master Write Address
	output reg	[31:0]	m_axi_awaddr,
	output reg	m_axi_awvalid,
	input	m_axi_awready,
	//output	[M_AXI_ID_WIDTH-1:0]	m_axi_awid,
	//output	[7:0]	m_axi_awlen,
	//output	[2:0]	m_axi_awsize,
	//output	[1:0]	m_axi_awburst,
	//output	[0:0]	m_axi_awlock,
	//output	[3:0]	m_axi_awcache,
	//output	[2:0]	m_axi_awprot,
	//output	[3:0]	m_axi_awqos,

	// AXI Master Write Data
	output reg	[M_AXI_DATA_WIDTH-1:0]	m_axi_wdata,
	output reg	[M_AXI_STRB_WIDTH-1:0]	m_axi_wstrb,
	output reg	m_axi_wvalid,
	input	m_axi_wready,
	//output	m_axi_wlast,

	// AXI Master Write Response
	output reg	m_axi_bready,
	input	[1:0]	m_axi_bresp,
	input	m_axi_bvalid,
	//input	[M_AXI_ID_WIDTH-1:0]	m_axi_bid,

	// AXI Master Read Address
	output reg	[31:0]	m_axi_araddr,
	output reg	m_axi_arvalid,
	input	m_axi_arready,
	//output	[M_AXI_ID_WIDTH-1:0]	m_axi_arid,
	//output	[7:0]	m_axi_arlen,
	//output	[2:0]	m_axi_arsize,
	//output	[1:0]	m_axi_arburst,
	//output	[0:0]	m_axi_arlock,
	//output	[3:0]	m_axi_arcache,
	//output	[2:0]	m_axi_arprot,
	//output	[3:0]	m_axi_arqos,

	// AXI Master Read Data
	output reg	m_axi_rready,
	input	[M_AXI_DATA_WIDTH-1:0]	m_axi_rdata,
	input	[1:0]	m_axi_rresp,
	input	m_axi_rvalid
	//input	[M_AXI_ID_WIDTH-1:0]	m_axi_rid,
	//input	m_axi_rlast
);

initial begin
	m_axi_aresetn = 1'b1;
	m_axi_awvalid = 1'b0;
	m_axi_wvalid = 1'b0;
	m_axi_bready = 1'b0;
	m_axi_arvalid = 1'b0;
	m_axi_rready = 1'b0;
end

task write(
	input [31:0] addr, 
	input [M_AXI_DATA_WIDTH-1:0] data,
	input [M_AXI_STRB_WIDTH-1:0] strb
	);
begin
	$display($time,,,"AXI-LITE WRITE: @%x = %x",addr,data);
	@(posedge m_axi_aclk);
	m_axi_awaddr <= addr;
	m_axi_awvalid <= 1'b1;
	m_axi_wdata <= data;
	m_axi_wstrb <= strb;
	m_axi_wvalid <= 1'b1;
	@(posedge m_axi_aclk);
	while(m_axi_awvalid || m_axi_wvalid) begin
		if(m_axi_awready) m_axi_awvalid <= 1'b0;
		if(m_axi_wready) m_axi_wvalid <= 1'b0;
		@(posedge m_axi_aclk);
	end
	while(!m_axi_bvalid) @(posedge m_axi_aclk);
	m_axi_bready <= 1'b1;
	if(m_axi_bresp) $display($time,,,"AXI-LITE WRITE: response with error");
	@(posedge m_axi_aclk);
	m_axi_bready <= 1'b0;
end
endtask

task read(
	input [31:0] addr, 
	output [M_AXI_DATA_WIDTH-1:0] data
	);
begin
	@(posedge m_axi_aclk);
	m_axi_araddr <= addr;
	m_axi_arvalid <= 1'b1;
	@(posedge m_axi_aclk);
	while(!m_axi_arready) @(posedge m_axi_aclk);
	m_axi_arvalid <= 1'b0;
	while(!m_axi_rvalid) @(posedge m_axi_aclk);
	data <= m_axi_rdata;
	m_axi_rready <= 1'b1;
	$display($time,,,"AXI-LITE READ: @%x = %x",addr,m_axi_rdata);
	if(m_axi_rresp) $display($time,,,"AXI-LITE READ: response with error");
	@(posedge m_axi_aclk);
	m_axi_rready <= 1'b0;
end
endtask

task reset;
begin
	@(posedge m_axi_aclk);
	m_axi_aresetn <= 1'b0;
	repeat(8) @(posedge m_axi_aclk);
	m_axi_aresetn <= 1'b1;
end
endtask

endmodule
