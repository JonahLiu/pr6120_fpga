module pci_target #(
	ADDR_VALID_BITS=24
)
(
	input [31:0] ADDR,
	output [31:0] ADIO_IN,
	input [31:0] ADIO_OUT,
	input ADDR_VLD,
	input [7:0] BASE_HIT,
	output S_TERM,
	output S_READY,
	output S_ABORT,
	input S_WRDN,
	input S_SRC_EN,
	input S_DATA_VLD,
	input S_CBE,
	input RST,
	input CLK,	

	input tgt_m_aclk,
	input tgt_m_aresetn,

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
	output tgt_m_arvalid,
	input	tgt_m_arready,

	input	[31:0] tgt_m_rdata,
	input	[1:0] tgt_m_rresp,
	input	tgt_m_rvalid,
	output  tgt_m_rready
);

reg s_term_r;
reg s_ready_r;
reg s_abort_r;
reg s_addr_r;
reg s_data_r;
reg awvalid_r;
reg wvalid_r;
reg bready_r;
reg [31:0] awaddr_r;
reg [31:0] wdata_r;
reg [3:0] wstrb_r;
reg write_ready;
reg arvalid_r;
reg rready_r;
reg [31:0] araddr_r;
reg [31:0] read_data;
reg read_ready;

integer state, state_next;
integer ws, ws_next;
integer rs, rs_next;

localparam S_IDLE=0, S_WRITE_0=1, S_WRITE_1=2, S_READ_0=3, S_READ_1=4;
localparam WS_IDLE=0, WS_LAT=1, WS_WRITE_REQ=2, WS_WRITE_ACK=3, WS_WRITE_WAIT=4;
localparam RS_IDLE=0, RS_LAT=1, RS_READ_ASTB=2, RS_READ_AWAIT=3, RS_READ_DWAIT=4, RS_READ_LATCH=5, RS_READ_READY=6;

assign ADIO_IN = s_data_r;
assign S_TERM = s_term_r;
assign S_READY = s_ready_r;
assign S_ABORT = s_abort_r;

assign tgt_m_awaddr = awaddr_r;
assign tgt_m_awvalid = awvalid_r;
assign tgt_m_wdata = wdata_r;
assign tgt_m_wstrb = wstrb_r;
assign tgt_m_wvalid = wvalid_r;
assign tgt_m_bready = bready_r;
assign tgt_m_araddr = araddr_r;
assign tgt_m_arvalid = arvalid_r;
assign tgt_m_rready = rready_r;

always @(posedge CLK, posedge RST)
begin
	if(RST)
		state <= S_IDLE;
	else
		state <= state_next;
end

always @(*)
begin
	case(state)
		S_IDLE: begin
			if(BASE_HIT)
				if(S_WRDN)
					if(write_ready)
						state_next = S_WRITE_1;
					else
						state_next = S_WRITE_0;
				else
					state_next = S_READ_0;
			else
				state_next = S_IDLE;
		end
		S_WRITE_0: begin
			if(!S_DATA)
				state_next = S_IDLE;
			else if(write_ready)
				state_next = S_WRITE_1;
			else
				state_next = S_WRITE_0;
		end
		S_WRITE_1: begin
			if(!S_DATA || S_DATA && S_DATA_VLD)
				state_next = S_IDLE;
			else
				state_next = S_WRITE_1;
		end
		S_READ_0: begin
			if(!S_DATA)
				state_next = S_IDLE;
			else if(read_ready)
				state_next = S_READ_1;
			else
				state_next = S_READ_0;
		end
		S_READ_1: begin
			if(!S_DATA || S_DATA && S_DATA_VLD)
				state_next = S_IDLE;
			else
				state_next = S_READ_1;
		end
		default: begin
			state_next = 'bx;
		end
	endcase
end

always @(posedge CLK, posedge RST)
begin
	if(RST) begin
		s_term_r <= 1'b0;
		s_ready_r <= 1'b0;
		s_abort_r <= 1'b0;
		s_data_r <= 'bx;
	end
	else case(state_next)
		S_IDLE: begin
			s_term_r <= 1'b0;
			s_ready_r <= 1'b0;
			s_abort_r <= 1'b0;
		end
		S_WRITE_0: begin
		end
		S_WRITE_1: begin
			s_term_r <= 1'b1;
			s_ready_r <= 1'b1;
			s_data_r <= ADIO_OUT;
			be_r <= ~S_CBE;
		end
		S_READ_0: begin
		end
		S_READ_1: begin
			s_data_r <= read_data;
			s_term_r <= 1'b1;
			s_ready_r <= 1'b1;
		end
	endcase
end

