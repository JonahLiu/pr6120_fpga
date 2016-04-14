module tx_ctrl(
	input aclk,
	input aresetn,

	// Parameters
	input EN, // Transmit Enable
	input PSP, // Pad Short Packets
	input [63:0] TDBA, // Transmit Descriptor Base Address
	input [12:0] TDLEN, // Transmit Descriptor Buffer length=TDLEN*16*8
	input [15:0] TDH, // Transmit Descriptor Head
	input [15:0] TDT, // Transmit Descriptor Tail
	input [15:0] TIDV, // Interrupt Delay
	input DPP, // Disable Packet Prefetching
	input [5:0] PTHRESH, // Prefetch Threshold
	input [5:0] HTHRESH, // Host Threshold
	input [5:0] WTHRESH, // Write Back Threshold
	input GRAN, // Granularity
	input [5:0] LWTHRESH, // Tx Desc Low Threshold
	input [15:0] IDV, // Absolute Interrupt Delay
	input [15:0] TSMT, // TCP Segmentation Minimum Transfer
	input [15:0] TSPBP, // TCP Segmentation Packet Buffer Padding

	input [3:0] ram_m_awid,
	input [15:0] ram_m_awaddr,

	input [3:0] ram_m_awlen,
	input [2:0] ram_m_awsize,
	input [1:0] ram_m_awburst,
	input ram_m_awvalid,
	output ram_m_awready,

	input [3:0] ram_m_wid,
	input [31:0] ram_m_wdata,
	input [3:0] ram_m_wstrb,
	input ram_m_wlast,
	input ram_m_wvalid,
	output ram_m_wready,

	input [3:0] ram_m_bid,
	input [1:0] ram_m_bresp,
	input ram_m_bvalid,
	output ram_m_bready,

	input [3:0] ram_m_arid,
	input [15:0] ram_m_araddr,
	input [3:0] ram_m_arlen,
	input [2:0] ram_m_arsize,
	input [1:0] ram_m_arburst,
	input ram_m_arvalid,
	output ram_m_arready,

	input [3:0] ram_m_rid,
	input [31:0] ram_m_rdata,
	input [1:0] ram_m_rresp,
	input ram_m_rlast,
	input ram_m_rvalid,
	output ram_m_rready,

	output [31:0] idma_m_tdata,
	output idma_m_tvalid,
	output idma_m_tlast,
	input idma_m_tready,

	input [31:0] idma_s_tdata,
	input idma_s_tvalid,
	input idma_s_tlast,
	output idma_s_tready
);

// iDMA Command Dispatch
integer s1, s1_next;

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn)
		s1 <= S_IDLE;
	else
		s1 <= s1_next;
end

always @(*)
begin
	case(s1)
		S_IDLE: begin
			if(EN)
				s1_next = S_READY;
			else
				s1_next = S_IDLE;
		end
		S_READY: begin
			if(td_out_prog_full || td_out_tmo_flush)
				s1_next = S_TDWB_1;
			else if(td_in_prog_empty && td_host_prog_full)
				s1_next = S_TDRD_1;
			else
				s1_next = S_READY;
		end
	endcase
end


endmodule
