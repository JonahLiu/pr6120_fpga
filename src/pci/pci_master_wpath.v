module pci_master_wpath(
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

	input clk,
	input rst,

	input [9:0] data_idx,
	output [31:0] data_dout,
	output [3:0] data_strb,

	output [3:0] cmd_id,
	output [7:0] cmd_len,
	output [63:0] cmd_addr,
	output cmd_valid,
	input cmd_ready,

	input [3:0] resp_id,
	input [7:0] resp_len,
	input [1:0] resp_err,
	input resp_valid,
	output resp_ready
);

wire w1_mem_full;

wire w1_len_wr;
wire w1_len_full;

wire w1_addr_full;
wire w1_addr_wr;

wire [3:0] w2_id;
wire [63:0] w2_addr;
wire w2_addr_empty;

wire [7:0] w2_len;
wire w2_len_empty;

wire w2_fifo_rd;

wire w2_fifo_full;
wire w2_fifo_wr;

wire [3:0] w3_id;
wire [7:0] w3_len;
wire [1:0] w3_err;
wire w3_fifo_empty;
wire w3_fifo_rd;

reg [7:0] w1_len;
reg [9:0] w1_widx;
reg [9:0] w1_ridx;
reg [4+32-1:0] w1_mem[0:1023];

assign mst_s_awready = !w1_addr_full;
assign mst_s_wready = !w1_mem_full && !w1_len_full;

assign mst_s_bid = w3_id;
assign mst_s_bresp = w3_err;
assign mst_s_bvalid = !w3_fifo_empty;

assign cmd_valid = !w2_addr_empty && !w2_len_empty;
assign cmd_id = w2_id;
assign cmd_addr = w2_addr;
assign cmd_len = w2_len;

assign resp_ready = !w2_fifo_full;

assign {data_strb,data_dout} = w1_mem[data_idx];

// Data buffer
always @(posedge mst_s_aclk, negedge mst_s_aresetn)
begin
	if(!mst_s_aresetn) begin
		w1_widx <= 'b0;
	end
	else if(mst_s_wvalid && mst_s_wready) begin
		w1_widx <= w1_widx+1;
	end
end

assign w1_mem_full = (w1_widx+1)==w1_ridx;

always @(posedge mst_s_aclk)
begin
	if(mst_s_wvalid && mst_s_wready) begin
		w1_mem[w1_widx] <= {mst_s_wstrb,mst_s_wdata};
	end
end

// Length FIFO
// Use length calculated from data port instead of the one from address port
always @(posedge mst_s_aclk, negedge mst_s_aresetn)
begin
	if(!mst_s_aresetn) begin
		w1_len <= 0;
	end
	else if(mst_s_wvalid && mst_s_wready) begin
		if(mst_s_wlast)
			w1_len <= 0;
		else
			w1_len <= w1_len+1;
	end
end

assign w1_len_wr = mst_s_wvalid && mst_s_wready && mst_s_wlast;

fifo_async #(.DSIZE(8),.ASIZE(8),.MODE("FWFT")) len_fifo_i(
	.wr_rst(!mst_s_aresetn),
	.wr_clk(mst_s_aclk),
	.din(w1_len),
	.full(w1_len_full),
	.wr_en(w1_len_wr),

	.rd_rst(rst),
	.rd_clk(clk),
	.dout(w2_len),
	.empty(w2_len_empty),
	.rd_en(w2_fifo_rd)
);

// Address FIFO
fifo_async #(.DSIZE(4+64),.ASIZE(8),.MODE("FWFT")) addr_fifo_i(
	.wr_rst(!mst_s_aresetn),
	.wr_clk(mst_s_aclk),
	.din({mst_s_awid,mst_s_awaddr}),
	.full(w1_addr_full),
	.wr_en(w1_addr_wr),

	.rd_rst(rst),
	.rd_clk(clk),
	.dout({w2_id,w2_addr}),
	.empty(w2_addr_empty),
	.rd_en(w2_fifo_rd)
);

assign w1_addr_wr = mst_s_awvalid && mst_s_awready;
assign w2_fifo_rd = cmd_valid && cmd_ready;

// Write stage 3
fifo_async #(.DSIZE(2+4+8),.ASIZE(4),.MODE("FWFT")) resp_fifo_i(
	.wr_rst(rst),
	.wr_clk(clk),
	.din({resp_err,resp_id,resp_len}),
	.full(w2_fifo_full),
	.wr_en(w2_fifo_wr),

	.rd_rst(!mst_s_aresetn),
	.rd_clk(mst_s_aclk),
	.dout({w3_err,w3_id,w3_len}),
	.empty(w3_fifo_empty),
	.rd_en(w3_fifo_rd)
);

assign w2_fifo_wr = resp_valid && resp_ready;
assign w3_fifo_rd = mst_s_bvalid && mst_s_bready;

// Step stage1 read index
always @(posedge mst_s_aclk, negedge mst_s_aresetn)
begin
	if(mst_s_aresetn) begin
		w1_ridx <= 'b0;
	end
	else if(mst_s_bvalid && mst_s_bready) begin
		w1_ridx <= w1_ridx+w3_len+1;
	end
end

endmodule
