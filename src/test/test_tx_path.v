`timescale 1ns/1ps
module test_tx_path;
parameter CLK_PERIOD_NS=8;
localparam DESC_SIZE=16;

reg aclk;
reg aresetn;

reg EN; // Transmit Enable
reg PSP; // Pad Short Packets
reg [63:0] TDBA; // Transmit Descriptor Base Address
reg [12:0] TDLEN; // Transmit Descriptor Buffer length=TDLEN*16*8
reg [15:0] TDH; // Transmit Descriptor Head
reg TDH_set; // TDH Update
wire [15:0] TDH_fb; // TDH feedback
reg [15:0] TDT; // Transmit Descriptor Tail
reg TDT_set; // TDT Update
reg [15:0] TIDV; // Interrupt Delay
reg DPP; // Disable Packet Prefetching
reg [5:0] PTHRESH; // Prefetch Threshold
reg [5:0] HTHRESH; // Host Threshold
reg [5:0] WTHRESH; // Write Back Threshold
reg GRAN; // Granularity
reg [5:0] LWTHRESH; // Tx Desc Low Threshold
reg [15:0] TADV; // Absolute Interrupt Delay
reg [15:0] TSMT; // TCP Segmentation Minimum Transfer
reg [15:0] TSPBP; // TCP Segmentation Packet Buffer Padding
wire TXDW_req; // Write-back interrupt set
wire TXQE_req; // TXD queue empty interrupt set
wire TXD_LOW_req; // TXD queue low interrupt set

// External Bus Access
wire [3:0] axi_m_awid;
wire [63:0] axi_m_awaddr;

wire [7:0] axi_m_awlen;
wire [2:0] axi_m_awsize;
wire [1:0] axi_m_awburst;
wire axi_m_awvalid;
wire axi_m_awready;

wire [3:0] axi_m_wid;
wire [31:0] axi_m_wdata;
wire [3:0] axi_m_wstrb;
wire axi_m_wlast;
wire axi_m_wvalid;
wire axi_m_wready;

wire [3:0] axi_m_bid;
wire [1:0] axi_m_bresp;
wire axi_m_bvalid;
wire axi_m_bready;

wire [3:0] axi_m_arid;
wire [63:0] axi_m_araddr;
wire [7:0] axi_m_arlen;
wire [2:0] axi_m_arsize;
wire [1:0] axi_m_arburst;
wire axi_m_arvalid;
wire axi_m_arready;

wire [3:0] axi_m_rid;
wire [31:0] axi_m_rdata;
wire [1:0] axi_m_rresp;
wire axi_m_rlast;
wire axi_m_rvalid;
wire axi_m_rready;

// MAC Tx Port
wire [7:0] mac_m_tdata;
wire mac_m_tvalid;
wire mac_m_tlast;
wire mac_m_tready;

wire [127:0] desc_data;
reg [63:0] desc_daddr;
reg [15:0] desc_length;
reg [7:0] desc_cso;
reg desc_eop;
reg desc_ifcs;
reg desc_ic;
reg desc_rs;
reg desc_dext;
reg desc_vle;
reg desc_ide;
reg [3:0] desc_sta;
reg [7:0] desc_css;
reg [15:0] desc_special;

assign desc_data[63:0] = desc_daddr;
assign desc_data[79:64] = desc_length;
assign desc_data[87:80] = desc_cso;
assign desc_data[88] = desc_eop;
assign desc_data[89] = desc_ifcs;
assign desc_data[90] = desc_ic;
assign desc_data[91] = desc_rs;
assign desc_data[92] = 1'b0;
assign desc_data[93] = desc_dext;
assign desc_data[94] = desc_vle;
assign desc_data[95] = desc_ide;
assign desc_data[99:96] = desc_sta;
assign desc_data[103:100] = 4'b0;
assign desc_data[111:104] = desc_css;
assign desc_data[127:112] = desc_special;

reg [127:0] resp_data;
wire [3:0] resp_sta;
wire resp_dd;

assign resp_sta = resp_data[99:96];
assign resp_dd = resp_sta[0];

task set_desc(input [31:0] addr, input [127:0] data);
begin
	ram_i.write(addr,data[31:0]); 
	ram_i.write(addr+4,data[63:32]);
	ram_i.write(addr+8,data[95:64]);
	ram_i.write(addr+12,data[127:96]);
end
endtask

task get_desc(input [31:0] addr, output [127:0] data);
begin
	data[31:0] = ram_i.read(addr); 
	data[63:32] = ram_i.read(addr+4);
	data[95:64] = ram_i.read(addr+8);
	data[127:96] = ram_i.read(addr+12);
end
endtask

task generate_traffic(input [12:0] octlen, input integer num);
	integer i;
	integer len;
begin
	len=octlen*8;

	$display($time,,,"========START TEST LEN=%d NUM=%d========",len,num);

	@(posedge aclk);
	TDLEN <= octlen; // Desc Num = octlen*8
	TDH <= 0;
	TDH_set <= 1;
	TDT <= 0;
	TDT_set <= 1;
	@(posedge aclk);
	EN <= 1;
	TDH_set <= 0;
	TDT_set <= 0;

	for(i=0;i<num;i=i+1) begin

		desc_daddr = i;
		@(posedge aclk);

		set_desc(TDBA+TDT*DESC_SIZE, desc_data);

		// Wait for host space
		while(((TDT+1)%len)==TDH_fb) @(posedge aclk);

		TDT <= (TDT+1)%len;
		TDT_set <= 1;
		@(posedge aclk);
		TDT_set <= 0;

		//repeat(16) @(posedge aclk);
	end

	while(TDH_fb != TDT) @(posedge aclk); // Wait for all DESCs done
	EN <= 0;

	$display($time,,,"========END TEST LEN=%d NUM=%d========",len,num);
end
endtask


tx_path #(.CLK_PERIOD_NS(CLK_PERIOD_NS)) tx_path_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.EN(EN),
	.PSP(PSP),
	.TDBA(TDBA),
	.TDLEN(TDLEN),
	.TDH(TDH),
	.TDH_set(TDH_set),
	.TDH_fb(TDH_fb),
	.TDT(TDT),
	.TDT_set(TDT_set),
	.TIDV(TIDV),
	.DPP(DPP),
	.PTHRESH(PTHRESH),
	.HTHRESH(HTHRESH),
	.WTHRESH(WTHRESH),
	.GRAN(GRAN),
	.LWTHRESH(LWTHRESH),
	.TADV(TADV),
	.TSMT(TSMT),
	.TSPBP(TSPBP),
	.TXDW_req(TXDW_req),
	.TXQE_req(TXQE_req),
	.TXD_LOW_req(TXD_LOW_req),

	.axi_m_awid(axi_m_awid),
	.axi_m_awaddr(axi_m_awaddr),

	.axi_m_awlen(axi_m_awlen),
	.axi_m_awsize(axi_m_awsize),
	.axi_m_awburst(axi_m_awburst),
	.axi_m_awvalid(axi_m_awvalid),
	.axi_m_awready(axi_m_awready),

	.axi_m_wid(axi_m_wid),
	.axi_m_wdata(axi_m_wdata),
	.axi_m_wstrb(axi_m_wstrb),
	.axi_m_wlast(axi_m_wlast),
	.axi_m_wvalid(axi_m_wvalid),
	.axi_m_wready(axi_m_wready),

	.axi_m_bid(axi_m_bid),
	.axi_m_bresp(axi_m_bresp),
	.axi_m_bvalid(axi_m_bvalid),
	.axi_m_bready(axi_m_bready),

	.axi_m_arid(axi_m_arid),
	.axi_m_araddr(axi_m_araddr),
	.axi_m_arlen(axi_m_arlen),
	.axi_m_arsize(axi_m_arsize),
	.axi_m_arburst(axi_m_arburst),
	.axi_m_arvalid(axi_m_arvalid),
	.axi_m_arready(axi_m_arready),

	.axi_m_rid(axi_m_rid),
	.axi_m_rdata(axi_m_rdata),
	.axi_m_rresp(axi_m_rresp),
	.axi_m_rlast(axi_m_rlast),
	.axi_m_rvalid(axi_m_rvalid),
	.axi_m_rready(axi_m_rready),

	.mac_m_tdata(mac_m_tdata),
	.mac_m_tvalid(mac_m_tvalid),
	.mac_m_tlast(mac_m_tlast),
	.mac_m_tready(mac_m_tready)
);

axi_ram #(.MEMORY_DEPTH(262144), .ID_WIDTH(4), .DATA_WIDTH(32))
ram_i(
    // AXI Clock & Reset
    .aresetn(aresetn),
    .aclk(aclk),
    
    // AXI Master Write Address
    .s_awid(axi_m_awid),
    .s_awaddr(axi_m_awaddr),
    .s_awlen(axi_m_awlen),
    .s_awsize(axi_m_awsize),
    .s_awburst(axi_m_awburst),
    .s_awvalid(axi_m_awvalid),
    .s_awready(axi_m_awready),
    
    // AXI Master Write Data
    .s_wid(axi_m_wid),
    .s_wdata(axi_m_wdata),
    .s_wstrb(axi_m_wstrb),
    .s_wlast(axi_m_wlast),
    .s_wvalid(axi_m_wvalid),
    .s_wready(axi_m_wready),
    
    // AXI Master Write Response
    .s_bready(axi_m_bready),
    .s_bid(axi_m_bid),
    .s_bresp(axi_m_bresp),
    .s_bvalid(axi_m_bvalid),
    
    // AXI Master Read Address
    .s_arid(axi_m_arid),
    .s_araddr(axi_m_araddr),
    .s_arlen(axi_m_arlen),
    .s_arsize(axi_m_arsize),
    .s_arburst(axi_m_arburst),
    .s_arvalid(axi_m_arvalid),
    .s_arready(axi_m_arready),
    
    // AXI Master Read Data
    .s_rready(axi_m_rready),
    .s_rid(axi_m_rid),
    .s_rdata(axi_m_rdata),
    .s_rresp(axi_m_rresp),
    .s_rlast(axi_m_rlast),
    .s_rvalid(axi_m_rvalid)
);

initial
begin
	aclk = 0;
	forever #(CLK_PERIOD_NS/2) aclk = ~aclk;
end

initial
begin
	aresetn = 0;
	EN = 0;
	PSP = 0;
	TDBA = 64'b0;
	TDLEN = 0;
	TDH = 0;
	TDH_set = 0;
	TDT = 0;
	TDT_set = 0;
	TIDV = 0;
	DPP = 0;
	PTHRESH = 0;
	HTHRESH = 0;
	WTHRESH = 0;
	GRAN = 0;
	LWTHRESH = 0;
	TADV = 0;
	TSMT = 0;
	TSPBP = 0;

	desc_daddr = 0;
	desc_length = 0;
	desc_cso = 0;
	desc_eop = 0;
	desc_ifcs = 0;
	desc_ic = 0;
	desc_rs = 0;
	desc_dext = 0;
	desc_vle = 0;
	desc_ide = 0;
	desc_sta = 0;
	desc_cso = 0;
	desc_css = 0;
	desc_special = 0;

	$dumpfile("test_tx_path.vcd");
	$dumpvars(0);

	#20000000;
	$stop;
end

initial
begin
	@(posedge aclk);
	aresetn <= 1;
	@(posedge aclk);

	desc_rs <= 1;
	TDBA <= 64'h0;

	generate_traffic(1, 1); // LEN=8, 1 Transfers

	generate_traffic(1, 7); // LEN=8, 7 Transfers

	generate_traffic(1, 8); // LEN=8, 8 Transfers

	generate_traffic(1, 15); // LEN=8, 15 Transfers

	generate_traffic(1, 16); // LEN=8, 16 Transfers

	generate_traffic(1, 24); // LEN=8, 24 Transfers

	generate_traffic(2, 15); // LEN=16, 15 Transfers

	generate_traffic(2, 16); // LEN=16, 16 Transfers

	generate_traffic(2, 32); // LEN=16, 32 Transfers

	generate_traffic(2, 48); // LEN=16, 48 Transfers

	DPP <= 1; // Disable prefetch

	generate_traffic(2, 48); // LEN=16, 48 Transfers

	desc_ide = 1;
	DPP <= 0;
	TDBA <= 64'h10; // Host address starts from 0x10
	TIDV <= 1; // Interrupt delay 1024 ns
	TADV <= 2; // Interrupt absolute delay 2048 ns

	generate_traffic(2, 48); // LEN=16, 48 Transfers

	TADV <= 16; // Interrupt absolute delay 16384 ns 

	generate_traffic(8191, 65536); // LEN=65528, 65536 Transfers

	#100000;
	$stop;
end

`define REPORT_FETCH
`define REPORT_WRITE_BACK
`define REPORT_INTERRUPT

