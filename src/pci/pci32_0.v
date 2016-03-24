// (c) Copyright 1995-2016 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


// IP VLNV: xilinx.com:ip:pci32:5.0
// IP Revision: 6

(* X_CORE_INFO = "pci32_v5_0_wrap,Vivado 2014.4" *)
(* CHECK_LICENSE_TYPE = "pci32_0,pci32_v5_0_wrap,{pci32=bought}" *)
(* CORE_GENERATION_INFO = "pci32_0,pci32_v5_0_wrap,{x_ipProduct=Vivado 2014.4,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=pci32,x_ipVersion=5.0,x_ipCoreRevision=6,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,x_ipLicense=pci32@2014.04(bought),c_bus_width=32,c_pci_cfg_width=512,c_vendor_id=8086,c_device_id=abcd,c_revision_id=00,c_subvendor_id=10EE,c_subdevice_id=0050,c_usercap_enabled=0,c_usercap_addr=80,c_base_class=02,c_sub_class=00,c_sw_interface=00,c_class_code=020000,c_cardbus_cis=00000000,c_max_lat=00,c_min_gnt=ff,c_bar0_enabled=1,c_bar0_width=0,c_bar0_size=7,c_bar0_scale=1,c_bar0_type=0,c_bar0_prefetchable=0,c_bar0_value=FFFE0000,c_bar1_enabled=1,c_bar1_width=0,c_bar1_size=7,c_bar1_scale=1,c_bar1_type=0,c_bar1_prefetchable=0,c_bar1_value=FFFE0000,c_bar2_enabled=1,c_bar2_width=0,c_bar2_size=3,c_bar2_scale=0,c_bar2_type=1,c_bar2_prefetchable=0,c_bar2_value=FFFFFFF1,c_implement_pcix133=0,c_implement_pcix66=0,c_implement_pci66=0,c_implement_pci33=1,c_reverse_pinout=0,c_clock_type=1}" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module pci32_0 (
  ado,
  adi,
  add,
  adt,
  cbo,
  cbi,
  cbd,
  cbt,
  paro,
  pari,
  pard,
  part,
  frameo,
  framei,
  framed,
  framet,
  trdyo,
  trdyi,
  trdyd,
  trdyt,
  irdyo,
  irdyi,
  irdyd,
  irdyt,
  stopo,
  stopi,
  stopd,
  stopt,
  devselo,
  devseli,
  devseld,
  devselt,
  perro,
  perri,
  perrd,
  perrt,
  serro,
  serri,
  serrd,
  serrt,
  into,
  intt,
  pmeo,
  pmet,
  reqo,
  reqt,
  gnti,
  gntd,
  idseli,
  idseld,
  frameq_n,
  trdyq_n,
  irdyq_n,
  stopq_n,
  devselq_n,
  addr,
  adio_in,
  adio_out,
  cfg_vld,
  cfg_hit,
  c_term,
  c_ready,
  addr_vld,
  base_hit,
  s_term,
  s_ready,
  s_abort,
  s_wrdn,
  s_src_en,
  s_data_vld,
  s_cbe,
  pci_cmd,
  request,
  requesthold,
  complete,
  m_wrdn,
  m_ready,
  m_src_en,
  m_data_vld,
  m_cbe,
  time_out,
  cfg_self,
  m_data,
  dr_bus,
  i_idle,
  m_addr_n,
  idle,
  b_busy,
  s_data,
  backoff,
  int_n,
  pme_n,
  perrq_n,
  serrq_n,
  keepout,
  csr,
  pciw_en,
  bw_detect_dis,
  bw_manual_32b,
  pcix_en,
  bm_detect_dis,
  bm_manual_pci,
  rtr,
  rst,
  cfg,
  clk
);

output wire [31 : 0] ado;
input wire [31 : 0] adi;
input wire [31 : 0] add;
output wire [31 : 0] adt;
output wire [3 : 0] cbo;
input wire [3 : 0] cbi;
input wire [3 : 0] cbd;
output wire [3 : 0] cbt;
output wire paro;
input wire pari;
input wire pard;
output wire part;
output wire frameo;
input wire framei;
input wire framed;
output wire framet;
output wire trdyo;
input wire trdyi;
input wire trdyd;
output wire trdyt;
output wire irdyo;
input wire irdyi;
input wire irdyd;
output wire irdyt;
output wire stopo;
input wire stopi;
input wire stopd;
output wire stopt;
output wire devselo;
input wire devseli;
input wire devseld;
output wire devselt;
output wire perro;
input wire perri;
input wire perrd;
output wire perrt;
output wire serro;
input wire serri;
input wire serrd;
output wire serrt;
output wire into;
output wire intt;
output wire pmeo;
output wire pmet;
output wire reqo;
output wire reqt;
input wire gnti;
input wire gntd;
input wire idseli;
input wire idseld;
output wire frameq_n;
output wire trdyq_n;
output wire irdyq_n;
output wire stopq_n;
output wire devselq_n;
output wire [31 : 0] addr;
input wire [31 : 0] adio_in;
output wire [31 : 0] adio_out;
output wire cfg_vld;
output wire cfg_hit;
input wire c_term;
input wire c_ready;
output wire addr_vld;
output wire [7 : 0] base_hit;
input wire s_term;
input wire s_ready;
input wire s_abort;
output wire s_wrdn;
output wire s_src_en;
output wire s_data_vld;
output wire [3 : 0] s_cbe;
output wire [15 : 0] pci_cmd;
input wire request;
input wire requesthold;
input wire complete;
input wire m_wrdn;
input wire m_ready;
output wire m_src_en;
output wire m_data_vld;
input wire [3 : 0] m_cbe;
output wire time_out;
input wire cfg_self;
output wire m_data;
output wire dr_bus;
output wire i_idle;
output wire m_addr_n;
output wire idle;
output wire b_busy;
output wire s_data;
output wire backoff;
input wire int_n;
input wire pme_n;
output wire perrq_n;
output wire serrq_n;
input wire keepout;
output wire [39 : 0] csr;
output wire pciw_en;
input wire bw_detect_dis;
input wire bw_manual_32b;
output wire pcix_en;
input wire bm_detect_dis;
input wire bm_manual_pci;
output wire rtr;
input wire rst;
output wire [511 : 0] cfg;
input wire clk;

  pci32_v5_0_wrap #(
    .c_bus_width(32),
    .c_pci_cfg_width(512),
    .c_vendor_id("8086"),
    .c_device_id("abcd"),
    .c_revision_id("00"),
    .c_subvendor_id("10EE"),
    .c_subdevice_id("0050"),
    .c_usercap_enabled(0),
    .c_usercap_addr("80"),
    .c_base_class("02"),
    .c_sub_class("00"),
    .c_sw_interface("00"),
    .c_class_code("020000"),
    .c_cardbus_cis("00000000"),
    .c_max_lat("00"),
    .c_min_gnt("ff"),
    .c_bar0_enabled(1),
    .c_bar0_width(0),
    .c_bar0_size(7),
    .c_bar0_scale(1),
    .c_bar0_type(0),
    .c_bar0_prefetchable(0),
    .c_bar0_value("FFFE0000"),
    .c_bar1_enabled(1),
    .c_bar1_width(0),
    .c_bar1_size(7),
    .c_bar1_scale(1),
    .c_bar1_type(0),
    .c_bar1_prefetchable(0),
    .c_bar1_value("FFFE0000"),
    .c_bar2_enabled(1),
    .c_bar2_width(0),
    .c_bar2_size(3),
    .c_bar2_scale(0),
    .c_bar2_type(1),
    .c_bar2_prefetchable(0),
    .c_bar2_value("FFFFFFF1"),
    .c_implement_pcix133(0),
    .c_implement_pcix66(0),
    .c_implement_pci66(0),
    .c_implement_pci33(1),
    .c_reverse_pinout(0),
    .c_clock_type(1)
  ) inst (
    .ado(ado),
    .adi(adi),
    .add(add),
    .adt(adt),
    .cbo(cbo),
    .cbi(cbi),
    .cbd(cbd),
    .cbt(cbt),
    .paro(paro),
    .pari(pari),
    .pard(pard),
    .part(part),
    .par64o(),
    .par64i(1'H0),
    .par64d(1'H0),
    .par64t(),
    .frameo(frameo),
    .framei(framei),
    .framed(framed),
    .framet(framet),
    .req64o(),
    .req64i(1'H0),
    .req64d(1'H0),
    .req64t(),
    .trdyo(trdyo),
    .trdyi(trdyi),
    .trdyd(trdyd),
    .trdyt(trdyt),
    .irdyo(irdyo),
    .irdyi(irdyi),
    .irdyd(irdyd),
    .irdyt(irdyt),
    .stopo(stopo),
    .stopi(stopi),
    .stopd(stopd),
    .stopt(stopt),
    .devselo(devselo),
    .devseli(devseli),
    .devseld(devseld),
    .devselt(devselt),
    .ack64o(),
    .ack64i(1'H0),
    .ack64d(1'H0),
    .ack64t(),
    .perro(perro),
    .perri(perri),
    .perrd(perrd),
    .perrt(perrt),
    .serro(serro),
    .serri(serri),
    .serrd(serrd),
    .serrt(serrt),
    .into(into),
    .intt(intt),
    .pmeo(pmeo),
    .pmet(pmet),
    .reqo(reqo),
    .reqt(reqt),
    .gnti(gnti),
    .gntd(gntd),
    .idseli(idseli),
    .idseld(idseld),
    .frameq_n(frameq_n),
    .req64q_n(),
    .trdyq_n(trdyq_n),
    .irdyq_n(irdyq_n),
    .stopq_n(stopq_n),
    .devselq_n(devselq_n),
    .ack64q_n(),
    .addr(addr),
    .adio_in(adio_in),
    .adio_out(adio_out),
    .cfg_vld(cfg_vld),
    .cfg_hit(cfg_hit),
    .c_term(c_term),
    .c_ready(c_ready),
    .addr_vld(addr_vld),
    .base_hit(base_hit),
    .s_cycle64(),
    .s_term(s_term),
    .s_ready(s_ready),
    .s_abort(s_abort),
    .s_wrdn(s_wrdn),
    .s_src_en(s_src_en),
    .s_data_vld(s_data_vld),
    .s_cbe(s_cbe),
    .pci_cmd(pci_cmd),
    .request(request),
    .request64(1'H0),
    .requesthold(requesthold),
    .complete(complete),
    .m_wrdn(m_wrdn),
    .m_ready(m_ready),
    .m_src_en(m_src_en),
    .m_data_vld(m_data_vld),
    .m_cbe(m_cbe),
    .time_out(time_out),
    .m_fail64(),
    .cfg_self(cfg_self),
    .m_data(m_data),
    .dr_bus(dr_bus),
    .i_idle(i_idle),
    .m_addr_n(m_addr_n),
    .idle(idle),
    .b_busy(b_busy),
    .s_data(s_data),
    .backoff(backoff),
    .int_n(int_n),
    .pme_n(pme_n),
    .perrq_n(perrq_n),
    .serrq_n(serrq_n),
    .keepout(keepout),
    .csr(csr),
    .pciw_en(pciw_en),
    .bw_detect_dis(bw_detect_dis),
    .bw_manual_32b(bw_manual_32b),
    .pcix_en(pcix_en),
    .bm_detect_dis(bm_detect_dis),
    .bm_manual_pci(bm_manual_pci),
    .rtr(rtr),
    .rst(rst),
    .cfg(cfg),
    .clk(clk)
  );
endmodule
