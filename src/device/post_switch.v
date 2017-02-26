module post_switch (
	input	rst,
	input	clk,
	input	[1:0] speed,
	input	[47:0] mac_address,
	input	mac_valid,
	input	trigger,
	input	[7:0] up_data,
	input	up_dv,
	input	up_er,
	output	reg [7:0] down_data,
	output	reg down_dv,
	output	reg down_er
);

parameter IFG_CLOCKS=125_000;
parameter SEND_REPEAT=3;
parameter HOLDOFF_CLOCKS=400_000; // a workaround for post switch MAC address collision.

integer s1, s1_next;
integer s2, s2_next;

localparam S1_IDLE=0,
	S1_HOLD=6,
	S1_REPEAT=1,
	S1_FETCH=2,
	S1_LATENCY=3,
	S1_DATA=4,
	S1_IFG=5; 

localparam S2_IDLE=0,
	S2_PRE=1,
	S2_DATA=2,
	S2_LAT=3,
	S2_FCS=4,
	S2_DONE=5;

wire [6:0] ram_raddr;
reg [7:0] ram_rdata;

reg [6:0] ram_waddr;
reg [7:0] ram_wdata;
reg ram_wen;

reg triggered;
(* ASYNC_REG = "TRUE" *)
reg [2:0] sync;
reg [7:0] pkt_cnt;
reg [7:0] byte_cnt;

reg [23:0] ifg_cnt;
reg [6:0] read_offset;
reg [6:0] write_offset;

reg [23:0] timer;

reg crc_init;
reg crc_wr;
reg crc_rd;
wire [7:0] crc_out;

CRC_gen crc_gen_i(
	.Reset(rst),
	.Clk(clk),
	.Init(crc_init),
	.Frame_data(ram_wdata),
	.Data_en(crc_wr),
	.CRC_rd(crc_rd),
	.CRC_end(),
	.CRC_out(crc_out)
);

assign ram_raddr = read_offset;

always @(posedge clk, posedge rst)
begin
	if(rst)
		sync <= 'b0;
	else 
		sync <= {sync,trigger};
end

always @(posedge clk, posedge rst)
begin
	if(rst) 
		triggered <= 1'b0;
	else if(sync[2] && !sync[1])
		triggered <= 1'b1;
	else if(s1_next!= S1_IDLE)
		triggered <= 1'b0;
end

always @(posedge clk, posedge rst)
begin
	if(rst) 
		s1 = S1_IDLE;
	else
		s1 = s1_next;
end

