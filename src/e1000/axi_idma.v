module axi_idma(
	input aclk,
	input aresetn,

	// Command Port
	// C1: [31]=IN(0)/OUT(1),[30:28]=RSV, [27:16]=Bytes, 
	//     [15:0]=Local Address
	// C2: Lower 32-bit address
	// C3: Upper 32-bit address
	input [31:0] cmd_s_tdata,
	input cmd_s_tvalid,
	input cmd_s_tlast,
	output reg cmd_s_tready,

	// Status Port
	// [31]=R(0)/W(1), [30:27]=Status, [27:16]=Bytes, [15:0]=Local
	// Address
	output reg [31:0] stat_m_tdata,
	output reg stat_m_tvalid,
	output reg stat_m_tlast,
	input stat_m_tready,

	output reg [3:0] int_m_awid,
	output [15:0] int_m_awaddr,

	output [7:0] int_m_awlen,
	output [2:0] int_m_awsize,
	output [1:0] int_m_awburst,
	output reg int_m_awvalid,
	input int_m_awready,

	output reg [3:0] int_m_wid,
	output reg [31:0] int_m_wdata,
	output reg [3:0] int_m_wstrb,
	output reg int_m_wlast,
	output reg int_m_wvalid,
	input int_m_wready,

	input [3:0] int_m_bid,
	input [1:0] int_m_bresp,
	input int_m_bvalid,
	output reg int_m_bready,

	output reg [3:0] int_m_arid,
	output [15:0] int_m_araddr,
	output [7:0] int_m_arlen,
	output [2:0] int_m_arsize,
	output [1:0] int_m_arburst,
	output reg int_m_arvalid,
	input int_m_arready,

	input [3:0] int_m_rid,
	input [31:0] int_m_rdata,
	input [1:0] int_m_rresp,
	input int_m_rlast,
	input int_m_rvalid,
	output reg int_m_rready,

	output reg [3:0] ext_m_awid,
	output [63:0] ext_m_awaddr,

	output [7:0] ext_m_awlen,
	output [2:0] ext_m_awsize,
	output [1:0] ext_m_awburst,
	output reg ext_m_awvalid,
	input ext_m_awready,

	output reg [3:0] ext_m_wid,
	output reg [31:0] ext_m_wdata,
	output reg [3:0] ext_m_wstrb,
	output reg ext_m_wlast,
	output reg ext_m_wvalid,
	input ext_m_wready,

	input [3:0] ext_m_bid,
	input [1:0] ext_m_bresp,
	input ext_m_bvalid,
	output reg ext_m_bready,

	output reg [3:0] ext_m_arid,
	output [63:0] ext_m_araddr,
	output [7:0] ext_m_arlen,
	output [2:0] ext_m_arsize,
	output [1:0] ext_m_arburst,
	output reg ext_m_arvalid,
	input ext_m_arready,

	input [3:0] ext_m_rid,
	input [31:0] ext_m_rdata,
	input [1:0] ext_m_rresp,
	input ext_m_rlast,
	input ext_m_rvalid,
	output reg ext_m_rready
);

reg cmd_direction;
reg [10:0] cmd_bytes;
reg [15:0] cmd_int_addr;
reg [63:0] cmd_ext_addr;
reg [2:0] cmd_shift;
reg [10:0] cmd_bytes_exp;
reg [10:0] cmd_bytes_in;
reg [10:0] cmd_bytes_out;
reg [3:0] first_wstrb;
reg [3:0] last_wstrb;
reg int_m_wfirst_n;
reg ext_m_wfirst_n;

wire [7:0] cmd_len_in;
wire [7:0] cmd_len_out;

integer state, state_next;

localparam S_IDLE=0, S_OUT_FETCH_ASTB=1, S_OUT_PUSH_ASTB=2, S_OUT_PUSH_DSTB=3,
	S_OUT_PUSH_RESP=4, S_IN_FETCH_ASTB=5, S_IN_PUSH_ASTB=6, S_IN_PUSH_DSTB=7,
	S_IN_PUSH_RESP=8, S_OUT_REPORT=9, S_IN_REPORT=10, S_REPORT=11;

assign cmd_len_in = cmd_bytes_in[9:2]-1;
assign cmd_len_out = cmd_bytes_out[9:2]-1;

