module grpci2_axi_mst(
	input ahb_hclk,
	input ahb_hresetn,

	input ahb_m_hgrant,
	input ahb_m_hready,
	input [1:0] ahb_m_hresp,
	input [31:0] ahb_m_hrdata,
	output ahb_m_hbusreq,
	output ahb_m_hlock,
	output [1:0] ahb_m_htrans,
	output [31:0] ahb_m_haddr,
	output ahb_m_hwrite,
	output [2:0] ahb_m_hsize,
	output [2:0] ahb_m_hburst,
	output [3:0] ahb_m_hprot,
	output [31:0] ahb_m_hwdata,

	input [7:0] cacheline_size,

	input mst_s_aclk,
	input mst_s_aresetn,

	input [3:0] mst_s_awid,
	input [63:0] mst_s_awaddr,
	input [7:0] mst_s_awlen,
	input [2:0] mst_s_awsize,
	input [1:0] mst_s_awburst,
	input [3:0] mst_s_awcache,
	input mst_s_awvalid,
	output mst_s_awready,

	input [3:0] mst_s_wid,
	input [31:0] mst_s_wdata,
	input [3:0] mst_s_wstrb,
	input mst_s_wlast,
	input mst_s_wvalid,
	output mst_s_wready,

	output [3:0] mst_s_bid,
	output [1:0] mst_s_bresp,
	output mst_s_bvalid,
	input mst_s_bready,

	input [3:0] mst_s_arid,
	input [63:0] mst_s_araddr,
	input [7:0] mst_s_arlen,
	input [2:0] mst_s_arsize,
	input [1:0] mst_s_arburst,
	input [3:0] mst_s_arcache,
	input mst_s_arvalid,
	output mst_s_arready,

	output [3:0] mst_s_rid,
	output [31:0] mst_s_rdata,
	output [1:0] mst_s_rresp,
	output mst_s_rlast,
	output mst_s_rvalid,
	input mst_s_rready
);

wire [9:0] wdata_idx;
wire [31:0] wdata_dout;
wire [3:0] wdata_strb;

wire [3:0] wcmd_id;
wire [7:0] wcmd_len;
wire [63:0] wcmd_addr;
wire wcmd_valid;
wire wcmd_ready;

wire [3:0] wresp_id;
wire [7:0] wresp_len;
wire [1:0] wresp_err;
wire wresp_valid;
wire wresp_ready;

wire [3:0] rcmd_id;
wire [7:0] rcmd_len;
wire [63:0] rcmd_addr;
wire rcmd_valid;
wire rcmd_ready;

wire [3:0] rresp_id;
wire [7:0] rresp_len;
wire [1:0] rresp_err;
wire rresp_valid;
wire rresp_ready;

wire [31:0] rdata_din;
wire rdata_valid;
wire rdata_ready;

wire clk;
wire rst;

assign clk = ahb_hclk;
assign rst = !ahb_hresetn;

pci_master_wpath wpath_i(
	.mst_s_aclk(mst_s_aclk),
	.mst_s_aresetn(mst_s_aresetn),

	.mst_s_awid(mst_s_awid),
	.mst_s_awaddr(mst_s_awaddr),
	.mst_s_awlen(mst_s_awlen),
	.mst_s_awsize(mst_s_awsize),
	.mst_s_awburst(mst_s_awburst),
	.mst_s_awcache(mst_s_awcache),
	.mst_s_awvalid(mst_s_awvalid),
	.mst_s_awready(mst_s_awready),

	.mst_s_wid(mst_s_wid),
	.mst_s_wdata(mst_s_wdata),
	.mst_s_wstrb(mst_s_wstrb),
	.mst_s_wlast(mst_s_wlast),
	.mst_s_wvalid(mst_s_wvalid),
	.mst_s_wready(mst_s_wready),

	.mst_s_bid(mst_s_bid),
	.mst_s_bresp(mst_s_bresp),
	.mst_s_bvalid(mst_s_bvalid),
	.mst_s_bready(mst_s_bready),

	.clk(clk),
	.rst(rst),

	.data_idx(wdata_idx),
	.data_dout(wdata_dout),
	.data_strb(wdata_strb),

	.cmd_id(wcmd_id),
	.cmd_len(wcmd_len),
	.cmd_addr(wcmd_addr),
	.cmd_valid(wcmd_valid),
	.cmd_ready(wcmd_ready),

	.resp_id(wresp_id),
	.resp_len(wresp_len),
	.resp_err(wresp_err),
	.resp_valid(wresp_valid),
	.resp_ready(wresp_ready)
);

