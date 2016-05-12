module axi_mdma #(
	parameter SRC_ADDRESS_BITS=31,
	parameter SRC_BIG_ENDIAN="TRUE",
	parameter DST_ADDRESS_BITS=31,
	parameter DST_BIG_ENDIAN="TRUE",
	parameter LENGTH_BITS=16
)
(
	input aclk,
	input aresetn,

	// Command Port
	input [SRC_ADDRESS_BITS-1:0] cmd_src_addr,
	input [DST_ADDRESS_BITS-1:0] cmd_dst_addr,
	input [LENGTH_BITS-1:0] cmd_bytes,
	input cmd_valid,
	output reg cmd_ready,

	// Status Port
	output [SRC_ADDRESS_BITS-1:0] rpt_src_addr,
	output [DST_ADDRESS_BITS-1:0] rpt_dst_addr,
	output [LENGTH_BITS-1:0] rpt_bytes,
	output [1:0] rpt_status,
	output reg rpt_valid,
	input rpt_ready,

	output [3:0] src_m_arid,
	output [SRC_ADDRESS_BITS-1:0] src_m_araddr,
	output [7:0] src_m_arlen,
	output [2:0] src_m_arsize,
	output [1:0] src_m_arburst,
	output src_m_arvalid,
	input src_m_arready,

	input [3:0] src_m_rid,
	input [31:0] src_m_rdata,
	input [1:0] src_m_rresp,
	input src_m_rlast,
	input src_m_rvalid,
	output src_m_rready,

	output [3:0] dst_m_awid,
	output [DST_ADDRESS_BITS-1:0] dst_m_awaddr,
	output [7:0] dst_m_awlen,
	output [2:0] dst_m_awsize,
	output [1:0] dst_m_awburst,
	output dst_m_awvalid,
	input dst_m_awready,

	output [3:0] dst_m_wid,
	output [31:0] dst_m_wdata,
	output [3:0] dst_m_wstrb,
	output dst_m_wlast,
	output dst_m_wvalid,
	input dst_m_wready,

	input [3:0] dst_m_bid,
	input [1:0] dst_m_bresp,
	input dst_m_bvalid,
	output dst_m_bready
);

wire [31:0] stream_tdata;
wire [3:0] stream_tkeep;
wire stream_tlast;
wire stream_tvalid;
wire stream_tready;

reg [SRC_ADDRESS_BITS-1:0] src_address;
reg [DST_ADDRESS_BITS-1:0] dst_address;
reg [LENGTH_BITS-1:0] bytes;

wire [SRC_ADDRESS_BITS-1:0] rcmd_address;
wire [LENGTH_BITS-1:0] rcmd_bytes;
reg rcmd_valid;
wire rcmd_ready;

wire [DST_ADDRESS_BITS-1:0] wcmd_address;
wire [LENGTH_BITS-1:0] wcmd_bytes;
reg wcmd_valid;
wire wcmd_ready;

integer state, state_next;
localparam S_IDLE=0, S_RCMD=1, S_WCMD=2, S_WAIT=3, S_RPT=4;

assign rpt_src_addr = src_address;
assign rpt_dst_addr = dst_address;
assign rpt_bytes = bytes;
assign rpt_status = 'b0;

assign rcmd_address = src_address;
assign rcmd_bytes = bytes;

assign wcmd_address = dst_address;
assign wcmd_bytes = bytes;

axi_rdma #(
	.ADDRESS_BITS(SRC_ADDRESS_BITS), 
	.LENGTH_BITS(LENGTH_BITS),
	.STREAM_BIG_ENDIAN(SRC_BIG_ENDIAN),
	.MEM_BIG_ENDIAN(SRC_BIG_ENDIAN)
) rdma_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.cmd_address(rcmd_address),
	.cmd_bytes(rcmd_bytes),
	.cmd_valid(rcmd_valid),
	.cmd_ready(rcmd_ready),

	.axi_m_arid(src_m_arid),
	.axi_m_araddr(src_m_araddr),
	.axi_m_arlen(src_m_arlen),
	.axi_m_arsize(src_m_arsize),
	.axi_m_arburst(src_m_arburst),
	.axi_m_arvalid(src_m_arvalid),
	.axi_m_arready(src_m_arready),

	.axi_m_rid(src_m_rid),
	.axi_m_rdata(src_m_rdata),
	.axi_m_rresp(src_m_rresp),
	.axi_m_rlast(src_m_rlast),
	.axi_m_rvalid(src_m_rvalid),
	.axi_m_rready(src_m_rready),

	.dout_tdata(stream_tdata),
	.dout_tkeep(stream_tkeep),
	.dout_tlast(stream_tlast),
	.dout_tvalid(stream_tvalid),
	.dout_tready(stream_tready)
);

