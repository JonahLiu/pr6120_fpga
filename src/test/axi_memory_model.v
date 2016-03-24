module axi_memory_model 
#(
	parameter MEMORY_DEPTH=1024,
	parameter S_AXI_ID_WIDTH=4,
	parameter S_AXI_DATA_WIDTH=32,
	parameter S_AXI_STRB_WIDTH=S_AXI_DATA_WIDTH/8,
	parameter INITIAL_VALUE=0
)
(
	// AXI Clock & Reset
	input	s_axi_aresetn,
	input	s_axi_aclk,

	// AXI Master Write Address
	input	[S_AXI_ID_WIDTH-1:0]	s_axi_awid,
	input	[31:0]	s_axi_awaddr,
	input	[7:0]	s_axi_awlen,
	input	[2:0]	s_axi_awsize,
	input	[1:0]	s_axi_awburst,
	//input	[0:0]	s_axi_awlock,
	//input	[3:0]	s_axi_awcache,
	//input	[2:0]	s_axi_awprot,
	//input	[3:0]	s_axi_awqos,
	input	s_axi_awvalid,
	output reg	s_axi_awready,

	// AXI Master Write Data
	input	[S_AXI_DATA_WIDTH-1:0]	s_axi_wdata,
	input	[S_AXI_STRB_WIDTH-1:0]	s_axi_wstrb,
	input	s_axi_wlast,
	input	s_axi_wvalid,
	output reg	s_axi_wready,

	// AXI Master Write Response
	input	s_axi_bready,
	output reg	[S_AXI_ID_WIDTH-1:0]	s_axi_bid,
	output reg	[1:0]	s_axi_bresp,
	output reg	s_axi_bvalid,

	// AXI Master Read Address
	input	[S_AXI_ID_WIDTH-1:0]	s_axi_arid,
	input	[31:0]	s_axi_araddr,
	input	[7:0]	s_axi_arlen,
	input	[2:0]	s_axi_arsize,
	input	[1:0]	s_axi_arburst,
	//input	[0:0]	s_axi_arlock,
	//input	[3:0]	s_axi_arcache,
	//input	[2:0]	s_axi_arprot,
	//input	[3:0]	s_axi_arqos,
	input	s_axi_arvalid,
	output reg	s_axi_arready,

	// AXI Master Read Data
	input	s_axi_rready,
	output reg	[S_AXI_ID_WIDTH-1:0]	s_axi_rid,
	output reg	[S_AXI_DATA_WIDTH-1:0]	s_axi_rdata,
	output reg	[1:0]	s_axi_rresp,
	output reg	s_axi_rlast,
	output reg	s_axi_rvalid
);

function integer clogb2 (input integer size);
begin
	size = size - 1;
	for (clogb2=1; size>1; clogb2=clogb2+1)
		size = size >> 1;
end
endfunction
localparam MEM_ADDR_LSB = clogb2(S_AXI_STRB_WIDTH);
localparam MEM_ADDR_MSB = clogb2(MEMORY_DEPTH)+MEM_ADDR_LSB-1;

reg	[S_AXI_DATA_WIDTH-1:0]	memory	[0:MEMORY_DEPTH-1];
reg	[31:0]	write_addr;
//reg	[7:0]	write_len;
//reg	[7:0]	write_cnt;
reg	[31:0]	read_addr;
reg	[7:0]	read_len;
reg	[7:0]	read_cnt;
reg	[S_AXI_ID_WIDTH-1:0]	write_id;
reg	[S_AXI_ID_WIDTH-1:0]	read_id;

task write(input integer addr, input [S_AXI_DATA_WIDTH-1:0] data);
begin
	memory[addr] = data;
end
endtask

task read(input integer addr, output [S_AXI_DATA_WIDTH-1:0] data);
begin
	data = memory[addr];
end
endtask

task clear;
reg [S_AXI_DATA_WIDTH-1:0] i;
begin
	for(i=0;i<MEMORY_DEPTH;i=i+1) begin
		memory[i] = INITIAL_VALUE;
	end
end
endtask

initial begin:INIT
	clear;
end

