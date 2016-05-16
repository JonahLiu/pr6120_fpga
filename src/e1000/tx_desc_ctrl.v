module tx_desc_ctrl(
	input aclk,
	input aresetn,

	// Parameters
	input EN, // Transmit Enable
	input [63:0] TDBA, // Transmit Descriptor Base Address
	input [12:0] TDLEN, // Transmit Descriptor Buffer length=TDLEN*16*8
	input [15:0] TDH, // Transmit Descriptor Head
	input TDH_set,
	output [15:0] TDH_fb,
	input [15:0] TDT, // Transmit Descriptor Tail
	input TDT_set,
	input [15:0] TIDV, // Interrupt Delay
	input DPP, // Disable Packet Prefetching
	input [5:0] PTHRESH, // Prefetch Threshold
	input [5:0] HTHRESH, // Host Threshold
	input [5:0] WTHRESH, // Write Back Threshold
	input GRAN, // Granularity. FIXME: not implemented
	input [5:0] LWTHRESH, // Tx Desc Low Threshold
	input [15:0] TADV, // Absolute Interrupt Delay
	output reg TXDW_req,
	output reg TXQE_req,
	output reg TXD_LOW_req,

	// Input DMA command port
	output reg [63:0] idma_src_addr,
	output reg [15:0] idma_dst_addr,
	output reg [15:0] idma_bytes,
	output reg idma_valid,
	input	idma_ready,

	// Input DMA report port
	input [63:0] irpt_src_addr,
	input [15:0] irpt_dst_addr,
	input [15:0] irpt_bytes,
	input irpt_valid,
	output irpt_ready,

	// Output DMA command port
	output reg [15:0] odma_src_addr,
	output reg [63:0] odma_dst_addr,
	output reg [15:0] odma_bytes,
	output reg odma_valid,
	input	odma_ready,

	// Output DMA report port
	input [15:0] orpt_src_addr,
	input [63:0] orpt_dst_addr,
	input [15:0] orpt_bytes,
	input orpt_valid,
	output orpt_ready,

	// tx engine command port
	// [31:16]=RSV, [15:0]=Local Address
	output reg [31:0] teng_m_tdata,
	output reg teng_m_tvalid,
	output reg teng_m_tlast,
	input teng_m_tready,

	// tx engine response port
	// [17]=IDE, [16]=RS, [15:0]=Local Address
	input [31:0] teng_s_tdata,
	input teng_s_tvalid,
	input teng_s_tlast,
	output reg teng_s_tready
);

parameter DESC_RAM_DWORDS = 1024;
parameter CLK_PERIOD_NS = 8;

function integer clogb2 (input integer size);
begin
	size = size - 1;
	for (clogb2=1; size>1; clogb2=clogb2+1)
		size = size >> 1;
end
endfunction

localparam CYCLES_1024NS = 1024/CLK_PERIOD_NS;
localparam DESC_MAX_NUM = DESC_RAM_DWORDS/4;
localparam DESC_NUM_BITS = clogb2(DESC_MAX_NUM);

// Flag memory for RS and IDE
reg [1:0] flag_mem[0:DESC_MAX_NUM-1];
reg [1:0] flag_current;
reg [3:0] delay_cnt;

wire flag_report_status;
wire flag_delay_interrupt;

// Host addresses
reg [63:0] host_wb_address;
reg [63:0] host_rd_address;

// Local addresses
wire [15:0] local_wb_address;
wire [15:0] local_rd_address;
wire [15:0] local_teng_address;

reg [7:0] fetch_num;
reg [8:0] fetch_num_s1;
reg [7:0] fetch_num_s2;
wire [11:0] fetch_bytes;

// Descriptor queues, first-in-first-out
// "tail" points to latest enqueued data
// "head" points to oldest data

// Host Queue
// Stores TX Descriptors in host memory
reg [15:0] host_head;
reg [15:0] host_curr;
reg [15:0] host_tail;
reg [15:0] host_pending;
reg [15:0] host_fresh;
reg [15:0] host_deq_incr;
reg host_dequeue;
reg [15:0] host_fwd_incr;
reg host_forward;
wire [15:0] host_length;
reg [15:0] host_limit;

// Input Queue
// Stores TX Descriptors in local memory but not submitted to TX engine
reg [DESC_NUM_BITS-1:0] in_head;
reg [DESC_NUM_BITS-1:0] in_tail;
reg [DESC_NUM_BITS-1:0] in_num;
reg [DESC_NUM_BITS-1:0] in_enq_incr;
reg in_enqueue;
reg in_dequeue;

