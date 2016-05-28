// IMPORTANT: address[31:24] is BAR selector
// address[24]==1 - Memory Mapped Register Map
// address[25]==1 - Memory Mapped Flash 
// address[26]==1 - IO Mapped Indirect Access to Register Map
// FIXME: Memory mapped flash access space is not implemented
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

	output CTRL_RST,
	output CTRL_PHY_RST,

	input STATUS_FD_fb,
	input STATUS_LU_fb,
	input [1:0] STATUS_FID_fb,
	input STATUS_TXOFF_fb,
	input [1:0] STATUS_SPEED_fb,
	input [1:0] STATUS_ASDV_fb,

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
	input [15:0] MDIC_DATA_i,

	output [31:0] ICR,
	input [31:0] ICR_fb_i,
	output ICR_set,
	output ICR_get,

	output [31:0] ITR,
	output ITR_set,

	output [31:0] ICS,
	output ICS_set,

	output [31:0] IMS,
	output IMS_set,

	output [31:0] IMC,
	output IMC_set,

	input PHYINT_fb_i,

	output TCTL_EN,
	output TCTL_PSP,

	output [63:0] TDBA,
	output [12:0] TDLEN,

	output [15:0] TDH,
	output TDH_set,
	input [15:0] TDH_fb,

	output [15:0] TDT,
	output TDT_set,

	output [15:0] TIDV,

	output DPP,

	output [5:0] TXDCTL_PTHRESH,
	output [5:0] TXDCTL_HTHRESH,
	output [5:0] TXDCTL_WTHRESH,
	output TXDCTL_GRAN,
	output [5:0] TXDCTL_LWTHRESH,
	output [15:0] TADV,
	output [15:0] TSMT,
	output [15:0] TSPBP,

	output RCTL_EN,
	output LPE,
	output [1:0] LBM,
	output [1:0] RDMTS,
	output [1:0] BSIZE,
	output BSEX,
	output SECRC,
	output [63:0] RDBA,
	output [12:0] RDLEN,
	output [15:0] RDH,
	output RDH_set,
	input  [15:0] RDH_fb,
	output [15:0] RDT,
	output RDT_set,
	output [5:0] RXDCTL_PTHRESH,
	output [5:0] RXDCTL_HTHRESH,
	output [5:0] RXDCTL_WTHRESH,
	output RXDCTL_GRAN,
	output [7:0] PCSS,
	output [15:0] RDTR,
	output FPD,
	output FPD_set,
	output [15:0] RADV
);

reg awready_r;
reg wready_r;
reg [1:0] bresp_r;
reg bvalid_r;
reg arready_r;
reg [31:0] rdata_r;
reg rvalid_r;
reg [1:0] rresp_r;

reg [15:0] write_addr;
reg [31:0] write_data;
reg write_enable;
reg [3:0] write_be;

reg [15:0] read_addr;
reg [31:0] read_data;
reg read_enable;
reg read_ready;

reg [15:0] reg_ioaddr;
reg ioaddr_en;

