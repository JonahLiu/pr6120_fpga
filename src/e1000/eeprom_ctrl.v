`timescale 1ns/1ns
module eeprom_ctrl #(
  parameter div=16,
  parameter Eecd=32'h00000010
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
  //eeprom
  output            sk        ,
  output            cs        ,
  output            di        ,
  input             do        

);
  wire [31:0] rdatai;
  wire [31:0] wdatao;

  axi4_eeprom #(
    .Eecd ( Eecd )
  )axi4_eeprom(
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
    .eerd_busy     ( eerd_busy ),

    .sk_eecd       ( sk_eecd   ),
    .cs_eecd       ( cs_eecd   ),
    .di_eecd       ( di_eecd   ),
    .eecd_busy     ( eecd_busy ),
     
    .rdatai        ( rdatai    ),
    .do            ( do        )
  );

  shift_eeprom #(
    .div ( div )
  )shift_eeprom(
    .clk       ( s_clk     ),
    .rst       ( !s_resetn ),

    .sk        ( sk        ),
    .cs        ( cs        ),
    .di        ( di        ),
    .do        ( do        ),

    .rdatao    ( rdatai    ),
    .sk_eecd   ( sk_eecd   ),
    .cs_eecd   ( cs_eecd   ),
    .di_eecd   ( di_eecd   ),
    .eecd_busy ( eecd_busy ),
                 
    .eni       ( eno       ),
    .wdatai    ( wdatao    ),
    .eerd_busy ( eerd_busy )
   );



endmodule