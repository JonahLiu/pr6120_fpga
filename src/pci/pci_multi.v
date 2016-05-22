module pci_multi (
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
	output [2:0] INT_O,
	output [2:0] PME_O,
	output [2:0] REQ_O,
	input [2:0] GNT_I,
	input RST_I,
	input CLK_I,

	output CLK,
	output RST,

	input [31:0] P0_ADIO_IN,
	output [31:0] P0_ADIO_OUT,

	output [31:0] P0_ADDR,
	output P0_ADDR_VLD,
	output [7:0] P0_BASE_HIT,
	input P0_S_TERM,
	input P0_S_READY,
	input P0_S_ABORT,
	output P0_S_WRDN,
	output P0_S_SRC_EN,
	output P0_S_DATA,
	output P0_S_DATA_VLD,
	output [3:0] P0_S_CBE,
	input P0_INT_N,

	input P0_REQUEST,
	input P0_REQUESTHOLD,
	input [3:0] P0_M_CBE,
	input P0_M_WRDN,
	input P0_COMPLETE,
	input P0_M_READY,
	output P0_M_DATA_VLD,
	output P0_M_SRC_EN,
	output P0_TIME_OUT,
	output P0_M_DATA,
	output P0_M_ADDR_N,
	output P0_STOPQ_N,

	input [31:0] P1_ADIO_IN,
	output [31:0] P1_ADIO_OUT,

	output [31:0] P1_ADDR,
	output P1_ADDR_VLD,
	output [7:0] P1_BASE_HIT,
	input P1_S_TERM,
	input P1_S_READY,
	input P1_S_ABORT,
	output P1_S_WRDN,
	output P1_S_SRC_EN,
	output P1_S_DATA,
	output P1_S_DATA_VLD,
	output [3:0] P1_S_CBE,
	input P1_INT_N,

	input P1_REQUEST,
	input P1_REQUESTHOLD,
	input [3:0] P1_M_CBE,
	input P1_M_WRDN,
	input P1_COMPLETE,
	input P1_M_READY,
	output P1_M_DATA_VLD,
	output P1_M_SRC_EN,
	output P1_TIME_OUT,
	output P1_M_DATA,
	output P1_M_ADDR_N,
	output P1_STOPQ_N,

	input [31:0] P2_ADIO_IN,
	output [31:0] P2_ADIO_OUT,

	output [31:0] P2_ADDR,
	output P2_ADDR_VLD,
	output [7:0] P2_BASE_HIT,
	input P2_S_TERM,
	input P2_S_READY,
	input P2_S_ABORT,
	output P2_S_WRDN,
	output P2_S_SRC_EN,
	output P2_S_DATA,
	output P2_S_DATA_VLD,
	output [3:0] P2_S_CBE,
	input P2_INT_N,

	input P2_REQUEST,
	input P2_REQUESTHOLD,
	input [3:0] P2_M_CBE,
	input P2_M_WRDN,
	input P2_COMPLETE,
	input P2_M_READY,
	output P2_M_DATA_VLD,
	output P2_M_SRC_EN,
	output P2_TIME_OUT,
	output P2_M_DATA,
	output P2_M_ADDR_N,
	output P2_STOPQ_N
);

IBUFG clk_ibufg_i(.O(CLK), .I(CLK_I));
BUFG rst_bufg_i(.O(RST), .I(!RST_I));

wire [31:0] adi, adf, add;
reg [31:0] ado, adt;
wire [3:0] cbi, cbf, cbd;
reg [3:0] cbo, cbt;
wire [2:0] into, intt;
wire [2:0] pmeo, pmet;
wire [2:0] reqo, reqt;
wire [2:0] gnti, gntf, gntd;
wire [2:0] idself, idseld;

generate
genvar i;
for(i=0;i<32;i=i+1) begin:G_AD
	IOBUF ad_iobuf_i(.O(adi[i]), .IO(AD_IO[i]), .I(ado[i]), .T(adt[i]));
	ZHOLD_DELAY ad_dly_i(.DLYFABRIC(adf[i]), .DLYIFF(add[i]), .DLYIN(adi[i]));
end
for(i=0;i<4;i=i+1) begin:G_CB
	IOBUF cb_iobuf_i(.O(cbi[i]), .IO(CBE_IO[i]), .I(cbo[i]), .T(cbt[i]));
	ZHOLD_DELAY cb_dly_i(.DLYFABRIC(cbf[i]), .DLYIFF(cbd[i]), .DLYIN(cbi[i]));
