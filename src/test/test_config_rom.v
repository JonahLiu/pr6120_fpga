`timescale 1ns/1ps
module test_config_rom;

reg clk;
reg [7:0] read_addr;
reg read_enable;
wire [15:0] read_data;

config_rom dut_i(
	.clk_i(clk),
	.rst_i(1'b0),
	.read_addr(read_addr),
	.read_enable(read_enable),
	.read_data(read_data)
);


initial
begin
	clk=0;
	forever #10 clk = ~clk;
end

task test_read(input [7:0] addr, output [15:0] data);
	begin
		@(posedge clk);
		read_addr <= addr;
		read_enable <= 1'b1;
		@(posedge clk);
		read_enable <= 1'b0;
		@(posedge clk);
		data = read_data;
	end
endtask

initial
begin:T0
	reg [15:0] data;
	reg [15:0] csum;
	integer i;
	$dumpfile("test_config_rom.vcd");
	$dumpvars(0);
	#2000;
	csum=0;

	for(i=0;i<8'h40;i=i+1) begin
		test_read(i,data);
		csum=csum+data;
	end

	$display("Checksum is %x", csum);
	#1000;

	$finish();
end


endmodule
