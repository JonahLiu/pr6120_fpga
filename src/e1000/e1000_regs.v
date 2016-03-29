module e1000_regs(
	input aclk,
	input aresetn,

	// Register Space Access Port
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

	output [31:0] EECD,
	input 	EECD_DO_i,
	input	EECD_GNT_i,

	output [31:0] EERD,
	output EERD_START,
	input EERD_DONE_i,
	input [15:0] EERD_DATA_i,

	output [31:0] MDIC,
	output MDIC_start,
	input MDIC_R_i,
	input [15:0] MDIC_DATA_i
);

reg awready_r;
reg wready_r;
reg [1:0] bresp_r;
reg bvalid_r;
reg arready_r;
reg [31:0] rdata_r;
reg rvalid_r;
reg [1:0] rresp_r;

reg [31:0] write_addr;
reg [31:0] write_data;
reg write_enable;
reg [3:0] write_be;

reg [31:0] read_addr;
reg [31:0] read_data;
reg read_enable;
reg read_ready;

assign axi_s_awready = awready_r;
assign axi_s_wready = wready_r;
assign axi_s_bresp = bresp_r;
assign axi_s_bvalid = bvalid_r;
assign axi_s_arready = arready_r;
assign axi_s_rdata = rdata_r;
assign axi_s_rresp = rresp_r;
assign axi_s_rvalid = rvalid_r;

//% Write Stage
//% Address acknowledge
always @(posedge aclk,negedge aresetn)
begin
	if(!aresetn) begin
		awready_r <= 1'b1;
	end
	else if(awready_r) begin
		if(axi_s_awvalid) begin
			awready_r <= 1'b0;
		end
	end
	else if(axi_s_bvalid && axi_s_bready) begin
		awready_r <= 1'b1;
	end
end

//% Data acknowledge
always @(posedge aclk,negedge aresetn)
begin
	if(!aresetn) begin
		wready_r <= 1'b1;
	end
	else if(wready_r) begin
		if(axi_s_wvalid) begin
			wready_r <= 1'b0;
		end
	end
	else if(axi_s_bvalid && axi_s_bready) begin
		wready_r <= 1'b1;
	end
end

//% Write response
always @(posedge aclk,negedge aresetn)
begin
	if(!aresetn) begin
		bvalid_r <= 1'b0;
		bresp_r <= 2'b0;
	end
	else if(axi_s_wvalid && axi_s_wready) begin
		bvalid_r <= 1'b1;
	end
	else if(axi_s_bready) begin
		bvalid_r <= 1'b0;
	end
end

//% Data write 
always @(posedge aclk)
begin
	if(axi_s_awvalid && axi_s_awready) begin
		write_addr <= axi_s_awaddr;
	end
	if(axi_s_wvalid && axi_s_wready) begin
		write_data <= axi_s_wdata;
		write_be <= axi_s_wstrb;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		write_enable <= 1'b0;
	end
	else if(axi_s_wvalid && axi_s_wready) begin
		write_enable <= 1'b1;
	end
	else begin
		write_enable <= 1'b0;
	end
end

//% Read Stage
//% Read Address Acknowledge
always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		arready_r <= 1'b1;
	end
	else if(axi_s_arvalid && arready_r) begin
		arready_r <= 1'b0;
	end
	else if(axi_s_rvalid && axi_s_rready) begin
		arready_r <= 1'b1;
	end
end

//% Read Data Response
always @(posedge aclk, negedge aresetn) 
begin
	if(!aresetn) begin
		arready_r <= 1'b1;
		rvalid_r <= 1'b0;
		rresp_r <= 2'b0;
		rdata_r <= 'bx;
	end
	else if(arready_r && axi_s_arvalid) begin
		arready_r <= 1'b0;
		read_addr <= axi_s_araddr;
		read_enable <= 1'b1;
	end
	else if(read_enable) begin
		if(read_ready) begin
			read_enable <= 1'b0;
			rdata_r <= read_data;
			rvalid_r <= 1'b1;
		end
	end
	else if(rvalid_r && axi_s_rready) begin
		rvalid_r <= 1'b0;
		arready_r <= 1'b1;
	end
end

// Test stub
/*
reg [7:0] mem0 [0:127];
reg [15:8] mem1 [0:127];
reg [23:16] mem2 [0:127];
reg [31:24] mem3 [0:127];
always @(posedge aclk)
begin
	if(write_enable) begin
		if(write_be[0]) mem0[write_addr] <= write_data[7:0];
		if(write_be[1]) mem1[write_addr] <= write_data[15:8];
		if(write_be[2]) mem2[write_addr] <= write_data[23:16];
		if(write_be[3]) mem3[write_addr] <= write_data[31:24];
	end

	if(read_enable) begin
		read_data <= {mem3[read_addr], mem2[read_addr], 
			mem1[read_addr], mem0[read_addr]};
		read_ready <= 1'b1;
	end
	else begin
		read_ready <= 1'b0;
	end
end
*/

reg CTRL_wstb;
reg CTRL_rstb;
wire [31:0] CTRL_o;
wire [31:0] CTRL_i;
e1000_register #(.init(32'h0000_0201)) CTRL_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(CTRL_wstb), .q_o(CTRL_o)
);
assign CTRL_i = CTRL_o;

reg STATUS_wstb;
reg STATUS_rstb;
wire [31:0] STATUS_i;
assign STATUS_i = 'b0; // FIXIT: actual value

reg EECD_wstb;
reg EECD_rstb;
wire [31:0] EECD_o;
wire [31:0] EECD_i;
e1000_register #(.init(32'h0000_0110)) EECD_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(EECD_wstb), .q_o(EECD_o)
);
assign EECD = EECD_o;
assign EECD_i = {24'h0000_01,EECD_GNT_i,EECD_o[6:4],EECD_DO_i,EECD[2:0]};

reg EERD_wstb;
reg EERD_rstb;
wire [31:0] EERD_o;
wire [31:0] EERD_i;
e1000_register #(.init(32'h0)) EERD_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(EERD_wstb), .q_o(EERD_o)
);
assign EERD = EERD_o;
assign EERD_i = {EERD_DATA_i,EERD_o[15:8],3'b0,EERD_DONE_i,4'b0};
reg EERD_wstb_0;
always @(posedge aclk) EERD_wstb_0 <= EERD_wstb;
assign EERD_START = EERD_o[0]&EERD_wstb_0;


// FLA is ignored
reg FLA_wstb;
reg FLA_rstb;
wire [31:0] FLA_i;
assign FLA_i = 'b0;

reg CTRL_EXT_wstb;
reg CTRL_EXT_rstb;
wire [31:0] CTRL_EXT_o;
wire [31:0] CTRL_EXT_i;
e1000_register #(.init(32'h0)) CTRL_EXT_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(CTRL_EXT_wstb), .q_o(CTRL_EXT_o)
);
assign CTRL_EXT_i = CTRL_EXT_o;

reg MDIC_wstb;
reg MDIC_rstb;
wire [31:0] MDIC_o;
wire [31:0] MDIC_i;
e1000_register #(.init(32'h0)) MDIC_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(MDIC_wstb), .q_o(MDIC_o)
);
assign MDIC = MDIC_o;
assign MDIC_i = {2'b0,MDIC_o[29],MDIC_R_i,MDIC_o[27:16],MDIC_DATA_i};
reg MDIC_wstb_0;
always @(posedge aclk) MDIC_wstb_0 <= MDIC_wstb;
assign MDIC_start = MDIC_wstb_0;

reg FCAL_wstb;
reg FCAL_rstb;
wire [31:0] FCAL_o;
wire [31:0] FCAL_i;
e1000_register #(.init(32'h00C2_8001)) FCAL_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(FCAL_wstb), .q_o(FCAL_o)
);
assign FCAL_i = FCAL_o;

reg FCAH_wstb;
reg FCAH_rstb;
wire [31:0] FCAH_o;
wire [31:0] FCAH_i;
e1000_register #(.init(32'h0000_0100)) FCAH_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(FCAH_wstb), .q_o(FCAH_o)
);
assign FCAH_i = {16'b0,FCAH_o[15:0]};

reg FCT_wstb;
reg FCT_rstb;
wire [31:0] FCT_o;
wire [31:0] FCT_i;
e1000_register #(.init(32'h0000_8808)) FCT_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(FCT_wstb), .q_o(FCT_o)
);
assign FCT_i = {16'b0,FCT_o[15:0]};

reg VET_wstb;
reg VET_rstb;
wire [31:0] VET_o;
wire [31:0] VET_i;
e1000_register #(.init(32'h0000_8100)) VET_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(VET_wstb), .q_o(VET_o)
);
assign VET_i = {16'b0,VET_o[15:0]};

reg FCTTV_wstb;
reg FCTTV_rstb;
wire [31:0] FCTTV_o;
wire [31:0] FCTTV_i;
e1000_register #(.init(32'h0000_8100)) FCTTV_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(FCTTV_wstb), .q_o(FCTTV_o)
);
assign FCTTV_i = {16'b0,FCTTV_o[15:0]};

// TXCW is ignored
reg TXCW_wstb;
reg TXCW_rstb;
wire [31:0] TXCW_i;
assign TXCW_i = 'b0;

// RXCW is ignored
reg RXCW_wstb;
reg RXCW_rstb;
wire [31:0] RXCW_i;
assign RXCW_i = 'b0;

reg LEDCTL_wstb;
reg LEDCTL_rstb;
wire [31:0] LEDCTL_o;
wire [31:0] LEDCTL_i;
e1000_register #(.init(32'h0706_8302)) LEDCTL_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(LEDCTL_wstb), .q_o(LEDCTL_o)
);
assign LEDCTL_i = LEDCTL_o;

