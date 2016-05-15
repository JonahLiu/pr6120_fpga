module rx_engine(
	input aclk,
	input aresetn,

	input [1:0] BSIZE, // Receive Buffer Size
	input BSEX, // Buffer Size Extension

	// Command Port
	// [31:16]=RSV, [15:0]=Local Address
	input [31:0] cmd_s_tdata,
	input cmd_s_tvalid,
	input cmd_s_tlast,
	output reg cmd_s_tready,

	// Response Port
	// [31:16]=RSV, [15:0]=Local Address
	output reg [31:0] stat_m_tdata,
	output reg stat_m_tvalid,
	output reg stat_m_tlast,
	input stat_m_tready,

	output reg [3:0] ram_m_awid,
	output reg [15:0] ram_m_awaddr,

	output reg [7:0] ram_m_awlen,
	output reg [2:0] ram_m_awsize,
	output reg [1:0] ram_m_awburst,
	output reg ram_m_awvalid,
	input ram_m_awready,

	output reg [3:0] ram_m_wid,
	output reg [31:0] ram_m_wdata,
	output reg [3:0] ram_m_wstrb,
	output reg ram_m_wlast,
	output reg ram_m_wvalid,
	input ram_m_wready,

	input [3:0] ram_m_bid,
	input [1:0] ram_m_bresp,
	input ram_m_bvalid,
	output reg ram_m_bready,

	output reg [3:0] ram_m_arid,
	output reg [15:0] ram_m_araddr,
	output reg [7:0] ram_m_arlen,
	output reg [2:0] ram_m_arsize,
	output reg [1:0] ram_m_arburst,
	output reg ram_m_arvalid,
	input ram_m_arready,

	input [3:0] ram_m_rid,
	input [31:0] ram_m_rdata,
	input [1:0] ram_m_rresp,
	input ram_m_rlast,
	input ram_m_rvalid,
	output reg ram_m_rready,

	// iDMA Command Port
	output reg [15:0] dma_src_addr,
	output reg [63:0] dma_dst_addr,
	output reg [15:0] dma_bytes,
	output reg dma_valid,
	input	dma_ready,

	// iDMA Response Port
	input [15:0] rpt_src_addr,
	input [63:0] rpt_dst_addr,
	input [15:0] rpt_bytes,
	input rpt_valid,
	output rpt_ready,

	// Frame Process Command Port
	// C1: [31:16]=Length, [15:0]=Local Address (Free Buffer)
	output reg [31:0] frm_m_tdata,
	output reg frm_m_tvalid,
	output reg frm_m_tlast,
	input frm_m_tready,

	// Frame Process Response Port
	// [31:16]=Length, [15:0]=Local Address (Valid Buffer)
	// C2: [31:0]=DESC_DW2
	// C3: [31:0]=DESC_DW3
	input [31:0] frm_s_tdata,
	input frm_s_tvalid,
	input frm_s_tlast,
	output frm_s_tready
);

reg [15:0] local_addr;
reg [1:0] fetch_cnt;

reg [31:0] desc_dw0;
reg [31:0] desc_dw1;
reg [31:0] desc_dw2;
reg [31:0] desc_dw3;

reg host_buf_ready;
reg host_buf_filled;

reg [31:0] wback_dw2;
reg [31:0] wback_dw3;

reg [31:0] pkt_desc_dw2;
reg [31:0] pkt_desc_dw3;

reg [15:0] host_available;
reg [15:0] remain_bytes;
reg [15:0] fetch_bytes_s1;
reg [15:0] fetch_bytes_next;
reg [15:0] fetch_bytes;

reg [15:0] pkt_address;
reg [15:0] desc_length;

reg [11:0] fetch_dwords;
reg [11:0] fetch_dwords_next;
reg [63:0] host_address;
reg [15:0] local_start;

wire [31:0] pkt_fifo_din;
wire pkt_fifo_wr;
wire pkt_fifo_full;
wire [31:0] pkt_fifo_dout;
reg pkt_fifo_rd;
wire pkt_fifo_empty;

// Legacy Descriptor Layout
wire [63:0] host_buf_addr;

reg [15:0] host_buf_size;

