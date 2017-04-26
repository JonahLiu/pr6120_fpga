module grpci2_master_ctrl(
	input clk,
	input rst,

	input ahb_m_hgrant,
	input ahb_m_hready,
	input [1:0] ahb_m_hresp,
	input [31:0] ahb_m_hrdata,
	output ahb_m_hbusreq,
	output ahb_m_hlock,
	output [1:0] ahb_m_htrans,
	output [31:0] ahb_m_haddr,
	output ahb_m_hwrite,
	output [2:0] ahb_m_hsize,
	output [2:0] ahb_m_hburst,
	output [3:0] ahb_m_hprot,
	output [31:0] ahb_m_hwdata,

	output [9:0] wdata_idx,
	input [31:0] wdata_dout,
	input [3:0] wdata_strb,

	input [3:0] wcmd_id,
	input [7:0] wcmd_len,
	input [63:0] wcmd_addr,
	input wcmd_valid,
	output wcmd_ready,

	output [3:0] wresp_id,
	output [7:0] wresp_len,
	output [1:0] wresp_err,
	output wresp_valid,
	input wresp_ready,

	input [3:0] rcmd_id,
	input [7:0] rcmd_len,
	input [63:0] rcmd_addr,
	input rcmd_valid,
	output rcmd_ready,

	output [3:0] rresp_id,
	output [7:0] rresp_len,
	output [1:0] rresp_err,
	output rresp_valid,
	input rresp_ready,

	output [31:0] rdata_din,
	output rdata_valid,
	input rdata_ready,

	input [7:0] cacheline_size
);

localparam AXI_OK = 0, AXI_EXOK = 1, AXI_SLVERR = 2, AXI_DECERR = 3;
localparam AHB_IDLE=2'b00, AHB_BUSY=2'b01, AHB_NONSEQ=2'b10, AHB_SEQ=2'b11;
localparam AHB_OKAY=2'b00, AHB_ERROR=2'b01, AHB_RETRY=2'b10, AHB_SPLT=2'b11;
localparam AHB_SINGLE=3'b000, AHB_INCR=3'b001, 
	AHB_WRAP4  =3'b010, AHB_INCR4  =3'b011,
	AHB_WRAP8  =3'b100, AHB_INCR8  =3'b101,
	AHB_WRAP16 =3'b110, AHB_INCR16 =3'b111;
localparam AHB_8BIT=3'b000, AHB_16BIT=3'b001, AHB_32BIT=3'b010;

reg [31:0] haddr_r;
reg hbusreq_r;
reg hwrite_r;
reg [1:0] htrans_r;
reg [2:0] hsize_r;
reg [31:0] hwdata_r;

reg wcmd_ready_r;
reg [1:0] wresp_err_r;
reg wresp_valid_r;
reg rcmd_ready_r;
reg [1:0] rresp_err_r;
reg rresp_valid_r;

reg [3:0] id;
reg [7:0] length_m1;
reg [8:0] count;
reg write_cycle;
reg [9:0] idx_r;

reg write_data_valid;
reg [31:0] write_ack_addr;
reg [9:0] write_ack_idx;
reg [8:0] write_ack_cnt;

assign wdata_idx = idx_r;

assign wcmd_ready = wcmd_ready_r;
assign wresp_id = id;
assign wresp_len = length_m1;
assign wresp_err = wresp_err_r;
assign wresp_valid = wresp_valid_r;
assign rresp_id = id;
assign rresp_len = length_m1;
assign rresp_err = rresp_err_r;
assign rresp_valid = rresp_valid_r;

assign ahb_m_hbusreq = hbusreq_r;
assign ahb_m_hlock = 1'b0;
assign ahb_m_htrans = htrans_r;
assign ahb_m_haddr = haddr_r;
assign ahb_m_hwrite = hwrite_r;
assign ahb_m_hsize = hsize_r;
assign ahb_m_hburst = AHB_INCR;
assign ahb_m_hprot = 4'b1111;
assign ahb_m_hwdata = hwdata_r;

integer s1, s1_next;

localparam S1_IDLE=0, S1_WRITE_INIT=1, S1_WRITE_NONSEQ=2, S1_WRITE_SEQ=3, 
	S1_WRITE_WAIT=4, S1_WRITE_DONE=5, S1_WRITE_FAIL=6, S1_READ_INIT=7;
localparam S1_WRITE_RETRY=8, S1_WRITE_RESP=9, S1_WRITE_LAST=10;

always @(posedge clk, posedge rst)
begin
	if(rst)
		s1 <= S1_IDLE;
	else
		s1 <= s1_next;
end