end
for(i=0;i<3;i=i+1) begin:G_MISC
	OBUFT int_obuft_i(.O(INT_O[i]), .T(intt[i]), .I(into[i]));
	OBUFT pme_obuft_i(.O(PME_O[i]), .T(pmet[i]), .I(pmeo[i]));
	OBUFT req_obuft_i(.O(REQ_O[i]), .T(reqt[i]), .I(reqo[i]));
	IBUF gnt_ibuf_i(.O(gnti[i]), .I(GNT_I[i]));
	ZHOLD_DELAY gnt_dly_i(.DLYFABRIC(gntf[i]), .DLYIFF(gntd[i]), .DLYIN(gnti[i]));
end
endgenerate

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

wire [31:0] p0_ado, p0_adt;
wire [3:0] p0_cbo, p0_cbt;
wire p0_paro, p0_part;
wire p0_frameo, p0_framet;
wire p0_trdyo, p0_trdyt;
wire p0_irdyo, p0_irdyt;
wire p0_stopo, p0_stopt;
wire p0_devselo, p0_devselt;
wire p0_perro, p0_perrt;
wire p0_serro, p0_serrt;

wire [31:0] p1_ado, p1_adt;
wire [3:0] p1_cbo, p1_cbt;
wire p1_paro, p1_part;
wire p1_frameo, p1_framet;
wire p1_trdyo, p1_trdyt;
wire p1_irdyo, p1_irdyt;
wire p1_stopo, p1_stopt;
wire p1_devselo, p1_devselt;
wire p1_perro, p1_perrt;
wire p1_serro, p1_serrt;

wire [31:0] p2_ado, p2_adt;
wire [3:0] p2_cbo, p2_cbt;
wire p2_paro, p2_part;
wire p2_frameo, p2_framet;
wire p2_trdyo, p2_trdyt;
wire p2_irdyo, p2_irdyt;
wire p2_stopo, p2_stopt;
wire p2_devselo, p2_devselt;
wire p2_perro, p2_perrt;
wire p2_serro, p2_serrt;

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

