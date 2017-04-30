module mpc_pci_wrapper #(
	parameter VENDORID = 16'h13FE, // Advantech
	parameter DEVICEID = 16'hC202, // C202 two port CAN
	parameter SUBVID = 16'h13FE, 
	parameter SUBSYSID = 16'hC202, 
	parameter CLASSCODE = 24'h0C0900,
	parameter PORT_NUM=4
) (
	input clki,
	input rstni,

	input idseli,
	input [31:0] adi,
	output [31:0] ado,
	output adt,
	input [3:0] cbi,
	output [3:0] cbo,
	output cbt,
	input pari,
	output paro,
	output part,
	input framei,
	output frameo,
	output framet,
	input trdyi,
	output trdyo,
	output trdyt,
	input irdyi,
	output irdyo,
	output irdyt,
	input stopi,
	output stopo,
	output stopt,
	input devseli,
	output devselo,
	output devselt,
	input perri,
	output perro,
	output perrt,
	input serri,
	output serro,
	output serrt,
	input locki,
	output locko,
	output lockt,
	input gnti,
	output reqo,
	output reqt,
	input inti,
	output into,
	output intt,
	input pmei,
	output pmeo,
	output pmet,
	input m66eni,

	// CAN signals
	input  [PORT_NUM-1:0] rx_i,
	output [PORT_NUM-1:0] tx_o,
	output [PORT_NUM-1:0] bus_off_on
);

function integer clogb2 (input integer size);
begin
	size = size - 1;
	for (clogb2=1; size>1; clogb2=clogb2+1)
		size = size >> 1;
end
endfunction
localparam BARSIZE=clogb2(PORT_NUM)+10;

wire aclk;
wire aresetn;

(* MARK_DEBUG="TRUE" *) wire mpc_s_awvalid;
(* MARK_DEBUG="TRUE" *) wire mpc_s_awready;
(* MARK_DEBUG="TRUE" *) wire [31:0] mpc_s_awaddr;
(* MARK_DEBUG="TRUE" *) wire mpc_s_wvalid;
(* MARK_DEBUG="TRUE" *) wire mpc_s_wready;
(* MARK_DEBUG="TRUE" *) wire [31:0] mpc_s_wdata;
(* MARK_DEBUG="TRUE" *) wire [3:0] mpc_s_wstrb;
(* MARK_DEBUG="TRUE" *) wire mpc_s_bvalid;
(* MARK_DEBUG="TRUE" *) wire mpc_s_bready;
(* MARK_DEBUG="TRUE" *) wire [1:0] mpc_s_bresp;
(* MARK_DEBUG="TRUE" *) wire mpc_s_arvalid;
(* MARK_DEBUG="TRUE" *) wire mpc_s_arready;
(* MARK_DEBUG="TRUE" *) wire [31:0] mpc_s_araddr;
(* MARK_DEBUG="TRUE" *) wire [3:0] mpc_s_aruser;
(* MARK_DEBUG="TRUE" *) wire mpc_s_rvalid;
(* MARK_DEBUG="TRUE" *) wire mpc_s_rready;
(* MARK_DEBUG="TRUE" *) wire [31:0] mpc_s_rdata;
(* MARK_DEBUG="TRUE" *) wire [1:0] mpc_s_rresp;
(* MARK_DEBUG="TRUE" *) wire intr_request;

wire ahb_mst_hgrant;
wire ahb_mst_hready;
wire [1:0] ahb_mst_hresp;
wire [31:0] ahb_mst_hrdata;
wire ahb_mst_hbusreq;
wire ahb_mst_hlock;
wire [1:0] ahb_mst_htrans;
wire [31:0] ahb_mst_haddr;
wire ahb_mst_hwrite;
wire [2:0] ahb_mst_hsize;
wire [2:0] ahb_mst_hburst;
wire [3:0] ahb_mst_hprot;
wire [31:0] ahb_mst_hwdata;

wire intr_req;

wire can_clk;
wire clk_locked;

reg [6:0] rst_sync;
(* ASYNC_REG = "TRUE" *)
reg [1:0] intr_sync;

