module test_axis_realign;

reg aclk;
reg aresetn;

reg [31:0] s_tdata;
reg [3:0] s_tkeep;
reg s_tlast;
reg s_tvalid;
reg [1:0] s_tuser;
wire s_tready;

wire [31:0] m_tdata;
wire [3:0] m_tkeep;
wire m_tlast;
wire m_tvalid;
reg m_tready;

axis_realign #(.INPUT_BIG_ENDIAN("TRUE"),.OUTPUT_BIG_ENDIAN("FALSE")) dut(
	.aclk(aclk),
	.aresetn(aresetn),
	.s_tdata(s_tdata),
	.s_tkeep(s_tkeep),
	.s_tlast(s_tlast),
	.s_tvalid(s_tvalid),
	.s_tuser(s_tuser),
	.s_tready(s_tready),
	.m_tdata(m_tdata),
	.m_tkeep(m_tkeep),
	.m_tlast(m_tlast),
	.m_tvalid(m_tvalid),
	.m_tready(m_tready)
);

initial
begin
	aclk = 0;
	forever #10 aclk = ~aclk;
end

initial
begin
	$dumpfile("test_axis_realign.vcd");
	$dumpvars(0);
	aresetn = 0;
	@(posedge aclk) aresetn <= 1;
	#1000000;
	$finish();
end

task strobe(input [31:0] data, input [3:0] be, input last);
	begin
		s_tdata <= data;
		s_tkeep <= be;
		s_tlast <= last;
		s_tvalid <= 1'b1;
		@(posedge aclk);
		while(!s_tready) @(posedge aclk);
	end
endtask

task finish();
	begin
		s_tvalid <= 1'b0;
		s_tlast <= 1'b0;
		@(posedge aclk);
	end
endtask

task set_offset(input [1:0] value);
	begin
		s_tuser <= value;
	end
endtask

