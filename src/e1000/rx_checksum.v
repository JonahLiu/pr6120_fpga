// Cyclic 
module rx_checksum(
	input clk,
	input rst,

	input [7:0] PCSS,

	input [31:0] data, // Big endian
	input [3:0] keep,
	input last,
	input valid,

	output [15:0] csum,
	output csum_valid
);

function [15:0] cyclic_carry_add(input [15:0] a, input [15:0] b);
	reg [16:0] sum;
	begin
		sum = a + b;
		cyclic_carry_add = sum[15:0] + sum[16];
	end
endfunction

reg valid_0, valid_1, valid_2, valid_3;
reg last_0, last_1, last_2;
reg [31:0] data_0;
reg [31:0] data_1;
reg [15:0] sum_low_2;
reg [15:0] sum_high_2;
reg [15:0] sum_3;
reg [15:0] bytes;
reg [3:0] mask;

assign csum = ~sum_3; // Checksum is one's complement of sum
assign csum_valid = valid_3;

// Pipline strobes
always @(posedge clk, posedge rst)
begin
	if(rst) begin
		valid_0 <= 1'b0;
		valid_1 <= 1'b0;
		valid_2 <= 1'b0;
		last_0 <= 1'b0;
		last_1 <= 1'b0;
		last_2 <= 1'b0;
	end
	else begin
		valid_0 <= valid;
		valid_1 <= valid_0;
		valid_2 <= valid_1;
		last_0 <= last;
		last_1 <= last_0;
		last_2 <= last_1;
	end
end

////////////////////////////////////////////////////////////////////////////////
// Step-1 
// Strip bytes not enabled
always @(posedge clk)
begin
	if(valid) begin // translate to little-endian
		data_0[7:0] <= keep[3]?data[31:24]:8'b0;
		data_0[15:8] <= keep[2]?data[23:16]:8'b0;
		data_0[23:16] <= keep[1]?data[15:8]:8'b0;
		data_0[31:24] <= keep[0]?data[7:0]:8'b0;
	end
end

// Generate offset mask
always @(posedge clk, posedge rst)
begin
	if(rst) begin
		bytes <= 'b0;
	end
	else if(valid) begin
		mask[0] <= bytes>=PCSS;
		mask[1] <= (bytes+1)>=PCSS;
		mask[2] <= (bytes+2)>=PCSS;
		mask[3] <= (bytes+3)>=PCSS;

		if(last)
			bytes <= 0;
		else
			bytes <= bytes+4;
	end
end

////////////////////////////////////////////////////////////////////////////////
// Step-2
// Strip bytes before PCSS
always @(posedge clk, posedge rst)
begin
	if(rst) begin
		data_1 <= 'b0;
	end
	else if(valid_0) begin
		data_1[7:0] <= mask[0]?data_0[7:0]:8'b0;
		data_1[15:8] <= mask[1]?data_0[15:8]:8'b0;
		data_1[23:16] <= mask[2]?data_0[23:16]:8'b0;
		data_1[31:24] <= mask[3]?data_0[31:24]:8'b0;
	end
end

////////////////////////////////////////////////////////////////////////////////
// Step-3
// Calculate respective sum for high and low words.
always @(posedge clk, posedge rst)
begin
	if(rst) begin
		sum_low_2 <= 'b0;
		sum_high_2 <= 'b0;
	end
	else if(valid_1) begin
		if(last_2) begin
			sum_low_2 <= data_1[15:0];
			sum_high_2 <= data_1[31:16];
		end
		else begin
			sum_low_2 <= cyclic_carry_add(sum_low_2, data_1[15:0]);
			sum_high_2 <= cyclic_carry_add(sum_high_2, data_1[31:16]);
		end
	end
	else if(last_2) begin
		sum_low_2 <= 'b0;
		sum_high_2 <= 'b0;
	end
end

////////////////////////////////////////////////////////////////////////////////
// Step-4
// Add two parts together.
always @(posedge clk)
begin
	if(valid_2 && last_2) begin
		sum_3 <= cyclic_carry_add(sum_low_2, sum_high_2);
	end
end

// Output Strobe
always @(posedge clk, posedge rst)
begin
	if(rst) begin
		valid_3 <= 1'b0;
	end
	else begin
		valid_3 <= valid_2 && last_2;
	end
end

endmodule
