module config_rom(
	input clk_i,
	input rst_i,
	input [7:0] read_addr,
	input read_enable,
	output reg [15:0] read_data,
	output [47:0] mac_address,
	output mac_valid
);
parameter [23:0] MAC_OUI=24'hEC3F05;
parameter [15:0] ICW1=16'h6000;
parameter [15:0] SUB_PID=16'h6120;
parameter [15:0] SUB_VID=16'hFACE;
parameter [15:0] PID=16'h0050;
parameter [15:0] VID=16'h8086;
parameter [15:0] ICW2=16'h1000;
parameter [15:0] BAMSO=16'h8000;

parameter [15:0] CSUM_PRECALC= ICW1 + SUB_PID + SUB_VID + PID + VID + ICW2 + BAMSO +
	{MAC_OUI[15:8],MAC_OUI[23:16]} + {8'b0,MAC_OUI[7:0]};

wire [56:0] id;

reg [15:0] csum;

reg [23:0] mac;

dna dna_i(
	.clk(clk_i),
	.id(id),
	.valid(mac_valid)
);

assign mac_address = {MAC_OUI[23:0], mac[23:0]};

always @(posedge clk_i)
	mac <= id[56:48] + id[47:24] + id[23:0];

always @(posedge clk_i)
	csum <= 16'hBABA-CSUM_PRECALC-({mac[23:16],8'b0}+{mac[7:0],mac[15:8]});

always @(posedge clk_i)
begin
	case(read_addr)
		8'h00: read_data <= {MAC_OUI[15:8],MAC_OUI[23:16]}; // MAC[15:0]
		8'h01: read_data <= {mac[23:16],MAC_OUI[7:0]}; // MAC[31:16]
		8'h02: read_data <= {mac[7:0],mac[15:8]}; // MAC[47:32]
		8'h03: read_data <= 16'h0000; // Compatiblility
		8'h04: read_data <= 16'h0000; // No use
		8'h05: read_data <= 16'h0000; // No use
		8'h06: read_data <= 16'h0000; // No use
		8'h07: read_data <= 16'h0000; // No use
		8'h08: read_data <= 16'h0000; // PBA Number
		8'h09: read_data <= 16'h0000; // PBA Number
		8'h0A: read_data <= ICW1; // Initialization
		8'h0B: read_data <= SUB_PID; // Subsystem ID
		8'h0C: read_data <= SUB_VID; // Subsystem VID
		8'h0D: read_data <= PID; // Device ID
		8'h0E: read_data <= VID; // Vendor ID
		8'h0F: read_data <= ICW2; // Init 2
		8'h10: read_data <= 16'h0000; // No use
		8'h11: read_data <= 16'h0000; // No use
		8'h12: read_data <= 16'h0000; // No use
		8'h13: read_data <= 16'h0000;
		8'h14: read_data <= 16'h0000;
		8'h15: read_data <= 16'h0000;
		8'h16: read_data <= 16'h0000;
		8'h17: read_data <= 16'h0000;
		8'h18: read_data <= 16'h0000;
		8'h19: read_data <= 16'h0000;
		8'h1A: read_data <= 16'h0000;
		8'h1B: read_data <= 16'h0000;
		8'h1C: read_data <= 16'h0000;
		8'h1D: read_data <= 16'h0000;
		8'h1E: read_data <= 16'h0000;
		8'h1F: read_data <= 16'h0000;
		8'h20: read_data <= 16'h0000;
		8'h21: read_data <= 16'h0000;
		8'h22: read_data <= 16'h0000;
		8'h23: read_data <= 16'h0000;
		8'h24: read_data <= 16'h0000;
		8'h25: read_data <= 16'h0000;
		8'h26: read_data <= 16'h0000;
		8'h27: read_data <= 16'h0000;
		8'h28: read_data <= 16'h0000;
		8'h29: read_data <= 16'h0000;
		8'h2A: read_data <= 16'h0000;
		8'h2B: read_data <= 16'h0000;
		8'h2C: read_data <= 16'h0000;
		8'h2D: read_data <= 16'h0000;
		8'h2E: read_data <= 16'h0000;
		8'h2F: read_data <= 16'h0000;
		8'h30: read_data <= BAMSO; // BA Setup
		8'h31: read_data <= 16'h0000;
		8'h32: read_data <= 16'h0000;
		8'h33: read_data <= 16'h0000;
		8'h34: read_data <= 16'h0000;
		8'h35: read_data <= 16'h0000;
		8'h36: read_data <= 16'h0000;
		8'h37: read_data <= 16'h0000;
		8'h38: read_data <= 16'h0000;
		8'h39: read_data <= 16'h0000;
		8'h3A: read_data <= 16'h0000;
		8'h3B: read_data <= 16'h0000;
		8'h3C: read_data <= 16'h0000;
		8'h3D: read_data <= 16'h0000;
		8'h3E: read_data <= 16'h0000;
		8'h3F: read_data <= csum; // Checksum, must add up to BABA
		default: read_data <= 16'hFFFF;
	endcase
end

endmodule
