module tx_frame(
	input aclk,
	input aresetn,

	// Command Port
	// C1: [31:16]=Length, [15:0]=Local Address 
	// C2: [31:0]=DESC_DW2
	// C3: [31:0]=DESC_DW3
	input [31:0] cmd_s_tdata,
	input cmd_s_tvalid,
	input cmd_s_tlast,
	output reg cmd_s_tready,

	// Response Port
	// [31:16]=Length, [15:0]=Local Address
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

	output  [3:0] dram_m_arid,
	output  [15:0] dram_m_araddr,
	output  [7:0] dram_m_arlen,
	output  [2:0] dram_m_arsize,
	output  [1:0] dram_m_arburst,
	output  dram_m_arvalid,
	input dram_m_arready,

	input [3:0] dram_m_rid,
	input [31:0] dram_m_rdata,
	input [1:0] dram_m_rresp,
	input dram_m_rlast,
	input dram_m_rvalid,
	output dram_m_rready,

	// MAC Tx Port
	output [31:0] mac_m_tdata,
	output [3:0] mac_m_tkeep,
	output mac_m_tvalid,
	output mac_m_tlast,
	input mac_m_tready	
);

reg [15:0] length;
reg [15:0] local_addr;
reg [31:0] desc_dw2;
reg [31:0] desc_dw3;

reg [1:0] cmd_cnt;

wire cmd_valid;

assign cmd_valid = cmd_s_tready&cmd_s_tvalid&cmd_s_tlast;

axi_rdma #(.ADDRESS_BITS(16), .LENGTH_BITS(16)) rdma_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.cmd_address(local_addr),
	.cmd_bytes(length),
	.cmd_valid(cmd_valid),
	.cmd_ready(cmd_ready),

	.axi_m_arid(dram_m_arid),
	.axi_m_araddr(dram_m_araddr),
	.axi_m_arlen(dram_m_arlen),
	.axi_m_arsize(dram_m_arsize),
	.axi_m_arburst(dram_m_arburst),
	.axi_m_arvalid(dram_m_arvalid),
	.axi_m_arready(dram_m_arready),

	.axi_m_rid(dram_m_rid),
	.axi_m_rdata(dram_m_rdata),
	.axi_m_rresp(dram_m_rresp),
	.axi_m_rlast(dram_m_rlast),
	.axi_m_rvalid(dram_m_rvalid),
	.axi_m_rready(dram_m_rready),

	.dout_tdata(mac_m_tdata),
	.dout_tkeep(mac_m_tkeep),
	.dout_tlast(mac_m_tlast),
	.dout_tvalid(mac_m_tvalid),
	.dout_tready(mac_m_tready)
);

always @(*) stat_m_tdata = {length, local_addr};

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		cmd_cnt <= 'b0;
		length <= 'bx;
		local_addr <= 'bx;
		desc_dw2 <= 'bx;
		desc_dw3 <= 'bx;
	end
	else if(cmd_s_tready && cmd_s_tvalid) begin
		case(cmd_cnt) /* synthesis parallel_case */
			0: begin
				length <= cmd_s_tdata[31:16];
				local_addr <= cmd_s_tdata[15:0];
			end
			1: begin
				desc_dw2 <= cmd_s_tdata;
			end
			2: begin
				desc_dw3 <= cmd_s_tdata;
			end
		endcase
		if(cmd_s_tlast) 
			cmd_cnt <= 0;
		else
			cmd_cnt <= cmd_cnt+1;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		cmd_s_tready <= 1'b1;
	end
	else if(cmd_s_tready && cmd_s_tvalid && cmd_s_tlast) begin
		cmd_s_tready <= 1'b0;
	end
	else if(stat_m_tvalid && stat_m_tlast && stat_m_tready) begin
		cmd_s_tready <= 1'b1;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		stat_m_tvalid <= 1'b0;
		stat_m_tlast <= 1'b1;
	end
	else if(mac_m_tvalid && mac_m_tlast && mac_m_tready) begin
		stat_m_tvalid <= 1'b1;
	end
	else if(stat_m_tvalid && stat_m_tready && stat_m_tlast) begin
		stat_m_tvalid <= 1'b0;
	end
end

endmodule
