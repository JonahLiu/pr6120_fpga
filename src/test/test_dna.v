`timescale 1ns/1ps
module test_dna;

reg clk;
wire [56:0] id;
wire valid;

dna dut(
	.clk(clk),
	.id(id),
	.valid(valid)
);

initial
begin
	clk=0;
	forever #10 clk = ~clk;
end

initial
begin
	$dumpfile("test_dna.vcd");
	$dumpvars(0);
	#10000;
	$finish();
end

endmodule
