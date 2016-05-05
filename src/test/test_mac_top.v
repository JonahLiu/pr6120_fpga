`timescale 1ns/1ps
module test_mac_top(
);
//******************************************************************************
//internal signals                                                              
//******************************************************************************
				//system signals
reg				Reset					;
reg				Clk_125M				;
reg				Clk_user				;
reg				Clk_25m					;//used for 100 Mbps mode
reg				Clk_2_5m				;//used for 10 Mbps mode
reg				Clk_reg					;
				//user interface 
wire			Rx_mac_ra				;
reg				Rx_mac_rd				;
wire	[31:0]	Rx_mac_data				;
wire	[1:0]	Rx_mac_BE				;
wire			Rx_mac_pa				;
wire			Rx_mac_sop				;
wire			Rx_mac_eop				;
				//user interface 
wire			Tx_mac_wa	        	;
reg				Tx_mac_wr	        	;
reg		[31:0]	Tx_mac_data	        	;
reg		[1:0]	Tx_mac_BE				;//big endian
reg				Tx_mac_sop	        	;
reg				Tx_mac_eop				;
				//pkg_lgth fifo
wire			Pkg_lgth_fifo_rd		;
wire			Pkg_lgth_fifo_ra		;
wire	[15:0]	Pkg_lgth_fifo_data		;
				//Phy interface     	 
				//Phy interface			
wire			Gtx_clk					;//used only in GMII mode
wire			Rx_clk					;
wire			Tx_clk					;//used only in MII mode
wire			Tx_er					;
wire			Tx_en					;
wire	[7:0]	Txd						;
wire			Rx_er					;
wire			Rx_dv					;
wire 	[7:0]	Rxd						;
wire			Crs						;
wire			Col						;
wire            CSB                     ;
wire            WRB                     ;
wire    [15:0]  CD_in                   ;
wire    [15:0]  CD_out                  ;
wire    [7:0]   CA                      ;				
				//Phy int host interface     
wire			Line_loop_en			;
wire	[2:0]	Speed					;
				//mii
wire         	Mdo	                	;// MII Management Data Out
wire         	MdoEn                	;// MII Management Data OE
wire         	Mdi	                	;// MII Management Data In
wire        	Mdc                		;// MII Management Data Clock	
wire            CPU_init_end            ;
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
	#5		Clk_user=0;
	#5		Clk_user=1;
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
	
always 
	begin
	#10		Clk_reg=0;
	#10		Clk_reg=1;
	end


initial	
	begin
	$dumpfile("test_mac_top.vcd");
	$dumpvars(1);
	//#100_000;
	//$finish();
	end


assign CSB = 1'b1;
assign WRB = 1'b1;

MAC_top U_MAC_top(
 //system signals     			(//system signals           ),
.Reset					        (Reset					    ),
.Clk_125M				        (Clk_125M				    ),
.Clk_user				        (Clk_user				    ),
.Clk_reg					    (Clk_reg					),
.Speed                          (Speed                      ),
 //user interface               (//user interface           ),
.Rx_mac_ra				        (Rx_mac_ra				    ),
.Rx_mac_rd				        (Rx_mac_rd				    ),
.Rx_mac_data				    (Rx_mac_data				),
.Rx_mac_BE				        (Rx_mac_BE				    ),
.Rx_mac_pa				        (Rx_mac_pa				    ),
.Rx_mac_sop				        (Rx_mac_sop				    ),
.Rx_mac_eop				        (Rx_mac_eop				    ),
 //user interface               (//user interface           ),
.Tx_mac_wa	        	        (Tx_mac_wa	        	    ),
.Tx_mac_wr	        	        (Tx_mac_wr	        	    ),
.Tx_mac_data	        	    (Tx_mac_data	        	),
.Tx_mac_BE				        (Tx_mac_BE				    ),
.Tx_mac_sop	        	        (Tx_mac_sop	        	    ),
.Tx_mac_eop				        (Tx_mac_eop				    ),
 //pkg_lgth fifo
.Pkg_lgth_fifo_rd				(Pkg_lgth_fifo_rd			),
.Pkg_lgth_fifo_ra				(Pkg_lgth_fifo_ra			),
.Pkg_lgth_fifo_data				(Pkg_lgth_fifo_data			),
 //Phy interface     	        (//Phy interface     	    ),
 //Phy interface			    (//Phy interface			),
.Gtx_clk					    (Gtx_clk					),
.Rx_clk					        (Rx_clk					    ),
.Tx_clk					        (Tx_clk					    ),
.Tx_er					        (Tx_er					    ),
.Tx_en					        (Tx_en					    ),
.Txd						    (Txd						),
.Rx_er					        (Rx_er					    ),
.Rx_dv					        (Rx_dv					    ),
.Rxd						    (Rxd						),
.Crs						    (Crs						),
.Col						    (Col						),
//host interface
.CSB                            (CSB                        ),
.WRB                            (WRB                        ),
.CD_in                          (CD_in                      ),
.CD_out                         (CD_out                     ),
.CA                             (CA                         ),
 //MII interface signals        (//MII interface signals    ),
.Mdo                	        (Mdo                	    ),
.MdoEn                	        (MdoEn                	    ),
.Mdi                	        (Mdi                	    ),
.Mdc                		    (Mdc                		)
);

assign 	Rx_clk=Speed[2]?Gtx_clk:Speed[1]?Clk_25m:Speed[0]?Clk_2_5m:0;        
assign 	Tx_clk=Speed[2]?Gtx_clk:Speed[1]?Clk_25m:Speed[0]?Clk_2_5m:0;
	
assign	Rx_dv	=Tx_en	;
assign	Rxd		=Txd	;
assign	Rx_er	=0		;
assign	Crs    	=Tx_en	;
assign  Col		=0		;

/*
Phy_sim U_Phy_sim (
.Gtx_clk						(Gtx_clk		         	),
.Rx_clk		                    (Rx_clk		                ),
.Tx_clk		                    (Tx_clk		                ),
.Tx_er		                    (Tx_er		                ),
.Tx_en		                    (Tx_en		                ),
.Txd			                (Txd			            ),
.Rx_er		                    (Rx_er		                ),
.Rx_dv		                    (Rx_dv		                ),
.Rxd			                (Rxd			            ),
.Crs			                (Crs			            ),
.Col			                (Col			            ),
.Speed		                    (Speed		                )
);

User_int_sim U_User_int_sim( 
.Reset							(Reset						),
.Clk_user			            (Clk_user			        ),
.CPU_init_end                   (CPU_init_end               ),
 //user inputerface             (//user inputerface         ),
.Rx_mac_ra			            (Rx_mac_ra			        ),
.Rx_mac_rd			            (Rx_mac_rd			        ),
.Rx_mac_data			        (Rx_mac_data			    ),
.Rx_mac_BE			            (Rx_mac_BE			        ),
.Rx_mac_pa			            (Rx_mac_pa			        ),
.Rx_mac_sop			            (Rx_mac_sop			        ),
.Rx_mac_eop			            (Rx_mac_eop			        ),
 //user inputerface             (//user inputerface         ),
.Tx_mac_wa	                    (Tx_mac_wa	                ),
.Tx_mac_wr	                    (Tx_mac_wr	                ),
.Tx_mac_data	                (Tx_mac_data	            ),
.Tx_mac_BE			            (Tx_mac_BE			        ),
.Tx_mac_sop	                    (Tx_mac_sop	                ),
.Tx_mac_eop			            (Tx_mac_eop			        )
);

host_sim U_host_sim(
.Reset	               			(Reset	                  	),    
.Clk_reg                  		(Clk_reg                 	), 
.CSB                            (CSB                        ),
.WRB                            (WRB                        ),
.CD_in                          (CD_in                      ),
.CD_out                         (CD_out                     ),
.CPU_init_end                   (CPU_init_end               ),
.CA                             (CA                         )
);
*/

task generate_packet(input integer length);
	integer i;
	begin
		i=0;
		while(i<length) begin
			@(posedge Clk_user);
			if(Tx_mac_wa) begin
				Tx_mac_wr <= 1'b1;
				Tx_mac_data[31:24] <= i;
				Tx_mac_data[23:16] <= i+1;
				Tx_mac_data[15:8] <= i+2;
				Tx_mac_data[7:0] <= i+3;

				if(i==0)
					Tx_mac_sop <= 1;
				else
					Tx_mac_sop <= 0;

				if(i+4 >= length)
					Tx_mac_eop <= 1;
				else
					Tx_mac_eop <= 0;

				if(i+4 >= length && length-i-1<3)
					Tx_mac_BE <= (length-i); 
				else
					Tx_mac_BE <= 0;

				i = i+4;
			end
			else begin
				Tx_mac_wr <= 1'b0;
			end
		end
		@(posedge Clk_user);
		Tx_mac_wr <= 1'b0;
		Tx_mac_sop <= 1'b0;
		Tx_mac_eop <= 1'b0;
		Tx_mac_data <= 'b0;
		Tx_mac_BE <= 'b0;
	end
endtask

initial
begin
	Tx_mac_wr <= 0;
	Tx_mac_data <= 0;
	Tx_mac_BE <= 0;
	Tx_mac_sop <= 0;
	Tx_mac_eop <= 0;

	#1000;
	generate_packet(12);
	generate_packet(13);
	generate_packet(60);
	generate_packet(1500);
	generate_packet(9996); // 9996+4(FCS) = 10000
	//generate_packet(16380); // 16380+4(FCS) = 16384

	#1000000;
	$finish();
end

always @(posedge Clk_user, posedge Reset)
begin
	if(Reset)
		Rx_mac_rd <= 1'b0;
	else if(!Rx_mac_rd && Rx_mac_ra)
		Rx_mac_rd <= 1'b1;
	else if(Rx_mac_pa && Rx_mac_eop)
		Rx_mac_rd <= 1'b0;
end

assign Pkg_lgth_fifo_rd = Pkg_lgth_fifo_ra;

endmodule