pci32_p0 pci_p0_i(
	.ado(p0_ado),
	.adt(p0_adt),
	.adi(adf),
	.add(adf),

	.cbo(p0_cbo),
	.cbt(p0_cbt),
	.cbi(cbf),
	.cbd(cbf),

	.paro(p0_paro),
	.part(p0_part),
	.pari(parf),
	.pard(parf),

	.frameo(p0_frameo),
	.framet(p0_framet),
	.framei(framef),
	.framed(framef),

	.trdyo(p0_trdyo),
	.trdyt(p0_trdyt),
	.trdyi(trdyf),
	.trdyd(trdyf),

	.irdyo(p0_irdyo),
	.irdyt(p0_irdyt),
	.irdyi(irdyf),
	.irdyd(irdyf),

	.stopo(p0_stopo),
	.stopt(p0_stopt),
	.stopi(stopf),
	.stopd(stopf),

	.devselo(p0_devselo),
	.devselt(p0_devselt),
	.devseli(devself),
	.devseld(devself),

	.perro(p0_perro),
	.perrt(p0_perrt),
	.perri(perrf),
	.perrd(perrf),

	.serro(p0_serro),
	.serrt(p0_serrt),
	.serri(serrf),
	.serrd(serrf),

	.into(into[0]),
	.intt(intt[0]),

	.pmeo(pmeo[0]),
	.pmet(pmet[0]),

	.reqo(reqo[0]),
	.reqt(reqt[0]),

	.gnti(gntf[0]),
	.gntd(gntf[0]),

	.idseli(idself[0]),
	.idseld(idself[0]),

	.frameq_n(),
	.trdyq_n(),
	.irdyq_n(),
	.stopq_n(P0_STOPQ_N),
	.devselq_n(),
	.addr(P0_ADDR),
	.adio_in(P0_ADIO_IN),
	.adio_out(P0_ADIO_OUT),
	.cfg_vld(),
	.cfg_hit(),
	.c_term(1'b1),
	.c_ready(1'b1),
	.addr_vld(P0_ADDR_VLD),
	.base_hit(P0_BASE_HIT),
	.s_term(P0_S_TERM),
	.s_ready(P0_S_READY),
	.s_abort(P0_S_ABORT),
	.s_wrdn(P0_S_WRDN),
	.s_src_en(P0_S_SRC_EN),
	.s_data_vld(P0_S_DATA_VLD),
	.s_cbe(P0_S_CBE),
	.pci_cmd(),
	.request(P0_REQUEST),
	.requesthold(P0_REQUESTHOLD),
	.complete(P0_COMPLETE),
	.m_wrdn(P0_M_WRDN),
	.m_ready(P0_M_READY),
	.m_src_en(P0_M_SRC_EN),
	.m_data_vld(P0_M_DATA_VLD),
	.m_cbe(P0_M_CBE),
	.time_out(P0_TIME_OUT),
	.cfg_self(1'b0),
	.m_data(P0_M_DATA),
	.dr_bus(),
	.i_idle(),
	.m_addr_n(P0_M_ADDR_N),
	.idle(),
	.b_busy(),
	.s_data(P0_S_DATA),
	.backoff(),
	.int_n(P0_INT_N),
	.pme_n(1'b1),
	.perrq_n(),
	.serrq_n(),
	.keepout(1'b0),
	.csr(),
	.pciw_en(),
	.bw_detect_dis(1'b1),
	.bw_manual_32b(1'b1),
	.pcix_en(),
	.bm_detect_dis(1'b1),
	.bm_manual_pci(1'b1),
	.rtr(),
	.rst(RST),
	.cfg(),
	.clk(CLK)
);

pci32_p1 pci_p1_i(
	.ado(p1_ado),
	.adt(p1_adt),
	.adi(adf),
	.add(adf),

	.cbo(p1_cbo),
	.cbt(p1_cbt),
	.cbi(cbf),
	.cbd(cbf),

	.paro(p1_paro),
	.part(p1_part),
	.pari(parf),
	.pard(parf),

	.frameo(p1_frameo),
	.framet(p1_framet),
	.framei(framef),
	.framed(framef),

	.trdyo(p1_trdyo),
	.trdyt(p1_trdyt),
	.trdyi(trdyf),
	.trdyd(trdyf),

	.irdyo(p1_irdyo),
	.irdyt(p1_irdyt),
	.irdyi(irdyf),
	.irdyd(irdyf),

	.stopo(p1_stopo),
	.stopt(p1_stopt),
	.stopi(stopf),
	.stopd(stopf),

	.devselo(p1_devselo),
	.devselt(p1_devselt),
	.devseli(devself),
	.devseld(devself),

	.perro(p1_perro),
	.perrt(p1_perrt),
	.perri(perrf),
	.perrd(perrf),

	.serro(p1_serro),
	.serrt(p1_serrt),
	.serri(serrf),
	.serrd(serrf),

	.into(into[1]),
	.intt(intt[1]),

	.pmeo(pmeo[1]),
	.pmet(pmet[1]),

	.reqo(reqo[1]),
	.reqt(reqt[1]),

	.gnti(gntf[1]),
	.gntd(gntf[1]),

	.idseli(idself[1]),
	.idseld(idself[1]),

	.frameq_n(),
	.trdyq_n(),
	.irdyq_n(),
	.stopq_n(P1_STOPQ_N),
	.devselq_n(),
	.addr(P1_ADDR),
	.adio_in(P1_ADIO_IN),
	.adio_out(P1_ADIO_OUT),
	.cfg_vld(),
	.cfg_hit(),
	.c_term(1'b1),
	.c_ready(1'b1),
	.addr_vld(P1_ADDR_VLD),
	.base_hit(P1_BASE_HIT),
	.s_term(P1_S_TERM),
	.s_ready(P1_S_READY),
	.s_abort(P1_S_ABORT),
	.s_wrdn(P1_S_WRDN),
	.s_src_en(P1_S_SRC_EN),
	.s_data_vld(P1_S_DATA_VLD),
	.s_cbe(P1_S_CBE),
	.pci_cmd(),
	.request(P1_REQUEST),
	.requesthold(P1_REQUESTHOLD),
	.complete(P1_COMPLETE),
	.m_wrdn(P1_M_WRDN),
	.m_ready(P1_M_READY),
	.m_src_en(P1_M_SRC_EN),
	.m_data_vld(P1_M_DATA_VLD),
	.m_cbe(P1_M_CBE),
	.time_out(P1_TIME_OUT),
	.cfg_self(1'b0),
	.m_data(P1_M_DATA),
	.dr_bus(),
	.i_idle(),
	.m_addr_n(P1_M_ADDR_N),
	.idle(),
	.b_busy(),
	.s_data(P1_S_DATA),
	.backoff(),
	.int_n(P1_INT_N),
	.pme_n(1'b1),
	.perrq_n(),
	.serrq_n(),
	.keepout(1'b0),
	.csr(),
	.pciw_en(),
	.bw_detect_dis(1'b1),
	.bw_manual_32b(1'b1),
	.pcix_en(),
	.bm_detect_dis(1'b1),
	.bm_manual_pci(1'b1),
	.rtr(),
	.rst(RST),
	.cfg(),
	.clk(CLK)
);

pci32_p2 pci_p2_i(
	.ado(p2_ado),
	.adt(p2_adt),
	.adi(adf),
	.add(adf),

	.cbo(p2_cbo),
	.cbt(p2_cbt),
	.cbi(cbf),
	.cbd(cbf),

	.paro(p2_paro),
	.part(p2_part),
	.pari(parf),
	.pard(parf),

	.frameo(p2_frameo),
	.framet(p2_framet),
	.framei(framef),
	.framed(framef),

	.trdyo(p2_trdyo),
	.trdyt(p2_trdyt),
	.trdyi(trdyf),
	.trdyd(trdyf),

	.irdyo(p2_irdyo),
	.irdyt(p2_irdyt),
	.irdyi(irdyf),
	.irdyd(irdyf),

	.stopo(p2_stopo),
	.stopt(p2_stopt),
	.stopi(stopf),
	.stopd(stopf),

	.devselo(p2_devselo),
	.devselt(p2_devselt),
	.devseli(devself),
	.devseld(devself),

	.perro(p2_perro),
	.perrt(p2_perrt),
	.perri(perrf),
	.perrd(perrf),

	.serro(p2_serro),
	.serrt(p2_serrt),
	.serri(serrf),
	.serrd(serrf),

	.into(into[2]),
	.intt(intt[2]),

	.pmeo(pmeo[2]),
	.pmet(pmet[2]),

	.reqo(reqo[2]),
	.reqt(reqt[2]),

	.gnti(gntf[2]),
	.gntd(gntf[2]),

	.idseli(idself[2]),
	.idseld(idself[2]),

	.frameq_n(),
	.trdyq_n(),
	.irdyq_n(),
	.stopq_n(P2_STOPQ_N),
	.devselq_n(),
	.addr(P2_ADDR),
	.adio_in(P2_ADIO_IN),
	.adio_out(P2_ADIO_OUT),
	.cfg_vld(),
	.cfg_hit(),
	.c_term(1'b1),
	.c_ready(1'b1),
	.addr_vld(P2_ADDR_VLD),
	.base_hit(P2_BASE_HIT),
	.s_term(P2_S_TERM),
	.s_ready(P2_S_READY),
	.s_abort(P2_S_ABORT),
	.s_wrdn(P2_S_WRDN),
	.s_src_en(P2_S_SRC_EN),
	.s_data_vld(P2_S_DATA_VLD),
	.s_cbe(P2_S_CBE),
	.pci_cmd(),
	.request(P2_REQUEST),
	.requesthold(P2_REQUESTHOLD),
	.complete(P2_COMPLETE),
	.m_wrdn(P2_M_WRDN),
	.m_ready(P2_M_READY),
	.m_src_en(P2_M_SRC_EN),
	.m_data_vld(P2_M_DATA_VLD),
	.m_cbe(P2_M_CBE),
	.time_out(P2_TIME_OUT),
	.cfg_self(1'b0),
	.m_data(P2_M_DATA),
	.dr_bus(),
	.i_idle(),
	.m_addr_n(P2_M_ADDR_N),
	.idle(),
	.b_busy(),
	.s_data(P2_S_DATA),
	.backoff(),
	.int_n(P2_INT_N),
	.pme_n(1'b1),
	.perrq_n(),
	.serrq_n(),
	.keepout(1'b0),
	.csr(),
	.pciw_en(),
	.bw_detect_dis(1'b1),
	.bw_manual_32b(1'b1),
	.pcix_en(),
	.bm_detect_dis(1'b1),
	.bm_manual_pci(1'b1),
	.rtr(),
	.rst(RST),
	.cfg(),
	.clk(CLK)
);

endmodule
