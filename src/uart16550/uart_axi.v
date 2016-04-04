module uart_axi (
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
	input axi_s_arvalid,
	output	axi_s_arready,

	output	[31:0] axi_s_rdata,
	output	[1:0] axi_s_rresp,
	output	axi_s_rvalid,
	input axi_s_rready,

	output [5:0] wb_adr_o,
	output [7:0] wb_dat_o,
	input [7:0] wb_dat_i,	
	output wb_we_o,
	output wb_re_o
);

reg awready_r;
reg wready_r;
reg [1:0] bresp_r;
reg bvalid_r;
reg arready_r;
reg rvalid_r;
reg [1:0] rresp_r;
reg [31:0] rdata_r;
reg [5:0] wb_adr_r;
reg [7:0] wb_dat_r;
reg wb_we_r;
reg read_enable;
reg wb_re_r;

assign axi_s_awready = awready_r;
assign axi_s_wready = wready_r;
assign axi_s_bresp = bresp_r;
assign axi_s_bvalid = bvalid_r;
assign axi_s_arready = arready_r;
assign axi_s_rdata = rdata_r;
assign axi_s_rresp = rresp_r;
assign axi_s_rvalid = rvalid_r;
assign wb_adr_o = wb_adr_r;
assign wb_dat_o = wb_dat_r;
assign wb_we_o = wb_we_r;
assign wb_re_o = wb_re_r;

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
	else if(wb_re_r) begin
		rdata_r <= {4{wb_dat_i}};
		rvalid_r <= 1'b1;
	end
	else if(axi_s_rready) begin
		rvalid_r <= 1'b0;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		wb_adr_r <= 'bx;
	end
	else if(axi_s_arvalid && axi_s_arready) begin
		wb_adr_r <= axi_s_araddr;
	end
	else if(axi_s_awvalid && axi_s_awready) begin
		wb_adr_r <= axi_s_awaddr;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		wb_dat_r <= 'bx;
	end
	else if(axi_s_wvalid && axi_s_wready) begin
		case(axi_s_awaddr[1:0])
			2'b00: wb_dat_r <= axi_s_wdata[7:0];
			2'b01: wb_dat_r <= axi_s_wdata[15:8];
			2'b10: wb_dat_r <= axi_s_wdata[23:16];
			2'b11: wb_dat_r <= axi_s_wdata[31:24];
		endcase
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		wb_we_r <= 1'b0;
	end
	else if(!bvalid_r && !awready_r && !wready_r) begin
		wb_we_r <= 1'b1;
	end
	else begin
		wb_we_r <= 1'b0;
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
		wb_re_r <= 1'b0;
	end
	else begin
		wb_re_r <= read_enable;
	end
end


endmodule