pci_master_rpath rpath_i(
	.mst_s_aclk(mst_s_aclk),
	.mst_s_aresetn(mst_s_aresetn),

	.mst_s_arid(mst_s_arid),
	.mst_s_araddr(mst_s_araddr),
	.mst_s_arlen(mst_s_arlen),
	.mst_s_arsize(mst_s_arsize),
	.mst_s_arburst(mst_s_arburst),
	.mst_s_arcache(mst_s_arcache),
	.mst_s_arvalid(mst_s_arvalid),
	.mst_s_arready(mst_s_arready),

	.mst_s_rid(mst_s_rid),
	.mst_s_rdata(mst_s_rdata),
	.mst_s_rresp(mst_s_rresp),
	.mst_s_rlast(mst_s_rlast),
	.mst_s_rvalid(mst_s_rvalid),
	.mst_s_rready(mst_s_rready),

	.clk(clk),
	.rst(rst),

	.cmd_id(rcmd_id),
	.cmd_len(rcmd_len),
	.cmd_addr(rcmd_addr),
	.cmd_valid(rcmd_valid),
	.cmd_ready(rcmd_ready),

	.resp_id(rresp_id),
	.resp_len(rresp_len),
	.resp_err(rresp_err),
	.resp_valid(rresp_valid),
	.resp_ready(rresp_ready),

	.data_din(rdata_din),
	.data_valid(rdata_valid),
	.data_ready(rdata_ready)
);

grpci2_master_ctrl ctrl_i(
	.clk(clk),
	.rst(rst),

	.ahb_m_hgrant(ahb_m_hgrant),
	.ahb_m_hready(ahb_m_hready),
	.ahb_m_hresp(ahb_m_hresp),
	.ahb_m_hrdata(ahb_m_hrdata),
	.ahb_m_hbusreq(ahb_m_hbusreq),
	.ahb_m_hlock(ahb_m_hlock),
	.ahb_m_htrans(ahb_m_htrans),
	.ahb_m_haddr(ahb_m_haddr),
	.ahb_m_hwrite(ahb_m_hwrite),
	.ahb_m_hsize(ahb_m_hsize),
	.ahb_m_hburst(ahb_m_hburst),
	.ahb_m_hprot(ahb_m_hprot),
	.ahb_m_hwdata(ahb_m_hwdata),

	.wdata_idx(wdata_idx),
	.wdata_dout(wdata_dout),
	.wdata_strb(wdata_strb),

	.wcmd_id(wcmd_id),
	.wcmd_len(wcmd_len),
	.wcmd_addr(wcmd_addr),
	.wcmd_valid(wcmd_valid),
	.wcmd_ready(wcmd_ready),

	.wresp_id(wresp_id),
	.wresp_len(wresp_len),
	.wresp_err(wresp_err),
	.wresp_valid(wresp_valid),
	.wresp_ready(wresp_ready),

	.rcmd_id(rcmd_id),
	.rcmd_len(rcmd_len),
	.rcmd_addr(rcmd_addr),
	.rcmd_valid(rcmd_valid),
	.rcmd_ready(rcmd_ready),

	.rresp_id(rresp_id),
	.rresp_len(rresp_len),
	.rresp_err(rresp_err),
	.rresp_valid(rresp_valid),
	.rresp_ready(rresp_ready),

	.rdata_din(rdata_din),
	.rdata_valid(rdata_valid),
	.rdata_ready(rdata_ready),

	.cacheline_size(cacheline_size)
);

endmodule
