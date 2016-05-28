module tx_engine(
	input aclk,
	input aresetn,

	output dbg_desc_dext,

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
	output reg [63:0] idma_src_addr,
	output reg [15:0] idma_dst_addr,
	output reg [15:0] idma_bytes,
	output reg idma_valid,
	input	idma_ready,

	// iDMA Response Port
	input [63:0] irpt_src_addr,
	input [15:0] irpt_dst_addr,
	input [15:0] irpt_bytes,
	input irpt_valid,
	output irpt_ready,

	// Frame Process Command Port
	// C1: [31:16]=Length, [15:0]=Local Address 
	// C2: [31:0]=DESC_DW2
	// C3: [31:0]=DESC_DW3
	output reg [31:0] frm_m_tdata,
	output reg frm_m_tvalid,
	output reg frm_m_tlast,
	input frm_m_tready,

	// Frame Process Response Port
	// [31:16]=Length, [15:0]=Local Address
	input [31:0] frm_s_tdata,
	input frm_s_tvalid,
	input frm_s_tlast,
	output reg frm_s_tready
);

parameter DATA_RAM_DWORDS=8192;

function integer clogb2 (input integer size);
begin
	size = size - 1;
	for (clogb2=1; size>1; clogb2=clogb2+1)
		size = size >> 1;
end
endfunction

localparam DRAM_ADDR_BITS = clogb2(DATA_RAM_DWORDS*4);

localparam DTYPE_DATA = 4'b0001;
localparam DTYPE_CONTEXT = 4'b0000;

reg [15:0] local_addr;
reg [1:0] fetch_cnt;

reg [31:0] desc_dw0;
reg [31:0] desc_dw1;
reg [31:0] desc_dw2;
reg [31:0] desc_dw3;

reg start_fetch_data;
reg busy_fetch_data;
reg [DRAM_ADDR_BITS-1:0] dram_head;
reg [DRAM_ADDR_BITS-1:0] dram_tail;
reg [DRAM_ADDR_BITS-1:0] dram_available;

// Legacy Descriptor Layout
wire [63:0] desc_buf_addr;
wire [3:0] desc_dtyp;
wire [15:0] desc_special;
wire [7:0] desc_css;
wire [7:0] desc_cso;
wire [15:0] desc_length;
wire desc_eop;
wire desc_ifcs;
wire desc_ic;
wire desc_rs;
wire desc_dext;
wire desc_vle;
wire desc_ide;
wire [7:0] desc_cmd;
wire [3:0] desc_sta;
wire [11:0] desc_vlan;
wire desc_cfi;
wire [2:0] desc_pri;

// Context Descriptor Layout
wire [7:0] desc_ipcss;
wire [7:0] desc_ipcso;
wire [15:0] desc_ipcse;
wire [7:0] desc_tucss;
wire [7:0] desc_tucso;
wire [15:0] desc_tucse;
wire [19:0] desc_paylen;
wire [7:0] desc_tucmd;
wire [7:0] desc_hdrlen;
wire [15:0] desc_mss;

// Data Descriptor Layout
wire [19:0] desc_dtalen;
wire [7:0] desc_dcmd;
wire [7:0] desc_ports;
wire desc_ixsm;
wire desc_txsm;

integer state, state_next;

localparam S_IDLE=0, S_FETCH_ASTB=1, S_FETCH_DLATCH=2, S_PROCESS=3,
	S_CHECK_RS=4, S_WRITE_STROBE=5, S_WRITE_ACK=6, S_REPORT=7;

integer s2, s2_next;
localparam S2_IDLE=0, S2_FETCH_CALC=1, S2_FETCH_C1=2,  S2_FETCH_ACK=6, 
	S2_CMD_C1=7, S2_CMD_C2=8, S2_CMD_C3=9, S2_INCR=10, S2_UNSUPPORT=11;

assign irpt_ready = 1'b1;

assign desc_buf_addr = {desc_dw1, desc_dw0};
assign desc_length = desc_dw2[15:0];
assign desc_cso = desc_dw2[23:16];
assign desc_dtyp = desc_dw2[23:20];

assign desc_cmd = desc_dw2[31:24];
assign desc_eop = desc_cmd[0];
assign desc_ifcs = desc_cmd[1];
assign desc_ic = desc_cmd[2];
assign desc_rs = desc_cmd[3];
assign desc_dext = desc_cmd[5];
assign desc_vle = desc_cmd[6];
assign desc_ide = desc_cmd[7];