reg PBA_wstb;
reg PBA_rstb;
wire [31:0] PBA_o;
wire [31:0] PBA_i;
e1000_register #(.init(32'h0010_0030)) PBA_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(PBA_wstb), .q_o(PBA_o)
);
assign PBA_i = PBA_o;

//FIXIT: ICR is R-C, W1-C
reg ICR_wstb;
reg ICR_rstb;
wire [31:0] ICR_o;
wire [31:0] ICR_i;
e1000_register #(.init(32'h0)) ICR_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(ICR_wstb), .q_o(ICR_o)
);
assign ICR_i = {17'b0,ICR_o[14:0]};

reg ITR_wstb;
reg ITR_rstb;
wire [31:0] ITR_o;
wire [31:0] ITR_i;
e1000_register #(.init(32'h0)) ITR_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(ITR_wstb), .q_o(ITR_o)
);
assign ITR_i = {16'b0,ITR_o[15:0]};

reg ICS_wstb;
reg ICS_rstb;
wire [31:0] ICS_o;
wire [31:0] ICS_i;
e1000_register #(.init(32'h0)) ICS_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(ICS_wstb), .q_o(ICS_o)
);
assign ICS_i = {16'b0,ICS_o[15:0]};

reg IMS_wstb;
reg IMS_rstb;
wire [31:0] IMS_o;
wire [31:0] IMS_i;
e1000_register #(.init(32'h0)) IMS_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(IMS_wstb), .q_o(IMS_o)
);
assign IMS_i = {15'b0,IMS_o[16:0]};

reg IMC_wstb;
reg IMC_rstb;
wire [31:0] IMC_o;
wire [31:0] IMC_i;
e1000_register #(.init(32'h0)) IMC_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(IMC_wstb), .q_o(IMC_o)
);
assign IMC_i = {15'b0,IMC_o[16:0]};

reg RCTL_wstb;
reg RCTL_rstb;
wire [31:0] RCTL_o;
wire [31:0] RCTL_i;
e1000_register #(.init(32'h0)) RCTL_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(RCTL_wstb), .q_o(RCTL_o)
);
assign RCTL_i = {5'b0,RCTL_o[26:0]};

reg FCRTL_wstb;
reg FCRTL_rstb;
wire [31:0] FCRTL_o;
wire [31:0] FCRTL_i;
e1000_register #(.init(32'h0)) FCRTL_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(FCRTL_wstb), .q_o(FCRTL_o)
);
assign FCRTL_i = {FCRTL_o[31],15'b0,FCRTL_o[15:3],3'b0};

reg FCRTH_wstb;
reg FCRTH_rstb;
wire [31:0] FCRTH_o;
wire [31:0] FCRTH_i;
e1000_register #(.init(32'h0)) FCRTH_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(FCRTH_wstb), .q_o(FCRTH_o)
);
assign FCRTH_i = {FCRTH_o[31],15'b0,FCRTH_o[15:3],3'b0};

reg RDBAL_wstb;
reg RDBAL_rstb;
wire [31:0] RDBAL_o;
wire [31:0] RDBAL_i;
e1000_register #(.init(32'h0)) RDBAL_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(RDBAL_wstb), .q_o(RDBAL_o)
);
assign RDBAL_i = {RDBAL_o[31:4],4'b0};

reg RDBAH_wstb;
reg RDBAH_rstb;
wire [31:0] RDBAH_o;
wire [31:0] RDBAH_i;
e1000_register #(.init(32'h0)) RDBAH_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(RDBAH_wstb), .q_o(RDBAH_o)
);
assign RDBAH_i = RDBAH_o;

reg RDLEN_wstb;
reg RDLEN_rstb;
wire [31:0] RDLEN_o;
wire [31:0] RDLEN_i;
e1000_register #(.init(32'h0)) RDLEN_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(RDLEN_wstb), .q_o(RDLEN_o)
);
assign RDLEN_i = {12'b0,RDLEN_o[19:7],7'b0};

reg RDH_wstb;
reg RDH_rstb;
wire [31:0] RDH_o;
wire [31:0] RDH_i;
e1000_register #(.init(32'h0)) RDH_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(RDH_wstb), .q_o(RDH_o)
);
assign RDH_i = {16'b0,RDH_o[15:0]};

reg RDT_wstb;
reg RDT_rstb;
wire [31:0] RDT_o;
wire [31:0] RDT_i;
e1000_register #(.init(32'h0)) RDT_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(RDT_wstb), .q_o(RDT_o)
);
assign RDT_i = {16'b0,RDT_o[15:0]};

reg RDTR_wstb;
reg RDTR_rstb;
wire [31:0] RDTR_o;
wire [31:0] RDTR_i;
e1000_register #(.init(32'h0)) RDTR_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(RDTR_wstb), .q_o(RDTR_o)
);
assign RDTR_i = {RDTR_o[31],15'b0,RDTR_o[15:0]};

reg RADV_wstb;
reg RADV_rstb;
wire [31:0] RADV_o;
wire [31:0] RADV_i;
e1000_register #(.init(32'h0)) RADV_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(RADV_wstb), .q_o(RADV_o)
);
assign RADV_i = {RADV_o[31],15'b0,RADV_o[15:0]};

reg RSRPD_wstb;
reg RSRPD_rstb;
wire [31:0] RSRPD_o;
wire [31:0] RSRPD_i;
e1000_register #(.init(32'h0)) RSRPD_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(RSRPD_wstb), .q_o(RSRPD_o)
);
assign RSRPD_i = {20'b0,RSRPD_o[11:0]};

reg TCTL_wstb;
reg TCTL_rstb;
wire [31:0] TCTL_o;
wire [31:0] TCTL_i;
e1000_register #(.init(32'h0)) TCTL_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(TCTL_wstb), .q_o(TCTL_o)
);
assign TCTL_i = TCTL_o;

reg TIPG_wstb;
reg TIPG_rstb;
wire [31:0] TIPG_o;
wire [31:0] TIPG_i;
e1000_register #(.init(32'h0)) TIPG_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(TIPG_wstb), .q_o(TIPG_o)
);
assign TIPG_i = {2'b0,TIPG_o[29:0]};

// Should be ignored
reg AIFS_wstb;
reg AIFS_rstb;
wire [31:0] AIFS_o;
wire [31:0] AIFS_i;
e1000_register #(.init(32'h0)) AIFS_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(AIFS_wstb), .q_o(AIFS_o)
);
assign AIFS_i = {16'b0,AIFS_o[15:0]};

reg TDBAL_wstb;
reg TDBAL_rstb;
wire [31:0] TDBAL_o;
wire [31:0] TDBAL_i;
e1000_register #(.init(32'h0)) TDBAL_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(TDBAL_wstb), .q_o(TDBAL_o)
);
assign TDBAL_i = {TDBAL_o[31:4],4'b0};

reg TDBAH_wstb;
reg TDBAH_rstb;
wire [31:0] TDBAH_o;
wire [31:0] TDBAH_i;
e1000_register #(.init(32'h0)) TDBAH_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(TDBAH_wstb), .q_o(TDBAH_o)
);
assign TDBAH_i = TDBAH_o;

reg TDLEN_wstb;
reg TDLEN_rstb;
wire [31:0] TDLEN_o;
wire [31:0] TDLEN_i;
e1000_register #(.init(32'h0)) TDLEN_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(TDLEN_wstb), .q_o(TDLEN_o)
);
assign TDLEN_i = {12'b0,TDLEN_o[19:7],7'b0};

reg TDH_wstb;
reg TDH_rstb;
wire [31:0] TDH_o;
wire [31:0] TDH_i;
e1000_register #(.init(32'h0)) TDH_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(TDH_wstb), .q_o(TDH_o)
);
assign TDH_i = {16'b0,TDH_o[15:0]};

reg TDT_wstb;
reg TDT_rstb;
wire [31:0] TDT_o;
wire [31:0] TDT_i;
e1000_register #(.init(32'h0)) TDT_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(TDT_wstb), .q_o(TDT_o)
);
assign TDT_i = {16'b0,TDT_o[15:0]};

reg TIDV_wstb;
reg TIDV_rstb;
wire [31:0] TIDV_o;
wire [31:0] TIDV_i;
e1000_register #(.init(32'h0)) TIDV_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(TIDV_wstb), .q_o(TIDV_o)
);
assign TIDV_i = {16'b0,TIDV_o[15:0]};

reg TXDMAC_wstb;
reg TXDMAC_rstb;
wire [31:0] TXDMAC_o;
wire [31:0] TXDMAC_i;
e1000_register #(.init(32'h0000_0001)) TXDMAC_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(TXDMAC_wstb), .q_o(TXDMAC_o)
);
assign TXDMAC_i = {31'b0,TXDMAC_o[0]};

reg TXDCTL_wstb;
reg TXDCTL_rstb;
wire [31:0] TXDCTL_o;
wire [31:0] TXDCTL_i;
e1000_register #(.init(32'h0)) TXDCTL_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(TXDCTL_wstb), .q_o(TXDCTL_o)
);
assign TXDCTL_i = TXDCTL_o;

