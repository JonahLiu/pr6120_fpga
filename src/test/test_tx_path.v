`timescale 1ns/10ps
module test_tx_path;
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


tx_path tx_path_i(
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

axi_ram #(.MEMORY_DEPTH(65536), .ID_WIDTH(4), .DATA_WIDTH(32))
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
	forever #5 aclk = ~aclk;
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

	$dumpfile("test_tx_path.vcd");
	$dumpvars(0);

	#1000000;
	$stop;
end

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

task set_desc(input [63:0] base, input [15:0] idx, input [127:0] data);
	integer addr;
begin
	addr = base+idx*DESC_SIZE;
	ram_i.write(addr,data[31:0]); 
	ram_i.write(addr+4,data[63:32]);
	ram_i.write(addr+8,data[95:64]);
	ram_i.write(addr+12,data[127:96]);
end
endtask

task get_desc(input [63:0] base, input [15:0] idx, output [127:0] data);
	integer addr;
begin
	#1;
	addr = base+idx*DESC_SIZE;
	data[31:0] = ram_i.read(addr); 
	data[63:32] = ram_i.read(addr+4);
	data[95:64] = ram_i.read(addr+8);
	data[127:96] = ram_i.read(addr+12);
end
endtask


task test_case_01;
	integer i;
begin
	@(posedge aclk);
	TDBA <= 64'b0;
	TDLEN <= 64; // 64*8== 512 DESCs
	TDH <= 0;
	TDH_set <= 1;
	TDT <= 0;
	TDT_set <= 1;
	TIDV <= 0;
	DPP <= 0;
	PTHRESH <= 0;
	HTHRESH <= 0;
	WTHRESH <= 0;
	GRAN <= 0;
	LWTHRESH <= 1;
	TADV <= 0;
	TSMT <= 0;
	TSPBP <= 0;
	@(posedge aclk);
	EN <= 1;
	TDH_set <= 0;
	TDT_set <= 0;
	
	for(i=0;i<512;i=i+1) begin
		desc_daddr = i*16;
		desc_length = 0;
		desc_cso = 0;
		desc_eop = 1;
		desc_ifcs = 0;
		desc_ic = 0;
		desc_rs = 1;
		desc_dext = 0;
		desc_vle = 0;
		desc_ide = 0;
		desc_sta = 0;
		desc_cso = 0;
		desc_css = 0;
		desc_special = 0;

		#0;
		set_desc(TDBA, i, desc_data);
	end

	@(posedge aclk);
	TDT <= 256;
	TDT_set <= 1;
	@(posedge aclk);
	TDT_set <= 0;
	while(TDH_fb != 256) @(posedge aclk); // Wait for all DESCs done

	@(posedge aclk);
	TDT <= 0;
	TDT_set <= 1;
	@(posedge aclk);
	TDT_set <= 0;
	while(TDH_fb != 0) @(posedge aclk); // Wait for all DESCs done

	for(i=0;i<512;i=i+1) begin // Report status
		@(posedge aclk);
		get_desc(TDBA, i, resp_data);
	end
end
endtask

initial
begin
	@(posedge aclk);
	aresetn <= 1;
	@(posedge aclk);

	test_case_01;

	#100000;
	$stop;
end

always @(posedge aclk)
begin
	if(axi_m_awvalid && axi_m_awready)
		$display($time,,,"EXT WR ADDR=%x  LEN=%d", axi_m_awaddr, axi_m_awlen+1);

	if(axi_m_arvalid && axi_m_arready)
		$display($time,,,"EXT RD ADDR=%x  LEN=%d", axi_m_araddr, axi_m_arlen+1);
end

always @(posedge aclk)
begin
	if(tx_path_i.desc_s_awvalid && tx_path_i.desc_s_awready)
		$display($time,,,"INT WR ADDR=%x  LEN=%d", tx_path_i.desc_s_awaddr, tx_path_i.desc_s_awlen+1);

	if(tx_path_i.desc_s_arvalid && tx_path_i.desc_s_arready)
		$display($time,,,"INT RD ADDR=%x  LEN=%d", tx_path_i.desc_s_araddr, tx_path_i.desc_s_arlen+1);
end

always @(posedge aclk)
begin
	if(TXDW_req)
		$display($time,,,"INTR TXDW - TXD Write Back");

	if(TXQE_req)
		$display($time,,,"INTR TXQE - TXD Queue Empty");

	if(TXD_LOW_req)
		$display($time,,,"INTR TXD_LOW - TXD Low Threshold Hit");
end
endmodule