initial
begin
	s_tdata = 0;
	s_tkeep = 0;
	s_tlast = 0;
	s_tvalid = 0;
	m_tready = 0;

	repeat(10) @(posedge aclk);
	m_tready <= 1;

	set_offset(0);

	strobe(32'h00112233, 4'b1000, 1);
	finish();

	strobe(32'h00112233, 4'b1100, 1);
	finish();

	strobe(32'h00112233, 4'b1110, 1);
	finish();

	strobe(32'h00112233, 4'b1111, 1);
	finish();

	strobe(32'h00112233, 4'b0100, 1);
	finish();

	strobe(32'h00112233, 4'b0010, 1);
	finish();

	strobe(32'h00112233, 4'b0001, 1);
	finish();

	strobe(32'h00112233, 4'b1100, 1);
	finish();

	strobe(32'h00112233, 4'b0110, 1);
	finish();

	strobe(32'h00112233, 4'b0011, 1);
	finish();

	strobe(32'h00112233, 4'b1110, 1);
	finish();

	strobe(32'h00112233, 4'b0111, 1);
	finish();

	strobe(32'h00112233, 4'b1111, 1);
	finish();

	strobe(32'h00112233, 4'b1111, 0);
	strobe(32'h44556677, 4'b1000, 1);
	finish();

	strobe(32'h00112233, 4'b1111, 0);
	strobe(32'h44556677, 4'b1100, 1);
	finish();

	strobe(32'h00112233, 4'b1111, 0);
	strobe(32'h44556677, 4'b1110, 1);
	finish();

	strobe(32'h00112233, 4'b1111, 0);
	strobe(32'h44556677, 4'b1111, 1);
	finish();

	strobe(32'h00112233, 4'b0111, 0);
	strobe(32'h44556677, 4'b1111, 1);
	finish();

	strobe(32'h00112233, 4'b0011, 0);
	strobe(32'h44556677, 4'b1111, 1);
	finish();

	strobe(32'h00112233, 4'b0001, 0);
	strobe(32'h44556677, 4'b1111, 1);
	finish();

	strobe(32'h00XXXXXX, 4'b1000, 0);
	strobe(32'hXX11XXXX, 4'b0100, 0);
	strobe(32'hXXXX22XX, 4'b0010, 0);
	strobe(32'hXXXXXX33, 4'b0001, 0);
	strobe(32'h4455XXXX, 4'b1100, 0);
	strobe(32'hXXXX6677, 4'b0011, 0);
	strobe(32'h8899AAXX, 4'b1110, 0);
	strobe(32'hXXXXXXBB, 4'b0001, 0);
	strobe(32'hCCDDEEFF, 4'b1111, 1);
	finish();

	strobe(32'h00XXXXXX, 4'b1000, 0);
	strobe(32'hXX11XXXX, 4'b0100, 1);
	finish();

	strobe(32'h00XXXXXX, 4'b1000, 0);
	strobe(32'hXX11XXXX, 4'b0100, 0);
	strobe(32'hXXXX22XX, 4'b0010, 1);
	finish();

	strobe(32'h00XXXXXX, 4'b1000, 0);
	strobe(32'hXX11XXXX, 4'b0100, 0);
	strobe(32'hXXXX22XX, 4'b0010, 0);
	strobe(32'hXXXXXX33, 4'b0001, 1);
	finish();

	strobe(32'hXXXXXX33, 4'b0001, 0);
	strobe(32'hXXXX22XX, 4'b0010, 0);
	strobe(32'hXX11XXXX, 4'b0100, 0);
	strobe(32'h00XXXXXX, 4'b1000, 1);
	finish();

	strobe(32'h4455XXXX, 4'b1100, 0);
	strobe(32'hXX6677xx, 4'b0110, 0);
	strobe(32'hXXXX8899, 4'b0011, 1);
	finish();

	strobe(32'hXXXX4455, 4'b0011, 0);
	strobe(32'hXX6677xx, 4'b0110, 0);
	strobe(32'h8899XXXX, 4'b1100, 1);
	finish();

	// Test initial offset

	set_offset(0);
	strobe(32'h00112233, 4'b1111, 1);
	finish();

	set_offset(1);
	strobe(32'h00112233, 4'b1111, 1);
	finish();

	set_offset(2);
	strobe(32'h00112233, 4'b1111, 1);
	finish();

	set_offset(3);
	strobe(32'h00112233, 4'b1111, 1);
	finish();

	set_offset(1);
	strobe(32'h00112233, 4'b1000, 1);
	finish();

	set_offset(2);
	strobe(32'h00112233, 4'b1000, 1);
	finish();

	set_offset(3);
	strobe(32'h00112233, 4'b1000, 1);
	finish();

	set_offset(1);
	strobe(32'h00112233, 4'b1100, 1);
	finish();

	set_offset(2);
	strobe(32'h00112233, 4'b1100, 1);
	finish();

	set_offset(3);
	strobe(32'h00112233, 4'b1100, 1);
	finish();

	set_offset(1);
	strobe(32'h00112233, 4'b1110, 1);
	finish();

	set_offset(2);
	strobe(32'h00112233, 4'b1110, 1);
	finish();

	set_offset(3);
	strobe(32'h00112233, 4'b1110, 1);
	finish();

	set_offset(1);
	strobe(32'h00112233, 4'b0100, 1);
	finish();

	set_offset(2);
	strobe(32'h00112233, 4'b0100, 1);
	finish();

	set_offset(3);
	strobe(32'h00112233, 4'b0100, 1);
	finish();

	set_offset(1);
	strobe(32'h00112233, 4'b0010, 1);
	finish();

	set_offset(2);
	strobe(32'h00112233, 4'b0010, 1);
	finish();

	set_offset(3);
	strobe(32'h00112233, 4'b0010, 1);
	finish();

	set_offset(1);
	strobe(32'h00112233, 4'b0001, 1);
	finish();

	set_offset(2);
	strobe(32'h00112233, 4'b0001, 1);
	finish();

	set_offset(3);
	strobe(32'h00112233, 4'b0001, 1);
	finish();

	set_offset(1);
	strobe(32'h00112233, 4'b0110, 1);
	finish();

	set_offset(2);
	strobe(32'h00112233, 4'b0110, 1);
	finish();

	set_offset(3);
	strobe(32'h00112233, 4'b0110, 1);
	finish();

	set_offset(1);
	strobe(32'h00112233, 4'b0011, 1);
	finish();

	set_offset(2);
	strobe(32'h00112233, 4'b0011, 1);
	finish();

	set_offset(3);
	strobe(32'h00112233, 4'b0011, 1);
	finish();

	set_offset(1);
	strobe(32'h00112233, 4'b0111, 1);
	finish();

	set_offset(2);
	strobe(32'h00112233, 4'b0111, 1);
	finish();

	set_offset(3);
	strobe(32'h00112233, 4'b0111, 1);
	finish();

	set_offset(3);
	strobe(32'h00XXXXXX, 4'b1000, 0);
	strobe(32'hXX11XXXX, 4'b0100, 0);
	strobe(32'hXXXX22XX, 4'b0010, 0);
	strobe(32'hXXXXXX33, 4'b0001, 0);
	strobe(32'h4455XXXX, 4'b1100, 0);
	strobe(32'hXXXX6677, 4'b0011, 0);
	strobe(32'h8899AAXX, 4'b1110, 0);
	strobe(32'hXXXXXXBB, 4'b0001, 0);
	strobe(32'hCCDDEEFF, 4'b1111, 1);
	finish();

	#1000;
	$finish();
end


endmodule
