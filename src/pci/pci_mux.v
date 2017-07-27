module pci_mux(
	inout [31:0] AD_IO,
	inout [3:0] CBE_IO,
	inout PAR_IO,
	inout FRAME_IO,
	inout TRDY_IO,
	inout IRDY_IO,
	inout STOP_IO,
	inout DEVSEL_IO,
	inout PERR_IO,
	inout SERR_IO,
	inout INTA_IO,
	inout INTB_IO,
	inout INTC_IO,
	inout INTD_IO,
	//inout [2:0] PME_IO,
	inout [2:0] REQ_IO,
	inout [2:0] GNT_IO,
	input RST_I,
	input CLK_I,

	output clk_o,
	output rstn_o,

	output p0_idseli,
	output [31:0] p0_adi,
	input [31:0] p0_ado,
	input p0_adt,
	output [3:0] p0_cbi,
	input [3:0] p0_cbo,
	input p0_cbt,
	output p0_pari,
	input p0_paro,
	input p0_part,
	output p0_framei,
	input p0_frameo,
	input p0_framet,
	output p0_trdyi,
	input p0_trdyo,
	input p0_trdyt,
	output p0_irdyi,
	input p0_irdyo,
	input p0_irdyt,
	output p0_stopi,
	input p0_stopo,
	input p0_stopt,
	output p0_devseli,
	input p0_devselo,
	input p0_devselt,
	output p0_perri,
	input p0_perro,
	input p0_perrt,
	output p0_serri,
	input p0_serro,
	input p0_serrt,
	output p0_gnti,
	input p0_reqo,
	input p0_reqt,
	input p0_into,
	input p0_intt,
	input p0_pmeo,
	input p0_pmet,

	output p1_idseli,
	output [31:0] p1_adi,
	input [31:0] p1_ado,
	input p1_adt,
	output [3:0] p1_cbi,
	input [3:0] p1_cbo,
	input p1_cbt,
	output p1_pari,
	input p1_paro,
	input p1_part,
	output p1_framei,
	input p1_frameo,
	input p1_framet,
	output p1_trdyi,
	input p1_trdyo,
	input p1_trdyt,
	output p1_irdyi,
	input p1_irdyo,
	input p1_irdyt,
	output p1_stopi,
	input p1_stopo,
	input p1_stopt,
	output p1_devseli,
	input p1_devselo,
	input p1_devselt,
	output p1_perri,
	input p1_perro,
	input p1_perrt,
	output p1_serri,
	input p1_serro,
	input p1_serrt,
	output p1_gnti,
	input p1_reqo,
	input p1_reqt,
	input p1_into,
	input p1_intt,
	input p1_pmeo,
	input p1_pmet,

	output p2_idseli,
	output [31:0] p2_adi,
	input [31:0] p2_ado,
	input p2_adt,
	output [3:0] p2_cbi,
	input [3:0] p2_cbo,
	input p2_cbt,
	output p2_pari,
	input p2_paro,
	input p2_part,
	output p2_framei,
	input p2_frameo,
	input p2_framet,
	output p2_trdyi,
	input p2_trdyo,
	input p2_trdyt,
	output p2_irdyi,
	input p2_irdyo,
	input p2_irdyt,
	output p2_stopi,
	input p2_stopo,
	input p2_stopt,
	output p2_devseli,
	input p2_devselo,
	input p2_devselt,
	output p2_perri,
	input p2_perro,
	input p2_perrt,
	output p2_serri,
	input p2_serro,
	input p2_serrt,
	output p2_gnti,
	input p2_reqo,
	input p2_reqt,
	input p2_into,
	input p2_intt,
	input p2_pmeo,
	input p2_pmet
);

wire [31:0] adi, adf, add;
reg [31:0] ado;
reg adt;
wire [3:0] cbi, cbf, cbd;
reg [3:0] cbo;
reg cbt;
wire intai, intaf, intad, intao, intat;
wire intbi, intbf, intbd, intbo, intbt;
wire intci, intcf, intcd, intco, intct;
wire intdi, intdf, intdd, intdo, intdt;
wire [2:0] pmei, pmef, pmed, pmeo, pmet;
wire [2:0] reqi, reqf, reqd, reqo, reqt;
wire [2:0] gnti, gntf, gntd;
wire [2:0] idself, idseld;

IBUFG clk_ibufg_i(.O(clk_o), .I(CLK_I));

