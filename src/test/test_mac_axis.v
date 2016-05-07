`timescale 1ns/1ps
module test_mac_axis;
//******************************************************************************
//internal signals                                                              
//******************************************************************************
				//system signals
reg				Reset					;
reg				aclk				;
reg				Clk_125M				;
reg				Clk_25m					;//used for 100 Mbps mode
reg				Clk_2_5m				;//used for 10 Mbps mode

reg    	[2:0]   Speed                   ;
reg    			RX_APPEND_CRC			;       
reg    			CRC_chk_en				;       
reg    	[5:0]	RX_IFG_SET	  			;       
reg    	[15:0]	RX_MAX_LENGTH 			;
reg    	[6:0]	RX_MIN_LENGTH			;
reg    			pause_frame_send_en		;       
reg    	[15:0]	pause_quanta_set		;       
reg    			xoff_cpu	        	;       
reg    			xon_cpu	            	;       
reg    			FullDuplex         		;       
reg    	[3:0]	MaxRetry	        	;       
reg    	[5:0]	IFGset					;       
reg    			tx_pause_en				;       
reg    			Line_loop_en			;

				//Rx user interface 
wire	[31:0]	rx_mac_tdata			;
wire	[3:0]	rx_mac_tkeep			;
wire 	[15:0]  rx_mac_tuser			; // packet length
wire			rx_mac_tlast			;
wire			rx_mac_tvalid			;
wire			rx_mac_tready			;

                //Tx user interface 
reg    	[31:0]	tx_mac_tdata			;
reg    	[3:0]	tx_mac_tkeep			;
reg    			tx_mac_tlast			;
reg    			tx_mac_tvalid			;
wire			tx_mac_tready			;

				//Phy interface			
wire			u1_Gtx_clk					;//used only in GMII mode
wire			u1_Tx_clk					;//used only in MII mode
wire			u1_Tx_er					;
wire			u1_Tx_en					;
wire	[7:0]	u1_Txd						;

wire			u1_Rx_clk					;
wire			u1_Rx_er					;
wire			u1_Rx_dv					;
wire 	[7:0]	u1_Rxd						;
wire			u1_Crs						;
wire			u1_Col						;

				//Phy interface			
wire			u2_Gtx_clk					;//used only in GMII mode
wire			u2_Tx_clk					;//used only in MII mode
wire			u2_Tx_er					;
wire			u2_Tx_en					;
wire	[7:0]	u2_Txd						;

wire			u2_Rx_clk					;
wire			u2_Rx_er					;
wire			u2_Rx_dv					;
wire 	[7:0]	u2_Rxd						;
wire			u2_Crs						;
wire			u2_Col						;
//******************************************************************************
//internal signals                                                              
//******************************************************************************

initial 
	begin
			Reset	=1;
	#20		Reset	=0;
	end

always 
	begin
	#4		Clk_125M=0;
	#4		Clk_125M=1;
	end

always 
	begin
	#3		aclk=0;
	#3		aclk=1;
	end

always 
	begin
	#20		Clk_25m=0;
	#20		Clk_25m=1;
	end
	
always  
	begin
	#200	Clk_2_5m=0;
	#200	Clk_2_5m=1;
	end   

initial	
	begin
	$dumpfile("test_mac_axis.vcd");
	$dumpvars(0);
	//#100_000;
	//$finish();
	end

mac_axis dut_1_i(
 //system signals     			(//system signals           ),
.Clk_125M				        (Clk_125M				    ),
.aresetn				        (!Reset						),
.aclk							(aclk),

.Speed                          (Speed                      ),
.RX_APPEND_CRC					(RX_APPEND_CRC				),       
.CRC_chk_en						(CRC_chk_en					),       
.RX_IFG_SET	  					(RX_IFG_SET	  				),       
.RX_MAX_LENGTH 					(RX_MAX_LENGTH 				),
.RX_MIN_LENGTH					(RX_MIN_LENGTH				),
.pause_frame_send_en			(pause_frame_send_en		),       
.pause_quanta_set				(pause_quanta_set			),       
.xoff_cpu	        			(xoff_cpu	        		),       
.xon_cpu	            		(xon_cpu	            	),       
.FullDuplex         			(FullDuplex         		),       
.MaxRetry	        			(MaxRetry	        		),       
.IFGset							(IFGset						),       
.tx_pause_en					(tx_pause_en				),       
.Line_loop_en					(Line_loop_en				),

 //user interface               (//user interface           ),
 .rx_mac_tdata					(),
 .rx_mac_tkeep					(),
 .rx_mac_tuser					(),
 .rx_mac_tlast					(),
 .rx_mac_tvalid					(),
 .rx_mac_tready					(1'b1),

 .tx_mac_tdata					(tx_mac_tdata				),
 .tx_mac_tkeep					(tx_mac_tkeep				),
 .tx_mac_tlast					(tx_mac_tlast				),
 .tx_mac_tvalid					(tx_mac_tvalid				),
 .tx_mac_tready					(tx_mac_tready				),
 
 //Phy interface			    (//Phy interface			),
.Gtx_clk					    (u1_Gtx_clk					),
.Rx_clk					        (u1_Rx_clk					    ),
.Tx_clk					        (u1_Tx_clk					    ),
.Tx_er					        (u1_Tx_er					    ),
.Tx_en					        (u1_Tx_en					    ),
.Txd						    (u1_Txd						),
.Rx_er					        (u1_Rx_er					    ),
.Rx_dv					        (u1_Rx_dv					    ),
.Rxd						    (u1_Rxd						),
.Crs						    (u1_Crs						),
.Col						    (u1_Col						)
);

mac_axis dut_2_i(
 //system signals     			(//system signals           ),
.Clk_125M				        (Clk_125M				    ),
.aresetn				        (!Reset						),
.aclk							(aclk),

.Speed                          (Speed                      ),
.RX_APPEND_CRC					(RX_APPEND_CRC				),       
.CRC_chk_en						(CRC_chk_en					),       
.RX_IFG_SET	  					(RX_IFG_SET	  				),       
.RX_MAX_LENGTH 					(RX_MAX_LENGTH 				),
.RX_MIN_LENGTH					(RX_MIN_LENGTH				),
.pause_frame_send_en			(pause_frame_send_en		),       
.pause_quanta_set				(pause_quanta_set			),       
.xoff_cpu	        			(xoff_cpu	        		),       
.xon_cpu	            		(xon_cpu	            	),       
.FullDuplex         			(FullDuplex         		),       
.MaxRetry	        			(MaxRetry	        		),       
.IFGset							(IFGset						),       
.tx_pause_en					(tx_pause_en				),       
.Line_loop_en					(Line_loop_en				),

 //user interface               (//user interface           ),
 .rx_mac_tdata					(rx_mac_tdata				),
 .rx_mac_tkeep					(rx_mac_tkeep				),
 .rx_mac_tuser					(rx_mac_tuser				),
 .rx_mac_tlast					(rx_mac_tlast				),
 .rx_mac_tvalid					(rx_mac_tvalid				),
 .rx_mac_tready					(rx_mac_tready				),

 .tx_mac_tdata					('b0),
 .tx_mac_tkeep					('b0),
 .tx_mac_tlast					('b0),
 .tx_mac_tvalid					(1'b0),
 .tx_mac_tready					(),
 
 //Phy interface			    (//Phy interface			),
.Gtx_clk					    (u2_Gtx_clk),
.Rx_clk					        (u2_Rx_clk					    ),
.Tx_clk					        (u2_Tx_clk					    ),
.Tx_er					        (u2_Tx_er					    ),
.Tx_en					        (u2_Tx_en					    ),
.Txd						    (u2_Txd						),
.Rx_er					        (u2_Rx_er					    ),
.Rx_dv					        (u2_Rx_dv					    ),
.Rxd						    (u2_Rxd						),
.Crs						    (u2_Crs						),
.Col						    (u2_Col						)
);
	
assign 	u1_Tx_clk	=	Speed[2]?u2_Gtx_clk:Speed[1]?Clk_25m:Speed[0]?Clk_2_5m:0;
assign 	u1_Rx_clk	=	Speed[2]?u2_Gtx_clk:Speed[1]?Clk_25m:Speed[0]?Clk_2_5m:0;        
assign	u1_Rx_dv	=	u2_Tx_en	;
assign	u1_Rxd		=	u2_Txd		;
assign	u1_Rx_er	=	u2_Tx_er	;
assign	u1_Crs    	=	u2_Tx_en	;
assign  u1_Col		=	0			;

assign 	u2_Tx_clk	=	Speed[2]?u1_Gtx_clk:Speed[1]?Clk_25m:Speed[0]?Clk_2_5m:0;
assign 	u2_Rx_clk	=	Speed[2]?u1_Gtx_clk:Speed[1]?Clk_25m:Speed[0]?Clk_2_5m:0;        
assign	u2_Rx_dv	=	u1_Tx_en	;
assign	u2_Rxd		=	u1_Txd		;
assign	u2_Rx_er	=	u1_Tx_er	;
assign	u2_Crs    	=	u1_Tx_en	;
assign  u2_Col		=	0			;

task generate_packet(input integer length);
	integer i;
	begin
		i=0;
		while(i<length) begin
			tx_mac_tvalid <= 1'b1;
			tx_mac_tdata <= i;
			/*
			tx_mac_tdata[31:24] <= i;
			tx_mac_tdata[23:16] <= i+1;
			tx_mac_tdata[15:8] <= i+2;
			tx_mac_tdata[7:0] <= i+3;
			*/

			if(i+4 >= length)
				tx_mac_tlast <= 1;
			else
				tx_mac_tlast <= 0;

			if(i+4 >= length && length-i-1<3)
				tx_mac_tkeep <= (4'b1110 << (3-(length-i))); 
			else
				tx_mac_tkeep <= 4'b1111;

			i <= i+4;

			@(posedge aclk);
			while(!tx_mac_tready) @(posedge aclk);
		end
		tx_mac_tvalid <= 1'b0;
		tx_mac_tkeep <= 'b0;
		tx_mac_tlast <= 1'b0;
		tx_mac_tdata <= 'b0;
	end
endtask

initial
begin
	tx_mac_tvalid <= 0;
	tx_mac_tdata <= 0;
	tx_mac_tkeep <= 0;
	tx_mac_tlast <= 0;

	Speed <= 3'b100;
	RX_APPEND_CRC <= 1'b0;
	CRC_chk_en <= 1'b1;
	RX_IFG_SET <= 16'h000c;
	RX_MAX_LENGTH <= 16'h4000;
	RX_MIN_LENGTH <= 16'h40;
	pause_frame_send_en <= 1'b0;
	pause_quanta_set <= 16'h0;
	xoff_cpu <= 1'b0;
	xon_cpu <= 1'b0;
	FullDuplex <= 1'b1;
	MaxRetry <= 16'h0002;
	IFGset <= 16'h000c;
	tx_pause_en <= 1'b0;
	Line_loop_en <= 1'b0;

	#1000;
	Speed <= 3'b100;
	FullDuplex <= 1'b1;
	generate_packet(60);
	#1000;

	Speed <= 3'b010;
	FullDuplex <= 1'b1;
	generate_packet(60);
	#10_000;
	Speed <= 3'b010;
	FullDuplex <= 1'b0;
	generate_packet(60);
	#10_000;

	Speed <= 3'b001;
	FullDuplex <= 1'b1;
	generate_packet(60);
	#100_000;
	Speed <= 3'b001;
	FullDuplex <= 1'b0;
	generate_packet(60);
	#100_000;

	Speed <= 3'b100;
	FullDuplex <= 1'b1;
	generate_packet(12);
	generate_packet(13);
	generate_packet(60);
	generate_packet(61);
	generate_packet(1500);
	generate_packet(9996); // 9996+4(FCS) = 10000
	generate_packet(13);
	//generate_packet(16380); // 16380+4(FCS) = 16384

	#1000000;
	$finish();
end

assign rx_mac_tready = 1'b1;
endmodule
