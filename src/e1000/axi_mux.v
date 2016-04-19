module axi_mux(
	// AXI Clock & Reset
	aresetn,
	aclk,

	// AXI Slave Write Address
	s_awid,
	s_awaddr,
	s_awlen,
	s_awsize,
	s_awburst,
	s_awvalid,
	s_awready,

	// AXI Slave Write Data
	s_wid,
	s_wdata,
	s_wstrb,
	s_wlast,
	s_wvalid,
	s_wready,

	// AXI Slave Write Response
	s_bready,
	s_bid,
	s_bresp,
	s_bvalid,

	// AXI Slave Read Address
	s_arid,
	s_araddr,
	s_arlen,
	s_arsize,
	s_arburst,
	s_arvalid,
	s_arready,

	// AXI Slave Read Data
	s_rready,
 	s_rid,
	s_rdata,
 	s_rresp,
	s_rlast,
	s_rvalid,

	// AXI Master Write Address
	m_awid,
	m_awaddr,
	m_awlen,
	m_awsize,
	m_awburst,
	m_awvalid,
	m_awready,

	// AXI Master Write Data
	m_wid,
	m_wdata,
	m_wstrb,
	m_wlast,
	m_wvalid,
	m_wready,

	// AXI Master Write Response
	m_bready,
	m_bid,
	m_bresp,
	m_bvalid,

	// AXI Master Read Address
	m_arid,
	m_araddr,
	m_arlen,
	m_arsize,
	m_arburst,
	m_arvalid,
	m_arready,

	// AXI Master Read Data
	m_rready,
 	m_rid,
	m_rdata,
 	m_rresp,
	m_rlast,
	m_rvalid
);
parameter SLAVE_NUM=2;
parameter ID_WIDTH=4;
parameter ADDR_WIDTH=32;
parameter DATA_WIDTH=32;
parameter LEN_WIDTH=8;

localparam STRB_WIDTH=DATA_WIDTH/8;

// AXI Clock & Reset
input	aresetn;
input	aclk;

// AXI Slave Write Address
input	[ID_WIDTH*SLAVE_NUM-1:0]	s_awid;
input	[ADDR_WIDTH*SLAVE_NUM-1:0]	s_awaddr;
input	[LEN_WIDTH*SLAVE_NUM-1:0]	s_awlen;
input	[3*SLAVE_NUM-1:0]	s_awsize;
input	[2*SLAVE_NUM-1:0]	s_awburst;
input	[SLAVE_NUM-1:0] s_awvalid;
output reg	[SLAVE_NUM-1:0] s_awready;

// AXI Slave Write Data
input	[ID_WIDTH*SLAVE_NUM-1:0]	s_wid;
input	[DATA_WIDTH*SLAVE_NUM-1:0]	s_wdata;
input	[STRB_WIDTH*SLAVE_NUM-1:0]	s_wstrb;
input	[SLAVE_NUM-1:0] s_wlast;
input	[SLAVE_NUM-1:0] s_wvalid;
output reg	[SLAVE_NUM-1:0] s_wready;

// AXI Slave Write Response
input	[SLAVE_NUM-1:0] s_bready;
output reg [ID_WIDTH*SLAVE_NUM-1:0]	s_bid;
output reg [2*SLAVE_NUM-1:0]	s_bresp;
output reg [SLAVE_NUM-1:0] s_bvalid;

// AXI Slave Read Address
input	[ID_WIDTH*SLAVE_NUM-1:0]	s_arid;
input	[ADDR_WIDTH*SLAVE_NUM-1:0]	s_araddr;
input	[LEN_WIDTH*SLAVE_NUM-1:0]	s_arlen;
input	[3*SLAVE_NUM-1:0]	s_arsize;
input	[2*SLAVE_NUM-1:0]	s_arburst;
input	[SLAVE_NUM-1:0] s_arvalid;
output reg	[SLAVE_NUM-1:0] s_arready;

// AXI Slave Read Data
input	[SLAVE_NUM-1:0] s_rready;
output reg [ID_WIDTH*SLAVE_NUM-1:0]	s_rid;
output reg [DATA_WIDTH*SLAVE_NUM-1:0]	s_rdata;
output reg [2*SLAVE_NUM-1:0]	s_rresp;
output reg [SLAVE_NUM-1:0] s_rlast;
output reg [SLAVE_NUM-1:0] s_rvalid;

// AXI Master Write Address
output reg	[ID_WIDTH-1:0]	m_awid;
output reg	[ADDR_WIDTH-1:0]	m_awaddr;
output reg	[LEN_WIDTH-1:0]	m_awlen;
output reg	[2:0]	m_awsize;
output reg	[1:0]	m_awburst;
output reg	m_awvalid;
input	 m_awready;

// AXI Master Write Data
output reg	[ID_WIDTH-1:0]	m_wid;
output reg	[DATA_WIDTH-1:0]	m_wdata;
output reg	[STRB_WIDTH-1:0]	m_wstrb;
output reg	m_wlast;
output reg	m_wvalid;
input	m_wready;

// AXI Master Write Response
output reg	m_bready;
input [ID_WIDTH-1:0]	m_bid;
input [1:0]	m_bresp;
input m_bvalid;

