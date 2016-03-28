module config_rom(
	input clk_i,
	input rst_i,
	input [7:0] read_addr,
	input read_enable,
	output reg [15:0] read_data
);

always @(clk_i)
begin
	case(read_addr)
		8'h00: read_data <= 16'h0E00; // MAC[15:0]
		8'h01: read_data <= 16'h010C; // MAC[31:16]
		8'h02: read_data <= 16'h0302; // MAC[47:32]
		8'h03: read_data <= 16'h0000; // Compatiblility
		8'h04: read_data <= 16'h0000; // No use
		8'h05: read_data <= 16'h0000; // No use
		8'h06: read_data <= 16'h0000; // No use
		8'h07: read_data <= 16'h0000; // No use
		8'h08: read_data <= 16'h0000; // PBA Number
		8'h09: read_data <= 16'h0000; // PBA Number
		8'h0A: read_data <= 16'h6000; // Initialization
		8'h0B: read_data <= 16'h6120; // Subsystem ID
		8'h0C: read_data <= 16'hFACE; // Subsystem VID
		8'h0D: read_data <= 16'hABCD; // Device ID
		8'h0E: read_data <= 16'h8086; // Vendor ID
		8'h0F: read_data <= 16'h1000; // Init 2
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
		8'h30: read_data <= 16'h8000; // BA Setup
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
		8'h3F: read_data <= 16'h306B; // Checksum, must add up to BABA
		default: read_data <= 16'hFFFF;
	endcase
end

endmodule
