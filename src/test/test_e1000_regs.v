module test_e1000_regs;

localparam 
	EECD_OFFSET='h0010,
	EERD_OFFSET='h0014,
	MDIC_OFFSET='h0020;

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

wire [31:0] MDIC;
wire MDIC_start;
wire mdc;
reg mdio;
wire mm_mdio_o;
wire mm_mdio_oe;
wire [15:0] mm_rdatao;
wire mm_rd_doneo;
wire mm_wr_doneo;

wire me_mdio_o;
wire me_mdio_oe;
wire [4:0] me_raddr;
wire me_ren;
wire [15:0] me_rdata;
wire [4:0] me_waddr;
wire [15:0] me_wdata;
wire me_wen;

always @(*)
begin
	if(me_mdio_oe && mm_mdio_oe)
		mdio = #10 'bx;
	else if(me_mdio_oe)
		mdio = #10 me_mdio_o;
	else if(mm_mdio_oe)
		mdio = #10 mm_mdio_o;
	else
		mdio = #10 1'b1;
end

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
	.EERD_DATA_i(ee_rdatao[31:16]),

	.MDIC(MDIC),
	.MDIC_start(MDIC_start),
	.MDIC_R_i(mm_rd_doneo&&mm_wr_doneo),
	.MDIC_DATA_i(mm_rdatao)
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

shift_mdio shift_mdio_i(
	.clk(aclk),
	.rst(!aresetn),
	.mdc_o(mdc),
	.mdio_i(mdio),
	.mdio_o(mm_mdio_o),
	.mdio_oe(mm_mdio_oe),
	.rdatao(mm_rdatao),
	.rd_doneo(mm_rd_doneo),
	.eni(MDIC_start),
	.wdatai({2'b01,MDIC[27:26], MDIC[25:16],2'b10,MDIC[15:0]}),
	.wr_doneo(mm_wr_doneo)
);

mdio_emu mdio_emu_i(
	.clk_i(aclk),
	.rst_i(!aresetn),
	.mdc_i(mdc),
	.mdio_i(mdio),
	.mdio_o(me_mdio_o),
	.mdio_oe(me_mdio_oe),
	.read_addr(me_raddr),
	.read_enable(me_ren),
	.read_data(me_rdata),
	.write_addr(me_waddr),
	.write_data(me_wdata),
	.write_enable(me_wen)
);

reg [15:0] mdio_mem[0:63];
reg [15:0] me_rdata_r;
always @(posedge aclk)
begin
	if(me_wen)
		mdio_mem[me_waddr]<=me_wdata;
	if(me_ren)
		me_rdata_r <= mdio_mem[me_raddr];
end
assign me_rdata = me_rdata_r;


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

task eeprom_autoread(input [7:0] addr, output [15:0] data);
	reg [31:0] rc;
begin
	master.write(EERD_OFFSET,{16'b0,addr,8'h01},4'hF);
	master.read(EERD_OFFSET,rc);
	while(!rc[4]) begin
		#1000;
		master.read(EERD_OFFSET,rc);
	end
	data=rc[31:16];
end
endtask

task eeprom_request();
	reg [31:0] rc;
begin
	master.read(EECD_OFFSET,rc);
	master.write(EECD_OFFSET,32'h0000_0060,4'hF);
	master.read(EECD_OFFSET,rc);
	while(!rc[7]) begin
		#1000;
		master.read(EECD_OFFSET,rc);
	end
end
endtask

task eeprom_release();
begin
	master.write(EECD_OFFSET,32'h0000_0020,4'hF);
end
endtask

task eeprom_set(input sk, input cs, input di);
begin
	master.write(EECD_OFFSET,{28'h0000_006,1'b0,di,cs,sk},4'hF);
end
endtask

task eeprom_get(output do);
	reg [31:0] rc;
begin
	master.read(EECD_OFFSET,rc);
	do=rc[3];
end
endtask

task mdio_read(input [4:0] phyaddr, input [4:0] regaddr, output [15:0] data);
	reg [31:0] rc;
begin
	master.write(MDIC_OFFSET,{6'h02,phyaddr,regaddr,16'b0},4'hF);
	master.read(MDIC_OFFSET,rc);
	while(!rc[28]) begin
		#1000;
		master.read(MDIC_OFFSET,rc);
	end
	data=rc[15:0];
end
endtask

task mdio_write(input [4:0] phyaddr, input [4:0] regaddr, input [15:0] data);
	reg [31:0] rc;
begin
	master.write(MDIC_OFFSET,{6'h01,phyaddr,regaddr,data},4'hF);
	master.read(MDIC_OFFSET,rc);
	while(!rc[28]) begin
		#1000;
		master.read(MDIC_OFFSET,rc);
	end
end
endtask


initial
begin:T0
	reg [31:0] data;
	#100;
	master.reset();

	$display("===================Start Test EECD & EERD======================");
	eeprom_request();
	eeprom_set(1'b1,1'b0,1'b0);
	eeprom_get(data[0]);
	eeprom_set(1'b1,1'b1,1'b0);
	eeprom_get(data[0]);
	eeprom_set(1'b1,1'b1,1'b1);
	eeprom_get(data[0]);
	eeprom_set(1'b0,1'b1,1'b1);
	eeprom_get(data[0]);
	eeprom_set(1'b0,1'b0,1'b1);
	eeprom_get(data[0]);
	eeprom_set(1'b0,1'b0,1'b0);
	eeprom_get(data[0]);
	eeprom_release();
	//eeprom_set(1'b1,1'b1,1'b1); // should not work

	eeprom_autoread(0,data);
	eeprom_autoread(1,data);
	eeprom_autoread(255,data);

	#1000
	$display("===================End Test EECD & EERD======================");

	$display("===================Start Test MDIC======================");
	mdio_read(0,0,data);

	mdio_write(0,0,16'habcd);
	mdio_read(0,0,data);

	mdio_write(0,1,16'haa55);
	mdio_read(0,1,data);

	mdio_write(0,31,16'h3c3c);
	mdio_read(0,31,data);

	mdio_write(1,2,16'haa55);
	mdio_read(1,2,data);

	#1000;
	$display("===================End Test MDIC======================");

	$finish;
end

endmodule
