module rx_checksum(
	input clk,
	input rst,

	input [7:0] PCSS,

	input clr,

	input [31:0] data,
	input [3:0] keep,
	input last,
	input valid,

	output reg [15:0] csum,
	output reg csum_valid
);

reg valid_0, valid_1;
reg last_0, last_1;
reg [31:0] data_0;
reg [31:0] data_1;
reg [15:0] bytes;
reg [3:0] mask;

always @(posedge clk, posedge rst)
begin
	if(rst) begin
		valid_0 <= 1'b0;
		valid_1 <= 1'b0;
		last_0 <= 1'b0;
		last_1 <= 1'b0;
	end
	else begin
		valid_0 <= valid;
		valid_1 <= valid_0;
		last_0 <= last;
		last_1 <= last_0;
	end
end

always @(posedge clk, posedge rst)
begin
	if(rst) begin
		data_0 <= 'bx;
		bytes <= 'b0;
	end
	else if(valid) begin
		data_0[31:24] <= keep[3]?data[31:24]:8'b0;
		data_0[23:16] <= keep[2]?data[23:16]:8'b0;
		data_0[15:8] <= keep[1]?data[15:8]:8'b0;
		data_0[7:0] <= keep[0]?data[7:0]:8'b0;

		mask[3] <= bytes>=PCSS;
		mask[2] <= (bytes+1)>=PCSS;
		mask[1] <= (bytes+2)>=PCSS;
		mask[0] <= (bytes+3)>=PCSS;

		if(last)
			bytes <= 0;
		else
			bytes <= bytes+4;
	end
end

always @(posedge clk, posedge rst)
begin
	if(rst) begin
		data_1 <= 'b0;
	end
	else if(valid_0) begin
		data_1[31:24] <= mask[3]?data_0[31:24]:8'b0;
		data_1[23:16] <= mask[2]?data_0[23:16]:8'b0;
		data_1[15:8] <= mask[1]?data_0[15:8]:8'b0;
		data_1[7:0] <= mask[0]?data_0[7:0]:8'b0;
	end
end

always @(posedge clk, posedge rst)
begin
	if(rst) begin
		csum <= 'b0;
		csum_valid <= 1'b0;
	end
	else if(clr) begin
		csum <= 'b0;
		csum_valid <= 1'b0;
	end
	else if(valid_1) begin
		//csum <= csum + data_1[31:16] + data_1[15:0];
		csum <= csum + {data_1[23:16],data_1[31:24]} + {data_1[7:0],data_1[15:8]};
		csum_valid <= last_1;
	end
end

endmodule
