module axis_align(
	input	aclk,
	input	aresetn,

	input	[31:0] s_tdata,
	input	[3:0] s_tkeep,
	input	s_tlast,
	input	s_tvalid,	
	output 	s_tready,

	output	[31:0] m_tdata,
	output	[3:0] m_tkeep,
	output	m_tlast,
	output	m_tvalid,
	input	m_tready
);

wire [31:0] s_tdata_i;
wire [3:0] s_tkeep_i;
wire [31:0] m_tdata_o;
wire [3:0] m_tkeep_o;

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

assign m_tdata_o = {out_b0, out_b1, out_b2, out_b3};
assign m_tkeep_o = out_tkeep;

assign s_tready = m_tready;

always @(*)
begin
	casex({out_be, back_be, in_be})
		{7'b0xxxxxx, 4'b1000},
		{7'b0xxxxxx, 4'b0100},
		{7'b0xxxxxx, 4'b0010},
		{7'b0xxxxxx, 4'b0001},
		{7'b11110xx, 4'b1000},
		{7'b11110xx, 4'b0100},
		{7'b11110xx, 4'b0010},
		{7'b11110xx, 4'b0001}:
		begin
			out_be_next = 4'b1000;
			back_be_next = 3'b000;
		end
		{7'b0xxxxxx, 4'b1100}, 
		{7'b0xxxxxx, 4'b0110}, 
		{7'b0xxxxxx, 4'b0011}, 
		{7'b10xxxxx, 4'b1000},
		{7'b10xxxxx, 4'b0100},
		{7'b10xxxxx, 4'b0010},
		{7'b10xxxxx, 4'b0001},
		{7'b11110xx, 4'b1100},
		{7'b11110xx, 4'b0110},
		{7'b11110xx, 4'b0011},
		{7'b111110x, 4'b1000},
		{7'b111110x, 4'b0100},
		{7'b111110x, 4'b0010},
		{7'b111110x, 4'b0001}:
		begin
			out_be_next = 4'b1100;
			back_be_next = 3'b000;
		end
		{7'b0xxxxxx, 4'b1110}, 
		{7'b0xxxxxx, 4'b0111}, 
		{7'b10xxxxx, 4'b1100},
		{7'b10xxxxx, 4'b0110},
		{7'b10xxxxx, 4'b0011},
		{7'b110xxxx, 4'b1000},
		{7'b110xxxx, 4'b0100},
		{7'b110xxxx, 4'b0010},
		{7'b110xxxx, 4'b0001},
		{7'b11110xx, 4'b1110},
		{7'b11110xx, 4'b0111},
		{7'b111110x, 4'b1100},
		{7'b111110x, 4'b0110},
		{7'b111110x, 4'b0011},
		{7'b1111110, 4'b1000},
		{7'b1111110, 4'b0100},
		{7'b1111110, 4'b0010},
		{7'b1111110, 4'b0001}:
		begin 
			out_be_next = 4'b1110;
			back_be_next = 3'b000;
		end
		{7'b0xxxxxx, 4'b1111}, 
		{7'b10xxxxx, 4'b1110},
		{7'b10xxxxx, 4'b0111},
		{7'b110xxxx, 4'b1100},
		{7'b110xxxx, 4'b0110},
		{7'b110xxxx, 4'b0011},
		{7'b1110xxx, 4'b1000},
		{7'b1110xxx, 4'b0100},
		{7'b1110xxx, 4'b0010},
		{7'b1110xxx, 4'b0001},
		{7'b11110xx, 4'b1111},
		{7'b111110x, 4'b1110},
		{7'b111110x, 4'b0111},
		{7'b1111110, 4'b1100},
		{7'b1111110, 4'b0110},
		{7'b1111110, 4'b0011},
		{7'b1111111, 4'b1000},
		{7'b1111111, 4'b0100},
		{7'b1111111, 4'b0010},
		{7'b1111111, 4'b0001}:
		begin
			out_be_next = 4'b1111;
			back_be_next = 3'b000;
		end
		{7'b10xxxxx, 4'b1111},
		{7'b110xxxx, 4'b1110},
		{7'b110xxxx, 4'b0111},
		{7'b1110xxx, 4'b1100},
		{7'b1110xxx, 4'b0110},
		{7'b1110xxx, 4'b0011},
		{7'b111110x, 4'b1111},
		{7'b1111110, 4'b1110},
		{7'b1111110, 4'b0111},
		{7'b1111111, 4'b1100},
		{7'b1111111, 4'b0110},
		{7'b1111111, 4'b0011}:
		begin
			out_be_next = 4'b1111;
			back_be_next = 3'b100;
		end
		{7'b110xxxx, 4'b1111},
		{7'b1110xxx, 4'b1110},
		{7'b1110xxx, 4'b0111},
		{7'b1111110, 4'b1111},
		{7'b1111111, 4'b1110},
		{7'b1111111, 4'b0111}:
		begin
			out_be_next = 4'b1111;
			back_be_next = 3'b110;
		end
		{7'b1110xxx, 4'b1111},
		{7'b1111111, 4'b1111}:
		begin
			out_be_next = 4'b1111;
			back_be_next = 3'b111;
		end
	endcase
end

always @(*)
begin
	casex({out_be, back_be, in_be})
		{7'b0xxxxxx, 4'b1xxx},
			out_b0_next = in_b0;
		{7'b0xxxxxx, 4'b01xx},
			out_b0_next = in_b1;
		{7'b0xxxxxx, 4'b001x},
			out_b0_next = in_b2;
		{7'b0xxxxxx, 4'b000x},
			out_b0_next = in_b3;
		{7'b11111xx, 4'bxxxx},
			out_b0_next = out_b4;
	endcase
end

always @(*)
begin
	casex({out_be, back_be, in_be})
		{7'b111110x, 4'b1xxx},
			out_b1_next = in_b0;
		{7'b0xxxxxx, 4'b11xx},
		{7'b11110xx, 4'b11xx},
			out_b1_next = in_b1;
		{7'b0xxxxxx, 4'b011x},
			out_b1_next = in_b2;
		{7'b0xxxxxx, 4'b0011},
			out_b1_next = in_b3;
		{7'b111111x, 4'bxxxx},
			out_b1_next = out_b5;
	endcase
end

always @(*)
begin
	casex({out_be, back_be, in_be})
		{7'b1111110, 4'b1xxx},
			out_b2_next = in_b0;
		{7'b111110x, 4'b11xx},
		{7'b1111110, 4'b01xx},
			out_b2_next = in_b1;
		{7'b0xxxxxx, 4'b111x},
		{7'b11110xx, 4'b111x},
			out_b2_next = in_b2;
		{7'b0xxxxxx, 4'b0011},
			out_b2_next = in_b3;
		{7'b111111x, 4'bxxxx},
			out_b2_next = out_b5;
	endcase
end

always @(posedge aclk, negedge aresetn)
begin
	if(s_tvalid && s_tready) begin
		out_b0 <= out_b0_next;
		out_b1 <= out_b1_next;
		out_b2 <= out_b2_next;
		out_b3 <= out_b3_next;
		out_b4 <= out_b4_next;
		out_b5 <= out_b5_next;
		out_b6 <= out_b6_next;
	end
end

endmodule