axi_wdma #(
	.ADDRESS_BITS(DST_ADDRESS_BITS), 
	.LENGTH_BITS(LENGTH_BITS),
	.STREAM_BIG_ENDIAN(DST_BIG_ENDIAN),
	.MEM_BIG_ENDIAN(DST_BIG_ENDIAN)
) wdma_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.cmd_address(wcmd_address),
	.cmd_bytes(wcmd_bytes),
	.cmd_valid(wcmd_valid),
	.cmd_ready(wcmd_ready),

	.axi_m_awid(dst_m_awid),
	.axi_m_awaddr(dst_m_awaddr),
	.axi_m_awlen(dst_m_awlen),
	.axi_m_awsize(dst_m_awsize),
	.axi_m_awburst(dst_m_awburst),
	.axi_m_awvalid(dst_m_awvalid),
	.axi_m_awready(dst_m_awready),

	.axi_m_wid(dst_m_wid),
	.axi_m_wdata(dst_m_wdata),
	.axi_m_wlast(dst_m_wlast),
	.axi_m_wvalid(dst_m_wvalid),
	.axi_m_wstrb(dst_m_wstrb),
	.axi_m_wready(dst_m_wready),

	.axi_m_bid(dst_m_bid),
	.axi_m_bresp(dst_m_bresp),
	.axi_m_bvalid(dst_m_bvalid),
	.axi_m_bready(dst_m_bready),

	.din_tdata(stream_tdata),
	.din_tkeep(stream_tkeep),
	.din_tlast(stream_tlast),
	.din_tvalid(stream_tvalid),
	.din_tready(stream_tready)
);

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn)
		state <= S_IDLE;
	else
		state <= state_next;
end

always @(*)
begin
	case(state)
		S_IDLE: begin
			if(cmd_valid)
				state_next = S_RCMD;
			else
				state_next = S_IDLE;
		end
		S_RCMD: begin
			if(rcmd_ready)
				state_next = S_WCMD;
			else
				state_next = S_RCMD;
		end
		S_WCMD: begin
			if(wcmd_ready)
				state_next = S_WAIT;
			else
				state_next = S_WCMD;
		end
		S_WAIT: begin
			if(wcmd_ready)
				state_next = S_RPT;
			else
				state_next = S_WAIT;
		end
		S_RPT: begin
			if(rpt_ready)
				state_next = S_IDLE;
			else
				state_next = S_RPT;
		end
		default: begin
			state_next = 'bx;
		end
	endcase
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		cmd_ready <= 1'b0;
		rpt_valid <= 1'b0;
		src_address <= 'bx;
		dst_address <= 'bx;
		bytes <= 'bx;
		rcmd_valid <= 1'b0;
		wcmd_valid <= 1'b0;
	end
	else case(state_next)
		S_IDLE: begin
			cmd_ready <= 1'b1;
			rpt_valid <= 1'b0;
		end
		S_RCMD: begin
			cmd_ready <= 1'b0;
			src_address <= cmd_src_addr;
			dst_address <= cmd_dst_addr;
			bytes <= cmd_bytes;
			rcmd_valid <= 1'b1;
		end
		S_WCMD: begin
			rcmd_valid <= 1'b0;
			wcmd_valid <= 1'b1;
		end
		S_WAIT: begin
			wcmd_valid <= 1'b0;
		end
		S_RPT: begin
			rpt_valid <= 1'b1;
		end
	endcase
end
endmodule