assign aclk = can_clk;
assign aresetn = rst_sync[6];
assign areset = !aresetn;

assign intr_req = intr_sync[1];

always @(posedge aclk, negedge rstni)
begin
	if(!rstni) begin
		rst_sync <= 'b0;
	end
	else if(!clk_locked) begin
		rst_sync <= 'b0;
	end
	else if(!rst_sync[6])
		rst_sync <= rst_sync+1;
end

always @(posedge clki)
begin
	intr_sync <= {intr_sync, intr_request};
end

can_clk_gen can_clk_gen_i(
	.reset(!rstni),
	.clk_in1(clki),
	.clk_out1(can_clk),
	.locked(clk_locked)
);

grpci2_device #(
	.oepol(0),
	.vendorid(VENDORID),
	.deviceid(DEVICEID),
	.subsysid(SUBSYSID),
	.subvid(SUBVID),
	.classcode(CLASSCODE),
	.master(0),
	.target(1),
	.barminsize(5),
	.fifo_depth(3),
	.bar0(BARSIZE), // 1KByte per port
	.bar1(0), // no use, disabled
	.bar2(3), // 8 Byte IO for version number
	.bar3(0),
	.bar4(0),
	.bar5(0),
	.bar0_map(24'h010000),
	.bar1_map(24'h020000),
	.bar2_map(24'h040000),
	.bar3_map(24'h080000),
	.bar4_map(24'h100000),
	.bar5_map(24'h200000),
	.bartype(14'b00000100_00000000)
)
pci_i (
	.pci_rst(rstni),
	.pci_clk(clki),
	.pci_gnt(gnti),
	.pci_idsel(idseli),
	.pci_lock_i(locki),
	.pci_lock_o(locko),
	.pci_lock_oe(lockt),
	.pci_ad_i(adi),
	.pci_ad_o(ado),
	.pci_ad_oe(adt),
	.pci_cbe_i(cbi),
	.pci_cbe_o(cbo),
	.pci_cbe_oe(cbt),
	.pci_frame_i(framei),
	.pci_frame_o(frameo),
	.pci_frame_oe(framet),
	.pci_irdy_i(irdyi),
	.pci_irdy_o(irdyo),
	.pci_irdy_oe(irdyt),
	.pci_trdy_i(trdyi),
	.pci_trdy_o(trdyo),
	.pci_trdy_oe(trdyt),
	.pci_devsel_i(devseli),
	.pci_devsel_o(devselo),
	.pci_devsel_oe(devselt),
	.pci_stop_i(stopi),
	.pci_stop_o(stopo),
	.pci_stop_oe(stopt),
	.pci_perr_i(perri),
	.pci_perr_o(perro),
	.pci_perr_oe(perrt),
	.pci_par_i(pari),
	.pci_par_o(paro),
	.pci_par_oe(part),
	.pci_req_o(reqo),
	.pci_req_oe(reqt),
	.pci_serr_i(serri),
	.pci_serr_o(serro),
	.pci_serr_oe(serrt),
	.pci_int_i({3'b111,inti}),
	.pci_int_o(into),
	.pci_int_oe(intt),
	.pci_m66en(m66eni),
	.pci_pme_i(pmei),
	.pci_pme_o(pmeo),
	.pci_pme_oe(pmet),

	.ahb_hclk(aclk),
	.ahb_hresetn(aresetn),

	.ahb_mst_hgrant(1'b1),
	.ahb_mst_hready(ahb_mst_hready),
	.ahb_mst_hresp(ahb_mst_hresp),
	.ahb_mst_hrdata(ahb_mst_hrdata),
	.ahb_mst_hbusreq(ahb_mst_hbusreq),
	.ahb_mst_hlock(ahb_mst_hlock),
	.ahb_mst_htrans(ahb_mst_htrans),
	.ahb_mst_haddr(ahb_mst_haddr),
	.ahb_mst_hwrite(ahb_mst_hwrite),
	.ahb_mst_hsize(ahb_mst_hsize),
	.ahb_mst_hburst(ahb_mst_hburst),
	.ahb_mst_hprot(ahb_mst_hprot),
	.ahb_mst_hwdata(ahb_mst_hwdata),

	.ahb_slv_hsel(1'b0),
	.ahb_slv_haddr(31'b0),
	.ahb_slv_hwrite(1'b0),
	.ahb_slv_htrans(2'b0),
	.ahb_slv_hsize(3'b0),
	.ahb_slv_hburst(3'b0),
	.ahb_slv_hwdata(31'b0),
	.ahb_slv_hprot(2'b0),
	.ahb_slv_hmaster(4'b0),
	.ahb_slv_hmastlock(1'b0),
	.ahb_slv_hready_i(1'b0),
	.ahb_slv_hready_o(),
	.ahb_slv_hresp(),
	.ahb_slv_hrdata(),
	.ahb_slv_hsplit(),

	.intr_req({3'b000,intr_req})
);

grpci2_axi_lite_tgt tgt_i(
	.aclk(aclk),
	.aresetn(aresetn),

	.ahb_s_hsel(1'b1),
	.ahb_s_haddr(ahb_mst_haddr),
	.ahb_s_hwrite(ahb_mst_hwrite),
	.ahb_s_htrans(ahb_mst_htrans),
	.ahb_s_hsize(ahb_mst_hsize),
	.ahb_s_hburst(ahb_mst_hburst),
	.ahb_s_hprot(ahb_mst_hprot),
	.ahb_s_hmaster(4'b0),
	.ahb_s_hmastlock(ahb_mst_hlock),
	.ahb_s_hwdata(ahb_mst_hwdata),
	.ahb_s_hready_i(ahb_mst_hready),
	.ahb_s_hready_o(ahb_mst_hready),
	.ahb_s_hresp(ahb_mst_hresp),
	.ahb_s_hrdata(ahb_mst_hrdata),
	.ahb_s_hsplit(),

	.tgt_m_awvalid(mpc_s_awvalid),
	.tgt_m_awready(mpc_s_awready),
	.tgt_m_awaddr(mpc_s_awaddr),

	.tgt_m_wvalid(mpc_s_wvalid),
	.tgt_m_wready(mpc_s_wready),
	.tgt_m_wdata(mpc_s_wdata),
	.tgt_m_wstrb(mpc_s_wstrb),

	.tgt_m_bvalid(mpc_s_bvalid),
	.tgt_m_bready(mpc_s_bready),
	.tgt_m_bresp(mpc_s_bresp),

	.tgt_m_arvalid(mpc_s_arvalid),
	.tgt_m_arready(mpc_s_arready),
	.tgt_m_araddr(mpc_s_araddr),
	.tgt_m_aruser(mpc_s_aruser),

	.tgt_m_rvalid(mpc_s_rvalid),
	.tgt_m_rready(mpc_s_rready),
	.tgt_m_rdata(mpc_s_rdata),
	.tgt_m_rresp(mpc_s_rresp)
);

mpc_top #(.PORT_NUM(PORT_NUM)) mpc_top(
	.aclk(aclk),
	.aresetn(aresetn),

	.axi_s_awvalid(mpc_s_awvalid),
	.axi_s_awready(mpc_s_awready),
	.axi_s_awaddr(mpc_s_awaddr),

	.axi_s_wvalid(mpc_s_wvalid),
	.axi_s_wready(mpc_s_wready),
	.axi_s_wdata(mpc_s_wdata),
	.axi_s_wstrb(mpc_s_wstrb),

	.axi_s_bvalid(mpc_s_bvalid),
	.axi_s_bready(mpc_s_bready),
	.axi_s_bresp(mpc_s_bresp),

	.axi_s_arvalid(mpc_s_arvalid),
	.axi_s_arready(mpc_s_arready),
	.axi_s_araddr(mpc_s_araddr),
	.axi_s_aruser(mpc_s_aruser),

	.axi_s_rvalid(mpc_s_rvalid),
	.axi_s_rready(mpc_s_rready),
	.axi_s_rdata(mpc_s_rdata),
	.axi_s_rresp(mpc_s_rresp),

	.intr_request(intr_request),

	.rx_i(rx_i),
	.tx_o(tx_o),
	.bus_off_on(bus_off_on)
);

endmodule