assign int_m_awburst = 2'b01;
assign int_m_awsize = 3'b010;
assign int_m_awlen = cmd_len_in;
assign int_m_awaddr = {cmd_int_addr[15:2],2'b0};

assign int_m_arburst = 2'b01;
assign int_m_arsize = 3'b010;
assign int_m_arlen = cmd_len_out;
assign int_m_araddr = {cmd_int_addr[15:2],2'b0};

assign ext_m_awburst = 2'b01;
assign ext_m_awsize = 3'b010;
assign ext_m_awlen = cmd_len_out;
assign ext_m_awaddr = {cmd_ext_addr[63:2],2'b0};

assign ext_m_arburst = 2'b01;
assign ext_m_arsize = 3'b010;
assign ext_m_arlen = cmd_len_in;
assign ext_m_araddr = {cmd_ext_addr[63:2],2'b0};

always @(*)
begin
	case({cmd_int_addr[1:0],cmd_bytes[1:0]}) /* synthesis full_case */
		4'b0000: first_wstrb = 4'b1111;
		4'b0001: first_wstrb = 4'b0001;
		4'b0010: first_wstrb = 4'b0011;
		4'b0011: first_wstrb = 4'b0111;
		4'b0100: first_wstrb = 4'b1110;
		4'b0101: first_wstrb = 4'b0010;
		4'b0110: first_wstrb = 4'b0110;
		4'b0111: first_wstrb = 4'b1110;
		4'b1000: first_wstrb = 4'b1100;
		4'b1001: first_wstrb = 4'b0100;
		4'b1010: first_wstrb = 4'b1100;
		4'b1011: first_wstrb = 4'b1100;
		4'b1100: first_wstrb = 4'b1000;
		4'b1101: first_wstrb = 4'b1000;
		4'b1110: first_wstrb = 4'b1000;
		4'b1111: first_wstrb = 4'b1000;
	endcase
end

always @(*)
begin
	case({cmd_int_addr[1:0],cmd_bytes[1:0]}) /* synthesis full_case */
		4'b0000: last_wstrb = 4'b1111;
		4'b0001: last_wstrb = 4'b0001;
		4'b0010: last_wstrb = 4'b0011;
		4'b0011: last_wstrb = 4'b0111;
		4'b0100: last_wstrb = 4'b0001;
		4'b0101: last_wstrb = 4'b0011;
		4'b0110: last_wstrb = 4'b0111;
		4'b0111: last_wstrb = 4'b1111;
		4'b1000: last_wstrb = 4'b0011;
		4'b1001: last_wstrb = 4'b0111;
		4'b1010: last_wstrb = 4'b1111;
		4'b1011: last_wstrb = 4'b0001;
		4'b1100: last_wstrb = 4'b0111;
		4'b1101: last_wstrb = 4'b1111;
		4'b1110: last_wstrb = 4'b0001;
		4'b1111: last_wstrb = 4'b0011;
	endcase
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		cmd_shift <= 3'b001;
	end
	else if(cmd_s_tvalid && cmd_s_tready) begin
		if(cmd_s_tlast)
			cmd_shift <= 3'b001;
		else
			cmd_shift <= {cmd_shift,1'b0};
	end
end

always @(posedge aclk)
begin
	if(cmd_s_tvalid && cmd_s_tready) begin
		if(cmd_shift[0]) begin
			cmd_direction <= cmd_s_tdata[31];
			cmd_bytes <= cmd_s_tdata[27:16];
			cmd_int_addr <= cmd_s_tdata[15:0];
		end
		if(cmd_shift[1]) begin
			cmd_ext_addr[31:0] <= cmd_s_tdata;
			cmd_bytes_exp <= cmd_bytes+3;
		end
		if(cmd_shift[2]) begin
			cmd_ext_addr[63:32] <= cmd_s_tdata;
			cmd_bytes_in <= cmd_bytes_exp+cmd_ext_addr[1:0];
			cmd_bytes_out <= cmd_bytes_exp+cmd_int_addr[1:0];
		end
	end
end


always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		state <= S_IDLE;
	end
	else begin
		state <= state_next;
	end
end

always @(*)
begin
	case(state)
		S_IDLE: begin
			if(cmd_s_tvalid && cmd_s_tlast && cmd_s_tready) 
				if(cmd_direction) 
					state_next = S_OUT_FETCH_ASTB;
				else 
					state_next = S_IN_FETCH_ASTB;
			else
				state_next = S_IDLE;
		end
		S_OUT_FETCH_ASTB: begin
			if(int_m_arready)
				state_next = S_OUT_PUSH_ASTB;
			else
				state_next = S_OUT_FETCH_ASTB;
		end
		S_OUT_PUSH_ASTB: begin
			if(ext_m_awready)
				state_next = S_OUT_PUSH_DSTB;
			else
				state_next = S_OUT_PUSH_ASTB;
		end
		S_OUT_PUSH_DSTB: begin
			if(ext_m_wvalid && ext_m_wlast && ext_m_wready)
				state_next = S_OUT_PUSH_RESP;
			else
				state_next = S_OUT_PUSH_DSTB;
		end
		S_OUT_PUSH_RESP: begin
			if(ext_m_bvalid)
				state_next = S_OUT_REPORT;
			else
				state_next = S_OUT_PUSH_RESP;
		end
		S_IN_FETCH_ASTB: begin
			if(ext_m_arready)
				state_next = S_IN_PUSH_ASTB;
			else
				state_next = S_IN_FETCH_ASTB;
		end
		S_IN_PUSH_ASTB: begin
			if(int_m_awready)
				state_next = S_IN_PUSH_DSTB;
			else
				state_next = S_IN_PUSH_ASTB;
		end
		S_IN_PUSH_DSTB: begin
			if(int_m_wvalid && int_m_wlast && int_m_wready)
				state_next = S_IN_PUSH_RESP;
			else
				state_next = S_IN_PUSH_DSTB;
		end
		S_IN_PUSH_RESP: begin
			if(int_m_bvalid)
				state_next = S_IN_REPORT;
			else
				state_next = S_IN_PUSH_RESP;
		end
		S_OUT_REPORT, S_IN_REPORT, S_REPORT: begin
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
		cmd_s_tready <= 1'b0;

		stat_m_tlast <= 1'b1;
		stat_m_tvalid <= 1'b0;
		stat_m_tdata <= 'bx;

		int_m_arid <= 'b0;
		int_m_arvalid <= 1'b0;
		int_m_awid <= 'b0;
		int_m_awvalid <= 1'b0;
		int_m_bready <= 1'b0;

		ext_m_arid <= 'b0;
		ext_m_arvalid <= 1'b0;
		ext_m_awid <= 'b0;
		ext_m_awvalid <= 1'b0;
		ext_m_bready <= 1'b0;
	end
	else case(state_next)
		S_IDLE: begin
			cmd_s_tready <= 1'b1;
			stat_m_tvalid <= 1'b0;
		end
		S_OUT_FETCH_ASTB: begin
			cmd_s_tready <= 1'b0;
			int_m_arvalid <= 1'b1;
		end
		S_OUT_PUSH_ASTB: begin
			int_m_arvalid <= 1'b0;
			ext_m_awvalid <= 1'b1;
		end
		S_OUT_PUSH_DSTB: begin
			ext_m_awvalid <= 1'b0;
		end
		S_OUT_PUSH_RESP: begin
			ext_m_bready <= 1'b1;
		end
		S_OUT_REPORT: begin
			ext_m_bready <= 1'b0;
			stat_m_tdata[15:0] <= cmd_int_addr; 
			stat_m_tdata[27:16] <= {1'b0, cmd_bytes};
			stat_m_tdata[30:28] <= {1'b0, ext_m_bresp};
			stat_m_tdata[31] <= cmd_direction;
			stat_m_tvalid <= 1'b1;
		end
		S_IN_FETCH_ASTB: begin
			cmd_s_tready <= 1'b0;
			ext_m_arvalid <= 1'b1;
		end
		S_IN_PUSH_ASTB: begin
			ext_m_arvalid <= 1'b0;
			int_m_awvalid <= 1'b1;
		end
		S_IN_PUSH_DSTB: begin
			int_m_awvalid <= 1'b0;
		end
		S_IN_PUSH_RESP: begin
			int_m_bready <= 1'b1;
		end
		S_IN_REPORT: begin
			int_m_bready <= 1'b0;
			stat_m_tdata[15:0] <= cmd_int_addr; 
			stat_m_tdata[27:16] <= {1'b0, cmd_bytes};
			stat_m_tdata[30:28] <= {1'b0, int_m_bresp};
			stat_m_tdata[31] <= cmd_direction;
			stat_m_tvalid <= 1'b1;
		end
		S_REPORT: begin
		end
	endcase
end

always @(*)
begin
	int_m_wid = ext_m_rid;
	int_m_wdata = ext_m_rdata;
	int_m_wlast = ext_m_rlast;
end

always @(*)
begin
	if(state==S_IN_PUSH_DSTB) begin
		int_m_wvalid = ext_m_rvalid;
		ext_m_rready = int_m_wready;
	end
	else begin
		int_m_wvalid = 1'b0;
		ext_m_rready = 1'b0;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		int_m_wfirst_n <= 1'b0;
	end
	else if(int_m_wvalid && int_m_wready) begin
		if(int_m_wlast)
			int_m_wfirst_n <= 1'b0;
		else
			int_m_wfirst_n <= 1'b1;
	end
end
always @(*)
begin
	if(int_m_wfirst_n)
		if(int_m_wlast)
			int_m_wstrb = last_wstrb;
		else
			int_m_wstrb = 4'b1111;
	else
		int_m_wstrb = first_wstrb;
end

always @(*)
begin
	ext_m_wid = int_m_rid;
	ext_m_wdata = int_m_rdata;
	ext_m_wlast = int_m_rlast;
end

always @(*)
begin
	if(state==S_OUT_PUSH_DSTB) begin
		ext_m_wvalid = int_m_rvalid;
		int_m_rready = ext_m_wready;
	end
	else begin
		ext_m_wvalid = 1'b0;
		int_m_rready = 1'b0;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		ext_m_wfirst_n <= 1'b0;
	end
	else if(ext_m_wvalid && ext_m_wready) begin
		if(ext_m_wlast)
			ext_m_wfirst_n <= 1'b0;
		else
			ext_m_wfirst_n <= 1'b1;
	end
end
always @(*)
begin
	if(ext_m_wfirst_n)
		if(ext_m_wlast)
			ext_m_wstrb = last_wstrb;
		else
			ext_m_wstrb = 4'b1111;
	else
		ext_m_wstrb = first_wstrb;
end
endmodule