wire reset;
assign reset = !aresetn;

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
always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		ioaddr_en <= 1'b0;
	end
	else if(axi_s_awvalid && axi_s_awready) begin
		if(axi_s_awaddr[26] && axi_s_awaddr[2:0]==3'h0)
			// IOADDR
			ioaddr_en <= 1'b1;
	end
	else if(ioaddr_en && axi_s_bvalid && axi_s_bready) begin
		ioaddr_en <= 1'b0;
	end
end
always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		reg_ioaddr <= 'b0;
	end
	else if(ioaddr_en && axi_s_wvalid && axi_s_wready) begin
		reg_ioaddr <= axi_s_wdata;
	end
end

always @(posedge aclk)
begin
	if(axi_s_awvalid && axi_s_awready) begin
		if(axi_s_awaddr[24]) // Memory Mapped Register MAP
			write_addr <= axi_s_awaddr;
		else if(axi_s_awaddr[26] && axi_s_awaddr[2:0]==3'h4)
			// IO Mapped Indirect Register Access
			write_addr <= reg_ioaddr;
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
		if(axi_s_awaddr[24]) // Memory Mapped Register MAP
			write_enable <= 1'b1;
		else if(axi_s_awaddr[26] && axi_s_awaddr[2:0]==3'h04) 
			// IO Mapped Indirect Register Access
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
		rvalid_r <= 1'b0;
		rresp_r <= 2'b0;
		rdata_r <= 'bx;
		read_enable <= 1'b0;
	end
	else if(arready_r && axi_s_arvalid) begin
		if(axi_s_araddr[24]) // Memory Mapped Register Map
			read_addr <= axi_s_araddr;
		else if(axi_s_araddr[26] && axi_s_araddr[2:0]==3'h04)
			read_addr <= reg_ioaddr;
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
	end
end

wire [31:0] CTRL, CTRL_Q, CTRL_B;
wire CTRL_get, CTRL_set;
e1000_register #(.INIT(32'h0000_0201),.ADDR(16'h0000),.BMSK(32'h0000_0000)) CTRL_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(CTRL),.Q(CTRL_Q),.B(CTRL_B),.S(CTRL_set),.G(CTRL_get)
);
assign CTRL_B = CTRL;
assign CTRL_RST = CTRL[26];
assign CTRL_PHY_RST = CTRL[31];

wire [31:0] STATUS, STATUS_Q, STATUS_B;
wire STATUS_get, STATUS_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h0008),.BMSK(32'hFFFF_FFFF)) STATUS_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(STATUS),.Q(STATUS_Q),.B(STATUS_B),.S(STATUS_set),.G(STATUS_get)
);
assign STATUS_B[0] = STATUS_FD_fb;
assign STATUS_B[1] = STATUS_LU_fb;
assign STATUS_B[3:2] = STATUS_FID_fb;
assign STATUS_B[4] = STATUS_TXOFF_fb;
assign STATUS_B[5] = 1'b0;
assign STATUS_B[7:6] = STATUS_SPEED_fb;
assign STATUS_B[9:8] = STATUS_ASDV_fb;
assign STATUS_B[31:10] = 'b0;

wire [31:0] EECD_Q, EECD_B;
wire EECD_get, EECD_set;
e1000_register #(.INIT(32'h0000_0110),.ADDR(16'h0010),.BMSK(32'hFFFF_FF88)) EECD_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(EECD),.Q(EECD_Q),.B(EECD_B),.S(EECD_set),.G(EECD_get)
);
assign EECD_B = {24'h0000_07,EECD_GNT_i,EECD[6:4],EECD_DO_i,EECD[2:0]};

wire [31:0] EERD_Q, EERD_B;
wire EERD_get, EERD_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h0014),.BMSK(32'hFFFF_00FF)) EERD_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(EERD),.Q(EERD_Q),.B(EERD_B),.S(EERD_set),.G(EERD_get)
);
assign EERD_B = {EERD_DATA_i,EERD[15:8],3'b0,EERD_DONE_i,4'b0};
assign EERD_START = EERD[0]&EERD_set;

wire [31:0] FLA, FLA_Q, FLA_B;
wire FLA_get, FLA_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h001C),.BMSK(32'h0000_0000)) FLA_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(FLA),.Q(FLA_Q),.B(FLA_B),.S(FLA_set),.G(FLA_get)
);
assign FLA_B = FLA; // FLA is ignored

wire [31:0] CTRL_EXT, CTRL_EXT_Q, CTRL_EXT_B;
wire CTRL_EXT_get, CTRL_EXT_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h0018),.BMSK(32'h0000_0000)) CTRL_EXT_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(CTRL_EXT),.Q(CTRL_EXT_Q),.B(CTRL_EXT_B),.S(CTRL_EXT_set),.G(CTRL_EXT_get)
);
assign CTRL_EXT_B[4:0] = 5'b0;
assign CTRL_EXT_B[5] = PHYINT_fb_i;
assign CTRL_EXT_B[14:6] = 9'b0;
assign CTRL_EXT_B[15] = CTRL_EXT[15];
assign CTRL_EXT_B[31:16] = 16'b0;

wire [31:0] MDIC_Q, MDIC_B;
wire MDIC_get, MDIC_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h0020),.BMSK(32'hD000_FFFF)) MDIC_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(MDIC),.Q(MDIC_Q),.B(MDIC_B),.S(MDIC_set),.G(MDIC_get)
);
assign MDIC_B = {2'b0,MDIC[29],MDIC_R_i,MDIC[27:16],MDIC_DATA_i};
assign MDIC_start = MDIC_set;

wire [31:0] FCAL, FCAL_Q, FCAL_B;
wire FCAL_get, FCAL_set;
e1000_register #(.INIT(32'h00C2_8001),.ADDR(16'h0028),.BMSK(32'h0000_0000)) FCAL_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(FCAL),.Q(FCAL_Q),.B(FCAL_B),.S(FCAL_set),.G(FCAL_get)
);
assign FCAL_B = FCAL; // FCAL is ignored

