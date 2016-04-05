module can_axi (
	input	aclk,
	input	aresetn,

	input [31:0] axi_s_awaddr,
	input axi_s_awvalid,
	output	axi_s_awready,

	input [31:0] axi_s_wdata,
	input [3:0] axi_s_wstrb,
	input axi_s_wvalid,
	output	axi_s_wready,

	output	[1:0] axi_s_bresp,
	output	axi_s_bvalid,
	input axi_s_bready,

	input [31:0] axi_s_araddr,
	input [3:0] axi_s_aruser,
	input axi_s_arvalid,
	output	axi_s_arready,

	output	[31:0] axi_s_rdata,
	output	[1:0] axi_s_rresp,
	output	axi_s_rvalid,
	input axi_s_rready,

	output [9:0] addr_o,
	output [7:0] data_o,
	input [7:0] data_i,	
	output wr_o,
	output rd_o
);

reg awready_r;
reg wready_r;
reg [1:0] bresp_r;
reg bvalid_r;
reg arready_r;
reg rvalid_r;
reg [1:0] rresp_r;
reg [31:0] rdata_r;
reg [9:0] addr_r;
reg [7:0] data_r;
reg wr_r;
reg read_enable;
reg rd_r;

assign axi_s_awready = awready_r;
assign axi_s_wready = wready_r;
assign axi_s_bresp = bresp_r;
assign axi_s_bvalid = bvalid_r;
assign axi_s_arready = arready_r;
assign axi_s_rdata = rdata_r;
assign axi_s_rresp = rresp_r;
assign axi_s_rvalid = rvalid_r;
assign addr_o = addr_r;
assign data_o = data_r;
assign wr_o = wr_r;
assign rd_o = read_enable;

// Write Address Ack
always @(posedge aclk,negedge aresetn)
begin
	if(!aresetn) begin
		awready_r <= 1'b1;
	end
	else if(axi_s_awvalid && axi_s_awready) begin
		awready_r <= 1'b0;
	end
	else if(axi_s_bvalid && axi_s_bready) begin
		awready_r <= 1'b1;
	end
end

// Write Data Ack
always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		wready_r <= 1'b1;
	end
	else if(axi_s_wvalid && axi_s_wready) begin
		wready_r <= 1'b0;
	end
	else if(axi_s_bvalid && axi_s_bready) begin
		wready_r <= 1'b1;
	end
end

// Write Response
always @(posedge aclk,negedge aresetn)
begin
	if(!aresetn) begin
		bvalid_r <= 1'b0;
		bresp_r <= 2'b0;
	end
	else if(!bvalid_r && !awready_r && !wready_r) begin
		bvalid_r <= 1'b1;
	end
	else if(axi_s_bready) begin
		bvalid_r <= 1'b0;
	end
end

// Read Address Ack
always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		arready_r <= 1'b1;
	end
	else if(axi_s_arvalid && axi_s_arready) begin
		arready_r <= 1'b0;
	end
	else if(axi_s_rvalid && axi_s_rready) begin
		arready_r <= 1'b1;
	end
end

// Read Response
always @(posedge aclk, negedge aresetn) 
begin
	if(!aresetn) begin
		rvalid_r <= 1'b0;
		rresp_r <= 2'b0;
		rdata_r <= 'bx;
	end
	else if(rd_r) begin
		rdata_r <= {4{data_i}};
		rvalid_r <= 1'b1;
	end
	else if(axi_s_rready) begin
		rvalid_r <= 1'b0;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		addr_r <= 'bx;
	end
	else if(axi_s_arvalid && axi_s_arready) begin
		addr_r <= axi_s_araddr[31:2];
	end
	else if(axi_s_awvalid && axi_s_awready) begin
		addr_r <= axi_s_awaddr[31:2];
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		data_r <= 'bx;
	end
	else if(axi_s_wvalid && axi_s_wready) begin
		data_r <= axi_s_wdata[7:0];
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		wr_r <= 1'b0;
	end
	else if(!bvalid_r && !awready_r && !wready_r) begin
		wr_r <= 1'b1;
	end
	else begin
		wr_r <= 1'b0;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		read_enable <= 1'b0;
	end
	else if(axi_s_arvalid && axi_s_arready) begin
		read_enable <= 1'b1;
	end	
	else begin
		read_enable <= 1'b0;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		rd_r <= 1'b0;
	end
	else begin
		rd_r <= read_enable;
	end
end


endmodule