integer state, state_next;

localparam S_IDLE=0, S_FETCH_ASTB=1, S_FETCH_DLATCH=2, S_PROCESS=3,
	S_CHECK_NULL=4, S_WRITE_ASTB=5, S_WRITE_DW2=6, S_WRITE_DW3=7, S_REPORT=8;

integer s2, s2_next;
localparam S2_IDLE=0, S2_GET_PKT_0=1, S2_GET_PKT_1=2, S2_GET_PKT_2=3, S2_GET_DESC=4, S2_WBAK_CALC=5, S2_WBAK_0=6, 
	S2_WBAK_INCR=7, S2_WBAK_ACK=8, S2_FREE=9;

assign rpt_ready = 1'b1;

assign host_buf_addr = {desc_dw1, desc_dw0};

assign pkt_fifo_wr = frm_s_tvalid & frm_s_tready;
assign frm_s_tready = !pkt_fifo_full;
assign pkt_fifo_din = frm_s_tdata;

// FIXME: replace with fifo_sync
fifo_async #(.DSIZE(32),.ASIZE(10),.MODE("FWFT")) pkt_fifo_i(
	.wr_rst(!aresetn),
	.wr_clk(aclk),
	.din(pkt_fifo_din),
	.wr_en(pkt_fifo_wr),
	.full(pkt_fifo_full),
	.rd_rst(!aresetn),
	.rd_clk(aclk),
	.dout(pkt_fifo_dout),
	.rd_en(pkt_fifo_rd),
	.empty(pkt_fifo_empty)
);

always @(*)
begin
	case({BSEX,BSIZE}) // synthesis full_case
		3'b000: host_buf_size = 2048;
		3'b001: host_buf_size = 1024;
		3'b010: host_buf_size = 512;
		3'b011: host_buf_size = 256;
		3'b100: host_buf_size = 32768; // illegal
		3'b101: host_buf_size = 16384;
		3'b110: host_buf_size = 8192;
		3'b111: host_buf_size = 4096;
	endcase
end

////////////////////////////////////////////////////////////////////////////////
// Stage 1 Descriptor fetching

always @(*) 
begin
	stat_m_tdata[31:16] = 16'b0;
	stat_m_tdata[15:0] = local_addr;
end

always @(posedge aclk)
begin
	if(cmd_s_tvalid && cmd_s_tready)
		local_addr <= cmd_s_tdata[15:0];
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn)
		fetch_cnt <= 0;
	else if(ram_m_rvalid && ram_m_rready)
		if(ram_m_rlast)
			fetch_cnt <= 0;
		else
			fetch_cnt <= fetch_cnt+1;
end

always @(posedge aclk)
begin
	if(ram_m_rvalid && ram_m_rready)
		case(fetch_cnt) 
			2'b00: desc_dw0 <= ram_m_rdata;
			2'b01: desc_dw1 <= ram_m_rdata;
			//2'b10: desc_dw2 <= ram_m_rdata;
			//2'b11: desc_dw3 <= ram_m_rdata;
		endcase