wire [31:0] FCAH, FCAH_Q, FCAH_B;
wire FCAH_get, FCAH_set;
e1000_register #(.INIT(32'h0000_0100),.ADDR(16'h002C),.BMSK(32'hFFFF_0000)) FCAH_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(FCAH),.Q(FCAH_Q),.B(FCAH_B),.S(FCAH_set),.G(FCAH_get)
);
assign FCAH_B = {16'b0,FCAH[15:0]};

wire [31:0] FCT, FCT_Q, FCT_B;
wire FCT_get, FCT_set;
e1000_register #(.INIT(32'h0000_8808),.ADDR(16'h0030),.BMSK(32'hFFFF_0000)) FCT_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(FCT),.Q(FCT_Q),.B(FCT_B),.S(FCT_set),.G(FCT_get)
);
assign FCT_B = {16'b0,FCT[15:0]};

wire [31:0] VET, VET_Q, VET_B;
wire VET_get, VET_set;
e1000_register #(.INIT(32'h0000_8100),.ADDR(16'h0038),.BMSK(32'hFFFF_0000)) VET_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(VET),.Q(VET_Q),.B(VET_B),.S(VET_set),.G(VET_get)
);
assign VET_B = {16'b0,VET[15:0]};

wire [31:0] FCTTV, FCTTV_Q, FCTTV_B;
wire FCTTV_get, FCTTV_set;
e1000_register #(.INIT(32'h0000_8100),.ADDR(16'h0170),.BMSK(32'hFFFF_0000)) FCTTV_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(FCTTV),.Q(FCTTV_Q),.B(FCTTV_B),.S(FCTTV_set),.G(FCTTV_get)
);
assign FCTTV_B = {16'b0,FCTTV[15:0]};

wire [31:0] TXCW, TXCW_Q, TXCW_B;
wire TXCW_get, TXCW_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h0178),.BMSK(32'h0000_0000)) TXCW_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(TXCW),.Q(TXCW_Q),.B(TXCW_B),.S(TXCW_set),.G(TXCW_get)
);
assign TXCW_B = TXCW;

wire [31:0] RXCW, RXCW_Q, RXCW_B;
wire RXCW_get, RXCW_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h0180),.BMSK(32'h0000_0000)) RXCW_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(RXCW),.Q(RXCW_Q),.B(RXCW_B),.S(RXCW_set),.G(RXCW_get)
);
assign RXCW_B = RXCW;

wire [31:0] LEDCTL, LEDCTL_Q, LEDCTL_B;
wire LEDCTL_get, LEDCTL_set;
e1000_register #(.INIT(32'h0706_8302),.ADDR(16'h0E00),.BMSK(32'h0000_0000)) LEDCTL_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(LEDCTL),.Q(LEDCTL_Q),.B(LEDCTL_B),.S(LEDCTL_set),.G(LEDCTL_get)
);
assign LEDCTL_B = LEDCTL;

wire [31:0] PBA, PBA_Q, PBA_B;
wire PBA_get, PBA_set;
e1000_register #(.INIT(32'h0010_0030),.ADDR(16'h1000),.BMSK(32'h0000_0000)) PBA_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(PBA),.Q(PBA_Q),.B(PBA_B),.S(PBA_set),.G(PBA_get)
);
assign PBA_B = PBA;

// ICR is R-C, W1-C
wire [31:0] ICR_Q, ICR_B;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h00C0),.BMSK(32'hFFFF_FFFF)) ICR_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(ICR),.Q(ICR_Q),.B(ICR_B),.S(ICR_set),.G(ICR_get)
);
assign ICR_B = ICR_fb_i;

wire [31:0] ITR_Q, ITR_B;
wire ITR_get;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h00C4),.BMSK(32'hFFFF_0000)) ITR_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(ITR),.Q(ITR_Q),.B(ITR_B),.S(ITR_set),.G(ITR_get)
);
assign ITR_B = {16'b0,ITR[15:0]};

wire [31:0] ICS_Q, ICS_B;
wire ICS_get;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h00C8),.BMSK(32'hFFFF_0000)) ICS_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(ICS),.Q(ICS_Q),.B(ICS_B),.S(ICS_set),.G(ICS_get)
);
//assign ICS_B = {16'b0,ICS[15:0]};
assign ICS_B = ICR_fb_i; // Emulates E1000 behavior. This is undocumented.