// Output Queue
// Stores TX Descriptors in local memory that finished TX process
reg [DESC_NUM_BITS-1:0] out_head;
reg [DESC_NUM_BITS-1:0] out_tail;
reg [DESC_NUM_BITS-1:0] out_num;
reg [DESC_NUM_BITS-1:0] out_deq_incr;
reg out_enqueue;
reg out_dequeue;

// Overall local descriptors
reg [DESC_NUM_BITS:0] local_pending;
reg [DESC_NUM_BITS:0] local_available;

// Temporary variables for calculating host pointers
reg [4:0] host_calc_stage;
reg [16:0] host_head_n0;
reg [15:0] host_head_n1;
reg [16:0] host_curr_n0;
reg [15:0] host_curr_n1;
reg [16:0] host_pending_n0;
reg [16:0] host_pending_n1;
reg [15:0] host_pending_n2;
reg [16:0] host_fresh_n0;
reg [16:0] host_fresh_n1;
reg [15:0] host_fresh_n2;

// timers
reg [7:0] delay_prescale;
reg delay_tick;
reg [15:0] delay_timer;

reg [7:0] absolute_prescale;
reg absolute_tick;
reg [15:0] absolute_timer;

integer s1, s1_next;
integer s2, s2_next;

localparam S1_IDLE=0, S1_READY=1, S1_WRITE_BACK_0=2, S1_WRITE_BACK_ACK=3, 
	S1_DEQUEUE=4, S1_FETCH_0=5, S1_FETCH_ACK=6, S1_ENQUQUE=7, S1_DELAY=8,
	S1_SET_SIZE=9;

localparam S2_IDLE=0, S2_READY=1, S2_CMD=2, S2_DEQUEUE=3, S2_ACK=4, S2_ENQUEUE=5;

always @(posedge aclk)
	flag_current <= flag_mem[out_head];

