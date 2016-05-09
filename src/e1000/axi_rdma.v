module axi_rdma #(
	parameter ADDRESS_BITS=32,
	parameter LENGTH_BITS=32
)
(
	input aclk,
	input aresetn,

	input [ADDRESS_BITS-1:0] cmd_address,
	input [LENGTH_BITS-1:0] cmd_bytes,
	input cmd_valid,
	output reg cmd_ready,

	output reg [3:0] axi_m_arid,
	output reg [ADDRESS_BITS-1:0] axi_m_araddr,
	output reg [7:0] axi_m_arlen,
	output reg [2:0] axi_m_arsize,
	output reg [1:0] axi_m_arburst,
	output reg axi_m_arvalid,
	input axi_m_arready,

	input [3:0] axi_m_rid,
	input [31:0] axi_m_rdata,
	input [1:0] axi_m_rresp,
	input axi_m_rlast,
	input axi_m_rvalid,
	output reg axi_m_rready,

	output reg [31:0] dout_tdata,
	output reg [3:0] dout_tkeep,
	output reg dout_tlast,
	output reg dout_tvalid,
	input dout_tready
);

reg [LENGTH_BITS-1:0] length;
reg [LENGTH_BITS-1:0] dout_dwords;
reg [LENGTH_BITS-1:0] length_dwords;
reg [LENGTH_BITS-1:0] remain_dwords;
reg [LENGTH_BITS-1:0] remain_dwords_init;
reg [LENGTH_BITS-1:0] fetch_dwords;
reg [LENGTH_BITS-1:0] fetch_dwords_next;
reg [3:0] first_wstrb;
reg [3:0] first_wstrb_set;
reg [3:0] last_wstrb;

integer state, state_next;
localparam S_IDLE=0, S_INIT=1, S_CALC=2, S_ASTRB=3, S_INCR=4, S_WAIT=5;

always @(*)
begin
	dout_tvalid = axi_m_rvalid;
	dout_tdata = axi_m_rdata;

	if(dout_dwords==0)
		dout_tkeep = first_wstrb|first_wstrb_set;
	else if(dout_dwords==length_dwords-1)
		dout_tkeep = last_wstrb;
	else
		dout_tkeep = 4'b1111;

	if(dout_dwords==length_dwords-1)
		dout_tlast = 1'b1;
	else
		dout_tlast = 1'b0;

	axi_m_arsize = 3'b010;
	axi_m_arburst = 2'b01;
	axi_m_rready = dout_tready;
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
			if(cmd_valid)
				state_next = S_INIT;
			else
				state_next = S_IDLE;
		end
		S_INIT: begin
			if(remain_dwords>0)
				state_next = S_CALC;
			else
				state_next = S_IDLE;
		end
		S_CALC: begin
			state_next = S_ASTRB;
		end
		S_ASTRB: begin
			if(axi_m_arready)
				state_next = S_INCR;
			else
				state_next = S_ASTRB;
		end
		S_INCR: begin
			if(remain_dwords>0)
				state_next = S_CALC;
			else
				state_next = S_WAIT;
		end
		S_WAIT: begin
			if(dout_tvalid && dout_tlast && dout_tready)
				state_next = S_IDLE;
			else
				state_next = S_WAIT;
		end
		default: begin
			state_next = 'bx;
		end
	endcase
end

always @(*)
begin
	if(cmd_bytes!=0)
		length = cmd_bytes+cmd_address[1:0];
	else
		length = 0;

	remain_dwords_init = length[ADDRESS_BITS-1:2]+(|length[1:0]);
end

