module test_e1000_regs;

localparam 
	EECD_OFFSET='h0010,
	EERD_OFFSET='h0014;

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

wire [31:0] EECD;
wire [31:0] EERD;
wire EERD_START;

wire eesk;
wire eecs;
wire eedi;
wire eedo;
wire ee_busy;
wire [31:0] ee_rdatao;

wire [7:0] read_addr;
wire [15:0] read_data;
wire read_enable;

e1000_regs dut(
	.aclk(aclk),
	.aresetn(aresetn),

	.axi_s_awvalid(axi_s_awvalid),
	.axi_s_awready(axi_s_awready),
	.axi_s_awaddr(axi_s_awaddr),

	.axi_s_wvalid(axi_s_wvalid),
	.axi_s_wready(axi_s_wready),
	.axi_s_wdata(axi_s_wdata),
	.axi_s_wstrb(axi_s_wstrb),

	.axi_s_bvalid(axi_s_bvalid),
	.axi_s_bready(axi_s_bready),
	.axi_s_bresp(axi_s_bresp),

	.axi_s_arvalid(axi_s_arvalid),
	.axi_s_arready(axi_s_arready),
	.axi_s_araddr(axi_s_araddr),

	.axi_s_rvalid(axi_s_rvalid),
	.axi_s_rready(axi_s_rready),
	.axi_s_rdata(axi_s_rdata),
	.axi_s_rresp(axi_s_rresp),

	.EECD(EECD),
	.EECD_DO_i(eedo),
	.EECD_GNT_i(!ee_busy),

	.EERD(EERD),
	.EERD_START(EERD_START),
	.EERD_DONE_i(ee_rdatao[4]),
	.EERD_DATA_i(ee_rdatao[31:16])
);

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

shift_eeprom shift_eeprom_i(
	.clk(aclk),
	.rst(!aresetn),
	.sk(eesk),
	.cs(eecs),
	.di(eedi),
	.do(eedo),
	.wdatai(EERD),
	.eni(EERD_START),
	.eerd_busy(ee_busy),
	.sk_eecd(EECD[0]),
	.cs_eecd(EECD[1]),
	.di_eecd(EECD[2]),
	.eecd_busy(EECD[6]),
	.rdatao(ee_rdatao)
);

eeprom_emu eeprom_emu_i(
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

config_rom rom_i(
	.clk_i(aclk),
	.rst_i(!aresetn),
	.read_addr(read_addr),
	.read_enable(read_enable),
	.read_data(read_data)
);

initial
begin
	aclk = 0;
	forever #10 aclk = !aclk;
end

initial
begin
	$dumpfile("test_e1000_regs.vcd");
	$dumpvars(0);

	#1000000;
	$finish;
end

initial
begin:T0
	reg [31:0] data;
	#100;
	master.reset();

	$display("===================Start Test EECD & EERD======================");

	master.read(EECD_OFFSET,data);
	master.write(EECD_OFFSET,32'h0000_0060,4'hF);
	master.read(EECD_OFFSET,data);
	while(!data[7]) begin
		master.read(EECD_OFFSET,data);
	end
	master.write(EECD_OFFSET,32'h0000_0061,4'hF);
	master.read(EECD_OFFSET,data);
	master.write(EECD_OFFSET,32'h0000_0062,4'hF);
	master.read(EECD_OFFSET,data);
	master.write(EECD_OFFSET,32'h0000_0064,4'hF);
	master.read(EECD_OFFSET,data);
	master.write(EECD_OFFSET,32'h0000_0060,4'hF);
	master.read(EECD_OFFSET,data);
	master.write(EECD_OFFSET,32'h0000_0020,4'hF);
	master.read(EECD_OFFSET,data);

	#1000;

	master.write(EERD_OFFSET,32'h0000_0001,4'hF);
	master.read(EERD_OFFSET,data);
	while(!data[4]) begin
		#1000;
		master.read(EECD_OFFSET,data);
		master.read(EERD_OFFSET,data);
	end
	master.write(EERD_OFFSET,32'h0000_0101,4'hF);
	master.read(EERD_OFFSET,data);
	while(!data[4]) begin
		#1000;
		master.read(EECD_OFFSET,data);
		master.read(EERD_OFFSET,data);
	end

	master.write(EERD_OFFSET,32'h0000_0000,4'hF);

	#1000;
	$display("===================End Test EECD & EERD======================");
	$finish;
end

endmodule
