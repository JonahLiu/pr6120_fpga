module grpci2_axi_lite_tgt
(
	input aclk,
	input aresetn,

	input ahb_s_hsel,
	input [31:0] ahb_s_haddr,
	input ahb_s_hwrite,
	input [1:0] ahb_s_htrans,
	input [2:0] ahb_s_hsize,
	input [2:0] ahb_s_hburst,
	input [3:0] ahb_s_hprot,
	input [3:0] ahb_s_hmaster,
	input ahb_s_hmastlock,
	input [31:0] ahb_s_hwdata,
	input ahb_s_hready_i,
	output ahb_s_hready_o,
	output [1:0] ahb_s_hresp,
	output [31:0] ahb_s_hrdata,
	output [15:0] ahb_s_hsplit,

	output [31:0] tgt_m_awaddr,
	output tgt_m_awvalid,
	input	tgt_m_awready,

	output [31:0] tgt_m_wdata,
	output [3:0] tgt_m_wstrb,
	output tgt_m_wvalid,
	input	tgt_m_wready,

	input	[1:0] tgt_m_bresp,
	input	tgt_m_bvalid,
	output tgt_m_bready,

	output [31:0] tgt_m_araddr,
	output [3:0] tgt_m_aruser,
	output tgt_m_arvalid,
	input	tgt_m_arready,

	input	[31:0] tgt_m_rdata,
	input	[1:0] tgt_m_rresp,
	input	tgt_m_rvalid,
	output  tgt_m_rready
);

localparam AHB_IDLE=2'b00, AHB_BUSY=2'b01, AHB_NONSEQ=2'b10, AHB_SEQ=2'b11;
localparam AHB_OKAY=2'b00, AHB_ERROR=2'b01, AHB_RETRY=2'b10, AHB_SPLT=2'b11;

reg hready_r;
reg [31:0] hrdata_r;
reg [1:0] hresp_r;

reg awvalid_r;
reg wvalid_r;
reg bready_r;

reg [31:0] addr_r;

reg [31:0] wdata_r;
reg [3:0] strb_r;
reg arvalid_r;
reg rready_r;

integer s1, s1_next;

localparam S1_IDLE=0, S1_WRITE_REQ=1, S1_WRITE_ACK=2, S1_WRITE_WAIT=3,
	S1_READ_ASTB=4, S1_READ_AWAIT=5, S1_READ_DWAIT=6, S1_ERROR_1=7, S1_ERROR_2=8;

assign ahb_s_hready_o = hready_r;
assign ahb_s_hresp = hresp_r;
assign ahb_s_hrdata = hrdata_r;
assign ahb_s_hsplit = 16'hFFFF;

assign tgt_m_awaddr = addr_r;
assign tgt_m_awvalid = awvalid_r;
assign tgt_m_wdata = ahb_s_hwdata;
assign tgt_m_wstrb = strb_r;
assign tgt_m_wvalid = wvalid_r;
assign tgt_m_bready = bready_r;
assign tgt_m_araddr = addr_r;
assign tgt_m_aruser = strb_r;
assign tgt_m_arvalid = arvalid_r;
assign tgt_m_rready = rready_r;

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn)
		s1 <= S1_IDLE;
	else
		s1 <= s1_next;
end

