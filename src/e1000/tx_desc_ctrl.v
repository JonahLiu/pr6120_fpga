module tx_desc_ctrl(
	input aclk,
	input aresetn,

	// Parameters
	input EN, // Transmit Enable
	input [63:0] TDBA, // Transmit Descriptor Base Address
	input [12:0] TDLEN, // Transmit Descriptor Buffer length=TDLEN*16*8
	input [15:0] TDH, // Transmit Descriptor Head
	input TDH_set,
	output [15:0] TDH_fb_o,
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
	output reg TXDW_set,
	output reg TXQE_set,
	output reg TXD_LOW_set,

	// idma command port
	// C1: [31]=R(0)/W(1),[30:28]=RSV, [27:16]=Bytes, [15:0]=Local Address
	// C2: Lower 32-bit address
	// C3: Upper 32-bit address
	output reg [31:0] idma_m_tdata,
	output reg idma_m_tvalid,
	output reg idma_m_tlast,
	input idma_m_tready,

	// idma response port
	// tdata content ignored
	input [31:0] idma_s_tdata,
	input idma_s_tvalid,
	input idma_s_tlast,
	output reg idma_s_tready,

	// tx engine command port
	// [31:16]=RSV, [15:0]=Local Address
	output reg [31:0] txe_m_tdata,
	output reg txe_m_tvalid,
	output reg txe_m_tlast,
	input txe_m_tready,

	// tx engine response port
	// [17]=IDE, [16]=RS, [15:0]=Local Address
	input [31:0] txe_s_tdata,
	input txe_s_tvalid,
	input txe_s_tlast,
	output reg txe_s_tready
);

parameter CLOCK_PERIOD_NS = 8;
localparam CYCLES1_1024US = 1024/CLOCK_PERIOD_NS;
localparam WAIT_LATENCY = 2;

// Flag memory for RS and IDE
reg [1:0] flag_mem[0:255];
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
wire [15:0] local_txe_address;

reg [7:0] fetch_num;
wire [11:0] fetch_bytes;

// Descriptor queues, first-in-first-out
// "tail" points to latest enqueued data
// "head" points to oldest data

// Host Queue
// Stores TX Descriptors in host memory
reg [15:0] host_head;
reg [15:0] host_tail;
reg [15:0] host_num;
reg [15:0] host_deq_incr;
reg host_dequeue;
wire [15:0] host_length;

// Input Queue
// Stores TX Descriptors in local memory but not submitted to TX engine
reg [7:0] in_head;
reg [7:0] in_tail;
reg [7:0] in_num;
reg [7:0] in_enq_incr;
reg in_enqueue;
reg in_dequeue;

// Output Queue
// Stores TX Descriptors in local memory that finished TX process
reg [7:0] out_head;
reg [7:0] out_tail;
reg [7:0] out_num;
reg [7:0] out_deq_incr;
reg out_enqueue;
reg out_dequeue;

// Overall local descriptors
reg [8:0] local_pending;
reg [8:0] local_available;

// Temporary variables for calculating host pointers
reg [4:0] host_calc_stage;
reg [15:0] host_head_n0;
reg [15:0] host_head_n1;
reg [15:0] host_num_n0;
reg [15:0] host_num_n1;
reg [15:0] host_num_n2;

// timers
reg [7:0] tick_timer;
reg timer_tick;

reg [15:0] delay_timer;

reg [15:0] absolute_timer;

integer s1, s1_next;
integer s2, s2_next;

localparam S1_IDLE=0, S1_READY=1, S1_WRITE_BACK_0=2, S1_WRITE_BACK_1=3,
	S1_WRITE_BACK_2=4, S1_WRITE_BACK_ACK=5, S1_DEQUEUE=6, S1_FETCH_0=7,
	S1_FETCH_1=8, S1_FETCH_2=9, S1_FETCH_ACK=10, S1_ENQUQUE=11, S1_DELAY=12,
	S1_SET_SIZE=13;

localparam S2_IDLE=0, S2_READY=1, S2_CMD=2, S2_DEQUEUE=3, S2_ACK=4, S2_ENQUEUE=5;

always @(posedge aclk)
	flag_current <= flag_mem[out_head];

