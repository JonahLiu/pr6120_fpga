module rx_frame(
	input aclk,
	input aresetn,

	input [7:0] PCSS, // Packet Checksum Start

	// Command Port
	// C1: [31:16]=Length, [15:0]=Local Address (Free Buffer)
	input [31:0] cmd_s_tdata,
	input cmd_s_tvalid,
	input cmd_s_tlast,
	output cmd_s_tready,

	// Report Port
	// [31:16]=Length, [15:0]=Local Address (Valid Buffer)
	// C2: [31:0]=DESC_DW2
	// C3: [31:0]=DESC_DW3
	output reg [31:0] stat_m_tdata,
	output reg stat_m_tvalid,
	output reg stat_m_tlast,
	input stat_m_tready,

	output [3:0] dram_m_awid,
	output [15:0] dram_m_awaddr,
	output [7:0] dram_m_awlen,
	output [2:0] dram_m_awsize,
	output [1:0] dram_m_awburst,
	output dram_m_awvalid,
	input dram_m_awready,

	output [3:0] dram_m_wid,
	output [31:0] dram_m_wdata,
	output [3:0] dram_m_wstrb,
	output dram_m_wlast,
	output dram_m_wvalid,
	input dram_m_wready,

	input [3:0] dram_m_bid,
	input [1:0] dram_m_bresp,
	input dram_m_bvalid,
	output dram_m_bready,

	output [3:0] dram_m_arid,
	output [15:0] dram_m_araddr,
	output [7:0] dram_m_arlen,
	output [2:0] dram_m_arsize,
	output [1:0] dram_m_arburst,
	output dram_m_arvalid,
	input dram_m_arready,

	input [3:0] dram_m_rid,
	input [31:0] dram_m_rdata,
	input [1:0] dram_m_rresp,
	input dram_m_rlast,
	input dram_m_rvalid,
	output dram_m_rready,

	// MAC Rx Port
	input [31:0] mac_s_tdata,
	input [3:0] mac_s_tkeep,
	input [15:0] mac_s_tuser,
	input mac_s_tvalid,
	input mac_s_tlast,
	output mac_s_tready,

	output [16:0] dbg_ram_available,
	output [2:0] dbg_state
);

parameter DATA_RAM_DWORDS=8192;

function integer clogb2 (input integer size);
begin
	size = size - 1;
	for (clogb2=1; size>1; clogb2=clogb2+1)
		size = size >> 1;
end
endfunction

localparam ADDRESS_BITS = clogb2(DATA_RAM_DWORDS*4);

wire [15:0] addr_fifo_din;
wire addr_fifo_wr;
wire addr_fifo_full;
wire [15:0] addr_fifo_dout;
reg addr_fifo_rd;
wire addr_fifo_empty;

wire [15:0] checksum;
wire csum_valid;

reg [15:0] cmd_address;
reg [15:0] cmd_bytes;
reg cmd_valid;
wire cmd_ready;

reg [ADDRESS_BITS:0] ram_available;
reg [15:0] ram_address;

integer state, state_next;

localparam S_IDLE=0, S_CMD_C0=1, S_WAIT=2, S_RPT_STB=3, S_RPT_C0=4, S_RPT_C1=5, S_RPT_C2=6, S_COLLECT=7;

assign dram_m_arvalid = 1'b0;
assign dram_m_rready = 1'b1;

assign addr_fifo_din = cmd_s_tdata[31:16];
assign addr_fifo_wr = cmd_s_tvalid && cmd_s_tready;
assign cmd_s_tready = !addr_fifo_full;

assign dbg_ram_available = ram_available;

// FIXME: replace with fifo_sync
fifo_async #(.DSIZE(16),.ASIZE(4),.MODE("FWFT")) addr_fifo_i(
	.wr_rst(!aresetn),
	.wr_clk(aclk),
	.din(addr_fifo_din),
	.wr_en(addr_fifo_wr),
	.full(addr_fifo_full),
	.rd_rst(!aresetn),
	.rd_clk(aclk),
	.dout(addr_fifo_dout),
	.rd_en(addr_fifo_rd),
	.empty(addr_fifo_empty)
);