reg TADV_wstb;
reg TADV_rstb;
wire [31:0] TADV_o;
wire [31:0] TADV_i;
e1000_register #(.init(32'h0)) TADV_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(TADV_wstb), .q_o(TADV_o)
);
assign TADV_i = {16'b0,TADV_o[15:0]};

reg TSPMT_wstb;
reg TSPMT_rstb;
wire [31:0] TSPMT_o;
wire [31:0] TSPMT_i;
e1000_register #(.init(32'h0100_0400)) TSPMT_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(TSPMT_wstb), .q_o(TSPMT_o)
);
assign TSPMT_i = TSPMT_o;

reg RXDCTL_wstb;
reg RXDCTL_rstb;
wire [31:0] RXDCTL_o;
wire [31:0] RXDCTL_i;
e1000_register #(.init(32'h0101_0000)) RXDCTL_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(RXDCTL_wstb), .q_o(RXDCTL_o)
);
assign RXDCTL_i = RXDCTL_o;

reg RXCSUM_wstb;
reg RXCSUM_rstb;
wire [31:0] RXCSUM_o;
wire [31:0] RXCSUM_i;
e1000_register #(.init(32'h0)) RXCSUM_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(RXCSUM_wstb), .q_o(RXCSUM_o)
);
assign RXCSUM_i = RXCSUM_o;

reg MTA_wstb;
reg MTA_rstb;
wire [31:0] MTA_o;
wire [31:0] MTA_i;
assign MTA_o = write_data;
assign MTA_i = 'b0; // FIXIT: connect to RAM

reg RA_wstb;
reg RA_rstb;
wire [31:0] RA_o;
wire [31:0] RA_i;
assign RA_o = write_data;
assign RA_i = 'b0; // FIXIT: connect to RAM

reg VFTA_wstb;
reg VFTA_rstb;
wire [31:0] VFTA_o;
wire [31:0] VFTA_i;
assign VFTA_o = write_data;
assign VFTA_i = 'b0; // FIXIT: connect to RAM

reg WUC_wstb;
reg WUC_rstb;
wire [31:0] WUC_o;
wire [31:0] WUC_i;
e1000_register #(.init(32'h0)) WUC_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(WUC_wstb), .q_o(WUC_o)
);
assign WUC_i = {28'b0,WUC_o[3:0]};

reg WUFC_wstb;
reg WUFC_rstb;
wire [31:0] WUFC_o;
wire [31:0] WUFC_i;
e1000_register #(.init(32'h0)) WUFC_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(WUFC_wstb), .q_o(WUFC_o)
);
assign WUFC_i = {12'b0,WUFC_o[19:0]};

reg WUS_wstb;
reg WUS_rstb;
wire [31:0] WUS_o;
wire [31:0] WUS_i;
assign WUS_i = 'b0; // FIXIT: 

reg IPAV_wstb;
reg IPAV_rstb;
wire [31:0] IPAV_o;
wire [31:0] IPAV_i;
e1000_register #(.init(32'h0)) IPAV_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(IPAV_wstb), .q_o(IPAV_o)
);
assign IPAV_i = {15'b0,IPAV_o[16],12'b0,IPAV_o[3:0]};

reg IP4AT_wstb;
reg IP4AT_rstb;
wire [31:0] IP4AT_o;
wire [31:0] IP4AT_i;
assign IP4AT_o = write_data;
assign IP4AT_i = 'b0; // FIXIT: connect to RAM

reg IP6AT_wstb;
reg IP6AT_rstb;
wire [31:0] IP6AT_o;
wire [31:0] IP6AT_i;
assign IP6AT_o = write_data;
assign IP6AT_i = 'b0; // FIXIT: connect to RAM