end

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
			if(cmd_s_tvalid && cmd_s_tlast)
				state_next = S_FETCH_ASTB;
			else
				state_next = S_IDLE;
		end
		S_FETCH_ASTB: begin
			if(ram_m_arready)
				state_next = S_FETCH_DLATCH;
			else
				state_next = S_FETCH_ASTB;
		end
		S_FETCH_DLATCH: begin
			if(ram_m_rvalid && ram_m_rlast)
				state_next = S_CHECK_NULL;
			else
				state_next = S_FETCH_DLATCH;
		end
		S_CHECK_NULL: begin
			if(host_buf_addr==0)
				state_next = S_WRITE_ASTB;
			else
				state_next = S_PROCESS;
		end
		S_PROCESS: begin
			if(host_buf_filled)
				state_next = S_WRITE_ASTB;
			else
				state_next = S_PROCESS;
		end
		S_WRITE_ASTB: begin
			if(ram_m_awready)
				state_next = S_WRITE_DW2;
			else
				state_next = S_WRITE_ASTB;
		end
		S_WRITE_DW2: begin
			if(ram_m_wready)
				state_next = S_WRITE_DW3;
			else
				state_next = S_WRITE_DW2;
		end
		S_WRITE_DW3: begin
			if(ram_m_wready)
				state_next = S_REPORT;
			else
				state_next = S_WRITE_DW3;
		end
		S_REPORT: begin
			if(stat_m_tready)
				state_next = S_IDLE;
			else
				state_next = S_REPORT;
		end
		default: begin
			state_next = 'bx;
		end
	endcase
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		ram_m_arid <= 'b0;
		ram_m_arlen <= 3'd1; // two DWords
		ram_m_arsize <= 3'b010;
		ram_m_arburst <= 2'b01;
		ram_m_arvalid <= 1'b0;
		ram_m_awid <= 'b0;
		ram_m_awlen <= 3'd1; // two DWords
		ram_m_awsize <= 3'b010;
		ram_m_awburst <= 2'b01;
		ram_m_awvalid <= 1'b0;
		ram_m_wid <= 'b0;
		ram_m_wvalid <= 1'b0;
		ram_m_wstrb <= 4'b1111;
		ram_m_wlast <= 1'b0;
		stat_m_tlast <= 1'b1;
		ram_m_bready <= 1'b1;
		ram_m_rready <= 1'b1;
		ram_m_awaddr <= 'bx;
		ram_m_wdata <= 'bx;
		host_buf_ready <= 1'b0;
	end
	else case(state_next)
		S_IDLE: begin
			stat_m_tvalid <= 1'b0;
			cmd_s_tready <= 1'b1;
		end
		S_FETCH_ASTB: begin
			cmd_s_tready <= 1'b0;
			ram_m_araddr = local_addr;
			ram_m_arvalid <= 1'b1;
		end
		S_FETCH_DLATCH: begin
			ram_m_arvalid <= 1'b0;
		end
		S_CHECK_NULL: begin
		end
		S_PROCESS: begin
			host_buf_ready <= 1'b1;
		end
		S_WRITE_ASTB: begin
			host_buf_ready <= 1'b0;
			ram_m_awvalid <= 1'b1;
			ram_m_awaddr <= {local_addr[15:4],4'h8};
			wback_dw2 <= pkt_desc_dw2;
			wback_dw3 <= pkt_desc_dw3;
		end
		S_WRITE_DW2: begin
			ram_m_wlast <= 1'b0;
			ram_m_wdata <= wback_dw2;
			ram_m_awvalid <= 1'b0;
			ram_m_wvalid <= 1'b1;
		end
		S_WRITE_DW3: begin
			ram_m_wlast <= 1'b1;
			ram_m_wdata <= wback_dw3;
			ram_m_awvalid <= 1'b0;
			ram_m_wvalid <= 1'b1;
		end
		S_REPORT: begin
			ram_m_wvalid <= 1'b0;
			stat_m_tvalid <= 1'b1;
		end
	endcase
end

////////////////////////////////////////////////////////////////////////////////
// Stage 2 - Data Packet Fetching

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn)
		s2 <= S2_IDLE;
	else
		s2 <= s2_next;
end

always @(*)
begin
	case(s2)
		S2_IDLE: begin
			if(!pkt_fifo_empty)
				s2_next = S2_GET_PKT_0;
			else
				s2_next = S2_IDLE;
		end
		S2_GET_PKT_0: begin
			if(!pkt_fifo_empty)
				s2_next = S2_GET_PKT_1;
			else
				s2_next = S2_GET_PKT_0;
		end
		S2_GET_PKT_1: begin
			if(!pkt_fifo_empty)
				s2_next = S2_GET_PKT_2;
			else
				s2_next = S2_GET_PKT_1;
		end
		S2_GET_PKT_2: begin
			if(!pkt_fifo_empty)
				s2_next = S2_GET_DESC;
			else
				s2_next = S2_GET_PKT_2;
		end
		S2_GET_DESC: begin
			if(host_buf_ready)
				s2_next = S2_WBAK_CALC;
			else
				s2_next = S2_GET_DESC;
		end
		S2_WBAK_CALC: begin
			s2_next = S2_WBAK_0;
		end
		S2_WBAK_0: begin
			if(dma_ready)
				s2_next = S2_WBAK_INCR;
			else
				s2_next = S2_WBAK_0;
		end
		S2_WBAK_INCR,S2_WBAK_ACK: begin
			if(rpt_valid)
				s2_next = S2_FREE;
			else
				s2_next = S2_WBAK_ACK;
		end
		S2_FREE: begin
			if(frm_m_tready)
				if(remain_bytes > 0)
					if(host_available > 0)
						s2_next = S2_WBAK_CALC;
					else
						s2_next = S2_GET_DESC;
				else
					s2_next = S2_IDLE;
			else
				s2_next = S2_FREE;
		end
		default: begin
			s2_next = 'bx;
		end
	endcase