assign desc_sta = desc_dw3[3:0];
assign desc_css = desc_dw3[15:8];

assign desc_special = desc_dw3[31:16];
assign desc_vlan = desc_special[11:0];
assign desc_cfi = desc_special[12];
assign desc_pri = desc_special[15:13];

assign desc_ipcss = desc_dw0[7:0];
assign desc_ipcso = desc_dw0[15:8];
assign desc_ipcse = desc_dw0[31:16];
assign desc_tucss = desc_dw1[7:0];
assign desc_tucso = desc_dw1[15:8];
assign desc_tucse = desc_dw1[31:16];
assign desc_paylen = desc_dw2[19:0];

assign desc_tucmd = desc_dw2[31:24];
assign desc_tcp = desc_tucmd[0];
assign desc_ip = desc_tucmd[1];
assign desc_tse = desc_tucmd[2];

assign desc_hdrlen = desc_dw3[15:8];
assign desc_mss = desc_dw3[31:16];

assign desc_dcmd = desc_dw2[31:24];
assign desc_ports = desc_dw3[15:8];
assign desc_ixsm = desc_ports[0];
assign desc_txsm = desc_ports[1];

assign dbg_te_desc_dext = desc_dext;

////////////////////////////////////////////////////////////////////////////////
// Stage 1 Descriptor fetching