// AXI Master Read Address
output reg	[ID_WIDTH-1:0]	m_arid;
output reg	[ADDR_WIDTH-1:0]	m_araddr;
output reg	[LEN_WIDTH-1:0]	m_arlen;
output reg	[2:0]	m_arsize;
output reg	[1:0]	m_arburst;
output reg	m_arvalid;
input	m_arready;

// AXI Master Read Data
output reg	m_rready;
input [ID_WIDTH-1:0]	m_rid;
input [DATA_WIDTH-1:0]	m_rdata;
input [1:0]	m_rresp;
input m_rlast;
input m_rvalid;

function integer clogb2 (input integer size);
begin
	size = size - 1;
	for (clogb2=1; size>1; clogb2=clogb2+1)
		size = size >> 1;
end
endfunction

localparam SELECT_BITS = clogb2(SLAVE_NUM);

function [SELECT_BITS-1:0] select(input [SELECT_BITS-1:0] current, input [SLAVE_NUM-1:0] valid);
integer i,j;
begin
	select=current;
	for(i=0;i<SLAVE_NUM;i=i+1) begin
		j=current+i;
		if(j>=SLAVE_NUM)
			j=j-SLAVE_NUM;
		if(s_awvalid[j])
			select=j;
	end
end
endfunction

reg [SELECT_BITS-1:0] wi;
reg write_busy;
reg [SELECT_BITS-1:0] ri;
reg read_busy;

// Write Stage
always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		write_busy <= 1'b0;
	end
	else if(!write_busy && s_awvalid) begin
		write_busy <= 1'b1;
	end
	else if(write_busy && m_bvalid && m_bready) begin
		write_busy <= 1'b0;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		wi <= 0;
	end
	else if(!write_busy) begin
		wi <= select(wi, s_awvalid);
	end
end

always @(*)
begin:WRITE_SEL
	integer i;
	for(i=0;i<ID_WIDTH;i=i+1) 
		m_awid[i] = s_awid[ID_WIDTH*wi+i];

	for(i=0;i<ADDR_WIDTH;i=i+1) 
		m_awaddr[i] = s_awaddr[ADDR_WIDTH*wi+i];

	for(i=0;i<LEN_WIDTH;i=i+1) 
		m_awlen[i] = s_awlen[LEN_WIDTH*wi+i];

	for(i=0;i<3;i=i+1) 
		m_awsize[i] = s_awsize[3*wi+i];

	for(i=0;i<2;i=i+1) 
		m_awburst[i] = s_awburst[2*wi+i];

	m_awvalid = write_busy & s_awvalid[wi];

	for(i=0;i<ID_WIDTH;i=i+1) 
		m_wid[i] = s_wid[ID_WIDTH*wi+i];

	for(i=0;i<DATA_WIDTH;i=i+1) 
		m_wdata[i] = s_wdata[DATA_WIDTH*wi+i];

	for(i=0;i<STRB_WIDTH;i=i+1) 
		m_wstrb[i] = s_wstrb[STRB_WIDTH*wi+i];

	m_wlast = s_wlast[wi];

	m_wvalid = write_busy & s_wvalid[wi];

	m_bready = s_bready[wi];

	for(i=0;i<SLAVE_NUM;i=i+1) begin 
		s_awready[i] = (wi==i) & m_awready;
		s_wready[i] = (wi==i) & m_wready;
		s_bvalid[i] = (wi==i) & m_bvalid;
	end

	s_bid = {SLAVE_NUM{m_bid}};
	s_bresp = {SLAVE_NUM{m_bresp}};
end

// Read Stage
always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		read_busy <= 1'b0;
	end
	else if(!read_busy && s_arvalid) begin
		read_busy <= 1'b1;
	end
	else if(read_busy && m_rvalid && m_rready) begin
		read_busy <= 1'b0;
	end
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		ri <= 0;
	end
	else if(!read_busy) begin
		ri <= select(ri, s_arvalid);
	end
end

always @(*)
begin:READ_SEL
	integer i;
	for(i=0;i<ID_WIDTH;i=i+1) 
		m_arid[i] = s_arid[ID_WIDTH*ri+i];

	for(i=0;i<ADDR_WIDTH;i=i+1) 
		m_araddr[i] = s_araddr[ADDR_WIDTH*ri+i];

	for(i=0;i<LEN_WIDTH;i=i+1) 
		m_arlen[i] = s_arlen[LEN_WIDTH*ri+i];

	for(i=0;i<3;i=i+1) 
		m_arsize[i] = s_arsize[3*ri+i];

	for(i=0;i<2;i=i+1) 
		m_arburst[i] = s_arburst[2*ri+i];

	m_arvalid = read_busy & s_arvalid[ri];
	m_rready = s_rready[ri];

	for(i=0;i<SLAVE_NUM;i=i+1) begin
		s_arready[i] = (ri==i) & m_arready;
		s_rvalid[i] = (ri==i) & m_rvalid;
	end

	s_rid = {SLAVE_NUM{m_rid}};
	s_rdata = {SLAVE_NUM{m_rdata}};
	s_rresp = {SLAVE_NUM{m_rresp}};
	s_rlast = {SLAVE_NUM{m_rlast}};
end

endmodule