always @(posedge CLK)
begin
	if(BASE_HIT) begin
		s_addr_r[ADDR_VALID_BITS-1:0] <= ADDR;
		s_addr_r[31:ADDR_VALID_BITS] <= BASE_HIT;
	end
end

always @(posedge tgt_m_aclk, negedge tgt_m_aresetn)
begin
	if(!tgt_m_aresetn)
		ws <= WS_IDLE;
	else
		ws <= ws_next;
end

always @(*)
begin
	case(ws)
		WS_IDLE: begin
			if(state==S_WRITE_1) 
				ws_next = WS_LAT;
			else
				ws_next = WS_IDLE;
		end
		WS_LAT: begin
			ws_next = WS_WRITE_REQ;
		end
		WS_WRITE_REQ: begin
			ws_next = WS_WRITE_ACK;
		end
		WS_WRITE_ACK: begin
			if((!awvalid_r || tgt_m_awready) &&
				(!wvalid_r || tgt_m_wready))
				ws_next = WS_WRITE_WAIT;
			else
				ws_next = WS_WRITE_ACK;
		end
		WS_WRITE_WAIT: begin
			if(tgt_m_bvalid)
				ws_next = WS_IDLE;
			else
				ws_next = WS_WRITE_WAIT;
		end
	endcase
end

always @(posedge tgt_m_aclk, negedge tgt_m_aresetn)
begin
	if(!tgt_m_aresetn) begin
		awvalid_r <= 1'b0;
		wvalid_r <= 1'b0;
		bready_r <= 1'b0;
		awaddr_r <= 'bx;
		wdata_r <= 'bx;
		wstrb_r <= 'bx;
		write_ready <= 1'b0;
	end
	else case(ws_next)
		WS_IDLE: begin
			awvalid_r <= 1'b0;
			wvalid_r <= 1'b0;
			bready_r <= 1'b0;
			write_ready <= 1'b1;
		end
		WS_LAT: begin
			write_ready <= 1'b0;
		end
		WS_WRITE_REQ: begin
			awaddr_r <= s_addr_r;
			awvalid_r <= 1'b1;
			wdata_r <= s_data_r;
			wstrb <= be_r;
			wvalid_r <= 1'b1;
		end
		WS_WRITE_ACK: begin
			if(tgt_m_awready)
				awvalid_r <= 1'b0;
			if(tgt_m_wready)
				wvalid_r <= 1'b0;
		end
		WS_WRITE_WAIT: begin
			awvalid_r <= 1'b0;
			wvalid_r <= 1'b0;
			bready_r <= 1'b1;
		end
	endcase
end

always @(posedge tgt_m_aclk, negedge tgt_m_aresetn)
begin
	if(!tgt_m_aresetn)
		rs <= WS_IDLE;
	else
		rs <= rs_next;
end

always @(*)
begin
	case(rs)
		RS_IDLE: begin
			if(state==S_READ)
				rs_next = RS_LAT;
			else
				rs_next = RS_IDLE;
		end
		RS_LAT: begin
			rs_next = RS_READ_ASTB;
		end
		RS_READ_ASTB,RS_READ_AWAIT: begin
			if(tgt_m_arready)
				rs_next = RS_READ_DWAIT;
			else
				rs_next = RS_READ_AWAIT;
		end
		RS_READ_DWAIT: begin
			if(tgt_m_rvalid)
				rs_next = RS_READ_LATCH;
			else
				rs_next = RS_READ_DWAIT;
		end
		RS_READ_LATCH,RS_READ_READY: begin
			if(state!=S_READ_0)
				rs_next = RS_IDLE;
			else
				rs_next = RS_READ_READY;
		end
		default: begin
			rs_next = 'bx;
		end
	endcase
end

always @(posedge tgt_m_aclk, negedge tgt_m_aresetn)
begin
	if(!tgt_m_aresetn) begin
		arvalid_r <= 1'b0;
		rready_r <= 1'b0;
		read_ready <= 1'b0;
		araddr_r <= 'bx;
		read_data <= 'bx;
	end
	else case(rs_next)
		RS_IDLE: begin
			arvalid_r <= 1'b0;
			rready_r <= 1'b0;
			read_ready <= 1'b0;
		end
		RS_LAT: begin
		end
		RS_READ_ASTB: begin
			araddr_r <= s_addr_r;
			arvalid_r <= 1'b1;
		end
		RS_READ_AWAIT: begin
		end
		RS_READ_DWAIT: begin
			arvalid_r <= 1'b0;
		end
		RS_READ_LATCH: begin
			read_data <= tgt_m_rdata;
			rready_r <= 1'b1;
		end
		RS_READ_READY: begin
			read_ready <= 1'b1;
			rready_r <= 1'b0;
		end
	endcase
end

endmodule