axi_wdma #(
	.ADDRESS_BITS(16), 
	.LENGTH_BITS(16),
	.STREAM_BIG_ENDIAN("TRUE"),
	.MEM_BIG_ENDIAN("FALSE")
) wdma_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.cmd_address(cmd_address),
	.cmd_bytes(cmd_bytes),
	.cmd_valid(cmd_valid),
	.cmd_ready(cmd_ready),

	.axi_m_awid(dram_m_awid),
	.axi_m_awaddr(dram_m_awaddr),
	.axi_m_awlen(dram_m_awlen),
	.axi_m_awsize(dram_m_awsize),
	.axi_m_awburst(dram_m_awburst),
	.axi_m_awvalid(dram_m_awvalid),
	.axi_m_awready(dram_m_awready),

	.axi_m_wid(dram_m_wid),
	.axi_m_wdata(dram_m_wdata),
	.axi_m_wlast(dram_m_wlast),
	.axi_m_wvalid(dram_m_wvalid),
	.axi_m_wstrb(dram_m_wstrb),
	.axi_m_wready(dram_m_wready),

	.axi_m_bid(dram_m_bid),
	.axi_m_bresp(dram_m_bresp),
	.axi_m_bvalid(dram_m_bvalid),
	.axi_m_bready(dram_m_bready),

	.din_tdata(mac_s_tdata),
	.din_tkeep(mac_s_tkeep),
	.din_tlast(mac_s_tlast),
	.din_tvalid(mac_s_tvalid),
	.din_tready(mac_s_tready)
);

rx_checksum csum_i(
	.clk(aclk),
	.rst(!aresetn),
	.PCSS(PCSS),
	.data(mac_s_tdata),
	.keep(mac_s_tkeep),
	.last(mac_s_tlast),
	.valid((mac_s_tvalid && mac_s_tready)),
	.csum(checksum),
	.csum_valid(csum_valid)
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
			if(mac_s_tvalid && mac_s_tuser <= ram_available) 
				state_next = S_CMD_C0;
			else if(!addr_fifo_empty)
				state_next = S_COLLECT;
			else
				state_next = S_IDLE;
		end
		S_CMD_C0: begin
			if(cmd_ready)
				state_next = S_WAIT;
			else
				state_next = S_CMD_C0;
		end
		S_WAIT: begin
			if(cmd_ready)
				state_next = S_RPT_STB;
			else
				state_next = S_WAIT;
		end
		S_RPT_STB,S_RPT_C0: begin
			if(stat_m_tready)
				state_next = S_RPT_C1;
			else
				state_next = S_RPT_C0;
		end
		S_RPT_C1: begin
			if(stat_m_tready)
				state_next = S_RPT_C2;
			else
				state_next = S_RPT_C1;
		end
		S_RPT_C2: begin
			if(stat_m_tready)
				state_next = S_IDLE;
			else
				state_next = S_RPT_C2;
		end
		S_COLLECT: begin
			state_next = S_IDLE;
		end
		default: begin
			state_next = 'bx;
		end
	endcase
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		stat_m_tdata <= 'bx;
		stat_m_tvalid <= 1'b0;
		stat_m_tlast <= 1'bx;
		cmd_valid <= 1'b0;
		cmd_address <= 'bx;
		cmd_bytes <= 'bx;
		ram_address <= 'b0;
		ram_available <= DATA_RAM_DWORDS*4;
		addr_fifo_rd <= 1'b0;
	end
	else case(state_next)
		S_IDLE: begin
			stat_m_tvalid <= 1'b0;
			stat_m_tlast <= 1'b0;
			cmd_valid <= 1'b0;
			addr_fifo_rd <= 1'b0;
		end
		S_CMD_C0: begin
			cmd_address <= ram_address;
			cmd_bytes <= mac_s_tuser;
			cmd_valid <= 1'b1;
		end
		S_WAIT: begin
			cmd_valid <= 1'b0;
		end
		S_RPT_STB: begin
			stat_m_tdata <= {cmd_bytes, cmd_address}; 
			stat_m_tvalid <= 1'b1;
			stat_m_tlast <= 1'b0;
			ram_address <= ram_address+cmd_bytes;
			ram_available <= ram_available-cmd_bytes;
		end
		S_RPT_C0: begin
		end
		S_RPT_C1: begin
			stat_m_tdata[31:16] <= checksum; 
			stat_m_tdata[15:0] <= cmd_bytes;
		end
		S_RPT_C2: begin
			stat_m_tdata <= 32'h00000004; // IXSM=1
			stat_m_tlast <= 1'b1;
		end
		S_COLLECT: begin
			ram_available <= ram_available+addr_fifo_dout;
			addr_fifo_rd <= 1'b1;
		end
	endcase
end

endmodule
