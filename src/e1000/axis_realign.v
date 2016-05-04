module axis_realign(
	input	aclk,
	input	aresetn,

	input	[31:0] s_tdata,
	input	[3:0] s_tkeep,
	input	s_tlast,
	input	s_tvalid,	
	output 	s_tready,

	output	[31:0] m_tdata,
	output	[3:0] m_tkeep,
	output reg m_tlast,
	output reg m_tvalid,
	input	m_tready
);

parameter BIG_ENDIAN="TRUE";

reg [7:0] out_b0;
reg [7:0] out_b1;
reg [7:0] out_b2;
reg [7:0] out_b3;
reg [7:0] out_b4;
reg [7:0] out_b5;
reg [7:0] out_b6;

reg [7:0] out_b0_next;
reg [7:0] out_b1_next;
reg [7:0] out_b2_next;
reg [7:0] out_b3_next;
reg [7:0] out_b4_next;
reg [7:0] out_b5_next;
reg [7:0] out_b6_next;

reg [1:0] s;
reg [2:0] b;
reg [2:0] l;
reg [2:0] b_next;
reg last_r;
reg [3:0] out_be;

wire [7:0] in_b0;
wire [7:0] in_b1;
wire [7:0] in_b2;
wire [7:0] in_b3;
wire [3:0] s_tkeep_i;

generate
if(BIG_ENDIAN=="TRUE") begin
	assign m_tdata = {out_b0, out_b1, out_b2, out_b3};
	assign m_tkeep = out_be;
	assign {in_b0,in_b1,in_b2,in_b3} = s_tdata;
	assign s_tkeep_i = s_tkeep;
end
else begin
	assign m_tdata = {out_b3, out_b2, out_b1, out_b0};
	assign m_tkeep = {out_be[0],out_be[1],out_be[2],out_be[3]};
	assign {in_b3,in_b2,in_b1,in_b0} = s_tdata;
	assign {s_tkeep_i[0],s_tkeep_i[1],s_tkeep_i[2],s_tkeep_i[3]} = s_tkeep;
end
endgenerate

assign s_tready = last_r?1'b0:m_tready;

always @(*)
begin
	if(s_tvalid && s_tready)
		casex(s_tkeep_i)
			4'b1xxx: s = 0;
			4'b01xx: s = 1;
			4'b001x: s = 2;
			4'b0001: s = 3;
			default: s = 'bx;
		endcase
	else
		s = 0;

	if(s_tvalid && s_tready)
		casex(s_tkeep_i)
			4'b1000,4'b0100,4'b0010,4'b0001: l = 1;
			4'b1100,4'b0110,4'b0011: l = 2;
			4'b1110,4'b0111: l = 3;
			4'b1111: l = 4;
			default: l = 'bx;
		endcase
	else
		l = 0;
end

always @(*)
begin
	if(s_tvalid && s_tready)
		if(m_tvalid && m_tready)
			if(b+l>4)
				b_next = b+l-4;
			else
				b_next = 0;
		else
			b_next = b+l;
	else if(m_tvalid && m_tready)
		if(b>4)
			b_next = b-4;
		else
			b_next = 0;
	else
		b_next = b;
end

always @(posedge aclk)
begin
	case(b_next)
		0: out_be <= 4'b0000;
		1: out_be <= 4'b1000;
		2: out_be <= 4'b1100;
		3: out_be <= 4'b1110;
		default: out_be <= 4'b1111;
	endcase
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn)
		last_r <= 1'b0;
	else if(s_tvalid && s_tlast && s_tready)
		last_r <= 1'b1;
	else if(m_tvalid && m_tlast && m_tready)
		last_r <= 1'b0;
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn)
		m_tvalid <= 1'b0;
	else if(b_next>=4)
		m_tvalid <= 1;
	else if(s_tvalid && s_tlast && s_tready)
		m_tvalid <= 1;
	else if(b_next>0 && last_r)
		m_tvalid <= 1;
	else
		m_tvalid <= 0;
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn)
		m_tlast <= 1'b0;
	else if(s_tvalid && s_tlast && s_tready)
		if(b_next<=4) 
			m_tlast <= 1;
		else
			m_tlast <= 0;
	else if(last_r)
		m_tlast <= 1;
	else
		m_tlast <= 0;
end