always @(*) 
begin
	ram_m_awaddr = {local_addr[15:4],4'hC};
	ram_m_wdata = {desc_dw3[31:4],1'b0/*RSV*/,1'b0/*LC*/,1'b0/*EC*/,1'b1/*DD*/};
	ram_m_araddr = local_addr;
	stat_m_tdata[31:18] = 14'b0;
	stat_m_tdata[17] = desc_ide;
	stat_m_tdata[16] = desc_rs;
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
		case(fetch_cnt) /* synthesis full_case */
			2'b00: desc_dw0 <= ram_m_rdata;
			2'b01: desc_dw1 <= ram_m_rdata;
			2'b10: desc_dw2 <= ram_m_rdata;
			2'b11: desc_dw3 <= ram_m_rdata;
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
				state_next = S_CHECK_RS;
			else
				state_next = S_FETCH_DLATCH;
		end
		S_CHECK_RS: begin
			state_next = S_PROCESS;
		end
		S_PROCESS: begin
			if(busy_fetch_data)
				state_next = S_PROCESS;
			else if(desc_rs)
				state_next = S_WRITE_STROBE;
			else
				state_next = S_REPORT;
		end
		S_WRITE_STROBE: begin
			state_next = S_WRITE_ACK;
		end
		S_WRITE_ACK: begin
			if(!(ram_m_awvalid && !ram_m_awready)
			   	&& !(ram_m_wvalid && !ram_m_wready))
				state_next = S_REPORT;
			else
				state_next = S_WRITE_ACK;
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
		ram_m_arlen <= 3'd3;
		ram_m_arsize <= 3'b010;
		ram_m_arburst <= 2'b01;
		ram_m_arvalid <= 1'b0;
		ram_m_awid <= 'b0;
		ram_m_awlen <= 3'd0;
		ram_m_awsize <= 3'b010;
		ram_m_awburst <= 2'b01;
		ram_m_awvalid <= 1'b0;
		ram_m_wid <= 'b0;
		ram_m_wvalid <= 1'b0;
		ram_m_wstrb <= 4'b0001;
		ram_m_wlast <= 1'b1;
		stat_m_tlast <= 1'b1;
		ram_m_bready <= 1'b1;
		ram_m_rready <= 1'b1;
		start_fetch_data <= 1'b0;
	end
	else case(state_next)
		S_IDLE: begin
			stat_m_tvalid <= 1'b0;
			cmd_s_tready <= 1'b1;
		end
		S_FETCH_ASTB: begin
			cmd_s_tready <= 1'b0;
			ram_m_arvalid <= 1'b1;
		end
		S_FETCH_DLATCH: begin
			ram_m_arvalid <= 1'b0;
		end
		S_CHECK_RS: begin
			start_fetch_data <= 1'b1;
		end
		S_PROCESS: begin
			start_fetch_data <= 1'b0;
		end
		S_WRITE_STROBE: begin
			ram_m_awvalid <= 1'b1;
			ram_m_wvalid <= 1'b1;
		end
		S_WRITE_ACK: begin
			if(ram_m_awready)
				ram_m_awvalid <= 1'b0;
			if(ram_m_wready)
				ram_m_wvalid <= 1'b0;
		end
		S_REPORT: begin
			ram_m_awvalid <= 1'b0;
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
			if(start_fetch_data)
				if(!desc_dext || (desc_dext && desc_dtyp==DTYPE_DATA))
					s2_next = S2_FETCH_CALC;
				else // FIXME: add context descriptor support
					s2_next = S2_UNSUPPORT;
			else
				s2_next = S2_IDLE;
		end
		S2_FETCH_CALC: begin
			if(desc_length>0 && desc_buf_addr!=64'b0) // 0 is null pointer
				if(dram_available >= desc_length)
					s2_next = S2_FETCH_C1;
				else
					s2_next = S2_FETCH_CALC;
			else
				s2_next = S2_IDLE;
		end
		S2_FETCH_C1: begin
			if(idma_ready)
				s2_next = S2_FETCH_ACK;
			else
				s2_next = S2_FETCH_C1;
		end
		S2_FETCH_ACK: begin
			if(irpt_valid)
				s2_next = S2_CMD_C1;
			else
				s2_next = S2_FETCH_ACK;
		end
		S2_CMD_C1: begin
			if(frm_m_tready)
				s2_next = S2_CMD_C2;
			else
				s2_next = S2_CMD_C1;
		end
		S2_CMD_C2: begin
			if(frm_m_tready)
				s2_next = S2_CMD_C3;
			else
				s2_next = S2_CMD_C2;
		end
		S2_CMD_C3: begin
			if(frm_m_tready)
				s2_next = S2_INCR;
			else
				s2_next = S2_CMD_C3;
		end
		S2_INCR: begin
			s2_next = S2_IDLE;
		end
		S2_UNSUPPORT: begin // TODO: add other process 
			s2_next = S2_IDLE;
		end
		default: begin
			s2_next = 'bx;
		end
	endcase
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		busy_fetch_data <= 1'b0;
		idma_src_addr <= 'bx;
		idma_dst_addr <= 'bx;
		idma_bytes <= 'bx;
		idma_valid <= 1'b0;
		frm_m_tvalid <= 1'b0;
		frm_m_tlast <= 1'bx;
		frm_s_tready <= 1'b1;
		dram_tail <= 'b0;
	end
	else case(s2_next)
		S2_IDLE: begin
			busy_fetch_data <= 1'b0;
			frm_m_tvalid <= 1'b0;
		end
		S2_FETCH_CALC: begin
			busy_fetch_data <= 1'b1;
		end
		S2_FETCH_C1: begin
			idma_src_addr <= desc_buf_addr;
			idma_dst_addr <= dram_tail;
			idma_bytes <= desc_length;
			idma_valid <= 1'b1;
		end
		S2_FETCH_ACK: begin
			idma_valid <= 1'b0;
		end
		S2_CMD_C1: begin
			frm_m_tdata[15:0] <= dram_tail; 
			frm_m_tdata[31:16] <= desc_length;
			frm_m_tvalid <= 1'b1;
			frm_m_tlast <= 1'b0;
		end
		S2_CMD_C2: begin
			frm_m_tdata <= desc_dw2;
		end
		S2_CMD_C3: begin
			frm_m_tdata <= desc_dw3;
			frm_m_tlast <= 1'b1;
		end
		S2_INCR: begin
			frm_m_tvalid <= 1'b0;
			dram_tail <= dram_tail+desc_length;
		end
		S2_UNSUPPORT: begin
			busy_fetch_data <= 1'b1;
		end
	endcase
end

////////////////////////////////////////////////////////////////////////////////
// Stage 3 - Collect Data RAM space

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		dram_head <= 'b0;
	end
	else if(frm_s_tvalid && frm_s_tlast && frm_s_tready) begin
		dram_head <= frm_s_tdata[15:0] + frm_s_tdata[31:16];
	end
end

always @(posedge aclk)
begin
	dram_available <= dram_head-dram_tail-1;
end
endmodule
