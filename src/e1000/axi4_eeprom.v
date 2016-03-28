`timescale 1ns/1ns
module axi4_eeprom #(
  parameter Eecd=32'h00000010
)(
  input             clk             ,
  input             rst             ,
  //write_addr
  input             s_awvalid       ,
  output reg        s_awready       ,
  input      [31:0] s_awaddr        ,
  //write_data
  input             s_wvalid        ,
  output reg        s_wready        ,
  input      [31:0] s_wdata         ,
  //write_response
  output reg        s_bvalid        ,
  input             s_bready        ,
  output reg [ 1:0] s_bresp         ,
  //read_addr
  input             s_arvalid       ,
  output reg        s_arready       ,
  input      [31:0] s_araddr        ,
  //read_data
  output reg        s_rvalid        ,
  input             s_rready        ,
  output reg [31:0] s_rdata         ,
  output reg [ 1:0] s_rresp         ,
  //eeprom
  output reg [31:0] wdatao          ,
  output reg        eno             ,
  input             eerd_busy       ,
  
  output reg        sk_eecd         ,
  output reg        cs_eecd         ,
  output reg        di_eecd         ,
  output reg        eecd_busy       ,

  input      [31:0] rdatai          ,
  input             do
);

  reg [7:0] Wstate, Wnextstate;
  reg [7:0] Rstate, Rnextstate;
  parameter Idle        = 8'h01,
            Wr_addr     = 8'h02,
            Wr_data     = 8'h04,
            Wr_response = 8'h08,
            Eecd_wr     = 8'h10,
            Eerd_wr     = 8'h20,
            Rd_addr     = 8'h40,
            Rd_data     = 8'h80;

  reg [31:0] wdata_reg, rdata_reg, s_awaddr_reg, Eecd_rdata_reg, s_araddr_reg;

  always@(posedge clk or posedge rst)
  if(rst) begin
    Wstate<=Idle;
  end else begin
    Wstate<=Wnextstate;
  end

  always@(*) begin
    case(Wstate)
      Idle: begin
        if(s_awvalid) begin //addr_write_valid
          Wnextstate = Wr_addr;
        end else begin
          Wnextstate = Idle;
        end
      end
      Wr_addr: begin
        Wnextstate = Wr_data;
      end
      Wr_data: begin
        if(s_wvalid && s_awaddr_reg==Eecd) begin //data_write_valid
          Wnextstate = Eecd_wr;
        end else if(s_wvalid) begin //data_write_valid
          Wnextstate = Eerd_wr;
        end else begin
          Wnextstate = Wr_data;
        end
      end
      Eecd_wr: begin
        Wnextstate = Wr_response;
      end
      Eerd_wr: begin
        Wnextstate = Wr_response;
      end
      Wr_response: begin
        if(s_bready) begin //response_write_ready
          Wnextstate = Idle;
        end else begin
          Wnextstate = Wr_response;
        end
      end
      default: begin
        Wnextstate = 'bx;
      end
    endcase
  end
  
  always@(posedge clk or posedge rst)
  if(rst) begin
    s_awready<=0;
    s_wready<=0;
    s_bvalid<=0;
    s_bresp<=2'b0;
    //
    sk_eecd<=0;
    cs_eecd<=0;
    di_eecd<=0;
    eno<=0;
    rdata_reg<=0;
    eecd_busy<=0;
    wdatao<=0;
    wdata_reg<=0;
    s_awaddr_reg<=0;
  end else begin
    case(Wnextstate)
      Idle: begin
        s_awready<=0;
        s_wready<=0;
        s_bvalid<=0;
        //
        eno<=0;
      end
      Wr_addr: begin //ready_write_addr //Rwaddr
        s_awaddr_reg<=s_awaddr;
        s_awready<=1;
      end
      Wr_data: begin
        s_awready<=0;
        s_wready<=1;
        wdata_reg<=s_wdata;
      end
      Eecd_wr: begin
        s_wready<=0;
        //
        Eecd_rdata_reg<={wdata_reg[31:8], !eerd_busy, wdata_reg[6:4], do, wdata_reg[2:0]};
        sk_eecd<=wdata_reg[0];
        cs_eecd<=wdata_reg[1];
        di_eecd<=wdata_reg[2];
        eecd_busy<=wdata_reg[6];
      end
      Eerd_wr: begin
        s_wready<=0;
        //
        wdatao<=wdata_reg;
        eno<=wdata_reg[0];
      end
      Wr_response: begin
        s_wready<=0;
        s_bvalid<=1;
        //
        eno<=0;
      end
    endcase
  end
 //rd
  always@(posedge clk or posedge rst)
  if(rst) begin
    Rstate<=Idle;
  end else begin
    Rstate<=Rnextstate;
  end

  always@(*) begin
    case(Rstate)
      Idle: begin
        if(s_arvalid) begin
          Rnextstate = Rd_addr;
        end else begin
          Rnextstate = Idle;
        end
      end
      Rd_addr: begin
        Rnextstate = Rd_data;
      end
      Rd_data: begin
        if(s_rready) begin //data_read_ready
          Rnextstate = Idle;
        end else begin
          Rnextstate = Rd_data;
        end
      end
      default: begin
        Rnextstate = 'bx;
      end
    endcase
  end
  
  always@(posedge clk or posedge rst)
  if(rst) begin
    s_arready<=0;
    s_rvalid<=0;
    s_rresp<=2'b0;
    Eecd_rdata_reg<=32'h00000110;
    s_araddr_reg<=0;
  end else begin
    case(Rnextstate)
      Idle: begin
        s_arready<=0;
        s_rvalid<=0;
      end
      Rd_addr: begin
        s_arready<=1;
        s_araddr_reg<=s_araddr;
      end
      Rd_data: begin
        s_arready<=0;
        s_rvalid<=1;
        if(s_araddr_reg==Eecd)begin
          s_rdata<={Eecd_rdata_reg[31:8], !eerd_busy, Eecd_rdata_reg[6:0]};
        end else begin
          s_rdata<=rdatai;
        end
      end     
      default: begin
        Rnextstate = 'bx;
      end
    endcase
  end
  

endmodule


/*


  assign sk=eerd_busy?sk_eerd:sk_eecd;
  assign cs=eerd_busy?cs_eerd:cs_eecd;
  assign di=eerd_busy?di_eerd:di_eecd;

*/


