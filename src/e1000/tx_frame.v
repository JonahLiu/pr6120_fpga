module tx_frame(
	input aclk,
	input aresetn,

	// Command Port
	// [31:16]=RSV, [15:0]=Local Address
	input [31:0] cmd_s_tdata,
	input cmd_s_tvalid,
	input cmd_s_tlast,
	output reg cmd_s_tready,

	// Response Port
	// [31:18]=RSV, [17]=IDE, [16]=RS, [15:0]=Local Address
	output reg [31:0] stat_m_tdata,
	output reg stat_m_tvalid,
	output reg stat_m_tlast,
	input stat_m_tready,

	output reg [3:0] dram_m_awid,
	output reg [15:0] dram_m_awaddr,
	output reg [7:0] dram_m_awlen,
	output reg [2:0] dram_m_awsize,
	output reg [1:0] dram_m_awburst,
	output reg dram_m_awvalid,
	input dram_m_awready,

	output reg [3:0] dram_m_wid,
	output reg [31:0] dram_m_wdata,
	output reg [3:0] dram_m_wstrb,
	output reg dram_m_wlast,
	output reg dram_m_wvalid,
	input dram_m_wready,

	input [3:0] dram_m_bid,
	input [1:0] dram_m_bresp,
	input dram_m_bvalid,
	output reg dram_m_bready,

	output reg [3:0] dram_m_arid,
	output reg [15:0] dram_m_araddr,
	output reg [7:0] dram_m_arlen,
	output reg [2:0] dram_m_arsize,
	output reg [1:0] dram_m_arburst,
	output reg dram_m_arvalid,
	input dram_m_arready,

	input [3:0] dram_m_rid,
	input [31:0] dram_m_rdata,
	input [1:0] dram_m_rresp,
	input dram_m_rlast,
	input dram_m_rvalid,
	output reg dram_m_rready,

	// MAC Tx Port
	output [7:0] mac_m_tdata,
	output mac_m_tvalid,
	output mac_m_tlast,
	input mac_m_tready	
);
endmodule
