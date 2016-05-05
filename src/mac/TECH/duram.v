module duram(
data_a,
data_b,
wren_a,
wren_b,
address_a,
address_b,
clock_a,
clock_b,
q_a,
q_b); 

parameter DATA_WIDTH    = 32; 
parameter ADDR_WIDTH    = 5;  
parameter BLK_RAM_TYPE  = "AUTO";
parameter DURAM_MODE    = "AUTO";
parameter ADDR_DEPTH    = 2**ADDR_WIDTH;



input   [DATA_WIDTH -1:0]   data_a;
input                       wren_a;
input                       wren_b;
input   [ADDR_WIDTH -1:0]   address_a;
input                       clock_a;
output  [DATA_WIDTH -1:0]   q_a;
input   [DATA_WIDTH -1:0]   data_b;
input   [ADDR_WIDTH -1:0]   address_b;
input                       clock_b;
output  reg [DATA_WIDTH -1:0]   q_b;

reg [DATA_WIDTH-1:0] mem [0:ADDR_DEPTH-1];

always @(posedge clock_a)
begin
	if(wren_a)
		mem[address_a] <= data_a;
end

always @(posedge clock_b)
begin
	q_b <= mem[address_b];
end

assign q_a = 'b0;
 
 
 
endmodule 


