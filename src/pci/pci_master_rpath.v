module pci_master_rpath(
	input mst_s_aclk,
	input mst_s_aresetn,

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
	input mst_s_rready,

	input clk,
	input rst,

	output [3:0] cmd_id,
	output [7:0] cmd_len,
	output [63:0] cmd_addr,
	output cmd_valid,
	input cmd_ready,

	input [3:0] resp_id,
	input [7:0] resp_len,
	input [1:0] resp_err,
	input resp_valid,
	output resp_ready,

	input [31:0] data_din,
	input data_valid,
	output data_ready
);

wire r1_addr_full;
wire r1_addr_wr;

wire r2_resp_full;
wire r2_resp_wr;

wire r2_data_full;
wire r2_data_wr;

wire r2_addr_empty;
wire r2_addr_rd;

wire [7:0] r3_len;
wire [1:0] r3_err;
wire r3_resp_empty;
wire r3_resp_rd;

wire r3_data_empty;
wire r3_data_rd;

reg [7:0] r3_cnt;

// Read stage 1
assign mst_s_arready = !r1_addr_full;

assign mst_s_rlast = r3_cnt==r3_len;
assign mst_s_rresp = r3_err;
assign mst_s_rvalid = !r3_resp_empty && !r3_data_empty;

assign cmd_valid = !r2_addr_empty;

assign resp_ready = !r2_resp_full;

assign data_ready = !r2_data_full;

assign r1_addr_wr = mst_s_arvalid && mst_s_arready;

assign r2_addr_rd = cmd_valid && cmd_ready;

assign r2_data_wr = data_valid && data_ready;

assign r2_resp_wr = resp_valid && resp_ready;

assign r3_data_rd = mst_s_rvalid && mst_s_rready;

assign r3_resp_rd = mst_s_rvalid && mst_s_rready && mst_s_rlast;

fifo_async #(.DSIZE(4+8+64),.ASIZE(4),.MODE("FWFT")) rcmd_fifo_i(
	.wr_rst(!mst_s_aresetn),
	.wr_clk(mst_s_aclk),
	.din({mst_s_arid, mst_s_arlen, mst_s_araddr}),
	.full(r1_addr_full),
	.wr_en(r1_addr_wr),

	.rd_rst(rst),
	.rd_clk(clk),
	.dout({cmd_id, cmd_len, cmd_addr}),
	.empty(r2_addr_empty),
	.rd_en(r2_addr_rd)
);

// Read stage 3
fifo_async #(.DSIZE(32),.ASIZE(10),.MODE("FWFT")) rdata_fifo_i(
	.wr_rst(rst),
	.wr_clk(clk),
	.din(data_din),
	.full(r2_data_full),
	.wr_en(r2_data_wr),

	.rd_rst(!mst_s_aresetn),
	.rd_clk(mst_s_aclk),
	.dout(mst_s_rdata),
	.empty(r3_data_empty),
	.rd_en(r3_data_rd)
);

fifo_async #(.DSIZE(2+4+8),.ASIZE(4),.MODE("FWFT")) rresp_fifo_i(
	.wr_rst(rst),
	.wr_clk(clk),
	.din({resp_err,resp_id,resp_len}),
	.full(r2_resp_full),
	.wr_en(r2_resp_wr),

	.rd_rst(!mst_s_aresetn),
	.rd_clk(mst_s_aclk),
	.dout({r3_err, mst_s_rid, r3_len}),
	.empty(r3_resp_empty),
	.rd_en(r3_resp_rd)
);

always @(posedge mst_s_aclk, negedge mst_s_aresetn)
begin
	if(!mst_s_aresetn) begin
		r3_cnt <= 'b0;
	end
	else if(mst_s_rvalid && mst_s_rready) begin
		if(mst_s_rlast)
			r3_cnt <= 'b0;
		else
			r3_cnt <= r3_cnt+1;
	end
end

endmodule