assign flag_report_status = flag_current[0];
assign flag_delay_interrupt = flag_current[1];
assign fetch_bytes = {fetch_num,4'h0};


assign local_wb_address = {4'b1000, out_head, 4'b0};
assign local_rd_address = {4'b1000, in_tail, 4'b0};
assign local_txe_address = {4'b1000, in_head, 4'b0};

assign host_length = {TDLEN, 3'b0};

always @(posedge aclk)
begin
	if(txe_s_tvalid && txe_s_tlast && txe_s_tready)
		flag_mem[out_tail] <= txe_s_tdata[17:16];
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		host_calc_stage <= 'b0;
	end
	else begin
		host_calc_stage <= {host_calc_stage,(TDH_set|TDT_set|host_dequeue)};
	end
end

always @(posedge aclk)
begin
	if(host_dequeue) begin
		host_head_n0 <= host_head + host_deq_incr;
	end

	if(host_calc_stage[0]) begin
		if(host_head_n0 >= host_length)
			host_head_n1 <= host_head_n0 - host_length;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		host_head <= 'b0;
	end
	else if(TDH_set) begin
		host_head <= TDH;
	end
	else if(host_calc_stage[1]) begin
		host_head <= host_head_n1;
	end
end
assign TDH_fb_o = host_head;

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
		host_num_n0 <= host_tail + host_length;
	end

	if(host_calc_stage[2]) begin
		host_num_n1 <= host_num_n0 - host_head;
	end

	if(host_calc_stage[3]) begin
		if(host_num_n1 >= host_length)
			host_num_n2 <= host_num_n1 - host_length;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		host_num <= 'b0;
	end
	else if(host_calc_stage[4]) begin
		host_num <= host_num_n2;
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

always @(*)
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
		local_available <= 256;
	end
	else if(in_enqueue) begin
		local_pending <= local_pending+in_enq_incr;
	end
	else if(out_dequeue) begin
		local_available <= local_available-out_deq_incr;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		tick_timer <= 'b0;
		timer_tick <= 1'b0;
	end
	else if(tick_timer==CYCLES1_1024US) begin
		tick_timer <= 'b0;
		timer_tick <= 1'b1;
	end
	else begin
		tick_timer <= tick_timer+1;
		timer_tick <= 1'b0;
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
	else if(TXDW_set) begin
		// If interrupt trigered, clear timer to avoid redundant interrupt
		delay_timer <= 0;
	end
	else if(delay_timer && timer_tick) begin
		delay_timer <= delay_timer-1;
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
	else if(TXDW_set) begin
		// If interrupt trigered, clear timer to avoid redundant interrupt
		absolute_timer <= 0;
	end
	else if(absolute_timer && timer_tick) begin
		absolute_timer <= absolute_timer-1;
	end
end

// Write-back interrupt
always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		TXDW_set <= 1'b0;
	end
	else if(out_dequeue && flag_report_status && !flag_delay_interrupt) begin
		// immedieate interrupt
		TXDW_set <= 1'b1;
	end
	else if(absolute_timer==1 && timer_tick) begin
		// Absolute timer expired
		TXDW_set <= 1'b1;
	end
	else if(delay_timer==1 && timer_tick) begin
		// Delay timer expired
		TXDW_set <= 1'b1;
	end
	else begin
		TXDW_set <= 1'b0;
	end
end

// TXD queue interrupt
always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		TXQE_set <= 1'b0;
		TXD_LOW_set <= 1'b0;
	end
	else if(host_calc_stage[4]) begin
		if(host_num_n2==0)
			TXQE_set <= 1'b1;
		if(host_num_n2<LWTHRESH) 
			TXD_LOW_set <= 1'b1;
	end
	else begin
		TXQE_set <= 1'b0;
		TXD_LOW_set <= 1'b0;
	end
end

always @(posedge aclk)
begin
	host_wb_address <= TDBA + {host_head,4'b0};
	host_rd_address <= TDBA + {host_tail,4'b0};
end

// iDMA Command Dispatch
// Host-to-Local: if (in_num < PTHRESH && host_num > HTHRESH) ||
//     (local_pending == 0 && host_num > 0)
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
			else if((local_pending < PTHRESH && host_num > HTHRESH) ||
				(DPP && local_pending == 0 && host_num > 0))
				s1_next = S1_SET_SIZE;
			else
				s1_next = S1_READY;
		end
		S1_WRITE_BACK_0: begin // issue write-back DMA command
			if(idma_m_tready)
				s1_next = S1_WRITE_BACK_1;
			else
				s1_next = S1_WRITE_BACK_0;
		end
		S1_WRITE_BACK_1: begin
			if(idma_m_tready)
				s1_next = S1_WRITE_BACK_2;
			else
				s1_next = S1_WRITE_BACK_1;
		end
		S1_WRITE_BACK_2: begin
			if(idma_m_tready)
				s1_next = S1_WRITE_BACK_ACK;
			else
				s1_next = S1_WRITE_BACK_2;
		end
		S1_WRITE_BACK_ACK: begin
			if(idma_s_tvalid)
				s1_next = S1_DEQUEUE;
			else
				s1_next = S1_WRITE_BACK_ACK;
		end
		S1_DEQUEUE: begin // Dequeue Descriptor
			s1_next = S1_DELAY;
		end
		S1_SET_SIZE: begin
			s1_next = S1_FETCH_0;
		end
		S1_FETCH_0: begin // Issue fetch DMA command
			if(idma_m_tready)
				s1_next = S1_FETCH_1;
			else
				s1_next = S1_FETCH_0;
		end
		S1_FETCH_1: begin
			if(idma_m_tready)
				s1_next = S1_FETCH_2;
			else
				s1_next = S1_FETCH_1;
		end
		S1_FETCH_2: begin
			if(idma_m_tready)
				s1_next = S1_FETCH_ACK;
			else
				s1_next = S1_FETCH_2;
		end
		S1_FETCH_ACK: begin
			if(idma_s_tvalid && idma_s_tlast)
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
		idma_m_tdata <= 'bx;
		idma_m_tvalid <= 1'b0;
		idma_m_tlast <= 1'b0;
		idma_s_tready <= 1'b0;

		host_dequeue <= 1'b0;
		host_deq_incr <= 1'b1;

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
			idma_m_tdata <= {4'h8,12'd1,local_wb_address[15:4],4'hC}; 
			idma_m_tvalid <= 1'b1;
			idma_m_tlast <= 1'b0;
		end
		S1_WRITE_BACK_1: begin
			// Lower 32-bit address
			// Starts from the third DWORD
			idma_m_tdata <= {host_wb_address[31:4],4'hC};
		end
		S1_WRITE_BACK_2: begin
			// Upper 32-bit address
			idma_m_tdata <= host_wb_address[63:32];
			idma_m_tlast <= 1'b1;
		end
		S1_WRITE_BACK_ACK: begin
			idma_m_tvalid <= 1'b0;
			idma_s_tready <= 1'b1;
		end
		S1_DEQUEUE: begin
			idma_s_tready <= 1'b0;
			host_dequeue <= 1'b1;
			host_deq_incr <= 1'b1;
			out_dequeue <= 1'b1;
			out_deq_incr <= 1'b1;
			delay_cnt <= 5;
		end
		S1_SET_SIZE: begin
			if(DPP) // Prefetch disabled
				fetch_num <= 1; // size of one descriptor
			else if(local_available > host_num)
				if(host_num > 64)
					fetch_num <= 64;
				else
					fetch_num <= host_num;
			else
				if(local_available > 64)
					fetch_num <= 64;
				else
					fetch_num <= local_available;
		end
		S1_FETCH_0: begin
			idma_m_tdata <= {4'h0,fetch_bytes,local_rd_address}; 
			idma_m_tvalid <= 1'b1;
			idma_m_tlast <= 1'b0;
		end
		S1_FETCH_1: begin
			idma_m_tdata <= host_rd_address[31:0];
		end
		S1_FETCH_2: begin
			idma_m_tdata <= host_rd_address[63:32];
			idma_m_tlast <= 1'b1;
		end
		S1_FETCH_ACK: begin
			idma_m_tvalid <= 1'b0;
			idma_s_tready <= 1'b1;
		end
		S1_ENQUQUE: begin
			idma_s_tready <= 1'b0;
			in_enqueue <= 1'b1;
			in_enq_incr <= fetch_num;
			delay_cnt <= 1;
		end
		S1_DELAY: begin
			in_enqueue <= 1'b0;
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
			if(txe_s_tready)
				s2_next = S2_DEQUEUE;
			else
				s2_next = S2_CMD;
		end
		S2_DEQUEUE: begin
			s2_next = S2_CMD;
		end
		S2_ACK: begin
			if(txe_s_tvalid & txe_s_tlast)
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
		txe_m_tdata <= 'bx;
		txe_m_tvalid <= 1'b0;
		txe_m_tlast <= 'b1;
	end
	else case(s2_next)
		S2_IDLE: begin
		end
		S2_READY: begin
			out_enqueue <= 1'b0;
		end
		S2_CMD: begin
			txe_m_tdata <= {16'b0,local_txe_address};
			txe_m_tvalid <= 1'b1;
			txe_m_tlast <= 1'b1;
		end
		S2_DEQUEUE: begin
			txe_m_tvalid <= 1'b0;
			in_dequeue <= 1'b1;
		end
		S2_ACK: begin
			txe_s_tready <= 1'b1;
		end
		S2_ENQUEUE: begin
			txe_s_tready <= 1'b0;
			out_enqueue <= 1'b1;
		end
	endcase
end

endmodule
