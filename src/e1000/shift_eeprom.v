`timescale 1ns/1ns
module shift_eeprom #(
  parameter div=16
)(
  input             clk      ,
  input             rst      ,
  //eeprom
  output            sk        ,
  output            cs        ,
  output            di        ,
  input             do        ,
  
  //
  input      [31:0] wdatai          ,
  input             eni             ,
  output reg        eerd_busy       ,
  
  input             sk_eecd         ,
  input             cs_eecd         ,
  input             di_eecd         ,
  input             eecd_busy       ,

  output     [31:0] rdatao

);

  reg        sk_eerd, cs_eerd, di_eerd;
  reg [31:0] num;
  
  always@(posedge clk or posedge rst)
  if(rst) begin
    num<=0;
    sk_eerd<=0;
  end else if(num==div/2-1)begin
    num<=num+'d1;
    sk_eerd<=1;
  end else if(num<div-1)begin
    num<=num+'d1;
  end else begin
    num<=0;
    sk_eerd<=0;
  end

  reg [7:0] State, Nextstate;
  parameter Idle        = 8'h01,
            Rd_eecd    = 8'h02,
            Reg_eerd  = 8'h10,
            Rd_eerd   = 8'h04,
            Done        = 8'h08;
  reg        eerd_en;
  reg [ 7:0] cnt, addr;
  reg [15:0] shift_wr_reg, rdata_reg;
  reg [26:0] sreg;

  always@(posedge clk or posedge rst)
  if(rst) begin
    State<=Idle;
  end else begin
    State<=Nextstate;
  end

  always@(*) begin
    case(State)
      Idle: begin
        if(eni)begin
          Nextstate = Reg_eerd;
        end else if(eecd_busy) begin
          Nextstate = Rd_eecd;
        end else begin
          Nextstate = Idle;
        end
      end

      Rd_eecd: begin
        if(!eecd_busy)begin
          Nextstate = Idle;
        end else begin
          Nextstate = Rd_eecd;
        end
      end
      
      Reg_eerd: begin
        Nextstate = Rd_eerd;
      end
      
      Rd_eerd: begin
        if(cnt==29 && num==0)begin
          Nextstate = Idle;
        end else begin
          Nextstate = Rd_eerd;
        end
      end

      default: begin
        Nextstate = 'bx;
      end

    endcase

  end
  
  always@(posedge clk or posedge rst)
  if(rst) begin
    cnt<=0;
    eerd_busy<=0;
    di_eerd<=0;
    cs_eerd<=0;
    sreg<=0;
    addr<=0;
    shift_wr_reg<=0;
    rdata_reg<=0;
    eerd_en<=0;
  end else begin
    case(Nextstate)

      Idle: begin
        eerd_busy<=0;
        di_eerd<=0;
        cs_eerd<=0;
      end

      Rd_eecd: begin
      end
      
      Reg_eerd:begin
        eerd_busy<=1;
        sreg<={3'b110, wdatai[15:8], 16'd0};
        addr<=wdatai[15:8];
        shift_wr_reg<=0;
        cnt<=0;
      end
      
      Rd_eerd: begin
        if(cnt<29 && num==0) begin
          cnt<=cnt+'d1;
        end

        if(cnt==28 && num==0)begin
          eerd_en<=0;
          cs_eerd<=0;
        end else if(num==0)begin
          eerd_en<=1;
          di_eerd<=sreg[26];
          cs_eerd<=1;
          sreg<={sreg[25:0],1'b0};
        end
        
        if(cnt==28 && num==0)begin
          rdata_reg<=shift_wr_reg;
        end else if(num==0) begin
          shift_wr_reg<={shift_wr_reg[14:0], do};
        end
      end

    endcase
  end
  
  assign rdatao = {rdata_reg, addr, 3'b0, !eerd_busy, 4'b0};
  
  assign sk=eerd_en?sk_eerd:sk_eecd;
  assign cs=eerd_en?cs_eerd:cs_eecd;
  assign di=eerd_en?di_eerd:di_eecd;

endmodule
