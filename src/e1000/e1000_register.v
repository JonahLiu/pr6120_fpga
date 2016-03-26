module e1000_register(
	input clk_i,
	input arst_i,
	input srst_i,
	input wen_i,
	input [3:0] wbe_i,
	input [31:0] d_i,
	output [31:0] q_o
);
parameter init=32'b0;

reg [31:0] data;
assign q_o = data;
always @(posedge clk_i, posedge arst_i)
begin
	if(arst_i || srst_i) begin
		data <= init;
	end
	else if(wen_i) begin
		if(wbe_i[0]) data[7:0] <= d_i[7:0];
		if(wbe_i[1]) data[15:8] <= d_i[15:8];
		if(wbe_i[2]) data[23:16] <= d_i[23:16];
		if(wbe_i[3]) data[31:24] <= d_i[31:24];
	end
end

endmodule
