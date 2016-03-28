module test_eeprom;

reg aclk;
wire aresetn;
wire axi_s_awvalid;
wire axi_s_awready;
wire [31:0] axi_s_awaddr;
wire axi_s_wvalid;
wire axi_s_wready;
wire [31:0] axi_s_wdata;
wire [3:0] axi_s_wstrb;
wire axi_s_bvalid;
wire axi_s_bready;
wire [1:0] axi_s_bresp;
wire axi_s_arvalid;
wire axi_s_arready;
wire [31:0] axi_s_araddr;
wire axi_s_rvalid;
wire axi_s_rready;
wire [31:0] axi_s_rdata;
wire [1:0] axi_s_rresp;

wire eesk;
wire eecs;
wire eedi;
wire eedo;

wire [7:0] read_addr;
reg [15:0] read_data;
wire read_enable;

axi_lite_model master(
	.m_axi_aresetn(aresetn),
	.m_axi_aclk(aclk),
	.m_axi_awaddr(axi_s_awaddr),
	.m_axi_awvalid(axi_s_awvalid),
	.m_axi_awready(axi_s_awready),
	.m_axi_wdata(axi_s_wdata),
	.m_axi_wstrb(axi_s_wstrb),
	.m_axi_wvalid(axi_s_wvalid),
	.m_axi_wready(axi_s_wready),
	.m_axi_bready(axi_s_bready),
	.m_axi_bresp(axi_s_bresp),
	.m_axi_bvalid(axi_s_bvalid),
	.m_axi_araddr(axi_s_araddr),
	.m_axi_arvalid(axi_s_arvalid),
	.m_axi_arready(axi_s_arready),
	.m_axi_rready(axi_s_rready),
	.m_axi_rdata(axi_s_rdata),
	.m_axi_rresp(axi_s_rresp),
	.m_axi_rvalid(axi_s_rvalid)
);

eeprom_ctrl dut(
	.s_clk(aclk),
	.s_resetn(aresetn),
	.s_awvalid(axi_s_awvalid),
	.s_awready(axi_s_awready),
	.s_awaddr(axi_s_awaddr),
	.s_wvalid(axi_s_wvalid),
	.s_wready(axi_s_wready),
	.s_wdata(axi_s_wdata),
	.s_bvalid(axi_s_bvalid),
	.s_bready(axi_s_bready),
	.s_bresp(axi_s_bresp),
	.s_arvalid(axi_s_arvalid),
	.s_arready(axi_s_arready),
	.s_araddr(axi_s_araddr),
	.s_rvalid(axi_s_rvalid),
	.s_rready(axi_s_rready),
	.s_rdata(axi_s_rdata),
	.s_rresp(axi_s_rresp),
	.sk(eesk),
	.cs(eecs),
	.di(eedi),
	.do(eedo)
);

eeprom_emu stub(
	.clk_i(aclk),
	.rst_i(!aresetn),
	.sk_i(eesk),
	.cs_i(eecs),
	.di_i(eedi),
	.do_o(eedo),
	.do_oe_o(),
	.read_addr(read_addr),
	.read_enable(read_enable),
	.read_data(read_data)
);

always @(aclk)
begin
	if(read_enable)
		read_data <= {2{read_addr}};
end

initial
begin
	aclk = 1'b0;
	forever #10 aclk = !aclk;
end

initial
begin
	$dumpfile("test_eeprom.vcd");
	$dumpvars(0);
	#1000000;
	$finish;
end

initial
begin:T0
	reg [31:0] data;
	#100;
	master.reset();
	master.read(32'h10,data);
	master.write(32'h10,32'h0000_0060,4'hF);
	master.read(32'h10,data);
	while(!data[7]) begin
		master.read(32'h10,data);
	end
	master.write(32'h10,32'h0000_0061,4'hF);
	master.read(32'h10,data);
	master.write(32'h10,32'h0000_0062,4'hF);
	master.read(32'h10,data);
	master.write(32'h10,32'h0000_0064,4'hF);
	master.read(32'h10,data);
	master.write(32'h10,32'h0000_0060,4'hF);
	master.read(32'h10,data);
	master.write(32'h10,32'h0000_0020,4'hF);
	master.read(32'h10,data);

	#1000;

	master.write(32'h0,32'h0000_aa01,4'hF);
	master.read(32'h0,data);
	while(!data[4]) begin
		master.read(32'h10,data);
		master.read(32'h0,data);
	end

	master.write(32'h0,32'h0000_0000,4'hF);

	master.write(32'h10,32'h0000_0060,4'hF);
	master.read(32'h10,data);
	while(!data[7]) begin
		master.read(32'h10,data);
	end
	#1000;

end

endmodule
