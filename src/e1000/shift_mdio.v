`timescale 1ns/1ns
module shift_mdio #(
  parameter div=16
)(
  input             clk      ,
  input             rst      ,
  //mdio
  output reg        mdc_o    ,
  input             mdio_i   ,
  output reg        mdio_o   ,
  output reg        mdio_oe  ,
  //
  output reg [15:0] rdatao   ,
  output reg        rd_doneo ,

  input             eni      ,
  input      [31:0] wdatai   ,
  output reg        wr_doneo

);

  reg [31:0] num;

  always@(posedge clk or posedge rst)
  if(rst) begin
    num<=0;
    mdc_o<=0;
  end else if(num==div/2-1)begin
    num<=num+'d1;
    mdc_o<=1;
  end else if(num<div-1)begin
    num<=num+'d1;
  end else begin
    num<=0;
    mdc_o<=0;
  end

  reg [7:0] State, Nextstate;
  parameter Idle        = 8'h01,
            Rd_fifo     = 8'h02,
            Shift_reg   = 8'h04,
            Done        = 8'h08;

  reg [ 7:0] cnt;
  reg [15:0] fifo_wr_reg;
  reg [31:0] dreg;
  reg [63:0] sreg;

  always@(posedge clk or posedge rst)
  if(rst) begin
    State<=Idle;
  end else begin
    State<=Nextstate;
  end

  always@(*) begin
    case(State)
      Idle: begin
        if(eni) begin
          Nextstate = Rd_fifo;
        end else begin
          Nextstate = Idle;
        end
      end

      Rd_fifo: begin
        Nextstate = Shift_reg;
      end

      Shift_reg: begin
        if(dreg[29:28]==2'b10 && cnt==64 && num==0) begin
          Nextstate = Done;
        end else if(dreg[29:28]==2'b01 && cnt==64 && num==0) begin
          Nextstate = Done;
        end else begin
          Nextstate = Shift_reg;
        end
      end

      Done: begin
        Nextstate = Idle;
      end

      default: begin
        Nextstate = 'bx;
      end

    endcase

  end

  always@(posedge clk or posedge rst)
  if(rst) begin
    cnt<=0;
    fifo_wr_reg<=0;
    rdatao<=0;
    rd_doneo<=1;
    wr_doneo<=1;
    mdio_o<=0;
    mdio_oe<=0;
    dreg<=0;
    sreg<=0;
  end else begin
    case(Nextstate)

      Idle: begin
        cnt<=0;
        mdio_o<=1;
        mdio_oe<=1;
      end

      Rd_fifo: begin
        dreg<=wdatai;
        sreg<={32'hffffffff, wdatai};
        if(wdatai[29:28]==2'b10) begin
          rd_doneo<=0;
        end else begin
          wr_doneo<=0;
        end
      end

      Shift_reg: begin

        if(cnt<64 && num==0) begin
          cnt<=cnt+'d1;
        end

        if(dreg[29:28]==2'b10 && cnt>46 && num==0)begin
          mdio_oe<=0;
          fifo_wr_reg<={fifo_wr_reg[14:0], mdio_i};
        end else if(num==0)begin
          mdio_oe<=1;
          mdio_o<=sreg[63];
          sreg<={sreg[62:0],1'b1};
        end
      end

      Done: begin
        rdatao<=fifo_wr_reg;
        if(dreg[29:28]==2'b10) begin
          rd_doneo<=1;
        end else begin
          wr_doneo<=1;
        end
      end

    endcase
  end

endmodule