wire [31:0] IMS_Q, IMS_B;
wire IMS_get;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h00D0),.BMSK(32'hFFFF_0000)) IMS_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(IMS),.Q(IMS_Q),.B(IMS_B),.S(IMS_set),.G(IMS_get)
);
assign IMS_B = {16'b0,IMS[15:0]};

wire [31:0] IMC_Q, IMC_B;
wire IMC_get;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h00D8),.BMSK(32'hFFFF_0000)) IMC_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(IMC),.Q(IMC_Q),.B(IMC_B),.S(IMC_set),.G(IMC_get)
);
assign IMC_B = {16'b0,IMC[15:0]};

wire [31:0] RCTL, RCTL_Q, RCTL_B;
wire RCTL_get, RCTL_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h0100),.BMSK(32'hF800_0000)) RCTL_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(RCTL),.Q(RCTL_Q),.B(RCTL_B),.S(RCTL_set),.G(RCTL_get)
);
assign RCTL_B = {5'b0,RCTL[26:0]};
assign RCTL_EN = RCTL[1];
assign LPE = RCTL[5];
assign LBM = RCTL[7:6];
assign RDMTS = RCTL[9:8];
assign BSIZE = RCTL[17:16];
assign BSEX = RCTL[25];
assign SECRC = RCTL[26];

wire [31:0] FCRTL, FCRTL_Q, FCRTL_B;
wire FCRTL_get, FCRTL_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h2160),.BMSK(32'h7FFF_0007)) FCRTL_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(FCRTL),.Q(FCRTL_Q),.B(FCRTL_B),.S(FCRTL_set),.G(FCRTL_get)
);
assign FCRTL_B = {FCRTL[31],15'b0,FCRTL[15:3],3'b0};

wire [31:0] FCRTH, FCRTH_Q, FCRTH_B;
wire FCRTH_get, FCRTH_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h2168),.BMSK(32'h7FFF_0007)) FCRTH_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(FCRTH),.Q(FCRTH_Q),.B(FCRTH_B),.S(FCRTH_set),.G(FCRTH_get)
);
assign FCRTH_B = {FCRTH[31],15'b0,FCRTH[15:3],3'b0};

wire [31:0] RDBAL, RDBAL_Q, RDBAL_B;
wire RDBAL_get, RDBAL_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h2800),.BMSK(32'h0000_000F)) RDBAL_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(RDBAL),.Q(RDBAL_Q),.B(RDBAL_B),.S(RDBAL_set),.G(RDBAL_get)
);
assign RDBAL_B = {RDBAL[31:4],4'b0};

wire [31:0] RDBAH, RDBAH_Q, RDBAH_B;
wire RDBAH_get, RDBAH_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h2804),.BMSK(32'h0000_0000)) RDBAH_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(RDBAH),.Q(RDBAH_Q),.B(RDBAH_B),.S(RDBAH_set),.G(RDBAH_get)
);
assign RDBAH_B = RDBAH;

assign RDBA = {RDBAH, RDBAL[31:4], 4'b0};

wire [31:0] RDLEN_O, RDLEN_Q, RDLEN_B;
wire RDLEN_get, RDLEN_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h2808),.BMSK(32'hFFF0_007F)) RDLEN_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(RDLEN_O),.Q(RDLEN_Q),.B(RDLEN_B),.S(RDLEN_set),.G(RDLEN_get)
);
assign RDLEN_B = {12'b0,RDLEN_O[19:7],7'b0};
assign RDLEN = RDLEN_O[19:7];

wire [31:0] RDH_O, RDH_Q, RDH_B;
wire RDH_get;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h2810),.BMSK(32'hFFFF_FFFF)) RDH_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(RDH_O),.Q(RDH_Q),.B(RDH_B),.S(RDH_set),.G(RDH_get)
);
assign RDH_B = {16'b0,RDH_fb};
assign RDH = RDH_O[15:0];

wire [31:0] RDT_O, RDT_Q, RDT_B;
wire RDT_get;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h2818),.BMSK(32'hFFFF_0000)) RDT_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(RDT_O),.Q(RDT_Q),.B(RDT_B),.S(RDT_set),.G(RDT_get)
);
assign RDT_B = {16'b0,RDT_O[15:0]};
assign RDT = RDT_O[15:0];

wire [31:0] RDTR_O, RDTR_Q, RDTR_B;
wire RDTR_get, RDTR_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h2820),.BMSK(32'hFFFF_0000)) RDTR_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(RDTR_O),.Q(RDTR_Q),.B(RDTR_B),.S(RDTR_set),.G(RDTR_get)
);
assign RDTR_B = {16'b0,RDTR_O[15:0]};
assign RDTR = RDTR_O[15:0];
assign FPD = RDTR_O[31];
assign FPD_set = RDTR_set;

wire [31:0] RADV_O, RADV_Q, RADV_B;
wire RADV_get, RADV_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h282C),.BMSK(32'hFFFF_0000)) RADV_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(RADV_O),.Q(RADV_Q),.B(RADV_B),.S(RADV_set),.G(RADV_get)
);
assign RADV_B = {16'b0,RADV_O[15:0]};
assign RADV = RADV_O[15:0];

wire [31:0] RSRPD, RSRPD_Q, RSRPD_B;
wire RSRPD_get, RSRPD_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h2C00),.BMSK(32'hFFFF_F000)) RSRPD_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(RSRPD),.Q(RSRPD_Q),.B(RSRPD_B),.S(RSRPD_set),.G(RSRPD_get)
);
assign RSRPD_B = {20'b0,RSRPD[11:0]};

wire [31:0] TCTL, TCTL_Q, TCTL_B;
wire TCTL_get, TCTL_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h0400),.BMSK(32'h0000_0000)) TCTL_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(TCTL),.Q(TCTL_Q),.B(TCTL_B),.S(TCTL_set),.G(TCTL_get)
);
assign TCTL_B = TCTL;
assign TCTL_EN = TCTL[1];
assign TCTL_PSP = TCTL[3];