always @(*)
begin
	case(s1)
		S1_IDLE: begin
			if(write_cycle)
				if(rcmd_valid)
					s1_next = S1_READ_INIT;
				else if(wcmd_valid)
					s1_next = S1_WRITE_INIT;
				else
					s1_next = S1_IDLE;
			else
				if(wcmd_valid)
					s1_next = S1_WRITE_INIT;
				else if(rcmd_valid)
					s1_next = S1_READ_INIT;
				else
					s1_next = S1_IDLE;
		end
		S1_WRITE_INIT: begin
			s1_next = S1_WRITE_NONSEQ;
		end
		S1_WRITE_NONSEQ, S1_WRITE_SEQ, S1_WRITE_WAIT: begin
			if(ahb_m_hready &&  ahb_m_hgrant && ahb_m_hresp==AHB_OKAY)
				if(count == length_m1)
					s1_next = S1_WRITE_LAST;
				else
					s1_next = S1_WRITE_SEQ;
			else if(!ahb_m_hgrant || ahb_m_hresp == AHB_RETRY || ahb_m_hresp == AHB_SPLT)
				s1_next = S1_WRITE_RETRY;
			else if(ahb_m_hresp == AHB_ERROR)
				s1_next = S1_WRITE_FAIL;
			else
				s1_next = S1_WRITE_WAIT;
		end
		S1_WRITE_LAST: begin
			if(ahb_m_hready) 
				s1_next = S1_WRITE_DONE;
			else if(ahb_m_hresp==AHB_ERROR)
				s1_next = S1_WRITE_FAIL;
			else if(ahb_m_hresp==AHB_RETRY || ahb_m_hresp==AHB_SPLT)
				s1_next = S1_WRITE_RETRY;
			else
				s1_next = S1_WRITE_LAST;
		end
		S1_WRITE_RETRY: begin
			s1_next = S1_WRITE_NONSEQ;
		end
		S1_WRITE_DONE: begin
			if(wresp_ready)
				s1_next = S1_IDLE;
			else
				s1_next = S1_WRITE_DONE;
		end
		S1_WRITE_FAIL: begin
			if(wresp_ready)
				s1_next = S1_IDLE;
			else
				s1_next = S1_WRITE_FAIL;
		end
		default: begin
			s1_next = 'bx;
		end
	endcase
end

always @(posedge clk, posedge rst)
begin
	if(rst) begin
		id <= 'bx;
		length_m1 <= 'bx;
		wcmd_ready_r <= 1'b0;
		write_cycle <= 1'b0;
		haddr_r <= 'bx;
		hbusreq_r <= 1'b0;
		hwrite_r <= 1'bx;
		count <= 'bx;
		htrans_r <= AHB_IDLE;
		hwdata_r <= 'bx;
		wresp_valid_r <= 1'b0;
		wresp_err_r <= 'b0;

		rcmd_ready_r <= 1'b0;
		rresp_valid_r <= 1'b0;
		rresp_err_r <= 'b0;

		idx_r <= 0;
	end
	else case(s1_next)
		S1_IDLE: begin
			wcmd_ready_r <= 1'b0;
			wresp_valid_r <= 1'b0;
		end
		S1_WRITE_INIT: begin
			id <= wcmd_id;
			length_m1 <= wcmd_len;
			wcmd_ready_r <= 1'b1;
			write_cycle <= 1'b1;
			haddr_r <= wcmd_addr;
			hwrite_r <= 1'b1;
			count <= 'b0;
		end
		S1_WRITE_NONSEQ: begin
			wcmd_ready_r <= 1'b0;
			haddr_r <= write_ack_addr;
			hbusreq_r <= 1'b1;
			htrans_r <= AHB_NONSEQ;
			count <= write_ack_cnt;
			idx_r <= write_ack_idx;
		end
		S1_WRITE_SEQ: begin
			htrans_r <= AHB_SEQ;
			haddr_r <= {haddr_r[31:2],2'b00}+4;

			// data of previous beat
			hwdata_r <= wdata_dout;
			count <= count+1;
			idx_r <= idx_r+1;
		end
		S1_WRITE_RETRY: begin
			hbusreq_r <= 1'b0;
			htrans_r <= AHB_IDLE;
		end
		S1_WRITE_WAIT: begin
		end
		S1_WRITE_LAST: begin
			htrans_r <= AHB_IDLE;
			hwdata_r <= wdata_dout;
		end
		S1_WRITE_DONE: begin
			htrans_r <= AHB_IDLE;
			hbusreq_r <= 1'b0;
			wresp_valid_r <= 1'b1;
			wresp_err_r <= AXI_OK;
		end
		S1_WRITE_FAIL: begin
			wresp_valid_r <= 1'b1;
			wresp_err_r <= AXI_DECERR;
		end
	endcase
end

always @(*)
begin
	if(write_cycle)
		case(wdata_strb)
			4'b0001,4'b0010,4'b0100,4'b1000: hsize_r = AHB_8BIT;
			4'b0011,4'b1100: hsize_r = AHB_16BIT;
			4'b1111: hsize_r = AHB_32BIT;
			default: hsize_r = 'bx;
		endcase
	else
		hsize_r = AHB_32BIT;
end

always @(posedge clk, posedge rst)
begin
	if(rst) 
		write_data_valid <= 1'b0;
	else if(s1==S1_WRITE_NONSEQ)
		write_data_valid <= 1'b1;
	else if(write_data_valid && ahb_m_hready && ahb_m_hresp==AHB_OKAY && write_ack_cnt==length_m1)
		write_data_valid <= 1'b0;
	else if(!ahb_m_hready && ahb_m_hresp!=AHB_OKAY)
		write_data_valid <= 1'b0;
end

always @(posedge clk, posedge rst)
begin
	if(rst) begin
		write_ack_cnt <= 1'b0;
		write_ack_addr <= 'bx;
	end
	else if(s1_next==S1_WRITE_INIT) begin
		write_ack_cnt <= 0;
		write_ack_addr <= wcmd_addr;
	end
	else if(write_data_valid && ahb_m_hready && ahb_m_hresp==AHB_OKAY) begin
		write_ack_cnt <= write_ack_cnt+1;
		write_ack_addr <= {write_ack_addr[31:2],2'b00}+4;
	end
end

always @(posedge clk, posedge rst)
begin
	if(rst) begin
		write_ack_idx <= 'b0;
	end
	else if(write_data_valid && ahb_m_hready && ahb_m_hresp==AHB_OKAY) begin
		write_ack_idx <= write_ack_idx+1;
	end
end

endmodule