reg WUPL_wstb;
reg WUPL_rstb;
wire [31:0] WUPL_o;
wire [31:0] WUPL_i;
e1000_register #(.init(32'h0)) WUPL_reg_i( 
	.clk_i(aclk), .arst_i(!aresetn), 
	.wbe_i(write_be), .d_i(write_data), 
	.srst_i(1'b0), .wen_i(WUPL_wstb), .q_o(WUPL_o)
);
assign WUPL_i = {20'b0,WUPL_o[11:0]};

reg WUPM_wstb;
reg WUPM_rstb;
wire [31:0] WUPM_o;
wire [31:0] WUPM_i;
assign WUPM_o = write_data;
assign WUPM_i = 'b0; 

reg FFLT_wstb;
reg FFLT_rstb;
wire [31:0] FFLT_o;
wire [31:0] FFLT_i;
assign FFLT_o = write_data;
assign FFLT_i = 'b0; 

reg FFMT_wstb;
reg FFMT_rstb;
wire [31:0] FFMT_o;
wire [31:0] FFMT_i;
assign FFMT_o = write_data;
assign FFMT_i = 'b0; 

reg FFVT_wstb;
reg FFVT_rstb;
wire [31:0] FFVT_o;
wire [31:0] FFVT_i;
assign FFVT_o = write_data;
assign FFVT_i = 'b0; 

reg CRCERRS_wstb;
reg CRCERRS_rstb;
wire [31:0] CRCERRS_i;
assign CRCERRS_i = 'b0; 

reg ALGNERRC_wstb;
reg ALGNERRC_rstb;
wire [31:0] ALGNERRC_i;
assign ALGNERRC_i = 'b0; 

reg SYMERRS_wstb;
reg SYMERRS_rstb;
wire [31:0] SYMERRS_i;
assign SYMERRS_i = 'b0; 

reg RXERRC_wstb;
reg RXERRC_rstb;
wire [31:0] RXERRC_i;
assign RXERRC_i = 'b0; 

reg MPC_wstb;
reg MPC_rstb;
wire [31:0] MPC_i;
assign MPC_i = 'b0; 

reg SCC_wstb;
reg SCC_rstb;
wire [31:0] SCC_i;
assign SCC_i = 'b0; 

reg ECOL_wstb;
reg ECOL_rstb;
wire [31:0] ECOL_i;
assign ECOL_i = 'b0; 

reg MCC_wstb;
reg MCC_rstb;
wire [31:0] MCC_i;
assign MCC_i = 'b0; 

reg LATECOL_wstb;
reg LATECOL_rstb;
wire [31:0] LATECOL_i;
assign LATECOL_i = 'b0; 

reg COLC_wstb;
reg COLC_rstb;
wire [31:0] COLC_i;
assign COLC_i = 'b0; 

reg DC_wstb;
reg DC_rstb;
wire [31:0] DC_i;
assign DC_i = 'b0; 

reg TNCRS_wstb;
reg TNCRS_rstb;
wire [31:0] TNCRS_i;
assign TNCRS_i = 'b0; 

reg SEC_wstb;
reg SEC_rstb;
wire [31:0] SEC_i;
assign SEC_i = 'b0; 

reg CEXTERR_wstb;
reg CEXTERR_rstb;
wire [31:0] CEXTERR_i;
assign CEXTERR_i = 'b0; 

reg RLEC_wstb;
reg RLEC_rstb;
wire [31:0] RLEC_i;
assign RLEC_i = 'b0; 

reg XONRXC_wstb;
reg XONRXC_rstb;
wire [31:0] XONRXC_i;
assign XONRXC_i = 'b0; 

reg XONTXC_wstb;
reg XONTXC_rstb;
wire [31:0] XONTXC_i;
assign XONTXC_i = 'b0; 

reg XOFFRXC_wstb;
reg XOFFRXC_rstb;
wire [31:0] XOFFRXC_i;
assign XOFFRXC_i = 'b0; 

reg XOFFTXC_wstb;
reg XOFFTXC_rstb;
wire [31:0] XOFFTXC_i;
assign XOFFTXC_i = 'b0; 

reg FCRUC_wstb;
reg FCRUC_rstb;
wire [31:0] FCRUC_i;
assign FCRUC_i = 'b0; 

reg PRC64_wstb;
reg PRC64_rstb;
wire [31:0] PRC64_i;
assign PRC64_i = 'b0; 

reg PRC127_wstb;
reg PRC127_rstb;
wire [31:0] PRC127_i;
assign PRC127_i = 'b0; 

reg PRC255_wstb;
reg PRC255_rstb;
wire [31:0] PRC255_i;
assign PRC255_i = 'b0; 

reg PRC511_wstb;
reg PRC511_rstb;
wire [31:0] PRC511_i;
assign PRC511_i = 'b0; 

reg PRC1023_wstb;
reg PRC1023_rstb;
wire [31:0] PRC1023_i;
assign PRC1023_i = 'b0; 

reg PRC1522_wstb;
reg PRC1522_rstb;
wire [31:0] PRC1522_i;
assign PRC1522_i = 'b0; 

reg GPRC_wstb;
reg GPRC_rstb;
wire [31:0] GPRC_i;
assign GPRC_i = 'b0; 

reg BPRC_wstb;
reg BPRC_rstb;
wire [31:0] BPRC_i;
assign BPRC_i = 'b0; 

reg MPRC_wstb;
reg MPRC_rstb;
wire [31:0] MPRC_i;
assign MPRC_i = 'b0; 

reg GPTC_wstb;
reg GPTC_rstb;
wire [31:0] GPTC_i;
assign GPTC_i = 'b0; 

reg GORCL_wstb;
reg GORCL_rstb;
wire [31:0] GORCL_i;
assign GORCL_i = 'b0; 

reg GORCH_wstb;
reg GORCH_rstb;
wire [31:0] GORCH_i;
assign GORCH_i = 'b0; 

reg GOTCL_wstb;
reg GOTCL_rstb;
wire [31:0] GOTCL_i;
assign GOTCL_i = 'b0; 

reg GOTCH_wstb;
reg GOTCH_rstb;
wire [31:0] GOTCH_i;
assign GOTCH_i = 'b0; 

reg RNBC_wstb;
reg RNBC_rstb;
wire [31:0] RNBC_i;
assign RNBC_i = 'b0; 

reg RUC_wstb;
reg RUC_rstb;
wire [31:0] RUC_i;
assign RUC_i = 'b0; 

reg RFC_wstb;
reg RFC_rstb;
wire [31:0] RFC_i;
assign RFC_i = 'b0; 

reg ROC_wstb;
reg ROC_rstb;
wire [31:0] ROC_i;
assign ROC_i = 'b0; 

reg RJC_wstb;
reg RJC_rstb;
wire [31:0] RJC_i;
assign RJC_i = 'b0; 

reg MGTPRC_wstb;
reg MGTPRC_rstb;
wire [31:0] MGTPRC_i;
assign MGTPRC_i = 'b0; 

reg MGTPDC_wstb;
reg MGTPDC_rstb;
wire [31:0] MGTPDC_i;
assign MGTPDC_i = 'b0; 

reg MGTPTC_wstb;
reg MGTPTC_rstb;
wire [31:0] MGTPTC_i;
assign MGTPTC_i = 'b0; 

reg TORL_wstb;
reg TORL_rstb;
wire [31:0] TORL_i;
assign TORL_i = 'b0; 

reg TORH_wstb;
reg TORH_rstb;
wire [31:0] TORH_i;
assign TORH_i = 'b0; 

reg TOTL_wstb;
reg TOTL_rstb;
wire [31:0] TOTL_i;
assign TOTL_i = 'b0; 

reg TOTH_wstb;
reg TOTH_rstb;
wire [31:0] TOTH_i;
assign TOTH_i = 'b0; 

reg TPR_wstb;
reg TPR_rstb;
wire [31:0] TPR_i;
assign TPR_i = 'b0; 

reg TPT_wstb;
reg TPT_rstb;
wire [31:0] TPT_i;
assign TPT_i = 'b0; 

reg PTC64_wstb;
reg PTC64_rstb;
wire [31:0] PTC64_i;
assign PTC64_i = 'b0; 

reg PTC127_wstb;
reg PTC127_rstb;
wire [31:0] PTC127_i;
assign PTC127_i = 'b0; 

reg PTC255_wstb;
reg PTC255_rstb;
wire [31:0] PTC255_i;
assign PTC255_i = 'b0; 

reg PTC511_wstb;
reg PTC511_rstb;
wire [31:0] PTC511_i;
assign PTC511_i = 'b0; 

reg PTC1023_wstb;
reg PTC1023_rstb;
wire [31:0] PTC1023_i;
assign PTC1023_i = 'b0; 

reg PTC1522_wstb;
reg PTC1522_rstb;
wire [31:0] PTC1522_i;
assign PTC1522_i = 'b0; 

reg MPTC_wstb;
reg MPTC_rstb;
wire [31:0] MPTC_i;
assign MPTC_i = 'b0; 

reg BPTC_wstb;
reg BPTC_rstb;
wire [31:0] BPTC_i;
assign BPTC_i = 'b0; 

reg TSCTC_wstb;
reg TSCTC_rstb;
wire [31:0] TSCTC_i;
assign TSCTC_i = 'b0; 

reg TSCTFC_wstb;
reg TSCTFC_rstb;
wire [31:0] TSCTFC_i;
assign TSCTFC_i = 'b0; 


always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		CTRL_wstb <= 1'b0;
		STATUS_wstb <= 1'b0;
		EECD_wstb <= 1'b0;
		EERD_wstb <= 1'b0;
		FLA_wstb <= 1'b0;
		CTRL_EXT_wstb <= 1'b0;
		MDIC_wstb <= 1'b0;
		FCAL_wstb <= 1'b0;
		FCAH_wstb <= 1'b0;
		FCT_wstb <= 1'b0;
		VET_wstb <= 1'b0;
		FCTTV_wstb <= 1'b0;
		TXCW_wstb <= 1'b0;
		RXCW_wstb <= 1'b0;
		LEDCTL_wstb <= 1'b0;
		PBA_wstb <= 1'b0;
		ICR_wstb <= 1'b0;
		ITR_wstb <= 1'b0;
		ICS_wstb <= 1'b0;
		IMS_wstb <= 1'b0;
		IMC_wstb <= 1'b0;
		RCTL_wstb <= 1'b0;
		FCRTL_wstb <= 1'b0;
		FCRTH_wstb <= 1'b0;
		RDBAL_wstb <= 1'b0;
		RDBAH_wstb <= 1'b0;
		RDLEN_wstb <= 1'b0;
		RDH_wstb <= 1'b0;
		RDT_wstb <= 1'b0;
		RDTR_wstb <= 1'b0;
		RADV_wstb <= 1'b0;
		RSRPD_wstb <= 1'b0;
		TCTL_wstb <= 1'b0;
		TIPG_wstb <= 1'b0;
		AIFS_wstb <= 1'b0;
		TDBAL_wstb <= 1'b0;
		TDBAH_wstb <= 1'b0;
		TDLEN_wstb <= 1'b0;
		TDH_wstb <= 1'b0;
		TDT_wstb <= 1'b0;
		TIDV_wstb <= 1'b0;
		TXDMAC_wstb <= 1'b0;
		TXDCTL_wstb <= 1'b0;
		TADV_wstb <= 1'b0;
		TSPMT_wstb <= 1'b0;
		RXDCTL_wstb <= 1'b0;
		RXCSUM_wstb <= 1'b0;
		MTA_wstb <= 1'b0;
		RA_wstb <= 1'b0;
		VFTA_wstb <= 1'b0;
		WUC_wstb <= 1'b0;
		WUFC_wstb <= 1'b0;
		WUS_wstb <= 1'b0;
		IPAV_wstb <= 1'b0;
		IP4AT_wstb <= 1'b0;
		IP6AT_wstb <= 1'b0;
		WUPL_wstb <= 1'b0;
		WUPM_wstb <= 1'b0;
		FFLT_wstb <= 1'b0;
		FFMT_wstb <= 1'b0;
		FFVT_wstb <= 1'b0;
		CRCERRS_wstb <= 1'b0;
		ALGNERRC_wstb <= 1'b0;
		SYMERRS_wstb <= 1'b0;
		RXERRC_wstb <= 1'b0;
		MPC_wstb <= 1'b0;
		SCC_wstb <= 1'b0;
		ECOL_wstb <= 1'b0;
		MCC_wstb <= 1'b0;
		LATECOL_wstb <= 1'b0;
		COLC_wstb <= 1'b0;
		DC_wstb <= 1'b0;
		TNCRS_wstb <= 1'b0;
		SEC_wstb <= 1'b0;
		CEXTERR_wstb <= 1'b0;
		RLEC_wstb <= 1'b0;
		XONRXC_wstb <= 1'b0;
		XONTXC_wstb <= 1'b0;
		XOFFRXC_wstb <= 1'b0;
		XOFFTXC_wstb <= 1'b0;
		FCRUC_wstb <= 1'b0;
		PRC64_wstb <= 1'b0;
		PRC127_wstb <= 1'b0;
		PRC255_wstb <= 1'b0;
		PRC511_wstb <= 1'b0;
		PRC1023_wstb <= 1'b0;
		PRC1522_wstb <= 1'b0;
		GPRC_wstb <= 1'b0;
		BPRC_wstb <= 1'b0;
		MPRC_wstb <= 1'b0;
		GPTC_wstb <= 1'b0;
		GORCL_wstb <= 1'b0;
		GORCH_wstb <= 1'b0;
		GOTCL_wstb <= 1'b0;
		GOTCH_wstb <= 1'b0;
		RNBC_wstb <= 1'b0;
		RUC_wstb <= 1'b0;
		RFC_wstb <= 1'b0;
		ROC_wstb <= 1'b0;
		RJC_wstb <= 1'b0;
		MGTPRC_wstb <= 1'b0;
		MGTPDC_wstb <= 1'b0;
		MGTPTC_wstb <= 1'b0;
		TORL_wstb <= 1'b0;
		TORH_wstb <= 1'b0;
		TOTL_wstb <= 1'b0;
		TOTH_wstb <= 1'b0;
		TPR_wstb <= 1'b0;
		TPT_wstb <= 1'b0;
		PTC64_wstb <= 1'b0;
		PTC127_wstb <= 1'b0;
		PTC255_wstb <= 1'b0;
		PTC511_wstb <= 1'b0;
		PTC1023_wstb <= 1'b0;
		PTC1522_wstb <= 1'b0;
		MPTC_wstb <= 1'b0;
		BPTC_wstb <= 1'b0;
		TSCTC_wstb <= 1'b0;
		TSCTFC_wstb <= 1'b0;
	end
	else if(write_enable) begin
		casex({write_addr[15:2],2'b0}) /* synthesis parallel_case */
			16'h0000: CTRL_wstb <= 1'b1;
			16'h0008: STATUS_wstb <= 1'b1;
			16'h0010: EECD_wstb <= 1'b1;
			16'h0014: EERD_wstb <= 1'b1;
			16'h001C: FLA_wstb <= 1'b1;
			16'h0018: CTRL_EXT_wstb <= 1'b1;
			16'h0020: MDIC_wstb <= 1'b1;
			16'h0028: FCAL_wstb <= 1'b1;
			16'h002C: FCAH_wstb <= 1'b1;
			16'h0030: FCT_wstb <= 1'b1;
			16'h0038: VET_wstb <= 1'b1;
			16'h0170: FCTTV_wstb <= 1'b1;
			16'h0178: TXCW_wstb <= 1'b1;
			16'h0180: RXCW_wstb <= 1'b1;
			16'h0E00: LEDCTL_wstb <= 1'b1;
			16'h1000: PBA_wstb <= 1'b1;
			16'h00C0: ICR_wstb <= 1'b1;
			16'h00C4: ITR_wstb <= 1'b1;
			16'h00C8: ICS_wstb <= 1'b1;
			16'h00D0: IMS_wstb <= 1'b1;
			16'h00D8: IMC_wstb <= 1'b1;
			16'h0100: RCTL_wstb <= 1'b1;
			16'h2160: FCRTL_wstb <= 1'b1;
			16'h2168: FCRTH_wstb <= 1'b1;
			16'h2800: RDBAL_wstb <= 1'b1;
			16'h2804: RDBAH_wstb <= 1'b1;
			16'h2808: RDLEN_wstb <= 1'b1;
			16'h2810: RDH_wstb <= 1'b1;
			16'h2818: RDT_wstb <= 1'b1;
			16'h2820: RDTR_wstb <= 1'b1;
			16'h282C: RADV_wstb <= 1'b1;
			16'h2C00: RSRPD_wstb <= 1'b1;
			16'h0400: TCTL_wstb <= 1'b1;
			16'h0410: TIPG_wstb <= 1'b1;
			16'h0458: AIFS_wstb <= 1'b1;
			16'h3800: TDBAL_wstb <= 1'b1;
			16'h3804: TDBAH_wstb <= 1'b1;
			16'h3808: TDLEN_wstb <= 1'b1;
			16'h3810: TDH_wstb <= 1'b1;
			16'h3818: TDT_wstb <= 1'b1;
			16'h3820: TIDV_wstb <= 1'b1;
			16'h3000: TXDMAC_wstb <= 1'b1;
			16'h3828: TXDCTL_wstb <= 1'b1;
			16'h282C: TADV_wstb <= 1'b1;
			16'h3830: TSPMT_wstb <= 1'b1;
			16'h2828: RXDCTL_wstb <= 1'b1;
			16'h5000: RXCSUM_wstb <= 1'b1;
			16'b0101_001x_xxxx_xxxx: MTA_wstb <= 1'b1;
			16'b0101_0100_0xxx_xxxx: RA_wstb <= 1'b1;
			16'b0101_011x_xxxx_xxxx: VFTA_wstb <= 1'b1;
			16'h5800: WUC_wstb <= 1'b1;
			16'h5808: WUFC_wstb <= 1'b1;
			16'h5810: WUS_wstb <= 1'b1;
			16'h5838: IPAV_wstb <= 1'b1;
			16'b0101_1000_010x_xxxx: IP4AT_wstb <= 1'b1;
			16'b0101_1000_1000_xxxx: IP6AT_wstb <= 1'b1;
			16'h5900: WUPL_wstb <= 1'b1;
			16'b0101_1010_0xxx_xxxx: WUPM_wstb <= 1'b1;
			16'b0101_1111_000x_xxxx: FFLT_wstb <= 1'b1;
			16'b1001_11xx_xxxx_xxxx: FFMT_wstb <= 1'b1;
			16'b1001_10xx_xxxx_xxxx: FFVT_wstb <= 1'b1;
			16'h4000: CRCERRS_wstb <= 1'b1;
			16'h4004: ALGNERRC_wstb <= 1'b1;
			16'h4008: SYMERRS_wstb <= 1'b1;
			16'h400C: RXERRC_wstb <= 1'b1;
			16'h4010: MPC_wstb <= 1'b1;
			16'h4014: SCC_wstb <= 1'b1;
			16'h4018: ECOL_wstb <= 1'b1;
			16'h401C: MCC_wstb <= 1'b1;
			16'h4020: LATECOL_wstb <= 1'b1;
			16'h4028: COLC_wstb <= 1'b1;
			16'h4030: DC_wstb <= 1'b1;
			16'h4034: TNCRS_wstb <= 1'b1;
			16'h4038: SEC_wstb <= 1'b1;
			16'h403C: CEXTERR_wstb <= 1'b1;
			16'h4040: RLEC_wstb <= 1'b1;
			16'h4048: XONRXC_wstb <= 1'b1;
			16'h404C: XONTXC_wstb <= 1'b1;
			16'h4050: XOFFRXC_wstb <= 1'b1;
			16'h4054: XOFFTXC_wstb <= 1'b1;
			16'h4058: FCRUC_wstb <= 1'b1;
			16'h405C: PRC64_wstb <= 1'b1;
			16'h4060: PRC127_wstb <= 1'b1;
			16'h4064: PRC255_wstb <= 1'b1;
			16'h4068: PRC511_wstb <= 1'b1;
			16'h406C: PRC1023_wstb <= 1'b1;
			16'h4070: PRC1522_wstb <= 1'b1;
			16'h4074: GPRC_wstb <= 1'b1;
			16'h4078: BPRC_wstb <= 1'b1;
			16'h407C: MPRC_wstb <= 1'b1;
			16'h4080: GPTC_wstb <= 1'b1;
			16'h4088: GORCL_wstb <= 1'b1;
			16'h408C: GORCH_wstb <= 1'b1;
			16'h4090: GOTCL_wstb <= 1'b1;
			16'h4094: GOTCH_wstb <= 1'b1;
			16'h40A0: RNBC_wstb <= 1'b1;
			16'h40A4: RUC_wstb <= 1'b1;
			16'h40A8: RFC_wstb <= 1'b1;
			16'h40AC: ROC_wstb <= 1'b1;
			16'h40B0: RJC_wstb <= 1'b1;
			16'h40B4: MGTPRC_wstb <= 1'b1;
			16'h40B8: MGTPDC_wstb <= 1'b1;
			16'h40BC: MGTPTC_wstb <= 1'b1;
			16'h40C0: TORL_wstb <= 1'b1;
			16'h40C4: TORH_wstb <= 1'b1;
			16'h40C8: TOTL_wstb <= 1'b1;
			16'h40CC: TOTH_wstb <= 1'b1;
			16'h40D0: TPR_wstb <= 1'b1;
			16'h40D4: TPT_wstb <= 1'b1;
			16'h40D8: PTC64_wstb <= 1'b1;
			16'h40DC: PTC127_wstb <= 1'b1;
			16'h40E0: PTC255_wstb <= 1'b1;
			16'h40E4: PTC511_wstb <= 1'b1;
			16'h40E8: PTC1023_wstb <= 1'b1;
			16'h40EC: PTC1522_wstb <= 1'b1;
			16'h40F0: MPTC_wstb <= 1'b1;
			16'h40F4: BPTC_wstb <= 1'b1;
			16'h40F8: TSCTC_wstb <= 1'b1;
			16'h40FC: TSCTFC_wstb <= 1'b1;

		endcase
	end
	else begin
		CTRL_wstb <= 1'b0;
		STATUS_wstb <= 1'b0;
		EECD_wstb <= 1'b0;
		EERD_wstb <= 1'b0;
		FLA_wstb <= 1'b0;
		CTRL_EXT_wstb <= 1'b0;
		MDIC_wstb <= 1'b0;
		FCAL_wstb <= 1'b0;
		FCAH_wstb <= 1'b0;
		FCT_wstb <= 1'b0;
		VET_wstb <= 1'b0;
		FCTTV_wstb <= 1'b0;
		TXCW_wstb <= 1'b0;
		RXCW_wstb <= 1'b0;
		LEDCTL_wstb <= 1'b0;
		PBA_wstb <= 1'b0;
		ICR_wstb <= 1'b0;
		ITR_wstb <= 1'b0;
		ICS_wstb <= 1'b0;
		IMS_wstb <= 1'b0;
		IMC_wstb <= 1'b0;
		RCTL_wstb <= 1'b0;
		FCRTL_wstb <= 1'b0;
		FCRTH_wstb <= 1'b0;
		RDBAL_wstb <= 1'b0;
		RDBAH_wstb <= 1'b0;
		RDLEN_wstb <= 1'b0;
		RDH_wstb <= 1'b0;
		RDT_wstb <= 1'b0;
		RDTR_wstb <= 1'b0;
		RADV_wstb <= 1'b0;
		RSRPD_wstb <= 1'b0;
		TCTL_wstb <= 1'b0;
		TIPG_wstb <= 1'b0;
		AIFS_wstb <= 1'b0;
		TDBAL_wstb <= 1'b0;
		TDBAH_wstb <= 1'b0;
		TDLEN_wstb <= 1'b0;
		TDH_wstb <= 1'b0;
		TDT_wstb <= 1'b0;
		TIDV_wstb <= 1'b0;
		TXDMAC_wstb <= 1'b0;
		TXDCTL_wstb <= 1'b0;
		TADV_wstb <= 1'b0;
		TSPMT_wstb <= 1'b0;
		RXDCTL_wstb <= 1'b0;
		RXCSUM_wstb <= 1'b0;
		MTA_wstb <= 1'b0;
		RA_wstb <= 1'b0;
		VFTA_wstb <= 1'b0;
		WUC_wstb <= 1'b0;
		WUFC_wstb <= 1'b0;
		WUS_wstb <= 1'b0;
		IPAV_wstb <= 1'b0;
		IP4AT_wstb <= 1'b0;
		IP6AT_wstb <= 1'b0;
		WUPL_wstb <= 1'b0;
		WUPM_wstb <= 1'b0;
		FFLT_wstb <= 1'b0;
		FFMT_wstb <= 1'b0;
		FFVT_wstb <= 1'b0;
		CRCERRS_wstb <= 1'b0;
		ALGNERRC_wstb <= 1'b0;
		SYMERRS_wstb <= 1'b0;
		RXERRC_wstb <= 1'b0;
		MPC_wstb <= 1'b0;
		SCC_wstb <= 1'b0;
		ECOL_wstb <= 1'b0;
		MCC_wstb <= 1'b0;
		LATECOL_wstb <= 1'b0;
		COLC_wstb <= 1'b0;
		DC_wstb <= 1'b0;
		TNCRS_wstb <= 1'b0;
		SEC_wstb <= 1'b0;
		CEXTERR_wstb <= 1'b0;
		RLEC_wstb <= 1'b0;
		XONRXC_wstb <= 1'b0;
		XONTXC_wstb <= 1'b0;
		XOFFRXC_wstb <= 1'b0;
		XOFFTXC_wstb <= 1'b0;
		FCRUC_wstb <= 1'b0;
		PRC64_wstb <= 1'b0;
		PRC127_wstb <= 1'b0;
		PRC255_wstb <= 1'b0;
		PRC511_wstb <= 1'b0;
		PRC1023_wstb <= 1'b0;
		PRC1522_wstb <= 1'b0;
		GPRC_wstb <= 1'b0;
		BPRC_wstb <= 1'b0;
		MPRC_wstb <= 1'b0;
		GPTC_wstb <= 1'b0;
		GORCL_wstb <= 1'b0;
		GORCH_wstb <= 1'b0;
		GOTCL_wstb <= 1'b0;
		GOTCH_wstb <= 1'b0;
		RNBC_wstb <= 1'b0;
		RUC_wstb <= 1'b0;
		RFC_wstb <= 1'b0;
		ROC_wstb <= 1'b0;
		RJC_wstb <= 1'b0;
		MGTPRC_wstb <= 1'b0;
		MGTPDC_wstb <= 1'b0;
		MGTPTC_wstb <= 1'b0;
		TORL_wstb <= 1'b0;
		TORH_wstb <= 1'b0;
		TOTL_wstb <= 1'b0;
		TOTH_wstb <= 1'b0;
		TPR_wstb <= 1'b0;
		TPT_wstb <= 1'b0;
		PTC64_wstb <= 1'b0;
		PTC127_wstb <= 1'b0;
		PTC255_wstb <= 1'b0;
		PTC511_wstb <= 1'b0;
		PTC1023_wstb <= 1'b0;
		PTC1522_wstb <= 1'b0;
		MPTC_wstb <= 1'b0;
		BPTC_wstb <= 1'b0;
		TSCTC_wstb <= 1'b0;
		TSCTFC_wstb <= 1'b0;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		CTRL_rstb <= 1'b0;
		STATUS_rstb <= 1'b0;
		EECD_rstb <= 1'b0;
		EERD_rstb <= 1'b0;
		FLA_rstb <= 1'b0;
		CTRL_EXT_rstb <= 1'b0;
		MDIC_rstb <= 1'b0;
		FCAL_rstb <= 1'b0;
		FCAH_rstb <= 1'b0;
		FCT_rstb <= 1'b0;
		VET_rstb <= 1'b0;
		FCTTV_rstb <= 1'b0;
		TXCW_rstb <= 1'b0;
		RXCW_rstb <= 1'b0;
		LEDCTL_rstb <= 1'b0;
		PBA_rstb <= 1'b0;
		ICR_rstb <= 1'b0;
		ITR_rstb <= 1'b0;
		ICS_rstb <= 1'b0;
		IMS_rstb <= 1'b0;
		IMC_rstb <= 1'b0;
		RCTL_rstb <= 1'b0;
		FCRTL_rstb <= 1'b0;
		FCRTH_rstb <= 1'b0;
		RDBAL_rstb <= 1'b0;
		RDBAH_rstb <= 1'b0;
		RDLEN_rstb <= 1'b0;
		RDH_rstb <= 1'b0;
		RDT_rstb <= 1'b0;
		RDTR_rstb <= 1'b0;
		RADV_rstb <= 1'b0;
		RSRPD_rstb <= 1'b0;
		TCTL_rstb <= 1'b0;
		TIPG_rstb <= 1'b0;
		AIFS_rstb <= 1'b0;
		TDBAL_rstb <= 1'b0;
		TDBAH_rstb <= 1'b0;
		TDLEN_rstb <= 1'b0;
		TDH_rstb <= 1'b0;
		TDT_rstb <= 1'b0;
		TIDV_rstb <= 1'b0;
		TXDMAC_rstb <= 1'b0;
		TXDCTL_rstb <= 1'b0;
		TADV_rstb <= 1'b0;
		TSPMT_rstb <= 1'b0;
		RXDCTL_rstb <= 1'b0;
		RXCSUM_rstb <= 1'b0;
		MTA_rstb <= 1'b0;
		RA_rstb <= 1'b0;
		VFTA_rstb <= 1'b0;
		WUC_rstb <= 1'b0;
		WUFC_rstb <= 1'b0;
		WUS_rstb <= 1'b0;
		IPAV_rstb <= 1'b0;
		IP4AT_rstb <= 1'b0;
		IP6AT_rstb <= 1'b0;
		WUPL_rstb <= 1'b0;
		WUPM_rstb <= 1'b0;
		FFLT_rstb <= 1'b0;
		FFMT_rstb <= 1'b0;
		FFVT_rstb <= 1'b0;
		CRCERRS_rstb <= 1'b0;
		ALGNERRC_rstb <= 1'b0;
		SYMERRS_rstb <= 1'b0;
		RXERRC_rstb <= 1'b0;
		MPC_rstb <= 1'b0;
		SCC_rstb <= 1'b0;
		ECOL_rstb <= 1'b0;
		MCC_rstb <= 1'b0;
		LATECOL_rstb <= 1'b0;
		COLC_rstb <= 1'b0;
		DC_rstb <= 1'b0;
		TNCRS_rstb <= 1'b0;
		SEC_rstb <= 1'b0;
		CEXTERR_rstb <= 1'b0;
		RLEC_rstb <= 1'b0;
		XONRXC_rstb <= 1'b0;
		XONTXC_rstb <= 1'b0;
		XOFFRXC_rstb <= 1'b0;
		XOFFTXC_rstb <= 1'b0;
		FCRUC_rstb <= 1'b0;
		PRC64_rstb <= 1'b0;
		PRC127_rstb <= 1'b0;
		PRC255_rstb <= 1'b0;
		PRC511_rstb <= 1'b0;
		PRC1023_rstb <= 1'b0;
		PRC1522_rstb <= 1'b0;
		GPRC_rstb <= 1'b0;
		BPRC_rstb <= 1'b0;
		MPRC_rstb <= 1'b0;
		GPTC_rstb <= 1'b0;
		GORCL_rstb <= 1'b0;
		GORCH_rstb <= 1'b0;
		GOTCL_rstb <= 1'b0;
		GOTCH_rstb <= 1'b0;
		RNBC_rstb <= 1'b0;
		RUC_rstb <= 1'b0;
		RFC_rstb <= 1'b0;
		ROC_rstb <= 1'b0;
		RJC_rstb <= 1'b0;
		MGTPRC_rstb <= 1'b0;
		MGTPDC_rstb <= 1'b0;
		MGTPTC_rstb <= 1'b0;
		TORL_rstb <= 1'b0;
		TORH_rstb <= 1'b0;
		TOTL_rstb <= 1'b0;
		TOTH_rstb <= 1'b0;
		TPR_rstb <= 1'b0;
		TPT_rstb <= 1'b0;
		PTC64_rstb <= 1'b0;
		PTC127_rstb <= 1'b0;
		PTC255_rstb <= 1'b0;
		PTC511_rstb <= 1'b0;
		PTC1023_rstb <= 1'b0;
		PTC1522_rstb <= 1'b0;
		MPTC_rstb <= 1'b0;
		BPTC_rstb <= 1'b0;
		TSCTC_rstb <= 1'b0;
		TSCTFC_rstb <= 1'b0;
	end
	else if(read_enable) begin
		casex({read_addr[15:2],2'b0}) /* synthesis parallel_case */
			16'h0000: CTRL_rstb <= 1'b1;
			16'h0008: STATUS_rstb <= 1'b1;
			16'h0010: EECD_rstb <= 1'b1;
			16'h0014: EERD_rstb <= 1'b1;
			16'h001C: FLA_rstb <= 1'b1;
			16'h0018: CTRL_EXT_rstb <= 1'b1;
			16'h0020: MDIC_rstb <= 1'b1;
			16'h0028: FCAL_rstb <= 1'b1;
			16'h002C: FCAH_rstb <= 1'b1;
			16'h0030: FCT_rstb <= 1'b1;
			16'h0038: VET_rstb <= 1'b1;
			16'h0170: FCTTV_rstb <= 1'b1;
			16'h0178: TXCW_rstb <= 1'b1;
			16'h0180: RXCW_rstb <= 1'b1;
			16'h0E00: LEDCTL_rstb <= 1'b1;
			16'h1000: PBA_rstb <= 1'b1;
			16'h00C0: ICR_rstb <= 1'b1;
			16'h00C4: ITR_rstb <= 1'b1;
			16'h00C8: ICS_rstb <= 1'b1;
			16'h00D0: IMS_rstb <= 1'b1;
			16'h00D8: IMC_rstb <= 1'b1;
			16'h0100: RCTL_rstb <= 1'b1;
			16'h2160: FCRTL_rstb <= 1'b1;
			16'h2168: FCRTH_rstb <= 1'b1;
			16'h2800: RDBAL_rstb <= 1'b1;
			16'h2804: RDBAH_rstb <= 1'b1;
			16'h2808: RDLEN_rstb <= 1'b1;
			16'h2810: RDH_rstb <= 1'b1;
			16'h2818: RDT_rstb <= 1'b1;
			16'h2820: RDTR_rstb <= 1'b1;
			16'h282C: RADV_rstb <= 1'b1;
			16'h2C00: RSRPD_rstb <= 1'b1;
			16'h0400: TCTL_rstb <= 1'b1;
			16'h0410: TIPG_rstb <= 1'b1;
			16'h0458: AIFS_rstb <= 1'b1;
			16'h3800: TDBAL_rstb <= 1'b1;
			16'h3804: TDBAH_rstb <= 1'b1;
			16'h3808: TDLEN_rstb <= 1'b1;
			16'h3810: TDH_rstb <= 1'b1;
			16'h3818: TDT_rstb <= 1'b1;
			16'h3820: TIDV_rstb <= 1'b1;
			16'h3000: TXDMAC_rstb <= 1'b1;
			16'h3828: TXDCTL_rstb <= 1'b1;
			16'h282C: TADV_rstb <= 1'b1;
			16'h3830: TSPMT_rstb <= 1'b1;
			16'h2828: RXDCTL_rstb <= 1'b1;
			16'h5000: RXCSUM_rstb <= 1'b1;
			16'b0101_001x_xxxx_xxxx: MTA_rstb <= 1'b1;
			16'b0101_0100_0xxx_xxxx: RA_rstb <= 1'b1;
			16'b0101_011x_xxxx_xxxx: VFTA_rstb <= 1'b1;
			16'h5800: WUC_rstb <= 1'b1;
			16'h5808: WUFC_rstb <= 1'b1;
			16'h5810: WUS_rstb <= 1'b1;
			16'h5838: IPAV_rstb <= 1'b1;
			16'b0101_1000_010x_xxxx: IP4AT_rstb <= 1'b1;
			16'b0101_1000_1000_xxxx: IP6AT_rstb <= 1'b1;
			16'h5900: WUPL_rstb <= 1'b1;
			16'b0101_1010_0xxx_xxxx: WUPM_rstb <= 1'b1;
			16'b0101_1111_000x_xxxx: FFLT_rstb <= 1'b1;
			16'b1001_11xx_xxxx_xxxx: FFMT_rstb <= 1'b1;
			16'b1001_10xx_xxxx_xxxx: FFVT_rstb <= 1'b1;
			16'h4000: CRCERRS_rstb <= 1'b1;
			16'h4004: ALGNERRC_rstb <= 1'b1;
			16'h4008: SYMERRS_rstb <= 1'b1;
			16'h400C: RXERRC_rstb <= 1'b1;
			16'h4010: MPC_rstb <= 1'b1;
			16'h4014: SCC_rstb <= 1'b1;
			16'h4018: ECOL_rstb <= 1'b1;
			16'h401C: MCC_rstb <= 1'b1;
			16'h4020: LATECOL_rstb <= 1'b1;
			16'h4028: COLC_rstb <= 1'b1;
			16'h4030: DC_rstb <= 1'b1;
			16'h4034: TNCRS_rstb <= 1'b1;
			16'h4038: SEC_rstb <= 1'b1;
			16'h403C: CEXTERR_rstb <= 1'b1;
			16'h4040: RLEC_rstb <= 1'b1;
			16'h4048: XONRXC_rstb <= 1'b1;
			16'h404C: XONTXC_rstb <= 1'b1;
			16'h4050: XOFFRXC_rstb <= 1'b1;
			16'h4054: XOFFTXC_rstb <= 1'b1;
			16'h4058: FCRUC_rstb <= 1'b1;
			16'h405C: PRC64_rstb <= 1'b1;
			16'h4060: PRC127_rstb <= 1'b1;
			16'h4064: PRC255_rstb <= 1'b1;
			16'h4068: PRC511_rstb <= 1'b1;
			16'h406C: PRC1023_rstb <= 1'b1;
			16'h4070: PRC1522_rstb <= 1'b1;
			16'h4074: GPRC_rstb <= 1'b1;
			16'h4078: BPRC_rstb <= 1'b1;
			16'h407C: MPRC_rstb <= 1'b1;
			16'h4080: GPTC_rstb <= 1'b1;
			16'h4088: GORCL_rstb <= 1'b1;
			16'h408C: GORCH_rstb <= 1'b1;
			16'h4090: GOTCL_rstb <= 1'b1;
			16'h4094: GOTCH_rstb <= 1'b1;
			16'h40A0: RNBC_rstb <= 1'b1;
			16'h40A4: RUC_rstb <= 1'b1;
			16'h40A8: RFC_rstb <= 1'b1;
			16'h40AC: ROC_rstb <= 1'b1;
			16'h40B0: RJC_rstb <= 1'b1;
			16'h40B4: MGTPRC_rstb <= 1'b1;
			16'h40B8: MGTPDC_rstb <= 1'b1;
			16'h40BC: MGTPTC_rstb <= 1'b1;
			16'h40C0: TORL_rstb <= 1'b1;
			16'h40C4: TORH_rstb <= 1'b1;
			16'h40C8: TOTL_rstb <= 1'b1;
			16'h40CC: TOTH_rstb <= 1'b1;
			16'h40D0: TPR_rstb <= 1'b1;
			16'h40D4: TPT_rstb <= 1'b1;
			16'h40D8: PTC64_rstb <= 1'b1;
			16'h40DC: PTC127_rstb <= 1'b1;
			16'h40E0: PTC255_rstb <= 1'b1;
			16'h40E4: PTC511_rstb <= 1'b1;
			16'h40E8: PTC1023_rstb <= 1'b1;
			16'h40EC: PTC1522_rstb <= 1'b1;
			16'h40F0: MPTC_rstb <= 1'b1;
			16'h40F4: BPTC_rstb <= 1'b1;
			16'h40F8: TSCTC_rstb <= 1'b1;
			16'h40FC: TSCTFC_rstb <= 1'b1;

		endcase
	end
	else begin
		CTRL_rstb <= 1'b0;
		STATUS_rstb <= 1'b0;
		EECD_rstb <= 1'b0;
		EERD_rstb <= 1'b0;
		FLA_rstb <= 1'b0;
		CTRL_EXT_rstb <= 1'b0;
		MDIC_rstb <= 1'b0;
		FCAL_rstb <= 1'b0;
		FCAH_rstb <= 1'b0;
		FCT_rstb <= 1'b0;
		VET_rstb <= 1'b0;
		FCTTV_rstb <= 1'b0;
		TXCW_rstb <= 1'b0;
		RXCW_rstb <= 1'b0;
		LEDCTL_rstb <= 1'b0;
		PBA_rstb <= 1'b0;
		ICR_rstb <= 1'b0;
		ITR_rstb <= 1'b0;
		ICS_rstb <= 1'b0;
		IMS_rstb <= 1'b0;
		IMC_rstb <= 1'b0;
		RCTL_rstb <= 1'b0;
		FCRTL_rstb <= 1'b0;
		FCRTH_rstb <= 1'b0;
		RDBAL_rstb <= 1'b0;
		RDBAH_rstb <= 1'b0;
		RDLEN_rstb <= 1'b0;
		RDH_rstb <= 1'b0;
		RDT_rstb <= 1'b0;
		RDTR_rstb <= 1'b0;
		RADV_rstb <= 1'b0;
		RSRPD_rstb <= 1'b0;
		TCTL_rstb <= 1'b0;
		TIPG_rstb <= 1'b0;
		AIFS_rstb <= 1'b0;
		TDBAL_rstb <= 1'b0;
		TDBAH_rstb <= 1'b0;
		TDLEN_rstb <= 1'b0;
		TDH_rstb <= 1'b0;
		TDT_rstb <= 1'b0;
		TIDV_rstb <= 1'b0;
		TXDMAC_rstb <= 1'b0;
		TXDCTL_rstb <= 1'b0;
		TADV_rstb <= 1'b0;
		TSPMT_rstb <= 1'b0;
		RXDCTL_rstb <= 1'b0;
		RXCSUM_rstb <= 1'b0;
		MTA_rstb <= 1'b0;
		RA_rstb <= 1'b0;
		VFTA_rstb <= 1'b0;
		WUC_rstb <= 1'b0;
		WUFC_rstb <= 1'b0;
		WUS_rstb <= 1'b0;
		IPAV_rstb <= 1'b0;
		IP4AT_rstb <= 1'b0;
		IP6AT_rstb <= 1'b0;
		WUPL_rstb <= 1'b0;
		WUPM_rstb <= 1'b0;
		FFLT_rstb <= 1'b0;
		FFMT_rstb <= 1'b0;
		FFVT_rstb <= 1'b0;
		CRCERRS_rstb <= 1'b0;
		ALGNERRC_rstb <= 1'b0;
		SYMERRS_rstb <= 1'b0;
		RXERRC_rstb <= 1'b0;
		MPC_rstb <= 1'b0;
		SCC_rstb <= 1'b0;
		ECOL_rstb <= 1'b0;
		MCC_rstb <= 1'b0;
		LATECOL_rstb <= 1'b0;
		COLC_rstb <= 1'b0;
		DC_rstb <= 1'b0;
		TNCRS_rstb <= 1'b0;
		SEC_rstb <= 1'b0;
		CEXTERR_rstb <= 1'b0;
		RLEC_rstb <= 1'b0;
		XONRXC_rstb <= 1'b0;
		XONTXC_rstb <= 1'b0;
		XOFFRXC_rstb <= 1'b0;
		XOFFTXC_rstb <= 1'b0;
		FCRUC_rstb <= 1'b0;
		PRC64_rstb <= 1'b0;
		PRC127_rstb <= 1'b0;
		PRC255_rstb <= 1'b0;
		PRC511_rstb <= 1'b0;
		PRC1023_rstb <= 1'b0;
		PRC1522_rstb <= 1'b0;
		GPRC_rstb <= 1'b0;
		BPRC_rstb <= 1'b0;
		MPRC_rstb <= 1'b0;
		GPTC_rstb <= 1'b0;
		GORCL_rstb <= 1'b0;
		GORCH_rstb <= 1'b0;
		GOTCL_rstb <= 1'b0;
		GOTCH_rstb <= 1'b0;
		RNBC_rstb <= 1'b0;
		RUC_rstb <= 1'b0;
		RFC_rstb <= 1'b0;
		ROC_rstb <= 1'b0;
		RJC_rstb <= 1'b0;
		MGTPRC_rstb <= 1'b0;
		MGTPDC_rstb <= 1'b0;
		MGTPTC_rstb <= 1'b0;
		TORL_rstb <= 1'b0;
		TORH_rstb <= 1'b0;
		TOTL_rstb <= 1'b0;
		TOTH_rstb <= 1'b0;
		TPR_rstb <= 1'b0;
		TPT_rstb <= 1'b0;
		PTC64_rstb <= 1'b0;
		PTC127_rstb <= 1'b0;
		PTC255_rstb <= 1'b0;
		PTC511_rstb <= 1'b0;
		PTC1023_rstb <= 1'b0;
		PTC1522_rstb <= 1'b0;
		MPTC_rstb <= 1'b0;
		BPTC_rstb <= 1'b0;
		TSCTC_rstb <= 1'b0;
		TSCTFC_rstb <= 1'b0;
	end
end

always @(posedge aclk)
begin
	if(read_enable) begin
		casex({read_addr[15:2],2'b0}) 
			16'h0000: read_data <= CTRL_i;
			16'h0008: read_data <= STATUS_i;
			16'h0010: read_data <= EECD_i;
			16'h0014: read_data <= EERD_i;
			16'h001C: read_data <= FLA_i;
			16'h0018: read_data <= CTRL_EXT_i;
			16'h0020: read_data <= MDIC_i;
			16'h0028: read_data <= FCAL_i;
			16'h002C: read_data <= FCAH_i;
			16'h0030: read_data <= FCT_i;
			16'h0038: read_data <= VET_i;
			16'h0170: read_data <= FCTTV_i;
			16'h0178: read_data <= TXCW_i;
			16'h0180: read_data <= RXCW_i;
			16'h0E00: read_data <= LEDCTL_i;
			16'h1000: read_data <= PBA_i;
			16'h00C0: read_data <= ICR_i;
			16'h00C4: read_data <= ITR_i;
			16'h00C8: read_data <= ICS_i;
			16'h00D0: read_data <= IMS_i;
			16'h00D8: read_data <= IMC_i;
			16'h0100: read_data <= RCTL_i;
			16'h2160: read_data <= FCRTL_i;
			16'h2168: read_data <= FCRTH_i;
			16'h2800: read_data <= RDBAL_i;
			16'h2804: read_data <= RDBAH_i;
			16'h2808: read_data <= RDLEN_i;
			16'h2810: read_data <= RDH_i;
			16'h2818: read_data <= RDT_i;
			16'h2820: read_data <= RDTR_i;
			16'h282C: read_data <= RADV_i;
			16'h2C00: read_data <= RSRPD_i;
			16'h0400: read_data <= TCTL_i;
			16'h0410: read_data <= TIPG_i;
			16'h0458: read_data <= AIFS_i;
			16'h3800: read_data <= TDBAL_i;
			16'h3804: read_data <= TDBAH_i;
			16'h3808: read_data <= TDLEN_i;
			16'h3810: read_data <= TDH_i;
			16'h3818: read_data <= TDT_i;
			16'h3820: read_data <= TIDV_i;
			16'h3000: read_data <= TXDMAC_i;
			16'h3828: read_data <= TXDCTL_i;
			16'h282C: read_data <= TADV_i;
			16'h3830: read_data <= TSPMT_i;
			16'h2828: read_data <= RXDCTL_i;
			16'h5000: read_data <= RXCSUM_i;
			16'b0101_001x_xxxx_xxxx: read_data <= MTA_i;
			16'b0101_0100_0xxx_xxxx: read_data <= RA_i;
			16'b0101_011x_xxxx_xxxx: read_data <= VFTA_i;
			16'h5800: read_data <= WUC_i;
			16'h5808: read_data <= WUFC_i;
			16'h5810: read_data <= WUS_i;
			16'h5838: read_data <= IPAV_i;
			16'b0101_1000_010x_xxxx: read_data <= IP4AT_i;
			16'b0101_1000_1000_xxxx: read_data <= IP6AT_i;
			16'h5900: read_data <= WUPL_i;
			16'b0101_1010_0xxx_xxxx: read_data <= WUPM_i;
			16'b0101_1111_000x_xxxx: read_data <= FFLT_i;
			16'b1001_11xx_xxxx_xxxx: read_data <= FFMT_i;
			16'b1001_10xx_xxxx_xxxx: read_data <= FFVT_i;
			16'h4000: read_data <= CRCERRS_i;
			16'h4004: read_data <= ALGNERRC_i;
			16'h4008: read_data <= SYMERRS_i;
			16'h400C: read_data <= RXERRC_i;
			16'h4010: read_data <= MPC_i;
			16'h4014: read_data <= SCC_i;
			16'h4018: read_data <= ECOL_i;
			16'h401C: read_data <= MCC_i;
			16'h4020: read_data <= LATECOL_i;
			16'h4028: read_data <= COLC_i;
			16'h4030: read_data <= DC_i;
			16'h4034: read_data <= TNCRS_i;
			16'h4038: read_data <= SEC_i;
			16'h403C: read_data <= CEXTERR_i;
			16'h4040: read_data <= RLEC_i;
			16'h4048: read_data <= XONRXC_i;
			16'h404C: read_data <= XONTXC_i;
			16'h4050: read_data <= XOFFRXC_i;
			16'h4054: read_data <= XOFFTXC_i;
			16'h4058: read_data <= FCRUC_i;
			16'h405C: read_data <= PRC64_i;
			16'h4060: read_data <= PRC127_i;
			16'h4064: read_data <= PRC255_i;
			16'h4068: read_data <= PRC511_i;
			16'h406C: read_data <= PRC1023_i;
			16'h4070: read_data <= PRC1522_i;
			16'h4074: read_data <= GPRC_i;
			16'h4078: read_data <= BPRC_i;
			16'h407C: read_data <= MPRC_i;
			16'h4080: read_data <= GPTC_i;
			16'h4088: read_data <= GORCL_i;
			16'h408C: read_data <= GORCH_i;
			16'h4090: read_data <= GOTCL_i;
			16'h4094: read_data <= GOTCH_i;
			16'h40A0: read_data <= RNBC_i;
			16'h40A4: read_data <= RUC_i;
			16'h40A8: read_data <= RFC_i;
			16'h40AC: read_data <= ROC_i;
			16'h40B0: read_data <= RJC_i;
			16'h40B4: read_data <= MGTPRC_i;
			16'h40B8: read_data <= MGTPDC_i;
			16'h40BC: read_data <= MGTPTC_i;
			16'h40C0: read_data <= TORL_i;
			16'h40C4: read_data <= TORH_i;
			16'h40C8: read_data <= TOTL_i;
			16'h40CC: read_data <= TOTH_i;
			16'h40D0: read_data <= TPR_i;
			16'h40D4: read_data <= TPT_i;
			16'h40D8: read_data <= PTC64_i;
			16'h40DC: read_data <= PTC127_i;
			16'h40E0: read_data <= PTC255_i;
			16'h40E4: read_data <= PTC511_i;
			16'h40E8: read_data <= PTC1023_i;
			16'h40EC: read_data <= PTC1522_i;
			16'h40F0: read_data <= MPTC_i;
			16'h40F4: read_data <= BPTC_i;
			16'h40F8: read_data <= TSCTC_i;
			16'h40FC: read_data <= TSCTFC_i;
			default: read_data <= 'bx;
		endcase
	end
end

// FIXIT: need different timing for RAM-like tables
always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) 
		read_ready = 1'b1;
	else if(!read_ready && read_enable)
		read_ready <= 1'b1;
	else
		read_ready <= 1'b0;
end
endmodule
