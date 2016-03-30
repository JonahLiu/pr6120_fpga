module intr_ctrl(
	input clk_i,
	input rst_i,

	input [31:0] ICR,
	output [31:0] ICR_fb_o,
	input ICR_set,
	input ICR_get,

	input [31:0] ITR,
	input ITR_set,

	input [31:0] ICS,
	input ICS_set,

	input [31:0] IMS,
	input IMS_set,

	input [31:0] IMC,
	input IMC_set,

	output intr_request,

	input RXT0_req,
	input TXDW_req,
	input RXDMT0_req,
	input LSC_req
);
parameter CLK_PERIOD_NS = 8;

localparam TICK_CYCLES = 256/CLK_PERIOD_NS;

wire [31:0] src_req;

reg [31:0] intr_state;
reg [31:0] intr_next;

reg [31:0] intr_mask;

reg [7:0] tick_cnt;
reg tick_incr;

reg [15:0] interval_value;
reg [15:0] interval_cnt;
reg intr_delay;

reg intr_request_r;

wire intr_request_a;

assign ICR_fb_o = intr_state;
assign intr_request = intr_request_r;

assign src_req[0] = TXDW_req;
assign src_req[1] = 1'b0;
assign src_req[2] = LSC_req;
assign src_req[3] = 1'b0;
assign src_req[4] = RXDMT0_req;
assign src_req[6:5] = 2'b0;
assign src_req[7] = RXT0_req;
assign src_req[31:8] = 24'b0;

assign intr_request_a = (intr_state&intr_mask)!=32'b0;

always @(*)
begin
	if(ICR_get) intr_next = 32'b0;
	else if(ICR_set) intr_next = intr_state&(~ICR);
	else if(ICS_set) intr_next = intr_state|ICS;
	else intr_next = intr_state;
end

always @(posedge clk_i, posedge rst_i)
begin
	if(rst_i) 
		intr_state <= 32'b0;
	else
		intr_state <= intr_next | src_req;

end

always @(posedge clk_i, posedge rst_i)
begin
	if(rst_i)
		intr_mask <= 32'b0;
	else if(IMS_set)
		intr_mask <= intr_mask|IMS;
	else if(IMC_set)
		intr_mask <= intr_mask&(~IMC);
end

always @(posedge clk_i, posedge rst_i)
begin
	if(rst_i) begin
		tick_cnt <= 'b0;
		tick_incr <= 1'b0;
	end
	else if(intr_delay) begin
		if(tick_cnt == TICK_CYCLES) begin
			tick_cnt <= 'b0;
			tick_incr <= 1'b1;
		end
		else begin
			tick_cnt <= tick_cnt+1;
			tick_incr <= 1'b0;
		end
	end
	else begin
		tick_cnt <= 'b0;
		tick_incr <= 1'b0;
	end
end

always @(posedge clk_i, posedge rst_i)
begin
	if(rst_i)
		interval_value <= 'b0;
	else if(ITR_set)
		interval_value <= ITR[15:0];
end

always @(posedge clk_i, posedge rst_i)
begin
	if(rst_i) begin
		intr_delay <= 1'b0;
		interval_cnt <= 'b0;
	end
	else if(intr_delay) begin
		if(interval_cnt==interval_value) begin
			intr_delay <= 1'b0;
			interval_cnt <= 1'b0;
		end
		else if(tick_incr) begin
			interval_cnt <= interval_cnt+1;
		end
	end
	else if(intr_request_a) begin
		intr_delay <= 1'b1;
	end
end

always @(posedge clk_i, posedge rst_i)
begin
	if(rst_i) 
		intr_request_r <= 1'b0;
	else if(!intr_request_a)
		intr_request_r <= 1'b0;
	else if(!intr_delay)
		intr_request_r <= 1'b1;
end

endmodule