wire [31:0] TIPG, TIPG_Q, TIPG_B;
wire TIPG_get, TIPG_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h0410),.BMSK(32'hC000_0000)) TIPG_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(TIPG),.Q(TIPG_Q),.B(TIPG_B),.S(TIPG_set),.G(TIPG_get)
);
assign TIPG_B = {2'b0,TIPG[29:0]};

// Should be ignored
wire [31:0] AIFS, AIFS_Q, AIFS_B;
wire AIFS_get, AIFS_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h0458),.BMSK(32'hFFFF_0000)) AIFS_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(AIFS),.Q(AIFS_Q),.B(AIFS_B),.S(AIFS_set),.G(AIFS_get)
);
assign AIFS_B = {16'b0,AIFS[15:0]};

wire [31:0] TDBAL, TDBAL_Q, TDBAL_B;
wire TDBAL_get, TDBAL_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h3800),.BMSK(32'h0000_000F)) TDBAL_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(TDBAL),.Q(TDBAL_Q),.B(TDBAL_B),.S(TDBAL_set),.G(TDBAL_get)
);
assign TDBAL_B = {TDBAL[31:4],4'b0};

wire [31:0] TDBAH, TDBAH_Q, TDBAH_B;
wire TDBAH_get, TDBAH_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h3804),.BMSK(32'h0000_0000)) TDBAH_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(TDBAH),.Q(TDBAH_Q),.B(TDBAH_B),.S(TDBAH_set),.G(TDBAH_get)
);
assign TDBAH_B = TDBAH;

assign TDBA = {TDBAH,TDBAL[31:4],4'b0};

wire [31:0] TDLEN_O, TDLEN_Q, TDLEN_B;
wire TDLEN_get, TDLEN_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h3808),.BMSK(32'hFFF0_007F)) TDLEN_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(TDLEN_O),.Q(TDLEN_Q),.B(TDLEN_B),.S(TDLEN_set),.G(TDLEN_get)
);
assign TDLEN_B = {12'b0,TDLEN_O[19:7],7'b0};
assign TDLEN = TDLEN_O[19:7];

wire [31:0] TDH_O,TDH_Q, TDH_B;
wire TDH_get;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h3810),.BMSK(32'hFFFF_FFFF)) TDH_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(TDH_O),.Q(TDH_Q),.B(TDH_B),.S(TDH_set),.G(TDH_get)
);
assign TDH_B = {16'b0,TDH_fb};
assign TDH = TDH_O[15:0];

wire [31:0] TDT_O, TDT_Q, TDT_B;
wire TDT_get;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h3818),.BMSK(32'hFFFF_0000)) TDT_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(TDT_O),.Q(TDT_Q),.B(TDT_B),.S(TDT_set),.G(TDT_get)
);
assign TDT_B = {16'b0,TDT_O[15:0]};
assign TDT = TDT_O[15:0];

wire [31:0] TIDV_O, TIDV_Q, TIDV_B;
wire TIDV_get, TIDV_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h3820),.BMSK(32'hFFFF_0000)) TIDV_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(TIDV_O),.Q(TIDV_Q),.B(TIDV_B),.S(TIDV_set),.G(TIDV_get)
);
assign TIDV_B = {16'b0,TIDV_O[15:0]};
assign TIDV = TIDV_O[15:0];

wire [31:0] TXDMAC, TXDMAC_Q, TXDMAC_B;
wire TXDMAC_get, TXDMAC_set;
e1000_register #(.INIT(32'h0000_0001),.ADDR(16'h3000),.BMSK(32'hFFFF_FFFE)) TXDMAC_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(TXDMAC),.Q(TXDMAC_Q),.B(TXDMAC_B),.S(TXDMAC_set),.G(TXDMAC_get)
);
assign TXDMAC_B = {31'b0,TXDMAC[0]};
assign DPP = TXDMAC[0];

wire [31:0] TXDCTL, TXDCTL_Q, TXDCTL_B;
wire TXDCTL_get, TXDCTL_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h3828),.BMSK(32'h0000_0000)) TXDCTL_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(TXDCTL),.Q(TXDCTL_Q),.B(TXDCTL_B),.S(TXDCTL_set),.G(TXDCTL_get)
);
assign TXDCTL_B = TXDCTL;
assign TXDCTL_PTHRESH = TXDCTL[5:0];
assign TXDCTL_HTHRESH = TXDCTL[13:8];
assign TXDCTL_WTHRESH = TXDCTL[21:16];
assign TXDCTL_GRAN = TXDCTL[24];
assign TXDCTL_LWTHRESH = TXDCTL[31:25];