assign flag_report_status = flag_current[0];
assign flag_delay_interrupt = flag_current[1];
assign fetch_bytes = {fetch_num,4'h0};


assign local_wb_address = {16'b0, out_head, 4'b0};
assign local_rd_address = {16'b0, in_tail, 4'b0};
assign local_teng_address = {16'b0, in_head, 4'b0};

assign host_length = {TDLEN, 3'b0};

assign irpt_ready = 1'b1;
assign orpt_ready = 1'b1;

always @(posedge aclk)
begin
	if(teng_s_tvalid && teng_s_tlast && teng_s_tready)
		flag_mem[out_tail] <= teng_s_tdata[17:16];
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		host_calc_stage <= 'b0;
	end
	else begin
		host_calc_stage <= {host_calc_stage,(TDH_set|TDT_set|host_dequeue|host_forward)};
	end
end

always @(posedge aclk)
begin
	if(TDH_set) begin
		host_head_n0 <= TDH;
	end
	else if(host_dequeue) begin
		host_head_n0 <= host_head + host_deq_incr;
	end

	if(host_calc_stage[0]) begin
		if(host_head_n0 >= host_length)
			host_head_n1 <= host_head_n0 - host_length;
		else
			host_head_n1 <= host_head_n0;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		host_head <= 'b0;
	end
	else if(host_calc_stage[1]) begin
		host_head <= host_head_n1;
	end
end
assign TDH_fb = host_head;

always @(posedge aclk)
begin
	if(TDH_set) begin
		host_curr_n0 <= TDH;
	end
	else if(host_forward) begin
		host_curr_n0 <= host_curr + host_fwd_incr;
	end

	if(host_calc_stage[0]) begin
		if(host_curr_n0 >= host_length)
			host_curr_n1 <= host_curr_n0 - host_length;
		else
			host_curr_n1 <= host_curr_n0;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		host_curr <= 'b0;
	end
	else if(host_calc_stage[1]) begin
		host_curr <= host_curr_n1;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		host_tail <= 'b0;
	end
	else if(TDT_set) begin
		host_tail <= TDT;
	end
end

always @(posedge aclk)
begin
	if(host_calc_stage[1]) begin
		host_pending_n0 <= host_tail + host_length;
	end

	if(host_calc_stage[2]) begin
		host_pending_n1 <= host_pending_n0 - host_head;
	end

	if(host_calc_stage[3]) begin
		if(host_pending_n1 >= host_length)
			host_pending_n2 <= host_pending_n1 - host_length;
		else
			host_pending_n2 <= host_pending_n1;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		host_pending <= 'b0;
	end
	else if(host_calc_stage[4]) begin
		host_pending <= host_pending_n2;
	end
end

always @(posedge aclk)
begin
	if(host_calc_stage[1]) begin
		host_fresh_n0 <= host_tail + host_length;
	end

	if(host_calc_stage[2]) begin
		host_fresh_n1 <= host_fresh_n0 - host_curr;
	end

	if(host_calc_stage[3]) begin
		if(host_fresh_n1 >= host_length)
			host_fresh_n2 <= host_fresh_n1 - host_length;
		else
			host_fresh_n2 <= host_fresh_n1;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		host_fresh <= 'b0;
	end
	else if(host_calc_stage[4]) begin
		host_fresh <= host_fresh_n2;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		host_limit <= 'b0;
	end
	else if(host_calc_stage[2]) begin
		host_limit <= host_length - host_curr;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		in_tail <= 'b0;
	end
	else if(in_enqueue) begin
		in_tail <= in_tail + in_enq_incr;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		in_head <= 'b0;
	end
	else if(in_dequeue) begin
		in_head <= in_head + 1;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		in_num <= 0;
	end
	else if(in_enqueue) begin
		if(in_dequeue) 
			in_num <= in_num + in_enq_incr - 1;
		else
			in_num <= in_num + in_enq_incr;
	end
	else if(in_dequeue) begin
		in_num <= in_num-1;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		out_tail <= 'b0;
	end
	else if(out_enqueue) begin
		out_tail <= out_tail + 1;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		out_head <= 'b0;
	end
	else if(out_dequeue) begin
		out_head <= out_head + out_deq_incr;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		out_num <= 0;
	end
	else if(out_dequeue) begin
		if(out_enqueue) 
			out_num <= out_num - out_deq_incr + 1;
		else
			out_num <= out_num - out_deq_incr;
	end
	else if(out_enqueue) begin
		out_num <= out_num+1;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		local_pending <= 0;
		local_available <= DESC_MAX_NUM;
	end
	else if(in_enqueue) begin
		local_pending <= local_pending+in_enq_incr;
		local_available <= local_available-in_enq_incr;
	end
	else if(out_dequeue) begin
		local_pending <= local_pending-out_deq_incr;
		local_available <= local_available+out_deq_incr;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		delay_prescale <= 'b0;
		delay_tick <= 1'b0;
	end
	else if(out_dequeue && flag_report_status && flag_delay_interrupt) begin
		delay_prescale <= 'b0;
		delay_tick <= 1'b0;
	end
	else if(delay_prescale==CYCLES_1024NS) begin
		delay_prescale <= 'b0;
		delay_tick <= 1'b1;
	end
	else begin
		delay_prescale <= delay_prescale+1;
		delay_tick <= 1'b0;
	end
end

// Delayed interrupt timer 
always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		delay_timer <= 0;
	end
	else if(out_dequeue && flag_report_status && flag_delay_interrupt) begin
		// reload timer each write-back
		delay_timer <= TIDV;
	end
	else if(TXDW_req) begin
		// If interrupt trigered, clear timer to avoid redundant interrupt
		delay_timer <= 0;
	end
	else if(delay_timer && delay_tick) begin
		delay_timer <= delay_timer-1;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		absolute_prescale <= 'b0;
		absolute_tick <= 1'b0;
	end
	else if(absolute_timer==0 && out_dequeue && flag_report_status && 
		flag_delay_interrupt) begin
		absolute_prescale <= 'b0;
		absolute_tick <= 1'b0;
	end
	else if(absolute_prescale==CYCLES_1024NS) begin
		absolute_prescale <= 'b0;
		absolute_tick <= 1'b1;
	end
	else begin
		absolute_prescale <= absolute_prescale+1;
		absolute_tick <= 1'b0;
	end
end

// Absolute interrupt timer
always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		absolute_timer <= 0;
	end
	else if(absolute_timer==0 && out_dequeue && flag_report_status && 
		flag_delay_interrupt) begin
		// reload timer on first write-back
		absolute_timer <= TADV;
	end
	else if(TXDW_req) begin
		// If interrupt trigered, clear timer to avoid redundant interrupt
		absolute_timer <= 0;
	end
	else if(absolute_timer && absolute_tick) begin
		absolute_timer <= absolute_timer-1;
	end
end

// Write-back interrupt
always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		TXDW_req <= 1'b0;
	end
	else if(out_dequeue && flag_report_status && !flag_delay_interrupt) begin
		// immedieate interrupt
		TXDW_req <= 1'b1;
	end
	else if(absolute_timer==1 && absolute_tick) begin
		// Absolute timer expired
		TXDW_req <= 1'b1;
	end
	else if(delay_timer==1 && delay_tick) begin
		// Delay timer expired
		TXDW_req <= 1'b1;
	end
	else begin
		TXDW_req <= 1'b0;
	end
end

// TXD queue interrupt
always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		TXQE_req <= 1'b0;
		TXD_LOW_req <= 1'b0;
	end
	else if(host_calc_stage[4]) begin
		if(host_pending_n2 == 0)
			TXQE_req <= 1'b1;
		if(host_pending_n2 < LWTHRESH) 
			TXD_LOW_req <= 1'b1;
	end
	else begin
		TXQE_req <= 1'b0;
		TXD_LOW_req <= 1'b0;
	end
end

/*
always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		TXQE_req <= 1'b0;
		TXD_LOW_req <= 1'b0;
	end
	else if(!(|host_calc_stage)) begin
		if(host_pending == 0)
			TXQE_req <= 1'b1;
		if(host_pending < LWTHRESH) 
			TXD_LOW_req <= 1'b1;
	end
	else begin
		TXQE_req <= 1'b0;
		TXD_LOW_req <= 1'b0;
	end
end
*/

always @(posedge aclk)
begin
	host_wb_address <= TDBA + {host_head,4'b0};
	host_rd_address <= TDBA + {host_curr,4'b0};
end

always @(*)
begin
	// Choose smallest among host_limit, host_fresh and local_available
	if(host_limit <= host_fresh && host_limit <= local_available)
		fetch_num_s1 = host_limit;
	else if(host_fresh <= host_limit && host_fresh <= local_available)
		fetch_num_s1 = host_fresh;
	else
		fetch_num_s1 = local_available;

	if(fetch_num_s1 > 1 && DPP)
		fetch_num_s2 = 1;
	else 
		fetch_num_s2 = fetch_num_s1;
end

// iDMA Command Dispatch
// Host-to-Local: if (in_num < PTHRESH && host_fresh> HTHRESH) ||
//     (DPP && local_pending == 0 && host_fresh> 0)
// Local-to-Host: if wb_num > WTHRESH || (flush_timer > TIDV && wb_num >0)

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
			if(EN)
				s1_next = S1_READY;
			else
				s1_next = S1_IDLE;
		end
		S1_READY: begin
			if(!EN)
				s1_next = S1_IDLE;
			else if(out_num>0)
				if(flag_report_status)
					// Dequeue and write back
					s1_next = S1_WRITE_BACK_0;
				else 
					// Dequeue no report
					s1_next = S1_DEQUEUE;
			else if((!DPP && (PTHRESH==0 || local_pending < PTHRESH) && 
					host_fresh > HTHRESH) ||
				(local_pending == 0))
				s1_next = S1_SET_SIZE;
			else
				s1_next = S1_READY;
		end
		S1_WRITE_BACK_0: begin // issue write-back DMA command
			if(odma_ready)
				s1_next = S1_WRITE_BACK_ACK;
			else
				s1_next = S1_WRITE_BACK_0;
		end
		S1_WRITE_BACK_ACK: begin
			if(orpt_valid)
				s1_next = S1_DEQUEUE;
			else
				s1_next = S1_WRITE_BACK_ACK;
		end
		S1_DEQUEUE: begin // Dequeue Descriptor
			s1_next = S1_DELAY;
		end
		S1_SET_SIZE: begin
			if(fetch_num>0)
				s1_next = S1_FETCH_0;
			else
				s1_next = S1_READY;
		end
		S1_FETCH_0: begin // Issue fetch DMA command
			if(idma_ready)
				s1_next = S1_FETCH_ACK;
			else
				s1_next = S1_FETCH_0;
		end
		S1_FETCH_ACK: begin
			if(irpt_valid && irpt_ready)
				s1_next = S1_ENQUQUE;
			else
				s1_next = S1_FETCH_ACK;
		end
		S1_ENQUQUE: begin // Enqueue Descriptor
			s1_next = S1_DELAY;
		end
		S1_DELAY: begin // Wait for pointers to update
			if(delay_cnt==0)
				s1_next = S1_READY;
			else
				s1_next = S1_DELAY;
		end
		default: begin
			s1_next = 'bx;
		end
	endcase
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		idma_src_addr <= 'bx;
		idma_dst_addr <= 'bx;
		idma_bytes <= 'bx;
		idma_valid <= 1'b0;

		odma_src_addr <= 'bx;
		odma_dst_addr <= 'bx;
		odma_bytes <= 'bx;
		odma_valid <= 1'b0;

		host_dequeue <= 1'b0;
		host_deq_incr <= 1'b1;

		host_forward <= 1'b0;
		host_fwd_incr <= 'bx;

		out_dequeue <= 1'b0;
		out_deq_incr <= 1'b1;

		in_enqueue <= 1'b0;
		in_enq_incr <= 'bx;

		delay_cnt <= 'bx;
		fetch_num <= 'bx;
	end
	else case(s1_next)
		S1_IDLE: begin
		end
		S1_READY: begin
		end
		S1_WRITE_BACK_0: begin
			// iDMA Command
			// Only STA byte is updated
			odma_src_addr <= {local_wb_address[15:4],4'hC};
			odma_dst_addr <= {host_wb_address[63:4],4'hC};
			odma_bytes <= 1;
			odma_valid <= 1'b1;
		end
		S1_WRITE_BACK_ACK: begin
			odma_valid <= 1'b0;
		end
		S1_DEQUEUE: begin
			host_dequeue <= 1'b1;
			host_deq_incr <= 1'b1;
			out_dequeue <= 1'b1;
			out_deq_incr <= 1'b1;
			delay_cnt <= 5;
		end
		S1_SET_SIZE: begin
			fetch_num <= fetch_num_s2;
		end
		S1_FETCH_0: begin
			idma_src_addr <= host_rd_address;
			idma_dst_addr <= local_rd_address;
			idma_bytes <= fetch_bytes;
			idma_valid <= 1'b1;
		end
		S1_FETCH_ACK: begin
			idma_valid <= 1'b0;
		end
		S1_ENQUQUE: begin
			in_enqueue <= 1'b1;
			in_enq_incr <= fetch_num;
			host_forward <= 1'b1;
			host_fwd_incr <= fetch_num;
			delay_cnt <= 5;
		end
		S1_DELAY: begin
			in_enqueue <= 1'b0;
			host_forward <= 1'b0;
			out_dequeue <= 1'b0;
			host_dequeue <= 1'b0;
			delay_cnt <= delay_cnt-1;
		end
	endcase
end

// TX engine command dispatch

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn)
		s2 <= S2_IDLE;
	else
		s2 <= s2_next;
end

always @(*)
begin
	case(s2)
		S2_IDLE: begin
			if(EN)
				s2_next = S2_READY;
			else
				s2_next = S2_IDLE;
		end
		S2_READY: begin
			if(!EN)
				s2_next = S2_IDLE;
			else if(in_num>0)
				s2_next = S2_CMD;
			else
				s2_next = S2_READY;
		end
		S2_CMD: begin
			if(teng_m_tready)
				s2_next = S2_DEQUEUE;
			else
				s2_next = S2_CMD;
		end
		S2_DEQUEUE: begin
			s2_next = S2_ACK;
		end
		S2_ACK: begin
			if(teng_s_tvalid & teng_s_tlast)
				s2_next = S2_ENQUEUE;
			else
				s2_next = S2_ACK;
		end
		S2_ENQUEUE: begin
			s2_next = S2_READY;
		end
		default: begin
			s2_next = 'bx;
		end
	endcase
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		in_dequeue <= 1'b0;
		out_enqueue <= 1'b0;
		teng_m_tdata <= 'bx;
		teng_m_tvalid <= 1'b0;
		teng_m_tlast <= 'b1;
		teng_s_tready <= 1'b0;
	end
	else case(s2_next)
		S2_IDLE: begin
		end
		S2_READY: begin
			out_enqueue <= 1'b0;
		end
		S2_CMD: begin
			teng_m_tdata <= {16'b0,local_teng_address};
			teng_m_tvalid <= 1'b1;
			teng_m_tlast <= 1'b1;
		end
		S2_DEQUEUE: begin
			teng_m_tvalid <= 1'b0;
			in_dequeue <= 1'b1;
		end
		S2_ACK: begin
			in_dequeue <= 1'b0;
			teng_s_tready <= 1'b1;
		end
		S2_ENQUEUE: begin
			teng_s_tready <= 1'b0;
			out_enqueue <= 1'b1;
		end
	endcase
end

endmodule