always @(*)
begin
	case(s1)
		S1_IDLE: begin
			if(ahb_s_hsel && (ahb_s_htrans==AHB_NONSEQ || ahb_s_htrans==AHB_SEQ)
			   	&& ahb_s_hready_o && ahb_s_hready_i) 
				if(ahb_s_hwrite)
					s1_next = S1_WRITE_REQ;
				else
					s1_next = S1_READ_ASTB;
			else
				s1_next = S1_IDLE;
		end
		S1_WRITE_REQ: begin
			s1_next = S1_WRITE_ACK;
		end
		S1_WRITE_ACK: begin
			if((!awvalid_r || tgt_m_awready) &&
				(!wvalid_r || tgt_m_wready))
				s1_next = S1_WRITE_WAIT;
			else
				s1_next = S1_WRITE_ACK;
		end
		S1_WRITE_WAIT: begin
			if(tgt_m_bvalid)
				if(tgt_m_bresp[1]) // Error
					s1_next = S1_ERROR_1;
				else
					s1_next = S1_IDLE;
			else
				s1_next = S1_WRITE_WAIT;
		end
		S1_READ_ASTB,S1_READ_AWAIT: begin
			if(tgt_m_arready)
				s1_next = S1_READ_DWAIT;
			else
				s1_next = S1_READ_AWAIT;
		end
		S1_READ_DWAIT: begin
			if(tgt_m_rvalid)
				if(tgt_m_rresp[1]) // Error
					s1_next = S1_ERROR_1;
				else
					s1_next = S1_IDLE;
			else
				s1_next = S1_READ_DWAIT;
		end
		S1_ERROR_1: begin
			s1_next = S1_ERROR_2;
		end
		S1_ERROR_2: begin
			s1_next = S1_IDLE;
		end
		default: begin
			s1_next = 'bx;
		end
	endcase
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		awvalid_r <= 1'b0;
		wvalid_r <= 1'b0;
		bready_r <= 1'b0;
		addr_r <= 'bx;
		wdata_r <= 'bx;
		arvalid_r <= 1'b0;
		rready_r <= 1'b0;
		strb_r <= 'bx;
		hresp_r <= 'b0;
	end
	else case(s1_next)
		S1_IDLE: begin
			awvalid_r <= 1'b0;
			wvalid_r <= 1'b0;
			bready_r <= 1'b0;
			hready_r <= 1'b1;
			hresp_r <= AHB_OKAY;
		end
		S1_WRITE_REQ: begin
			hready_r <= 1'b0;
			addr_r <= ahb_s_haddr;
			awvalid_r <= 1'b1;
			case({ahb_s_hsize[1:0],ahb_s_haddr[1:0]})
				4'b0000: strb_r <= 4'b0001;
				4'b0001: strb_r <= 4'b0010;
				4'b0010: strb_r <= 4'b0100;
				4'b0011: strb_r <= 4'b1000;
				4'b0100: strb_r <= 4'b0011;
				4'b0110: strb_r <= 4'b1100;
				4'b1000: strb_r <= 4'b1111;
				default: strb_r <= 4'b0000;
			endcase
			wvalid_r <= 1'b1;
		end
		S1_WRITE_ACK: begin
			if(tgt_m_awready)
				awvalid_r <= 1'b0;
			if(tgt_m_wready)
				wvalid_r <= 1'b0;
		end
		S1_WRITE_WAIT: begin
			awvalid_r <= 1'b0;
			wvalid_r <= 1'b0;
			bready_r <= 1'b1;
		end
		S1_READ_ASTB: begin
			hready_r <= 1'b0;
			addr_r <= ahb_s_haddr;
			arvalid_r <= 1'b1;
			case({ahb_s_hsize[1:0],ahb_s_haddr[1:0]})
				4'b0000: strb_r <= 4'b0001;
				4'b0001: strb_r <= 4'b0010;
				4'b0010: strb_r <= 4'b0100;
				4'b0011: strb_r <= 4'b1000;
				4'b0100: strb_r <= 4'b0011;
				4'b0110: strb_r <= 4'b1100;
				4'b1000: strb_r <= 4'b1111;
				default: strb_r <= 4'b0000;
			endcase
		end
		S1_READ_AWAIT: begin
		end
		S1_READ_DWAIT: begin
			arvalid_r <= 1'b0;
			rready_r <= 1'b1;
		end
		S1_ERROR_1: begin
			hresp_r <= AHB_ERROR;
		end
		S1_ERROR_2: begin
			hready_r <= 1'b1;
		end
	endcase
end

always @(posedge aclk)
begin
	if(tgt_m_rvalid && tgt_m_rready)
		hrdata_r <= tgt_m_rdata;
end

endmodule