wire [31:0] TADV_O, TADV_Q, TADV_B;
wire TADV_get, TADV_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h382C),.BMSK(32'hFFFF_0000)) TADV_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(TADV_O),.Q(TADV_Q),.B(TADV_B),.S(TADV_set),.G(TADV_get)
);
assign TADV_B = {16'b0,TADV_O[15:0]};
assign TADV = TADV_O[15:0];

wire [31:0] TSPMT, TSPMT_Q, TSPMT_B;
wire TSPMT_get, TSPMT_set;
e1000_register #(.INIT(32'h0100_0400),.ADDR(16'h3830),.BMSK(32'h0000_0000)) TSPMT_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(TSPMT),.Q(TSPMT_Q),.B(TSPMT_B),.S(TSPMT_set),.G(TSPMT_get)
);
assign TSPMT_B = TSPMT;
assign TSPBP = TSPMT[31:16];
assign TSMT = TSPMT[15:0];

wire [31:0] RXDCTL, RXDCTL_Q, RXDCTL_B;
wire RXDCTL_get, RXDCTL_set;
e1000_register #(.INIT(32'h0101_0000),.ADDR(16'h2828),.BMSK(32'h0000_0000)) RXDCTL_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(RXDCTL),.Q(RXDCTL_Q),.B(RXDCTL_B),.S(RXDCTL_set),.G(RXDCTL_get)
);
assign RXDCTL_B = RXDCTL;
assign RXDCTL_PTHRESH = RXDCTL[5:0];
assign RXDCTL_HTHRESH = RXDCTL[13:8];
assign RXDCTL_WTHRESH = RXDCTL[21:16];
assign RXDCTL_GRAN = RXDCTL[24];

wire [31:0] RXCSUM, RXCSUM_Q, RXCSUM_B;
wire RXCSUM_get, RXCSUM_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h5000),.BMSK(32'h0000_0000)) RXCSUM_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(RXCSUM),.Q(RXCSUM_Q),.B(RXCSUM_B),.S(RXCSUM_set),.G(RXCSUM_get)
);
assign RXCSUM_B = RXCSUM;
assign PCSS = RXCSUM[7:0];

wire [31:0] MTA, MTA_Q, MTA_B;
wire MTA_get, MTA_set;
/*
e1000_map #(.BASE(16'b0101_0010_0000_0000),.AW(9)) MTA_map_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(MTA),.Q(MTA_Q),.B(MTA_B),.S(MTA_set),.G(MTA_get)
);
assign MTA_B = MTA_fb;
*/

wire [31:0] RA, RA_Q, RA_B;
wire RA_get, RA_set;
/*
e1000_map #(.BASE(16'b0101_0100_0000_0000),.AW(7)) RA_map_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(RA),.Q(RA_Q),.B(RA_B),.S(RA_set),.G(RA_get)
);
assign RA_B = RA_fb;
*/

wire [31:0] VFTA, VFTA_Q, VFTA_B;
wire VFTA_get, VFTA_set;
/*
e1000_map #(.BASE(16'b0101_0110_0000_0000),.AW(9)) VFTA_map_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(VFTA),.Q(VFTA_Q),.B(VFTA_B),.S(VFTA_set),.G(VFTA_get)
);
assign VFTA_B = VFTA_fb;
*/

