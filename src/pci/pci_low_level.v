module pci_low_level(
	// PCI Bus Signals
	inout  [31:0] AD,
	inout   [3:0] CBE,
	inout         PAR,
	inout         FRAME_N,
	inout         TRDY_N,
	inout         IRDY_N,
	inout         STOP_N,
	inout         DEVSEL_N,
	input         IDSEL,
	inout         PERR_N,
	inout         SERR_N,
	output        INTA_N,
	output        INTB_N,
	output        INTC_N,
	output        INTD_N,
	output        PME_N,
	output        REQ_N,
	input         GNT_N,
	input         RST_N,
	input         PCLK,

	output clock_out,
	output reset_out,

	output [63:0] s_cmd_address,
	output [3:0] s_cmd_command,
	output s_cmd_valid,
	input s_cmd_ready,

	output [31:0] s_wdata,
	input [31:0] s_rdata,
	output [3:0] s_strb,
	output s_last,
	output s_valid,
	input s_ready,
	input s_stop,
	input s_abort,

	input [63:0] m_cmd_address,
	input [3:0] m_cmd_command,
	input m_cmd_valid,
	output m_cmd_ready,

	input [31:0] m_wdata,
	output [31:0] m_rdata,
	input [3:0] m_strb,
	input m_last,
	input m_valid,
	output m_ready,
	output m_stop,

	input m_inta,
	input m_intb,
	input m_intc,
	input m_intd
);

wire [31:0] ad_i;
wire [31:0] ad_o;
wire ad_oe;

wire [3:0] cbe_i;
wire [3:0] cbe_o;
wire cbe_oe;

wire par_i;
wire par_o;
wire par_oe;

wire frame_i;
wire frame_o;
wire frame_oe;

wire trdy_i;
wire trdy_o;
wire trdy_oe;

wire irdy_i;
wire irdy_o;
wire irdy_oe;

wire stop_i;
wire stop_o;
wire stop_oe;

wire devsel_i;
wire devsel_o;
wire devsel_oe;

wire idsel_i;

wire perr_i;
wire perr_o;
wire perr_oe;

wire serr_i;
wire serr_o;
wire serr_oe;

wire inta_o;
wire inta_oe;

wire intb_o;
wire intb_oe;

wire intc_o;
wire intc_oe;

wire intd_o;
wire intd_oe;

wire pme_o;
wire pme_oe;

wire req_o;
wire req_oe;

wire gnt_i;
wire rst_i;
wire clk_i;

integer state, state_next;

assign clk_i = PCLK;
assign rst_i = !RST_N;
assign clock_out = clk_i;
assign reset_out = rst_i;

assign ad_i = AD;
assign AD = ad_oe?ad_o:32'bz;

assign cbe_i = CBE;
assign CBE = cbe_oe?cbe_o:4'bz;

assign par_i = PAR;
assign PAR = par_oe?par_o:1'bz;

assign frame_i = !FRAME_N;
assign FRAME_N = frame_oe?!frame_o:1'bz;

assign trdy_i = !TRDY_N;
assign TRDY_N = trdy_oe?!trdy_o:1'bz;

assign irdy_i = !IRDY_N;
assign IRDY_N = irdy_oe?!irdy_o:1'bz;

assign stop_i = !STOP_N;
assign STOP_N = stop_oe?!stop_o:1'bz;

assign devsel_i = !DEVSEL_N;
assign DEVSEL_N = devsel_oe?!devsel_o:1'bz;

assign idsel_i = IDSEL;

assign perr_i = !PERR_N;
assign PERR_N = perr_oe?!perr_o:1'bz;

assign serr_i = !SERR_N;
assign SERR_N = serr_oe?!serr_o:1'bz;

assign INTA_N = inta_oe?!inta_o:1'bz;
assign INTB_N = intb_oe?!intb_o:1'bz;
assign INTC_N = intc_oe?!intc_o:1'bz;
assign INTD_N = intd_oe?!intd_o:1'bz;
assign PME_N = pme_oe?!pme_o:1'bz;
assign REQ_N = req_oe?!req_o:1'bz;

assign gnt_i = !GNT_N;

always @(posedge rst_i)
begin
	if(rst_i) begin
		inta_o <= 1'b1;
		intb_o <= 1'b1;
		intc_o <= 1'b1;
		intd_o <= 1'b1;
		pme_o <= 1'b1;
		req_o <= 1'b1;
	end
end

always @(posedge clk_i, posedge rst_i)
begin
	if(rst)
		ss <= SS_IDLE;
	else
		ss <= ss_next;
end

always @(*)
begin
	case(ss)
		SS_IDLE: begin
			if(!master_busy && frame_i)
				if(cbe_i==PCI_CMD_DAC)
					ss_next = SS_DAC;
				else
					ss_next = SS_CMD;
			else
				ss_next = SS_IDLE;
		end
		SS_DAC: begin
			ss_next = SS_CMD;
		end
		SS_CMD: begin
			if(s_cmd_ready)
				if(is_write)
					ss_next = SS_WRITE_DATA;
				else
					ss_next = SS_READ_DATA;
			else if(devsel_i)
				ss_next = SS_BUSY;
			else if(!frame_i)
				ss_next = SS_IDLE;
			else
				ss_next = SS_CMD;
		end
		SS_WRITE_DATA: begin
			if(!devsel_i)
				ss_next = SS_WRITE_ABORT;
			else if(!frame_i && irdy_i && (trdy_o||stop_o))
				ss_next = SS_IDLE;
			else if(frame_i && stop_o)
				ss_next = SS_WRITE_DISCONNECT;
			else
				ss_next = SS_WRITE_DATA;
		end
		SS_WRITE_ABORT: begin
			if(!frame_i)
				ss_next = SS_IDLE;
			else
				ss_next = SS_WRITE_ABORT;
		end
		SS_WRITE_DISCONNECT: begin 
			if(!frame_i)
				ss_next = SS_IDLE;
			else
				ss_next = SS_WRITE_DISCONNECT;
		end
		SS_READ_DATA: begin
			if(!devsel_i)
				ss_next = SS_READ_ABORT;
			else if(!frame_i && irdy_i && (trdy_o||stop_o))
				ss_next = SS_IDLE;
			else if(frame_i && stop_o)
				ss_next = SS_READ_DISCONNECT;
			else
				ss_next = SS_READ_DATA;
		end
		SS_READ_ABORT: begin
			if(!frame_i)
				ss_next = SS_IDLE;
			else
				ss_next = SS_READ_ABORT;
		end
		SS_READ_DISCONNECT: begin
			if(!frame_i)
				ss_next = SS_IDLE;
			else
				ss_next = SS_READ_DISCONNECT;
		end
		SS_BUSY: begin
			if(!frame_i && irdy_i && (trdy_i||stop_i))
				ss_next = SS_IDLE;
			else
				ss_next = SS_BUSY;
		end
		default: begin
			ss_next = 'bx;
		end
	endcase
end

endmodule
