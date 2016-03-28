`timescale 1ns/1ns
module mdio_ctrl #(
  parameter div=16
)(
  input         s_clk           ,
  input         s_resetn        ,
  //write_addr
  input         s_awvalid       ,
  output        s_awready       ,
  input  [31:0] s_awaddr        ,
  //write_data
  input         s_wvalid        ,
  output        s_wready        ,
  input  [31:0] s_wdata         ,
  //write_response
  output        s_bvalid        ,
  input         s_bready        ,
  output [ 1:0] s_bresp         ,
  //read_addr
  input         s_arvalid       ,
  output        s_arready       ,
  input  [31:0] s_araddr        ,
  //read_data
  output        s_rvalid        ,
  input         s_rready        ,
  output [31:0] s_rdata         ,
  output [ 1:0] s_rresp         ,
  //mdio
  output        mdc             ,
  input         mdio_i          ,
  output        mdio_o          ,
  output        mdio_t          ,

  output        interrupt

);
  wire [15:0] rdatai;
  wire [31:0] wdatao;

  axi4_mdio axi4_mdio(
    .clk           ( s_clk     ),
    .rst           ( !s_resetn ),

    .s_awvalid     ( s_awvalid ),
    .s_awready     ( s_awready ),
    .s_awaddr      ( s_awaddr  ),

    .s_wvalid      ( s_wvalid  ),
    .s_wready      ( s_wready  ),
    .s_wdata       ( s_wdata   ),

    .s_bvalid      ( s_bvalid  ),
    .s_bready      ( s_bready  ),
    .s_bresp       ( s_bresp   ),

    .s_arvalid     ( s_arvalid ),
    .s_arready     ( s_arready ),
    .s_araddr      ( s_araddr  ),

    .s_rvalid      ( s_rvalid  ),
    .s_rready      ( s_rready  ),
    .s_rdata       ( s_rdata   ),
    .s_rresp       ( s_rresp   ),

    .wdatao        ( wdatao    ),
    .eno           ( eno       ),
    .wr_donei      ( wr_donei  ),

    .rdatai        ( rdatai    ),
    .rd_donei      ( rd_donei  ),
    .interrupt     ( interrupt )
  );

  shift_mdio #(
    .div ( div )
  )shift_mdio(
     .clk     ( s_clk     ),
     .rst     ( !s_resetn ),

     .mdc_o   ( mdc     ),
     .mdio_i  ( mdio_i  ),
     .mdio_o  ( mdio_o  ),
     .mdio_oe ( mdio_t  ),

     .rdatao  ( rdatai  ),
     .rd_doneo( rd_donei),

     .eni     ( eno    ),
     .wdatai  ( wdatao ),
     .wr_doneo( wr_donei )
   );



endmodule