////////////////////////////////////////////////////////////////////////////////
//% Write Stage
//% Address acknowledge
always @(posedge s_axi_aclk,negedge s_axi_aresetn)
begin
	if(!s_axi_aresetn) begin
		s_axi_awready <= 1'b1;
	end
	else if(s_axi_awready) begin
		if(s_axi_awvalid) begin
			s_axi_awready <= 1'b0;
		end
	end
	else if(s_axi_bvalid && s_axi_bready) begin
		s_axi_awready <= 1'b1;
	end
end

//% Data acknowledge
always @(posedge s_axi_aclk,negedge s_axi_aresetn)
begin
	if(!s_axi_aresetn) begin
		s_axi_wready <= 1'b0;
	end
	else if(s_axi_awvalid && s_axi_awready) begin
		s_axi_wready <= 1'b1;
	end
	else if(s_axi_wvalid && s_axi_wready && s_axi_wlast) begin
		s_axi_wready <= 1'b0;
	end
end

//% Data write 
always @(posedge s_axi_aclk)
begin
	if(s_axi_awvalid && s_axi_awready) begin
			write_addr <= s_axi_awaddr;
			//write_len <= s_axi_awlen;
			//write_cnt <= 'b0;
			write_id <= s_axi_awid;
	end
	else if(s_axi_wvalid && s_axi_wready) begin:DATA_WRITE
		/*
		integer i;
		for(i=0;i<S_AXI_STRB_WIDTH;i=i+1) begin
			if(s_axi_wstrb[i])
				memory[write_addr[31:MEM_ADDR_LSB]][8*i+7:8*i] <= s_axi_wdata[8*i+7:8*i];
		end
		*/
		memory[write_addr[MEM_ADDR_MSB:MEM_ADDR_LSB]] <= s_axi_wdata;
		write_addr <= write_addr + S_AXI_STRB_WIDTH;
		//write_cnt <= write_cnt + 1;
	end
end

//% Write response
always @(posedge s_axi_aclk,negedge s_axi_aresetn)
begin
	if(!s_axi_aresetn) begin
		s_axi_bvalid <= 1'b0;
		s_axi_bresp <= 2'b0;
	end
	else if(s_axi_wvalid && s_axi_wready && s_axi_wlast) begin
		s_axi_bvalid <= 1'b1;
		s_axi_bid <= write_id;
	end
	else if(s_axi_bready) begin
		s_axi_bvalid <= 1'b0;
	end
end

////////////////////////////////////////////////////////////////////////////////
//% Read Stage
//% Read Address Acknowledge
always @(posedge s_axi_aclk, negedge s_axi_aresetn)
begin
	if(!s_axi_aresetn) begin
		s_axi_arready <= 1'b1;
	end
	else if(s_axi_arvalid && s_axi_arready) begin
		s_axi_arready <= 1'b0;
	end
	else if(s_axi_rvalid && s_axi_rready && s_axi_rlast) begin
		s_axi_arready <= 1'b1;
	end
end

//% Read Data Response
always @(posedge s_axi_aclk, negedge s_axi_aresetn) 
begin
	if(!s_axi_aresetn) begin
		s_axi_rvalid <= 1'b0;
		s_axi_rresp <= 2'b0;
	end
	else if(s_axi_arvalid && s_axi_arready) begin

		s_axi_rdata <= memory[s_axi_araddr[MEM_ADDR_MSB:MEM_ADDR_LSB]];
		s_axi_rlast <= s_axi_arlen==0;
		s_axi_rvalid <= 1'b1;
		s_axi_rid <= s_axi_arid;

		read_addr <= s_axi_araddr + S_AXI_STRB_WIDTH;
		read_len <= s_axi_arlen;
		read_cnt <= 0;
		read_id <= s_axi_arid;
	end
	else if(s_axi_rvalid && s_axi_rready) begin
		s_axi_rdata <= memory[read_addr[MEM_ADDR_MSB:MEM_ADDR_LSB]];
		s_axi_rlast <= read_cnt+1==read_len;
		if(s_axi_rlast) begin
			s_axi_rvalid <= 1'b0;
		end

		read_addr <= read_addr + S_AXI_STRB_WIDTH;
		read_cnt <= read_cnt+1;
	end
end
endmodule