wire [31:0] WUC, WUC_Q, WUC_B;
wire WUC_get, WUC_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h5800),.BMSK(32'hFFFF_FFF0)) WUC_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(WUC),.Q(WUC_Q),.B(WUC_B),.S(WUC_set),.G(WUC_get)
);
assign WUC_B = {28'b0,WUC[3:0]};

wire [31:0] WUFC, WUFC_Q, WUFC_B;
wire WUFC_get, WUFC_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h5808),.BMSK(32'hFFF0_0000)) WUFC_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(WUFC),.Q(WUFC_Q),.B(WUFC_B),.S(WUFC_set),.G(WUFC_get)
);
assign WUFC_B = {12'b0,WUFC[19:0]};

wire [31:0] WUS, WUS_Q, WUS_B;
wire WUS_get, WUS_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h5810),.BMSK(32'h0000_0000)) WUS_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(WUS),.Q(WUS_Q),.B(WUS_B),.S(WUS_set),.G(WUS_get)
);
assign WUS_B = WUS; //FIXME

wire [31:0] IPAV, IPAV_Q, IPAV_B;
wire IPAV_get, IPAV_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h5838),.BMSK(32'hFFFE_FFF0)) IPAV_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(IPAV),.Q(IPAV_Q),.B(IPAV_B),.S(IPAV_set),.G(IPAV_get)
);
assign IPAV_B = {15'b0,IPAV[16],12'b0,IPAV[3:0]};

wire [31:0] IP4AT, IP4AT_Q, IP4AT_B;
wire IP4AT_get, IP4AT_set;
/*
e1000_map #(.BASE(16'b0101_1000_0100_0000),.AW(5)) IP4AT_map_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(IP4AT),.Q(IP4AT_Q),.B(IP4AT_B),.S(IP4AT_set),.G(IP4AT_get)
);
assign IP4AT_B = IP4AT_fb;
*/

wire [31:0] IP6AT, IP6AT_Q, IP6AT_B;
wire IP6AT_get, IP6AT_set;
/*
e1000_map #(.BASE(16'b0101_1000_1000_0000),.AW(4)) IP6AT_map_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(IP6AT),.Q(IP6AT_Q),.B(IP6AT_B),.S(IP6AT_set),.G(IP6AT_get)
);
assign IP6AT_B = IP6AT_fb;
*/

