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
	input axi_s_rready
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
		CFCERRS_wstb <= 1'b0;
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
			//16'h0008: STATUS_wstb <= 1'b1;
			16'h0010: EECD_wstb <= 1'b1;
			16'h0014: EERD_wstb <= 1'b1;
			//16'h001C: FLA_wstb <= 1'b1;
			16'h0018: CTRL_EXT_wstb <= 1'b1;
			16'h0020: MDIC_wstb <= 1'b1;
			16'h0028: FCAL_wstb <= 1'b1;
			16'h002C: FCAH_wstb <= 1'b1;
			16'h0030: FCT_wstb <= 1'b1;
			16'h0038: VET_wstb <= 1'b1;
			16'h0170: FCTTV_wstb <= 1'b1;
			//16'h0178: TXCW_wstb <= 1'b1;
			//16'h0180: RXCW_wstb <= 1'b1;
			16'h0E00: LEDCTL_wstb <= 1'b1;
			16'h1000: PBA_wstb <= 1'b1;
			//16'h00C0: ICR_wstb <= 1'b1;
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
			16'h4000: CFCERRS_wstb <= 1'b1;
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
		CFCERRS_wstb <= 1'b0;
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
		CFCERRS_rstb <= 1'b0;
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
			//16'h0008: STATUS_rstb <= 1'b1;
			16'h0010: EECD_rstb <= 1'b1;
			16'h0014: EERD_rstb <= 1'b1;
			//16'h001C: FLA_rstb <= 1'b1;
			16'h0018: CTRL_EXT_rstb <= 1'b1;
			16'h0020: MDIC_rstb <= 1'b1;
			16'h0028: FCAL_rstb <= 1'b1;
			16'h002C: FCAH_rstb <= 1'b1;
			16'h0030: FCT_rstb <= 1'b1;
			16'h0038: VET_rstb <= 1'b1;
			16'h0170: FCTTV_rstb <= 1'b1;
			//16'h0178: TXCW_rstb <= 1'b1;
			//16'h0180: RXCW_rstb <= 1'b1;
			16'h0E00: LEDCTL_rstb <= 1'b1;
			16'h1000: PBA_rstb <= 1'b1;
			//16'h00C0: ICR_rstb <= 1'b1;
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
			16'h4000: CFCERRS_rstb <= 1'b1;
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
		CFCERRS_rstb <= 1'b0;
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
endmodule
