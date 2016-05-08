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

parameter INPUT_BIG_ENDIAN="TRUE";
parameter OUTPUT_BIG_ENDIAN="TRUE";

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
reg [3:0] sum;
reg last_r;
reg [3:0] out_be;

reg signed [3:0] sel_base;
reg [1:0] b0_sel_a;
reg [1:0] b0_sel_d;
reg [1:0] b1_sel_a;
reg [1:0] b1_sel_d;
reg [1:0] b2_sel_a;
reg [1:0] b2_sel_d;
reg [1:0] b3_sel_a;
reg [1:0] b3_sel_d;
reg [1:0] b4_sel_a;
reg [1:0] b5_sel_a;
reg [1:0] b6_sel_a;

wire [7:0] in_b0;
wire [7:0] in_b1;
wire [7:0] in_b2;
wire [7:0] in_b3;
wire [3:0] in_be;

generate
if(INPUT_BIG_ENDIAN=="TRUE") begin
	assign {in_b0,in_b1,in_b2,in_b3} = s_tdata;
	assign in_be = s_tkeep;
end
else begin
	assign {in_b3,in_b2,in_b1,in_b0} = s_tdata;
	assign {in_be[0],in_be[1],in_be[2],in_be[3]} = s_tkeep;
end
endgenerate

generate
if(OUTPUT_BIG_ENDIAN=="TRUE") begin
	assign m_tdata = {out_b0, out_b1, out_b2, out_b3};
	assign m_tkeep = out_be;
end
else begin
	assign m_tdata = {out_b3, out_b2, out_b1, out_b0};
	assign m_tkeep = {out_be[0],out_be[1],out_be[2],out_be[3]};
end
endgenerate

assign s_tready = last_r?1'b0:m_tready;

always @(*)
begin
	if(s_tvalid && s_tready)
		casex(in_be)
			4'b1xxx: s = 0;
			4'b01xx: s = 1;
			4'b001x: s = 2;
			4'b0001: s = 3;
			default: s = 0; // invalid
		endcase
	else
		s = 0;
end

always @(*)
begin
	if(s_tvalid && s_tready)
		case(in_be)
			4'b1000,4'b0100,4'b0010,4'b0001: l = 1;
			4'b1100,4'b0110,4'b0011: l = 2;
			4'b1110,4'b0111: l = 3;
			4'b1111: l = 4;
			default: l = 0; // invalid
		endcase
	else
		l = 0;
end

always @(*)
begin
	sum = b+l;
end

always @(*)
begin
	if(s_tvalid && s_tready)
		if(m_tvalid && m_tready)
			if(sum>4)
				b_next = sum-4;
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
	else if(s_tvalid && s_tlast && s_tready && b_next>4)
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
	else if(s_tvalid && s_tlast && s_tready && b_next<=4)
		m_tlast <= 1;
	else if(last_r)
		m_tlast <= 1;
	else
		m_tlast <= 0;
end

always @(*)
begin
	sel_base = s-b;

	b0_sel_a = sel_base+4;
	b0_sel_d = sel_base;

	b1_sel_a = b0_sel_a+1;
	b1_sel_d = b0_sel_d+1;

	b2_sel_a = b1_sel_a+1;
	b2_sel_d = b1_sel_d+1;

	b3_sel_a = b2_sel_a+1;
	b3_sel_d = b2_sel_d+1;

	b4_sel_a = b3_sel_a+1;

	b5_sel_a = b4_sel_a+1;

	b6_sel_a = b5_sel_a+1;
end

always @(*)
begin
	if(m_tvalid && m_tready) // output valid
		if(b>4) // load buffered bytes
			out_b0_next = out_b4;
		else // load input bytes
			case(b0_sel_a) /* synthesis full_case */
				0:out_b0_next = in_b0;
				1:out_b0_next = in_b1;
				2:out_b0_next = in_b2;
				3:out_b0_next = in_b3;
			endcase
	else if(b<1 && s_tvalid && s_tready) // load input bytes
		case(b0_sel_d) /* synthesis full_case */
			0: out_b0_next = in_b0;
			1: out_b0_next = in_b1;
			2: out_b0_next = in_b2;
			3: out_b0_next = in_b3;
		endcase
	else // keep
		out_b0_next = out_b0;
end

always @(*)
begin
	if(m_tvalid && m_tready)
		if(b>5)
			out_b1_next = out_b5;
		else
			case(b1_sel_a)/* synthesis full_case */
				0:out_b1_next = in_b0;
				1:out_b1_next = in_b1;
				2:out_b1_next = in_b2;
				3:out_b1_next = in_b3;
			endcase
	else if(b<2 && s_tvalid && s_tready)
		case(b1_sel_d)/* synthesis full_case */
			0: out_b1_next = in_b0;
			1: out_b1_next = in_b1;
			2: out_b1_next = in_b2;
			3: out_b1_next = in_b3;
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
			case(b2_sel_a)/* synthesis full_case */
				0:out_b2_next = in_b0;
				1:out_b2_next = in_b1;
				2:out_b2_next = in_b2;
				3:out_b2_next = in_b3;
			endcase
	else if(b<3 && s_tvalid && s_tready)
		case(b2_sel_d)/* synthesis full_case */
			0: out_b2_next = in_b0;
			1: out_b2_next = in_b1;
			2: out_b2_next = in_b2;
			3: out_b2_next = in_b3;
		endcase
	else
		out_b2_next = out_b2;
end

always @(*)
begin
	if(m_tvalid && m_tready)
		case(b3_sel_a)/* synthesis full_case */
			0:out_b3_next = in_b0;
			1:out_b3_next = in_b1;
			2:out_b3_next = in_b2;
			3:out_b3_next = in_b3;
		endcase
	else if(b<4 && s_tvalid && s_tready)
		case(b3_sel_d)/* synthesis full_case */
			0: out_b3_next = in_b0;
			1: out_b3_next = in_b1;
			2: out_b3_next = in_b2;
			3: out_b3_next = in_b3;
		endcase
	else
		out_b3_next = out_b3;
end

always @(*)
begin
	if(s_tvalid && s_tready)
		case(b4_sel_a)/* synthesis full_case */
			0:out_b4_next = /*in_b0*/'bx; // invalid
			1:out_b4_next = in_b1;
			2:out_b4_next = in_b2;
			3:out_b4_next = in_b3;
		endcase
	else
		out_b4_next = out_b4;
end

always @(*)
begin
	if(s_tvalid && s_tready)
		case(b5_sel_a)/* synthesis full_case */
			0:out_b5_next = /*in_b0*/'bx; // invalid
			1:out_b5_next = /*in_b1*/'bx; // invalid
			2:out_b5_next = in_b2;
			3:out_b5_next = in_b3;
		endcase
	else
		out_b5_next = out_b5;
end

always @(*)
begin
	if(s_tvalid && s_tready)
		case(b6_sel_a)/* synthesis full_case */
			0:out_b6_next = /*in_b0*/'bx; // invalid
			1:out_b6_next = /*in_b1*/'bx; // invalid
			2:out_b6_next = /*in_b2*/'bx; // invalid
			3:out_b6_next = in_b3;
		endcase
	else
		out_b6_next = out_b6;
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
