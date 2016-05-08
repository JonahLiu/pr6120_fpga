module e1000_register(
	input C, // Clock
	input R, // Reset
	input [15:0] WA, // Write Address
	input WE, // Write Enable
	input [3:0] BE, // Byte Enable
	input [31:0] D, // Write Input
	output S, // Set Strobe
	input [15:0] RA, // Read Address
	input RE, // Read Enable
	output [31:0] Q, // Read Output
	output G, // Get Strobe
	output [31:0] O, // Direct Output
	input [31:0] B // Read Overwrite
);
parameter INIT=32'b0; // Initial Value
parameter ADDR=16'b0; // Address
parameter BMSK=32'b0; // Overwrite Mask

reg [31:0] data;
reg set;
reg get;
assign Q = (data&(~(BMSK)))|(B&BMSK);
assign O = data;
assign S = set;
assign G = get;
always @(posedge C, posedge R)
begin
	if(R) begin
		data <= INIT;
	end
	else if(WE && WA[15:2]==ADDR[15:2]) begin
		if(BE[0]) data[7:0] <= D[7:0];
		if(BE[1]) data[15:8] <= D[15:8];
		if(BE[2]) data[23:16] <= D[23:16];
		if(BE[3]) data[31:24] <= D[31:24];
	end
end
always @(posedge C, posedge R)
begin
	if(R) begin
		set <= 1'b0;
	end
	else if(WE && WA[15:2]==ADDR[15:2]) begin
		set <= 1'b1;
	end
	else begin
		set <= 1'b0;
	end
end
always @(posedge C, posedge R)
begin
	if(R) begin
		get <= 1'b0;
	end
	else if(RE && RA[15:2]==ADDR[15:2]) begin
		get <= 1'b1;
	end
	else begin
		get <= 1'b0;
	end
end

endmodule
