module pci_master_ctrl(
	input rst,
	input clk,

	output [31:0] ADIO_IN,
	input [31:0] ADIO_OUT,
	output REQUEST,
	output REQUESTHOLD,
	output [3:0] M_CBE,
	output M_WRDN,
	output COMPLETE,
	output M_READY,
	input M_DATA_VLD,
	input M_SRC_EN,
	input TIME_OUT,
	input M_DATA,
	input M_ADDR_N,
	input STOPQ_N,

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
localparam 
	CMD_INTR_ACK = 4'h0,
	CMD_SPECIAL = 4'h1,
	CMD_IO_READ = 4'h2,
	CMD_IO_WRITE = 4'h3,
	CMD_MEM_READ = 4'h6,
	CMD_MEM_WRITE = 4'h7,
	CMD_CONF_READ = 4'hA,
	CMD_CONF_WRITE = 4'hB,
	CMD_MEM_READ_MUL = 4'hC,
	CMD_DUAL_ADDR_CYC = 4'hD,
	CMD_MEM_READ_LN = 4'hE,
	CMD_MEM_WRITE_INVAL = 4'hF;

localparam
	RESP_OK = 0,
	RESP_EXOK = 1,
	RESP_SLVERR = 2,
	RESP_DECERR = 3;

reg [31:0] write_addr;
reg request_r;
reg request_hold_r;
reg [3:0] bus_command;
reg write_cycle;
reg [7:0] write_stb_cnt;
reg [8:0] write_ack_cnt;
reg m_ready_r;

reg [9:0] init_data_index;
reg [9:0] write_data_index;

reg wcmd_ready_r;
reg [1:0] wresp_err_r;
reg wresp_valid_r;
reg rcmd_ready_r;
reg [1:0] rresp_err_r;
reg rresp_valid_r;

reg [3:0] write_id;
reg [7:0] write_len_m1;

reg [3:0] read_id;
reg [7:0] read_len_m1;

reg [7:0] read_ack_cnt;
reg [31:0] read_addr;
reg [8:0] read_len;


reg rresp_fill;

reg target_abort;

wire [3:0] write_be_n;
wire [8:0] cacheline_mask;

assign ADIO_IN = M_ADDR_N?wdata_dout:(write_cycle?write_addr:read_addr);
assign REQUEST = request_r;
assign REQUESTHOLD = request_hold_r;
assign M_CBE = M_ADDR_N?(write_cycle?write_be_n:4'b0000):bus_command;
assign M_WRDN = write_cycle;
//assign COMPLETE = (write_stb_cnt==write_len_m1) || !STOPQ_N;
assign M_READY = m_ready_r;

assign wdata_idx = write_data_index;

assign wcmd_ready = wcmd_ready_r;

assign wresp_valid = wresp_valid_r;
assign wresp_err = wresp_err_r;

assign rcmd_ready = rcmd_ready_r;

assign rresp_valid = rresp_valid_r;
assign rresp_err = rresp_err_r;

assign rdata_valid = (!write_cycle && M_DATA_VLD) || rresp_fill ;

assign rdata_din = ADIO_OUT;

assign write_be_n = ~wdata_strb;

assign cacheline_mask = {1'b0,cacheline_size}-1;

assign wresp_id = write_id;
assign wresp_len = write_len_m1;
assign rresp_id = read_id;
assign rresp_len = read_len_m1;

integer state, state_next;

localparam S_IDLE=0, S_WRITE_INIT=1, S_WRITE_REQ=2, S_WRITE_ADDR=3,
	S_WRITE_DATA=4, S_WRITE_CONT=5, S_WRITE_DONE=6, S_WRITE_FAIL=7,
	S_READ_INIT=8, S_READ_REQ=9, S_READ_ADDR=10, S_READ_DATA=11,
	S_READ_CONT=12, S_READ_DONE=13, S_READ_FILL=14, S_READ_FAIL=15;

always @(posedge clk, posedge rst)
begin
	if(rst)
		state <= S_IDLE;
	else
		state <= state_next;
end

always @(*)
begin
	case(state)
		S_IDLE: begin
			if(write_cycle) 
				if(rcmd_valid)
					state_next = S_READ_INIT;
				else if(wcmd_valid)
					state_next = S_WRITE_INIT;
				else
					state_next = S_IDLE;
			else 
				if(wcmd_valid)
					state_next = S_WRITE_INIT;
				else if(rcmd_valid)
					state_next = S_READ_INIT;
				else
					state_next = S_IDLE;
		end
		S_WRITE_INIT: begin
			state_next = S_WRITE_REQ;
		end
		S_WRITE_REQ: begin
			state_next = S_WRITE_ADDR;
		end
		S_WRITE_ADDR: begin
			if(!M_ADDR_N)
				state_next = S_WRITE_DATA;
			else
				state_next = S_WRITE_ADDR;
		end
		S_WRITE_DATA: begin
			if(M_DATA_VLD && write_ack_cnt==write_len_m1)
				state_next = S_WRITE_DONE;
			else if(target_abort)
				state_next = S_WRITE_CONT;
			else if(!M_DATA)
				if(write_ack_cnt)
					state_next = S_WRITE_CONT;
				else
					state_next = S_WRITE_FAIL;
			else
				state_next = S_WRITE_DATA;
		end
		S_WRITE_CONT: begin
			if(!M_DATA)
				state_next = S_WRITE_REQ;
			else
				state_next = S_WRITE_CONT;
		end
		S_WRITE_DONE: begin
			if(wresp_ready)
				state_next = S_IDLE;
			else
				state_next = S_WRITE_DONE;
		end
		S_WRITE_FAIL: begin
			if(wresp_ready)
				state_next = S_IDLE;
			else
				state_next = S_WRITE_FAIL;
		end
		S_READ_INIT: begin
			state_next = S_READ_REQ;
		end
		S_READ_REQ: begin
			state_next = S_READ_ADDR;
		end
		S_READ_ADDR: begin
			if(!M_ADDR_N)
				state_next = S_READ_DATA;
			else
				state_next = S_READ_ADDR;
		end
		S_READ_DATA: begin
			if(M_DATA_VLD && read_ack_cnt==read_len_m1)
				state_next = S_READ_DONE;
			else if(target_abort)
				state_next = S_READ_CONT;
			else if(!M_DATA)
				if(read_ack_cnt)
					state_next = S_READ_CONT;
				else
					state_next = S_READ_FILL;
			else
				state_next = S_READ_DATA;
		end
		S_READ_CONT: begin
			if(!M_DATA)
				state_next = S_READ_REQ;
			else
				state_next = S_READ_CONT;
		end
		S_READ_DONE: begin
			if(rresp_ready)
				state_next = S_IDLE;
			else
				state_next = S_READ_DONE;
		end
		S_READ_FILL: begin
			if(read_ack_cnt==read_len_m1)
				state_next = S_READ_FAIL;
			else
				state_next = S_READ_FILL;
		end
		S_READ_FAIL: begin
			if(rresp_ready)
				state_next = S_IDLE;
			else
				state_next = S_READ_FAIL;
		end
		default: begin
			state_next = 'bx;
		end
	endcase
end

always @(posedge clk, posedge rst)
begin
	if(rst) begin
			request_r <= 1'b0;
			request_hold_r <= 1'b0;
			m_ready_r <= 1'b1;
			wcmd_ready_r <= 1'b0;
			wresp_valid_r <= 1'b0;
			rcmd_ready_r <= 1'b0;
			rresp_valid_r <= 1'b0;
			write_id <= 'bx;
			write_len_m1 <= 'bx;
			write_cycle <= 1'b0;
			target_abort <= 1'bx;
			bus_command <= 'bx;
			wresp_err_r <= 'bx;
			read_id <= 'bx;
			read_len_m1 <= 'bx;
			rresp_err_r <= 'bx;
			rresp_fill <= 1'b0;
	end
	else case(state_next)
		S_IDLE: begin
			request_r <= 1'b0;
			request_hold_r <= 1'b0;
			wcmd_ready_r <= 1'b0;
			wresp_valid_r <= 1'b0;
			rcmd_ready_r <= 1'b0;
			rresp_valid_r <= 1'b0;
		end
		S_WRITE_INIT: begin
			write_id <= wcmd_id;
			write_len_m1 <= wcmd_len;
			write_cycle <= 1'b1;
			wcmd_ready_r <= 1'b1;
		end
		S_WRITE_REQ: begin
			wcmd_ready_r <= 1'b0;
			request_r <= 1'b1;
			target_abort <= 1'b0;
		end
		S_WRITE_ADDR: begin
			request_r <= 1'b0;
			//TODO: try MEM_WRITE_INVAL
			bus_command <= CMD_MEM_WRITE;
		end
		S_WRITE_DATA: begin
			if(!STOPQ_N)
				target_abort <= 1'b1;
		end
		S_WRITE_CONT: begin
		end
		S_WRITE_DONE: begin
			wresp_valid_r <= 1'b1;
			wresp_err_r <= RESP_OK;
		end
		S_WRITE_FAIL: begin
			wresp_valid_r <= 1'b1;
			wresp_err_r <= RESP_DECERR;
		end
		S_READ_INIT: begin
			read_id <= rcmd_id;
			read_len_m1 <= rcmd_len;

			write_cycle <= 1'b0;

			rcmd_ready_r <= 1'b1;
		end
		S_READ_REQ: begin
			rcmd_ready_r <= 1'b0;
			request_r <= 1'b1;
			target_abort <= 1'b0;
		end
		S_READ_ADDR: begin
			request_r <= 1'b0;

			if(read_len==1)
				bus_command <= CMD_MEM_READ;
			if(((read_addr+read_len)^read_addr)&(~cacheline_mask)) // cross cacheline bundary
				bus_command <= CMD_MEM_READ_MUL;
			else
				bus_command <= CMD_MEM_READ_LN;
		end
		S_READ_DATA: begin
			if(!STOPQ_N)
				target_abort <= 1'b1;
		end
		S_READ_CONT: begin
		end
		S_READ_DONE: begin
			rresp_valid_r <= 1'b1;
			rresp_err_r <= RESP_OK;
		end
		S_READ_FILL: begin
			rresp_fill <= 1'b1;
		end
		S_READ_FAIL: begin
			rresp_fill <= 1'b0;
			rresp_valid_r <= 1'b1;
			rresp_err_r <= RESP_SLVERR;
		end
	endcase
end

always @(posedge clk, posedge rst)
begin
	if(rst) begin
		init_data_index <= 'b0;
	end
	else if(wresp_valid && wresp_ready) begin
		init_data_index <= init_data_index+write_ack_cnt;
	end
end

always @(posedge clk)
begin
	if(state_next == S_WRITE_INIT) begin
		write_stb_cnt <= 'b0;
	end
	else if(M_SRC_EN/* && !COMPLETE*/) begin
		write_stb_cnt <= write_stb_cnt + 1;
	end
end

always @(posedge clk)
begin
	if(state_next == S_WRITE_REQ) begin
		write_data_index <= init_data_index+write_ack_cnt;
	end
	else if(M_SRC_EN) begin
		write_data_index <= write_data_index + 1;
	end
end

always @(posedge clk)
begin
	if(state_next == S_WRITE_INIT) begin
		write_ack_cnt <= 'b0;
		write_addr <= {wcmd_addr[31:2],2'b00};
	end
	else if(M_DATA_VLD) begin
		write_ack_cnt <= write_ack_cnt + 1;
		write_addr <= write_addr + 3'b100;
	end
end

always @(posedge clk)
begin
	if(state_next == S_READ_INIT) begin
		read_ack_cnt <= 'b0;
		read_addr <= {rcmd_addr[31:2],2'b00};
		read_len <= rcmd_len+1;
	end
	else if(rdata_valid) begin
		read_ack_cnt <= read_ack_cnt + 1;
		read_addr <= read_addr + 3'b100;
		read_len <= read_len-1;
	end
end

reg [7:0] complete_cnt;
wire FIN1, FIN2, FIN3;
wire ASSERT_COMPLETE;
reg HOLD_COMPLETE;
reg M_DATAQ;

always @(posedge clk)
begin
	M_DATAQ <= M_DATA;
end

always @(posedge clk)
begin
	if(state==S_READ_INIT)
		complete_cnt <= read_len_m1;
	else if(state==S_WRITE_INIT)
		complete_cnt <= write_len_m1;
	else if(M_DATA_VLD)
		complete_cnt <= complete_cnt-1;
end


assign FIN1 = (complete_cnt==0) & REQUEST;
assign FIN2 = (complete_cnt==1) & M_DATAQ;
assign FIN3 = (complete_cnt==2) & M_DATA_VLD;
assign ASSERT_COMPLETE = FIN1 | FIN2 | FIN3;
assign COMPLETE = ASSERT_COMPLETE | HOLD_COMPLETE;

always @(posedge clk, posedge rst)
begin
	if(rst)
		HOLD_COMPLETE = 1'b0;
	else if(!M_DATA && M_DATAQ)
		HOLD_COMPLETE = 1'b0;
	else if(ASSERT_COMPLETE)
		HOLD_COMPLETE = 1'b1;
end



endmodule