wire rsti, rstd, rstf;
IBUF rst_ibuf_i(.O(rsti), .I(RST_I));
ZHOLD_DELAY rst_dly_i(.DLYFABRIC(rstf), .DLYIFF(rstd), .DLYIN(rsti));

generate
genvar i;
for(i=0;i<32;i=i+1) begin:G_AD
	IOBUF ad_iobuf_i(.O(adi[i]), .IO(AD_IO[i]), .I(ado[i]), .T(adt));
	ZHOLD_DELAY ad_dly_i(.DLYFABRIC(adf[i]), .DLYIFF(add[i]), .DLYIN(adi[i]));
end
for(i=0;i<4;i=i+1) begin:G_CB
	IOBUF cb_iobuf_i(.O(cbi[i]), .IO(CBE_IO[i]), .I(cbo[i]), .T(cbt));
	ZHOLD_DELAY cb_dly_i(.DLYFABRIC(cbf[i]), .DLYIFF(cbd[i]), .DLYIN(cbi[i]));
end
for(i=0;i<3;i=i+1) begin:G_MISC
	//IOBUF pme_obuft_i(.O(pmei[i]), .IO(PME_IO[i]), .T(pmet[i]), .I(pmeo[i]));
	//ZHOLD_DELAY pme_dly_i(.DLYFABRIC(pmef[i]), .DLYIFF(pmed[i]), .DLYIN(pmei[i]));

	IOBUF req_obuft_i(.O(reqi[i]), .IO(REQ_IO[i]), .T(reqt[i]), .I(reqo[i]));
	ZHOLD_DELAY req_dly_i(.DLYFABRIC(reqf[i]), .DLYIFF(reqd[i]), .DLYIN(reqi[i]));

	IOBUF gnt_ibuf_i(.O(gnti[i]), .IO(GNT_IO[i]), .T(1'b1), .I(1'b1));
	ZHOLD_DELAY gnt_dly_i(.DLYFABRIC(gntf[i]), .DLYIFF(gntd[i]), .DLYIN(gnti[i]));
end
endgenerate

IOBUF inta_obuft_i(.O(intai), .IO(INTA_IO), .T(intat), .I(intao));
ZHOLD_DELAY inta_dly_i(.DLYFABRIC(intaf), .DLYIFF(intad), .DLYIN(intai));

IOBUF intb_obuft_i(.O(intbi), .IO(INTB_IO), .T(intbt), .I(intbo));
ZHOLD_DELAY intb_dly_i(.DLYFABRIC(intbf), .DLYIFF(intbd), .DLYIN(intbi));

IOBUF intc_obuft_i(.O(intci), .IO(INTC_IO), .T(intct), .I(intco));
ZHOLD_DELAY intc_dly_i(.DLYFABRIC(intcf), .DLYIFF(intcd), .DLYIN(intci));

IOBUF intd_obuft_i(.O(intdi), .IO(INTD_IO), .T(intdt), .I(intdo));
ZHOLD_DELAY intd_dly_i(.DLYFABRIC(intdf), .DLYIFF(intdd), .DLYIN(intdi));

wire pari, parf, pard;
reg paro, part;
IOBUF par_iobuf_i(.O(pari), .IO(PAR_IO), .I(paro), .T(part));
ZHOLD_DELAY par_dly_i(.DLYFABRIC(parf), .DLYIFF(pard), .DLYIN(pari));

wire framei, framef, framed;
reg frameo, framet;
IOBUF frame_iobuf_i(.O(framei), .IO(FRAME_IO), .I(frameo), .T(framet));
ZHOLD_DELAY frame_dly_i(.DLYFABRIC(framef), .DLYIFF(framed), .DLYIN(framei));

wire trdyi, trdyf, trdyd;
reg trdyo, trdyt;
IOBUF trdy_iobuf_i(.O(trdyi), .IO(TRDY_IO), .I(trdyo), .T(trdyt));
ZHOLD_DELAY trdy_dly_i(.DLYFABRIC(trdyf), .DLYIFF(trdyd), .DLYIN(trdyi));

wire irdyi, irdyf, irdyd;
reg irdyo, irdyt;
IOBUF irdy_iobuf_i(.O(irdyi), .IO(IRDY_IO), .I(irdyo), .T(irdyt));
ZHOLD_DELAY irdy_dly_i(.DLYFABRIC(irdyf), .DLYIFF(irdyd), .DLYIN(irdyi));