end

always @(*)
begin
	if(remain_bytes > host_available)
		fetch_bytes_s1 = host_available;
	else
		fetch_bytes_s1 = remain_bytes;

	fetch_bytes_next = fetch_bytes_s1;
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		host_buf_filled <= 1'b0;
		dma_src_addr <= 'bx;
		dma_dst_addr <= 'bx;
		dma_bytes <= 'bx;
		dma_valid <= 1'b0;
		frm_m_tvalid <= 1'b0;
		frm_m_tlast <= 1'b1;
		pkt_address <= 'b0;
		pkt_fifo_rd <= 1'b0;
		remain_bytes <= 'bx;
		fetch_bytes <= 'bx;
		host_address <= 'bx;
		host_available <= 'bx;
		desc_length <= 'bx;
		pkt_desc_dw2 <= 'bx;
		pkt_desc_dw3 <= 'bx;
	end
	else case(s2_next)
		S2_IDLE: begin
			remain_bytes <= 'b0;
			frm_m_tvalid <= 1'b0;
			host_buf_filled <= 1'b0;
		end
		S2_GET_PKT_0: begin
			pkt_fifo_rd <= 1'b1;
		end
		S2_GET_PKT_1: begin
			if(!pkt_fifo_empty) begin
				pkt_address <= pkt_fifo_dout[15:0];
				remain_bytes <= pkt_fifo_dout[31:16];
			end
		end
		S2_GET_PKT_2: begin
			if(!pkt_fifo_empty) 
				pkt_desc_dw2 <= pkt_fifo_dout;
			desc_length <= 'b0;
		end
		S2_GET_DESC: begin
			host_buf_filled <= 1'b0;
			frm_m_tvalid <= 1'b0;
			if(pkt_fifo_rd)
				pkt_desc_dw3 <= pkt_fifo_dout;
			pkt_fifo_rd <= 1'b0;
			host_address <= host_buf_addr;
			host_available <= host_buf_size;
		end
		S2_WBAK_CALC: begin
			host_buf_filled <= 1'b0;
			frm_m_tvalid <= 1'b0;
			fetch_bytes <= fetch_bytes_next;
		end
		S2_WBAK_0: begin
			dma_src_addr <= pkt_address;
			dma_dst_addr <= host_address;
			dma_bytes <= fetch_bytes;
			dma_valid <= 1'b1;
		end
		S2_WBAK_INCR: begin
			dma_valid <= 1'b0;
			remain_bytes <= remain_bytes-fetch_bytes;
			pkt_address <= pkt_address+fetch_bytes;
			host_address <= host_address+fetch_bytes;
			host_available <= host_available-fetch_bytes;
			desc_length <= desc_length+fetch_bytes;
		end
		S2_WBAK_ACK: begin
		end
		S2_FREE: begin
			frm_m_tdata[15:0] <= pkt_address; 
			frm_m_tdata[31:16] <= fetch_bytes;
			frm_m_tvalid <= 1'b1;
			frm_m_tlast <= 1'b1;
			if(state!=S2_FREE) 
				host_buf_filled <= (remain_bytes == 0 || host_available==0);
			else 
				host_buf_filled <= 1'b0;
			pkt_desc_dw2[15:0] <= desc_length;
			pkt_desc_dw3[1] <= (remain_bytes==0);//EOP
			pkt_desc_dw3[0] <= 1'b1; //DD;
		end
	endcase
end
endmodule