wire [31:0] WUPL, WUPL_Q, WUPL_B;
wire WUPL_get, WUPL_set;
e1000_register #(.INIT(32'h0000_0000),.ADDR(16'h5900),.BMSK(32'hFFFF_F000)) WUPL_reg_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(WUPL),.Q(WUPL_Q),.B(WUPL_B),.S(WUPL_set),.G(WUPL_get)
);
assign WUPL_B = {20'b0,WUPL[11:0]};

wire [31:0] WUPM, WUPM_Q, WUPM_B;
wire WUPM_get, WUPM_set;
/*
e1000_map #(.BASE(16'b0101_1010_0000_0000),.AW(7)) WUPM_map_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(WUPM),.Q(WUPM_Q),.B(WUPM_B),.S(WUPM_set),.G(WUPM_get)
);
assign WUPM_B = WUPM_fb;
*/

wire [31:0] FFLT, FFLT_Q, FFLT_B;
wire FFLT_get, FFLT_set;
/*
e1000_map #(.BASE(16'b0101_1111_0000_0000),.AW(5)) FFLT_map_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(FFLT),.Q(FFLT_Q),.B(FFLT_B),.S(FFLT_set),.G(FFLT_get)
);
assign FFLT_B = FFLT_fb;
*/

wire [31:0] FFMT, FFMT_Q, FFMT_B;
wire FFMT_get, FFMT_set;
/*
e1000_map #(.BASE(16'b1001_1100_0000_0000),.AW(10)) FFMT_map_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(FFMT),.Q(FFMT_Q),.B(FFMT_B),.S(FFMT_set),.G(FFMT_get)
);
assign FFMT_B = FFMT_fb;
*/

wire [31:0] FFVT, FFVT_Q, FFVT_B;
wire FFVT_get, FFVT_set;
/*
e1000_map #(.BASE(16'b1001_1000_0000_0000),.AW(10)) FFVT_map_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(FFVT),.Q(FFVT_Q),.B(FFVT_B),.S(FFVT_set),.G(FFVT_get)
);
assign FFVT_B = FFVT_fb;
*/

wire [31:0] STATISTIC, STATISTIC_Q, STATISTIC_B;
wire STATISTIC_get, STATISTIC_set;
/*
e1000_map #(.BASE(16'b0100_0000_0000_0000),.AW(8)) STATISTIC_map_i(
	.C(aclk),.R(reset),.RA(read_addr),.RE(read_ready),
	.WA(write_addr),.WE(write_enable),.BE(write_be),.D(write_data),
	.O(STATISTIC),.Q(STATISTIC_Q),.B(STATISTIC_B),.S(STATISTIC_set),.G(STATISTIC_get)
);
assign STATISTIC_B = STATISTIC_fb;
*/

/*
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
		casex({write_addr[15:2],2'b0}) // synthesis parallel_case 
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
			16'h382C: TADV_wstb <= 1'b1;
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
		casex({read_addr[15:2],2'b0}) // synthesis parallel_case 
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
			16'h382C: TADV_rstb <= 1'b1;
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
*/

always @(posedge aclk)
begin
	if(read_enable) begin
		casex({read_addr[15:2],2'b0}) 
			16'h0000: read_data <= CTRL_Q;
			16'h0008: read_data <= STATUS_Q;
			16'h0010: read_data <= EECD_Q;
			16'h0014: read_data <= EERD_Q;
			16'h001C: read_data <= FLA_Q;
			16'h0018: read_data <= CTRL_EXT_Q;
			16'h0020: read_data <= MDIC_Q;
			16'h0028: read_data <= FCAL_Q;
			16'h002C: read_data <= FCAH_Q;
			16'h0030: read_data <= FCT_Q;
			16'h0038: read_data <= VET_Q;
			16'h0170: read_data <= FCTTV_Q;
			16'h0178: read_data <= TXCW_Q;
			16'h0180: read_data <= RXCW_Q;
			16'h0E00: read_data <= LEDCTL_Q;
			16'h1000: read_data <= PBA_Q;
			16'h00C0: read_data <= ICR_Q;
			16'h00C4: read_data <= ITR_Q;
			16'h00C8: read_data <= ICS_Q;
			16'h00D0: read_data <= IMS_Q;
			16'h00D8: read_data <= IMC_Q;
			16'h0100: read_data <= RCTL_Q;
			16'h2160: read_data <= FCRTL_Q;
			16'h2168: read_data <= FCRTH_Q;
			16'h2800: read_data <= RDBAL_Q;
			16'h2804: read_data <= RDBAH_Q;
			16'h2808: read_data <= RDLEN_Q;
			16'h2810: read_data <= RDH_Q;
			16'h2818: read_data <= RDT_Q;
			16'h2820: read_data <= RDTR_Q;
			16'h282C: read_data <= RADV_Q;
			16'h2C00: read_data <= RSRPD_Q;
			16'h0400: read_data <= TCTL_Q;
			16'h0410: read_data <= TIPG_Q;
			16'h0458: read_data <= AIFS_Q;
			16'h3800: read_data <= TDBAL_Q;
			16'h3804: read_data <= TDBAH_Q;
			16'h3808: read_data <= TDLEN_Q;
			16'h3810: read_data <= TDH_Q;
			16'h3818: read_data <= TDT_Q;
			16'h3820: read_data <= TIDV_Q;
			16'h3000: read_data <= TXDMAC_Q;
			16'h3828: read_data <= TXDCTL_Q;
			16'h382C: read_data <= TADV_Q;
			16'h3830: read_data <= TSPMT_Q;
			16'h2828: read_data <= RXDCTL_Q;
			16'h5000: read_data <= RXCSUM_Q;
			16'b0101_001x_xxxx_xxxx: read_data <= MTA_Q;
			16'b0101_0100_0xxx_xxxx: read_data <= RA_Q;
			16'b0101_011x_xxxx_xxxx: read_data <= VFTA_Q;
			16'h5800: read_data <= WUC_Q;
			16'h5808: read_data <= WUFC_Q;
			16'h5810: read_data <= WUS_Q;
			16'h5838: read_data <= IPAV_Q;
			16'b0101_1000_010x_xxxx: read_data <= IP4AT_Q;
			16'b0101_1000_1000_xxxx: read_data <= IP6AT_Q;
			16'h5900: read_data <= WUPL_Q;
			16'b0101_1010_0xxx_xxxx: read_data <= WUPM_Q;
			16'b0101_1111_000x_xxxx: read_data <= FFLT_Q;
			16'b1001_11xx_xxxx_xxxx: read_data <= FFMT_Q;
			16'b1001_10xx_xxxx_xxxx: read_data <= FFVT_Q;
			16'b0100_0000_xxxx_xxxx: read_data <= STATISTIC_Q;
			/*
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
			*/
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