wire stopi, stopf, stopd;
reg stopo, stopt;
IOBUF stop_iobuf_i(.O(stopi), .IO(STOP_IO), .I(stopo), .T(stopt));
ZHOLD_DELAY stop_dly_i(.DLYFABRIC(stopf), .DLYIFF(stopd), .DLYIN(stopi));

wire devseli, devself, devseld;
reg devselo, devselt;
IOBUF devsel_iobuf_i(.O(devseli), .IO(DEVSEL_IO), .I(devselo), .T(devselt));
ZHOLD_DELAY devsel_dly_i(.DLYFABRIC(devself), .DLYIFF(devseld), .DLYIN(devseli));

wire perri, perrf, perrd;
reg perro, perrt;
IOBUF perr_iobuf_i(.O(perri), .IO(PERR_IO), .I(perro), .T(perrt));
ZHOLD_DELAY perr_dly_i(.DLYFABRIC(perrf), .DLYIFF(perrd), .DLYIN(perri));

wire serri, serrf, serrd;
reg serro, serrt;
IOBUF serr_iobuf_i(.O(serri), .IO(SERR_IO), .I(serro), .T(serrt));
ZHOLD_DELAY serr_dly_i(.DLYFABRIC(serrf), .DLYIFF(serrd), .DLYIN(serri));

assign idself[0] = adf[24];
assign idseld[0] = add[24];
assign idself[1] = adf[25];
assign idseld[1] = add[25];
assign idself[2] = adf[26];
assign idseld[2] = add[26];

assign reqo[0] = p0_reqo;
assign reqt[0] = p0_reqt;
assign reqo[1] = p1_reqo;
assign reqt[1] = p1_reqt;
assign reqo[2] = p2_reqo;
assign reqt[2] = p2_reqt;

assign intao = 1'b0;
assign intat = p0_intt;
assign intbo = 1'b0;
assign intbt = p1_intt;
assign intco = 1'b0;
assign intct = p2_intt;
assign intdo = 1'b0;
assign intdt = 1'b1;

assign pmeo[0] = p0_pmeo;
assign pmet[0] = p0_pmet;
assign pmeo[1] = p1_pmeo;
assign pmet[1] = p1_pmet;
assign pmeo[2] = p2_pmeo;
assign pmet[2] = p2_pmet;

assign p0_idseli = idself[0];
assign p0_adi = adf;
assign p0_cbi = cbf;
assign p0_pari = parf;
assign p0_framei = framef;
assign p0_trdyi = trdyf;
assign p0_irdyi = irdyf;
assign p0_stopi = stopf;
assign p0_devseli = devself;
assign p0_perri = perrf;
assign p0_serri = serrf;
assign p0_gnti = gntf[0];

assign p1_idseli = idself[1];
assign p1_adi = adf;
assign p1_cbi = cbf;
assign p1_pari = parf;
assign p1_framei = framef;
assign p1_trdyi = trdyf;
assign p1_irdyi = irdyf;
assign p1_stopi = stopf;
assign p1_devseli = devself;
assign p1_perri = perrf;
assign p1_serri = serrf;
assign p1_gnti = gntf[1];

assign p2_idseli = idself[2];
assign p2_adi = adf;
assign p2_cbi = cbf;
assign p2_pari = parf;
assign p2_framei = framef;
assign p2_trdyi = trdyf;
assign p2_irdyi = irdyf;
assign p2_stopi = stopf;
assign p2_devseli = devself;
assign p2_perri = perrf;
assign p2_serri = serrf;
assign p2_gnti = gntf[2];

always @(*)
begin
	if(!p0_adt) ado = p0_ado;
	else if(!p1_adt) ado = p1_ado;
	else if(!p2_adt) ado = p2_ado;
	else ado = 'bx;
	adt = p0_adt & p1_adt & p2_adt;
end

always @(*)
begin
	if(!p0_cbt) cbo = p0_cbo;
	else if(!p1_cbt) cbo = p1_cbo;
	else if(!p2_cbt) cbo = p2_cbo;
	else cbo = 'bx;
	cbt = p0_cbt & p1_cbt & p2_cbt;
end

always @(*)
begin
	if(!p0_part) paro = p0_paro;
	else if(!p1_part) paro = p1_paro;
	else if(!p2_part) paro = p2_paro;
	else paro = 'bx;
	part = p0_part & p1_part & p2_part;