always @(*)
begin
	case(s1)
		S1_IDLE: begin
			if(triggered)
				s1_next = S1_HOLD;
			else
				s1_next = S1_IDLE;
		end
		S1_HOLD: begin
			if(speed == 2'b00 && timer == HOLDOFF_CLOCKS/100)
				s1_next = S1_REPEAT;
			else if(speed == 2'b01 && timer == HOLDOFF_CLOCKS/10)
				s1_next = S1_REPEAT;
			else if(timer == HOLDOFF_CLOCKS)
				s1_next = S1_REPEAT;
			else
				s1_next = S1_HOLD;
		end
		S1_REPEAT: begin
			if(pkt_cnt==SEND_REPEAT)
				s1_next = S1_IDLE;
			else
				s1_next = S1_FETCH;
		end
		S1_FETCH: begin
			s1_next = S1_LATENCY;
		end
		S1_LATENCY: begin
			s1_next = S1_DATA;
		end
		S1_DATA: begin
			if(byte_cnt==72)
				s1_next = S1_IFG;
			else
				s1_next = S1_DATA;
		end
		S1_IFG: begin
			if(ifg_cnt==IFG_CLOCKS)
				s1_next = S1_REPEAT;
			else
				s1_next = S1_IFG;
		end
		default: begin
			s1_next = 'bx;
		end
	endcase
end

always @(posedge clk, posedge rst)
begin
	if(rst) begin
		down_data <= 'bx;
		down_dv <= 1'b0;
		down_er <= 1'b0;
		pkt_cnt <= 'bx;
		byte_cnt <= 'bx;
		ifg_cnt <= 'bx;
		read_offset <= 'bx;
		timer <= 'bx;
	end
	else case(s1_next)
		S1_IDLE: begin
			down_data <= up_data;
			down_dv <= up_dv;
			down_er <= up_er;
			pkt_cnt <= 'b0;
			timer <= 'b0;
		end
		S1_HOLD: begin
			timer <= timer + 1;
			down_dv <= 1'b0;
			down_er <= 1'b0;
		end
		S1_REPEAT: begin
			down_dv <= 1'b0;
			down_er <= 1'b0;
			ifg_cnt <= 'b0;
			byte_cnt <= 'b0;
		end
		S1_FETCH: begin
			read_offset <= 'b0;
			pkt_cnt <= pkt_cnt+1;
		end
		S1_LATENCY: begin
			read_offset <= read_offset+1;
		end
		S1_DATA: begin
			read_offset <= read_offset+1;
			byte_cnt <= byte_cnt+1;
			down_data <= ram_rdata;
			down_dv <= 1'b1;
		end
		S1_IFG: begin
			ifg_cnt <= ifg_cnt + 1;
			down_dv <= 1'b0;
		end
	endcase
end

always @(posedge clk, posedge rst)
begin
	if(rst) 
		s2 = S2_IDLE;
	else
		s2 = s2_next;
end

always @(*)
begin
	case(s2)
		S2_IDLE: begin
			if(mac_valid)
				s2_next = S2_PRE;
			else
				s2_next = S2_IDLE;
		end
		S2_PRE: begin
			if(write_offset==8)
				s2_next = S2_DATA;
			else
				s2_next = S2_PRE;
		end
		S2_DATA: begin
			if(write_offset==68)
				s2_next = S2_LAT;
			else
				s2_next = S2_DATA;
		end
		S2_LAT: begin
			s2_next = S2_FCS;
		end
		S2_FCS: begin
			if(write_offset==72)
				s2_next = S2_DONE;
			else
				s2_next = S2_FCS;
		end
		S2_DONE: begin
			s2_next = S2_DONE;
		end
		default: begin
			s2_next = 'bx;
		end
	endcase
end

always @(posedge clk, posedge rst)
begin
	if(rst) begin
		ram_wen <= 1'b0;
		ram_wdata <= 'bx;
		ram_waddr <= 'bx;
		write_offset <= 'bx;
		crc_wr <= 1'b0;
		crc_rd <= 1'b0;
		crc_init <= 1'b0;
	end
	else case(s2_next)
		S2_IDLE: begin
			write_offset <= 'b0;
			crc_init <= 1'b1;
		end
		S2_PRE: begin
			case(write_offset)
				0,1,2,3,4,5,6: ram_wdata <= 8'h55;
				7: ram_wdata <= 8'hD5;
			endcase
			crc_init <= 1'b0;
			ram_waddr <= write_offset;
			ram_wen <= 1'b1;
			write_offset <= write_offset+1;
		end
		S2_DATA: begin
			case(write_offset)
				8,9,10,11,12,13: ram_wdata <= 8'hFF;
				14: ram_wdata <= mac_address[47:40];
				15: ram_wdata <= mac_address[39:32];
				16: ram_wdata <= mac_address[31:24];
				17: ram_wdata <= mac_address[23:16];
				18: ram_wdata <= mac_address[15:8];
				19: ram_wdata <= mac_address[7:0];
				20: ram_wdata <= 8'h08;
				21: ram_wdata <= 8'h06;
				22: ram_wdata <= 8'h00;
				23: ram_wdata <= 8'h01;
				24: ram_wdata <= 8'h08;
				25: ram_wdata <= 8'h00;
				26: ram_wdata <= 8'h06;
				27: ram_wdata <= 8'h04;
				28: ram_wdata <= 8'h00;
				29: ram_wdata <= 8'h03;
				30: ram_wdata <= mac_address[47:40];
				31: ram_wdata <= mac_address[39:32];
				32: ram_wdata <= mac_address[31:24];
				33: ram_wdata <= mac_address[23:16];
				34: ram_wdata <= mac_address[15:8];
				35: ram_wdata <= mac_address[7:0];
				36,37,38,39: ram_wdata <= 8'h00;
				40: ram_wdata <= mac_address[47:40];
				41: ram_wdata <= mac_address[39:32];
				42: ram_wdata <= mac_address[31:24];
				43: ram_wdata <= mac_address[23:16];
				44: ram_wdata <= mac_address[15:8];
				45: ram_wdata <= mac_address[7:0];
				46,47,48,49: ram_wdata <= 8'h00;
				50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67: ram_wdata <= 8'h00;
			endcase
			crc_wr <= 1'b1;
			ram_waddr <= write_offset;
			ram_wen <= 1'b1;
			write_offset <= write_offset+1;
		end
		S2_LAT: begin
			ram_wen <= 1'b0;
			crc_wr <= 1'b0;
			crc_rd <= 1'b1;
		end
		S2_FCS: begin
			case(write_offset)
				68,69,70,71: ram_wdata <= crc_out;
			endcase
			ram_waddr <= write_offset;
			ram_wen <= 1'b1;
			write_offset <= write_offset+1;
		end
		S2_DONE: begin
			crc_rd <= 1'b0;
			ram_wen <= 1'b0;
		end
	endcase
end

reg [7:0] mem[0:127];

always @(posedge clk)
begin
	if(ram_wen)
		mem[ram_waddr] <= ram_wdata;

	ram_rdata <= mem[ram_raddr];
end

endmodule
