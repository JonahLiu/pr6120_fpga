module fifo_async(
	dout,
	full,
	empty,
	din,
	wr_en,
	wr_clk,
	wr_rst,
	rd_en,
	rd_clk,
	rd_rst
);
parameter DSIZE = 8;
parameter ASIZE = 4;
parameter MODE = "NORMAL";

output [DSIZE-1:0] dout;
output full;
output empty;
input [DSIZE-1:0] din;
input wr_en, wr_clk, wr_rst;
input rd_en, rd_clk, rd_rst;

reg full,empty;
reg [ASIZE:0] wptr, rptr, wq2_rptr, rq2_wptr, wq1_rptr,rq1_wptr;
reg [ASIZE:0] rbin, wbin;
reg [DSIZE-1:0] mem[0:(1<<ASIZE)-1];

wire [ASIZE-1:0] waddr, raddr;
wire [ASIZE:0]  rgraynext, rbinnext,wgraynext,wbinnext;
wire  empty_val,full_val;

generate
if(MODE=="FWFT") begin
	assign dout=mem[raddr];
end
else begin
	reg [DSIZE-1:0] dout_r;
	always @(posedge rd_clk or posedge rd_rst)
	begin
		if(rd_rst)
			dout_r <= 0;
		else if(rd_en && !empty)
			dout_r <= mem[raddr];
	end
end
endgenerate

// Write data latch
always@(posedge wr_clk)
begin
	if (wr_en && !full)
		mem[waddr] <= din;
end

// Read pointer synchornization
always @(posedge wr_clk or posedge wr_rst)
	if (wr_rst)
		{wq2_rptr,wq1_rptr} <= 0;
	else
		{wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};

// Write pointer synchornization
always @(posedge rd_clk or posedge rd_rst)
	if (rd_rst)
		{rq2_wptr,rq1_wptr} <= 0;
	else
		{rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr};

// Read pointers
always @(posedge rd_clk or posedge rd_rst)
begin
if (rd_rst)
	{rbin, rptr} <= 0;
else
	{rbin, rptr} <= {rbinnext, rgraynext};
end

// Memory read-address pointer (okay to use binary to address memory)
assign raddr = rbin[ASIZE-1:0];
assign rbinnext = rbin + (rd_en & ~empty);
assign rgraynext = (rbinnext>>1) ^ rbinnext;

// FIFO empty when the next rptr == synchronized wptr or on reset
assign empty_val = (rgraynext == rq2_wptr);
always @(posedge rd_clk or posedge rd_rst)
begin
 if (rd_rst)
	 empty <= 1'b1;
 else
	 empty <= empty_val;
end

// Write pointers
always @(posedge wr_clk or posedge wr_rst)
begin
	if (wr_rst)
		{wbin, wptr} <= 0;
	else
		{wbin, wptr} <= {wbinnext, wgraynext};
end

// Memory write-address pointer (okay to use binary to address memory)
assign waddr = wbin[ASIZE-1:0];
assign wbinnext = wbin + (wr_en & ~full);
assign wgraynext = (wbinnext>>1) ^ wbinnext;

//------------------------------------------------------------------
// Simplified version of the three necessary full-tests:
// assign full_val=((wgnext[ADDRSIZE] !=wq2_rptr[ADDRSIZE] ) &&
// (wgnext[ADDRSIZE-1] !=wq2_rptr[ADDRSIZE-1]) &&
// (wgnext[ADDRSIZE-2:0]==wq2_rptr[ADDRSIZE-2:0]));

//------------------------------------------------------------------
assign full_val = (wgraynext=={~wq2_rptr[ASIZE:ASIZE-1], wq2_rptr[ASIZE-2:0]});
always @(posedge wr_clk or posedge wr_rst)
begin
	if (wr_rst)
		full <= 1'b0;
	else
		full <= full_val;
end

endmodule