end

always @(*)
begin
	if(!p0_framet) frameo = p0_frameo;
	else if(!p1_framet) frameo = p1_frameo;
	else if(!p2_framet) frameo = p2_frameo;
	else frameo = 'bx;
	framet = p0_framet & p1_framet & p2_framet;
end

always @(*)
begin
	if(!p0_trdyt) trdyo = p0_trdyo;
	else if(!p1_trdyt) trdyo = p1_trdyo;
	else if(!p2_trdyt) trdyo = p2_trdyo;
	else trdyo = 'bx;
	trdyt = p0_trdyt & p1_trdyt & p2_trdyt;
end

always @(*)
begin
	if(!p0_irdyt) irdyo = p0_irdyo;
	else if(!p1_irdyt) irdyo = p1_irdyo;
	else if(!p2_irdyt) irdyo = p2_irdyo;
	else irdyo = 'bx;
	irdyt = p0_irdyt & p1_irdyt & p2_irdyt;
end

always @(*)
begin
	if(!p0_stopt) stopo = p0_stopo;
	else if(!p1_stopt) stopo = p1_stopo;
	else if(!p2_stopt) stopo = p2_stopo;
	else stopo = 'bx;
	stopt = p0_stopt & p1_stopt & p2_stopt;
end

always @(*)
begin
	if(!p0_devselt) devselo = p0_devselo;
	else if(!p1_devselt) devselo = p1_devselo;
	else if(!p2_devselt) devselo = p2_devselo;
	else devselo = 'bx;
	devselt = p0_devselt & p1_devselt & p2_devselt;
end

always @(*)
begin
	if(!p0_perrt) perro = p0_perro;
	else if(!p1_perrt) perro = p1_perro;
	else if(!p2_perrt) perro = p2_perro;
	else perro = 'bx;
	perrt = p0_perrt & p1_perrt & p2_perrt;
end

always @(*)
begin
	if(!p0_serrt) serro = p0_serro;
	else if(!p1_serrt) serro = p1_serro;
	else if(!p2_serrt) serro = p2_serro;
	else serro = 'bx;
	serrt = p0_serrt & p1_serrt & p2_serrt;
end

assign rstn_o = rstf;

(* MARK_DEBUG="TRUE" *) reg [31:0] PCI_AD;
(* MARK_DEBUG="TRUE" *) reg [3:0] PCI_CBE;
(* MARK_DEBUG="TRUE" *) reg PCI_PAR;
(* MARK_DEBUG="TRUE" *) reg PCI_FRAME;
(* MARK_DEBUG="TRUE" *) reg PCI_TRDY;
(* MARK_DEBUG="TRUE" *) reg PCI_IRDY;
(* MARK_DEBUG="TRUE" *) reg PCI_STOP;
(* MARK_DEBUG="TRUE" *) reg PCI_DEVSEL;
(* MARK_DEBUG="TRUE" *) reg PCI_PERR;
(* MARK_DEBUG="TRUE" *) reg PCI_SERR;
(* MARK_DEBUG="TRUE" *) reg PCI_INTA;
(* MARK_DEBUG="TRUE" *) reg PCI_INTB;
(* MARK_DEBUG="TRUE" *) reg PCI_INTC;
(* MARK_DEBUG="TRUE" *) reg PCI_INTD;
(* MARK_DEBUG="TRUE" *) reg [2:0] PCI_REQ;
//(* MARK_DEBUG="TRUE" *) reg [2:0] PCI_PME;
(* MARK_DEBUG="TRUE" *) reg [2:0] PCI_GNT;
(* MARK_DEBUG="TRUE" *) reg PCI_RST;

always @(posedge clk_o)
begin
	PCI_RST <= rstd;
	PCI_AD <= add;
	PCI_CBE <= cbd;
	PCI_INTA <= intat;
	PCI_INTB <= intbt;
	PCI_INTC <= intct;
	PCI_INTD <= intdt;
	PCI_REQ <= reqd;
	//PCI_PME <= pmed;
	PCI_GNT <= gntd;
	PCI_PAR <= pard;
	PCI_FRAME <= framed;
	PCI_TRDY <= trdyd;
	PCI_IRDY <= irdyd;
	PCI_STOP <= stopd;
	PCI_DEVSEL <= devseld;
	PCI_PERR <= perrd;
	PCI_SERR <= serrd;
end

endmodule