`ifdef REPORT_FETCH
always @(posedge aclk)
begin
	/*
	if(axi_m_awvalid && axi_m_awready) 
		$display($time,,,"EXT WR ADDR=%x  LEN=%d", axi_m_awaddr, axi_m_awlen+1);
	*/

	if(axi_m_arvalid && axi_m_arready)
		$display($time,,,"FETCH ADDR=%x  LEN=%d", axi_m_araddr, axi_m_arlen+1);
end
`endif

`ifdef REPORT_WRITE_BACK
always @(posedge aclk)
begin
	if(axi_m_wvalid && axi_m_wready) begin
		get_desc(axi_m_awaddr/DESC_SIZE*DESC_SIZE, resp_data);
		#0;
		$display($time,,,"WRITE BACK ADDR=%x TXD=%d STA=%x", axi_m_awaddr, resp_data[31:0], axi_m_wdata[3:0]);
	end
end
`endif

`ifdef REPORT_INTERNAL_RAM_ACCESS
always @(posedge aclk)
begin
	if(tx_path_i.desc_s_awvalid && tx_path_i.desc_s_awready)
		$display($time,,,"INT WR ADDR=%x  LEN=%d", tx_path_i.desc_s_awaddr, tx_path_i.desc_s_awlen+1);

	if(tx_path_i.desc_s_arvalid && tx_path_i.desc_s_arready)
		$display($time,,,"INT RD ADDR=%x  LEN=%d", tx_path_i.desc_s_araddr, tx_path_i.desc_s_arlen+1);
end
`endif

`ifdef REPORT_INTERRUPT
always @(posedge aclk)
begin
	if(TXDW_req)
		$display($time,,,"INTR TXDW - TXD Write Back");

	if(TXQE_req)
		$display($time,,,"INTR TXQE - TXD Queue Empty");

	if(TXD_LOW_req)
		$display($time,,,"INTR TXD_LOW - TXD Low Threshold Hit");
end
`endif
endmodule