always @(*)
begin
	if(m_tvalid && m_tready)
		if(b>4)
			out_b0_next = out_b4;
		else
			case((s+4-b)&2'b11)
				0:out_b0_next = in_b0;
				1:out_b0_next = in_b1;
				2:out_b0_next = in_b2;
				3:out_b0_next = in_b3;
				default: out_b0_next = 'bx;
			endcase
	else if(b<1 && s_tvalid && s_tready)
		case((s-b)&2'b11)
			0: out_b0_next = in_b0;
			1: out_b0_next = in_b1;
			2: out_b0_next = in_b2;
			3: out_b0_next = in_b3;
			default: out_b0_next = 'bx;
		endcase
	else
		out_b0_next = out_b0;
end

always @(*)
begin
	if(m_tvalid && m_tready)
		if(b>5)
			out_b1_next = out_b5;
		else
			case((s+5-b)&2'b11)
				0:out_b1_next = in_b0;
				1:out_b1_next = in_b1;
				2:out_b1_next = in_b2;
				3:out_b1_next = in_b3;
				default: out_b1_next = 'bx;
			endcase
	else if(b<2 && s_tvalid && s_tready)
		case((s+1-b)&2'b11)
			0: out_b1_next = in_b0;
			1: out_b1_next = in_b1;
			2: out_b1_next = in_b2;
			3: out_b1_next = in_b3;
			default: out_b1_next = 'bx;
		endcase
	else
		out_b1_next = out_b1;
end

always @(*)
begin
	if(m_tvalid && m_tready)
		if(b>6)
			out_b2_next = out_b6;
		else
			case((s+6-b)&2'b11)
				0:out_b2_next = in_b0;
				1:out_b2_next = in_b1;
				2:out_b2_next = in_b2;
				3:out_b2_next = in_b3;
				default: out_b2_next = 'bx;
			endcase
	else if(b<3 && s_tvalid && s_tready)
		case((s+2-b)&2'b11)
			0: out_b2_next = in_b0;
			1: out_b2_next = in_b1;
			2: out_b2_next = in_b2;
			3: out_b2_next = in_b3;
			default: out_b2_next = 'bx;
		endcase
	else
		out_b2_next = out_b2;
end

always @(*)
begin
	if(m_tvalid && m_tready)
		case((s+7-b)&2'b11)
			0:out_b3_next = in_b0;
			1:out_b3_next = in_b1;
			2:out_b3_next = in_b2;
			3:out_b3_next = in_b3;
			default: out_b3_next = 'bx;
		endcase
	else if(b<4 && s_tvalid && s_tready)
		case((s+3-b)&2'b11)
			0: out_b3_next = in_b0;
			1: out_b3_next = in_b1;
			2: out_b3_next = in_b2;
			3: out_b3_next = in_b3;
			default: out_b3_next = 'bx;
		endcase
	else
		out_b3_next = out_b3;
end

always @(*)
begin
	if(s_tvalid && s_tready)
		case((s+8-b)&2'b11)
			//0:out_b4_next = in_b0;
			1:out_b4_next = in_b1;
			2:out_b4_next = in_b2;
			3:out_b4_next = in_b3;
			default: out_b4_next = 'bx;
		endcase
	else
		out_b4_next = 'bx;
end

always @(*)
begin
	if(s_tvalid && s_tready)
		case((s+9-b)&2'b11)
			//0:out_b5_next = in_b0;
			//1:out_b5_next = in_b1;
			2:out_b5_next = in_b2;
			3:out_b5_next = in_b3;
			default: out_b5_next = 'bx;
		endcase
	else
		out_b5_next = 'bx;
end

always @(*)
begin
	if(s_tvalid && s_tready)
		case((s+10-b)&2'b11)
			//0:out_b6_next = in_b0;
			//1:out_b6_next = in_b1;
			//2:out_b6_next = in_b2;
			3:out_b6_next = in_b3;
			default: out_b6_next = 'bx;
		endcase
	else
		out_b6_next = 'bx;
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		out_b0 <= 'bx;
		out_b1 <= 'bx;
		out_b2 <= 'bx;
		out_b3 <= 'bx;
		out_b4 <= 'bx;
		out_b5 <= 'bx;
		out_b6 <= 'bx;
		b <= 'b0;
	end
	else begin
		out_b0 <= out_b0_next;
		out_b1 <= out_b1_next;
		out_b2 <= out_b2_next;
		out_b3 <= out_b3_next;
		out_b4 <= out_b4_next;
		out_b5 <= out_b5_next;
		out_b6 <= out_b6_next;
		b <= b_next;
	end
end

endmodule
