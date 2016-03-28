`timescale 1ns/1ns
module axi4_mdio(
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
  //mdiofifo
  output reg [31:0] wdatao          ,
  output reg        eno             ,
  input             wr_donei        ,

  input      [15:0] rdatai          ,
  input             rd_donei        ,
  output reg        interrupt
);

  reg [7:0] Wstate, Wnextstate;
  reg [7:0] Rstate, Rnextstate;
  parameter Idle        = 8'h01,
            Wr_addr     = 8'h02,
            Wr_data     = 8'h04,
            Wr_response = 8'h08,
            Mdio_wr     = 8'h10,
            Mdio_rd     = 8'h20,
            Rd_addr     = 8'h40,
            Rd_data     = 8'h80;

  reg [31:0] wdata_reg, rdata_reg;

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
        if(s_wvalid && s_wdata[27:26]==2'b01) begin //data_write_valid
          Wnextstate = Mdio_wr;
        end else if(s_wvalid) begin //data_write_valid
          Wnextstate = Mdio_rd;
        end else begin
          Wnextstate = Wr_data;
        end
      end
      Mdio_wr: begin
        Wnextstate = Wr_response;
      end
      Mdio_rd: begin
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
    eno<=0;
    rdata_reg<=0;
  end else begin
    case(Wnextstate)
      Idle: begin
        s_awready<=0;
        s_wready<=0;
        s_bvalid<=0;
        eno<=0;
      end
      Wr_addr: begin //ready_write_addr //Rwaddr
        s_awready<=1;
      end
      Wr_data: begin
        s_awready<=0;
        s_wready<=1;
        wdata_reg<=s_wdata;
      end
      Mdio_wr: begin
        s_wready<=0;
        //
        wdatao<={4'b0101, wdata_reg[25:16], 2'b10, wdata_reg[15:0]};
        eno<=1;
      end
      Mdio_rd: begin
        s_wready<=0;
        //
        rdata_reg<=wdata_reg;
        wdatao<={4'b0110, wdata_reg[25:16], 2'b10, wdata_reg[15:0]};
        eno<=1;
      end
      Wr_response: begin
        s_wready<=0;
        s_bvalid<=1;
        //wr_donei
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
  end else begin
    case(Rnextstate)
      Idle: begin
        s_arready<=0;
        s_rvalid<=0;
      end
      Rd_addr: begin
        s_arready<=1;
      end
      Rd_data: begin
        s_arready<=0;
        s_rvalid<=1;
      end     
      default: begin
        Rnextstate = 'bx;
      end
    endcase
  end
  //interrupt
  always@(posedge clk or posedge rst)
  if(rst)begin
    interrupt<=1;
    s_rdata<=0;
  end else begin
    interrupt<=rdata_reg[29];
    s_rdata<={2'b00, rdata_reg[29], (rd_donei && wr_donei), rdata_reg[27:16], rdatai};
  end


endmodule