always @(*)
begin
	if(remain_dwords > 256)
		fetch_dwords_next = 256;
	else
		fetch_dwords_next = remain_dwords;
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		length_dwords <= 'bx;
		remain_dwords <= 'bx;
		axi_m_araddr <= 'bx;
		first_wstrb <= 'bx;
		last_wstrb <= 'bx;
		first_wstrb_set <= 'bx;
		axi_m_arvalid <= 1'b0;
		axi_m_arlen <= 'bx;
		cmd_ready <= 1'b1;
	end
	else case(state_next)
		S_IDLE: begin
			cmd_ready <= 1'b1;
		end
		S_INIT: begin
			cmd_ready <= 1'b0;
			length_dwords <= remain_dwords_init;
			remain_dwords <= remain_dwords_init;
			axi_m_araddr <= {cmd_address[ADDRESS_BITS-1:2],2'b0};
			case({cmd_address[1:0],cmd_bytes[1:0]}) /* synthesis parallel_case */
				4'b0000: first_wstrb <= 4'b1111;
				4'b0001: first_wstrb <= 4'b0001;
				4'b0010: first_wstrb <= 4'b0011;
				4'b0011: first_wstrb <= 4'b0111;
				4'b0100: first_wstrb <= 4'b1110;
				4'b0101: first_wstrb <= 4'b0010;
				4'b0110: first_wstrb <= 4'b0110;
				4'b0111: first_wstrb <= 4'b1110;
				4'b1000: first_wstrb <= 4'b1100;
				4'b1001: first_wstrb <= 4'b0100;
				4'b1010: first_wstrb <= 4'b1100;
				4'b1011: first_wstrb <= 4'b1100;
				4'b1100: first_wstrb <= 4'b1000;
				4'b1101: first_wstrb <= 4'b1000;
				4'b1110: first_wstrb <= 4'b1000;
				4'b1111: first_wstrb <= 4'b1000;
			endcase
			case({cmd_address[1:0],cmd_bytes[1:0]}) /* synthesis parallel_case */
				4'b0000: last_wstrb <= 4'b1111;
				4'b0001: last_wstrb <= 4'b0001;
				4'b0010: last_wstrb <= 4'b0011;
				4'b0011: last_wstrb <= 4'b0111;
				4'b0100: last_wstrb <= 4'b0001;
				4'b0101: last_wstrb <= 4'b0011;
				4'b0110: last_wstrb <= 4'b0111;
				4'b0111: last_wstrb <= 4'b1111;
				4'b1000: last_wstrb <= 4'b0011;
				4'b1001: last_wstrb <= 4'b0111;
				4'b1010: last_wstrb <= 4'b1111;
				4'b1011: last_wstrb <= 4'b0001;
				4'b1100: last_wstrb <= 4'b0111;
				4'b1101: last_wstrb <= 4'b1111;
				4'b1110: last_wstrb <= 4'b0001;
				4'b1111: last_wstrb <= 4'b0011;
			endcase
			case(cmd_address[1:0])// synthesis full_case
				2'b00: first_wstrb_set <= 4'b1111;
				2'b01: first_wstrb_set <= 4'b1110;
				2'b10: first_wstrb_set <= 4'b1100;
				2'b11: first_wstrb_set <= 4'b1000;
			endcase
		end
		S_CALC: begin
			if(length_dwords==1)
				first_wstrb_set <= 4'b0;
			fetch_dwords <= fetch_dwords_next;
		end
		S_ASTRB: begin
			axi_m_arvalid <= 1'b1;
			axi_m_arlen <= fetch_dwords-1;
		end
		S_INCR: begin
			axi_m_arvalid <= 1'b0;
			axi_m_araddr[ADDRESS_BITS-1:2] <= axi_m_araddr[ADDRESS_BITS-1:2] + fetch_dwords;
			remain_dwords <= remain_dwords - fetch_dwords;
		end
		S_WAIT: begin
		end
	endcase
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		dout_dwords <= 'b0;
	end
	else if(state_next == S_INIT) begin
		dout_dwords <= 'b0;
	end
	else if(dout_tvalid && dout_tready) begin
		dout_dwords <= dout_dwords+1;
	end
end

endmodule
