module mac_axis(
// system signals
input			Clk_125M				,
input			aresetn					,
input			aclk					,
// Options
input	[2:0]   Speed                   ,
input			RX_APPEND_CRC			,       
input			CRC_chk_en				,       
input	[5:0]	RX_IFG_SET	  			,       
input	[15:0]	RX_MAX_LENGTH 			,
input	[6:0]	RX_MIN_LENGTH			,
input			pause_frame_send_en		,       
input	[15:0]	pause_quanta_set		,       
input			xoff_cpu	        	,       
input			xon_cpu	            	,       
input			FullDuplex         		,       
input	[3:0]	MaxRetry	        	,       
input	[5:0]	IFGset					,       
input			tx_pause_en				,       
input			Line_loop_en			,

//Rx user interface 
output	[31:0]	rx_mac_tdata			,
output	[3:0]	rx_mac_tkeep			,
output  [15:0]  rx_mac_tuser			, // packet length
output			rx_mac_tlast			,
output			rx_mac_tvalid			,
input			rx_mac_tready			,

//Tx user interface 
input	[31:0]	tx_mac_tdata			,
input	[3:0]	tx_mac_tkeep			,
input			tx_mac_tlast			,
input			tx_mac_tvalid			,
output			tx_mac_tready			,

//Phy interface         
output          Gtx_clk                 ,//used only in GMII mode
input           Rx_clk                  ,
input           Tx_clk                  ,//used only in MII mode
output          Tx_er                   ,
output          Tx_en                   ,
output  [7:0]   Txd                     ,
input           Rx_er                   ,
input           Rx_dv                   ,
input   [7:0]   Rxd                     ,
input           Crs                     ,
input           Col                     
);                       

//******************************************************************************
//internal signals                                                              
//******************************************************************************
wire          Rx_mac_ra               ;
wire		  Rx_mac_rd               ;
wire  [31:0]  Rx_mac_data             ;
wire  [1:0]   Rx_mac_BE               ;
wire          Rx_mac_pa               ;
wire          Rx_mac_sop              ;
wire          Rx_mac_eop              ;
wire		   Tx_mac_wa               ;
wire           Tx_mac_wr               ;
wire   [31:0]  Tx_mac_data             ;
wire   [1:0]   Tx_mac_BE               ;//big endian
wire           Tx_mac_sop              ;
wire           Tx_mac_eop              ;

wire 			Pkg_lgth_fifo_rd        ;
wire          Pkg_lgth_fifo_ra        ;
wire  [15:0]  Pkg_lgth_fifo_data      ;

                //RMON interface
wire    [15:0]  Rx_pkt_length_rmon      ;
wire            Rx_apply_rmon           ;
wire    [2:0]   Rx_pkt_err_type_rmon    ;
wire    [2:0]   Rx_pkt_type_rmon        ;
wire    [2:0]   Tx_pkt_type_rmon        ;
wire    [15:0]  Tx_pkt_length_rmon      ;
wire            Tx_apply_rmon           ;
wire    [2:0]   Tx_pkt_err_type_rmon    ;
                //PHY interface
wire            MCrs_dv                 ;       
wire    [7:0]   MRxD                    ;       
wire            MRxErr                  ;       
                //flow_control signals  
wire    [15:0]  pause_quanta            ;   
wire            pause_quanta_val        ; 
                //PHY interface
wire    [7:0]   MTxD                    ;
wire            MTxEn                   ;   
wire            MCRS                    ;
                //interface clk signals
wire            MAC_tx_clk              ;
wire            MAC_rx_clk              ;
wire            MAC_tx_clk_div          ;
wire            MAC_rx_clk_div          ;
                //reg signals   
wire    [4:0]	Tx_Hwmark				;       
wire    [4:0]	Tx_Lwmark				;       
wire    		MAC_tx_add_en			;       
wire    [7:0]	MAC_tx_add_prom_data	;       
wire    [2:0]	MAC_tx_add_prom_add		;       
wire    		MAC_tx_add_prom_wr		;       
		        //Rx host interface 	 
wire    		MAC_rx_add_chk_en		;       
wire    [7:0]	MAC_rx_add_prom_data	;       
wire    [2:0]	MAC_rx_add_prom_add		;       
wire    		MAC_rx_add_prom_wr		;       
wire    		broadcast_filter_en	    ;       
wire    [4:0]	Rx_Hwmark			    ;           
wire    [4:0]	Rx_Lwmark			    ;           
		        		//RMON host interface    
/*
wire    [5:0]	CPU_rd_addr				;
wire    		CPU_rd_apply			;
wire    		CPU_rd_grant			;
wire    [31:0]	CPU_rd_dout				;
*/
		        		//Phy int host interface 
		        		//MII to CPU             
/*
wire    [7:0] 	Divider            		;
wire    [15:0] 	CtrlData           		;
wire    [4:0] 	Rgad               		;
wire    [4:0] 	Fiad               		;
wire           	NoPre              		;
wire           	WCtrlData          		;
wire           	RStat              		;
wire           	ScanStat           		;
wire         	Busy               		;
wire         	LinkFail           		;
wire         	Nvalid             		;
wire    [15:0] 	Prsd               		;
wire         	WCtrlDataStart     		;
wire         	RStatStart         		;
wire         	UpdateMIIRX_DATAReg		;
*/


wire    [15:0]  broadcast_bucket_depth              ;
wire    [15:0]  broadcast_bucket_interval           ;
wire            Pkg_lgth_fifo_empty;

reg             rx_pkg_lgth_fifo_wr_tmp;
reg             rx_pkg_lgth_fifo_wr_tmp_pl1;
reg             rx_pkg_lgth_fifo_wr;

reg	tx_flag;
reg [1:0] tx_be;
reg [3:0] rx_keep;
reg rx_rd;
reg rx_rd_lgth;

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn)
		tx_flag<= 1'b0;
	else if(!tx_flag && tx_mac_tvalid && tx_mac_tready)
		tx_flag <= 1'b1;
	else if(tx_flag && tx_mac_tvalid && tx_mac_tlast && tx_mac_tready)
		tx_flag <= 1'b0;
end

always @(*)
begin
	casex(tx_mac_tkeep)
		4'b1110: tx_be = 2'b11;
		4'b110x: tx_be = 2'b10;
		4'b10xx: tx_be = 2'b01;
		default: tx_be = 2'b00;
	endcase
end

always @(*)
begin
	case(Rx_mac_BE) /* synthesis full_case */
		2'b00: rx_keep = 4'b1111;
		2'b11: rx_keep = 4'b1110;
		2'b10: rx_keep = 4'b1100;
		2'b01: rx_keep = 4'b1000;
	endcase
end

always @(posedge aclk, negedge aresetn)
begin
	if(!aresetn) begin
		rx_rd <= 1'b0;
		rx_rd_lgth <= 1'b0;
	end
	else begin
		case({rx_rd_lgth, rx_rd})
			2'b00: begin
				if(Pkg_lgth_fifo_ra) begin
					rx_rd <= 1'b1;
				end
			end
			2'b01: begin
				if(Rx_mac_pa && Rx_mac_eop) begin
					rx_rd <= 1'b0;
					rx_rd_lgth <= 1'b1;
				end
			end
			2'b10: begin
				rx_rd_lgth <= 1'b0;
			end
		endcase
	end
end

assign Reset = !aresetn;
assign Clk_user = aclk;

assign Tx_mac_data = tx_mac_tdata;
assign Tx_mac_wr = tx_mac_tvalid&tx_mac_tready;
assign Tx_mac_sop = !tx_flag;
assign Tx_mac_eop = tx_mac_tlast;
assign Tx_mac_BE = tx_be;

assign tx_mac_tready = Tx_mac_wa;

assign Rx_mac_rd = rx_rd;

assign rx_mac_tdata = Rx_mac_data;
assign rx_mac_tvalid = Rx_mac_pa;
assign rx_mac_tlast = Rx_mac_eop;
assign rx_mac_tkeep = rx_keep;
assign rx_mac_tuser = Pkg_lgth_fifo_data;

assign Pkg_lgth_fifo_rd = rx_rd_lgth;

assign MAC_rx_add_chk_en = 1'b0;
assign MAC_rx_add_prom_data = 'b0;
assign MAC_rx_add_prom_add = 'b0;
assign MAC_rx_add_prom_wr = 1'b0;

assign broadcast_filter_en = 1'b0;
assign broadcast_bucket_depth = 'b0;
assign broadcast_bucket_interval = 'b0;

assign Rx_Hwmark = 5'h1a;
assign Rx_Lwmark = 5'h10;

assign Tx_Hwmark = 5'h1e;
assign Tx_Lwmark = 5'h19;

assign MAC_tx_add_en = 1'b0;

assign MAC_tx_add_prom_data = 'b0;
assign MAC_tx_add_prom_add = 'b0;
assign MAC_tx_add_prom_wr = 1'b0;

//******************************************************************************
// internal modules
//******************************************************************************
MAC_rx U_MAC_rx(
.Reset                      (Reset                      ),    
.Clk_user                   (Clk_user                   ), 
.Clk                        (MAC_rx_clk_div             ), 
 //RMII interface           (//PHY interface            ),  
.MCrs_dv                    (MCrs_dv                    ),        
.MRxD                       (MRxD                       ),
.MRxErr                     (MRxErr                     ),
 //flow_control signals     (//flow_control signals     ),  
.pause_quanta               (pause_quanta               ),
.pause_quanta_val           (pause_quanta_val           ),
 //user interface           (//user interface           ),  
.Rx_mac_ra                  (Rx_mac_ra                  ),
.Rx_mac_rd                  (Rx_mac_rd                  ),
.Rx_mac_data                (Rx_mac_data                ),       
.Rx_mac_BE                  (Rx_mac_BE                  ),
.Rx_mac_pa                  (Rx_mac_pa                  ),
.Rx_mac_sop                 (Rx_mac_sop                 ),
.Rx_mac_eop                 (Rx_mac_eop                 ),
 //CPU                      (//CPU                      ),  
.MAC_rx_add_chk_en          (MAC_rx_add_chk_en          ),
.MAC_add_prom_data          (MAC_rx_add_prom_data       ),
.MAC_add_prom_add           (MAC_rx_add_prom_add        ),
.MAC_add_prom_wr            (MAC_rx_add_prom_wr         ),       
.broadcast_filter_en        (broadcast_filter_en        ),       
.broadcast_bucket_depth     (broadcast_bucket_depth     ),           
.broadcast_bucket_interval  (broadcast_bucket_interval  ),
.RX_APPEND_CRC              (RX_APPEND_CRC              ), 
.Rx_Hwmark                  (Rx_Hwmark                  ),
.Rx_Lwmark                  (Rx_Lwmark                  ),
.CRC_chk_en                 (CRC_chk_en                 ),  
.RX_IFG_SET                 (RX_IFG_SET                 ),
.RX_MAX_LENGTH              (RX_MAX_LENGTH              ),
.RX_MIN_LENGTH              (RX_MIN_LENGTH              ),
 //RMON interface           (//RMON interface           ),  
.Rx_pkt_length_rmon         (Rx_pkt_length_rmon         ),
.Rx_apply_rmon              (Rx_apply_rmon              ),
.Rx_pkt_err_type_rmon       (Rx_pkt_err_type_rmon       ),
.Rx_pkt_type_rmon           (Rx_pkt_type_rmon           )
);

MAC_tx U_MAC_tx(
.Reset                      (Reset                      ),
.Clk                        (MAC_tx_clk_div             ),
.Clk_user                   (Clk_user                   ),
 //PHY interface            (//PHY interface            ),
.TxD                        (MTxD                       ),
.TxEn                       (MTxEn                      ),
.CRS                        (MCRS                       ),
 //RMON                     (//RMON                     ),
.Tx_pkt_type_rmon           (Tx_pkt_type_rmon           ),
.Tx_pkt_length_rmon         (Tx_pkt_length_rmon         ),
.Tx_apply_rmon              (Tx_apply_rmon              ),
.Tx_pkt_err_type_rmon       (Tx_pkt_err_type_rmon       ),
 //user interface           (//user interface           ),
.Tx_mac_wa                  (Tx_mac_wa                  ),
.Tx_mac_wr                  (Tx_mac_wr                  ),
.Tx_mac_data                (Tx_mac_data                ),
.Tx_mac_BE                  (Tx_mac_BE                  ),
.Tx_mac_sop                 (Tx_mac_sop                 ),
.Tx_mac_eop                 (Tx_mac_eop                 ),
 //host interface           (//host interface           ),
.Tx_Hwmark                  (Tx_Hwmark                  ),
.Tx_Lwmark                  (Tx_Lwmark                  ),
.pause_frame_send_en        (pause_frame_send_en        ),
.pause_quanta_set           (pause_quanta_set           ),
.MAC_tx_add_en              (MAC_tx_add_en              ),
.FullDuplex                 (FullDuplex                 ),
.MaxRetry                   (MaxRetry                   ),
.IFGset                     (IFGset                     ),
.MAC_add_prom_data          (MAC_tx_add_prom_data       ),
.MAC_add_prom_add           (MAC_tx_add_prom_add        ),
.MAC_add_prom_wr            (MAC_tx_add_prom_wr         ),
.tx_pause_en                (tx_pause_en                ),
.xoff_cpu                   (xoff_cpu                   ),
.xon_cpu                    (xon_cpu                    ),
 //MAC_rx_flow              (//MAC_rx_flow              ),
.pause_quanta               (pause_quanta               ),
.pause_quanta_val           (pause_quanta_val           )
);


assign Pkg_lgth_fifo_ra=!Pkg_lgth_fifo_empty;
always @ (posedge Reset or posedge MAC_rx_clk_div)
    if (Reset)
        rx_pkg_lgth_fifo_wr_tmp <=0;    
    else if(Rx_apply_rmon&&Rx_pkt_err_type_rmon==3'b100)
        rx_pkg_lgth_fifo_wr_tmp <=1;
    else
        rx_pkg_lgth_fifo_wr_tmp <=0;  

always @ (posedge Reset or posedge MAC_rx_clk_div)
    if (Reset)
        rx_pkg_lgth_fifo_wr_tmp_pl1 <=0;    
    else
        rx_pkg_lgth_fifo_wr_tmp_pl1 <=rx_pkg_lgth_fifo_wr_tmp;         

always @ (posedge Reset or posedge MAC_rx_clk_div)
    if (Reset)
        rx_pkg_lgth_fifo_wr <=0;    
    else if(rx_pkg_lgth_fifo_wr_tmp&!rx_pkg_lgth_fifo_wr_tmp_pl1)
        rx_pkg_lgth_fifo_wr <=1; 
    else
        rx_pkg_lgth_fifo_wr <=0; 

afifo #(.DATA_WIDTH(16),.ADDR_WIDTH(8)) U_rx_pkg_lgth_fifo (
.din                        (RX_APPEND_CRC?Rx_pkt_length_rmon:Rx_pkt_length_rmon-16'd4),
.wr_en                      (rx_pkg_lgth_fifo_wr        ),
.wr_clk                     (MAC_rx_clk_div             ),
.rd_en                      (Pkg_lgth_fifo_rd           ),
.rd_clk                     (Clk_user                   ),
.ainit                      (Reset                      ),
.dout                       (Pkg_lgth_fifo_data         ),
.full                       (                           ),
.almost_full                (                           ),
.empty                      (Pkg_lgth_fifo_empty        ),
.wr_count                   (                           ),
.rd_count                   (                           ),
.rd_ack                     (                           ),
.wr_ack                     (                           ));


/*
RMON U_RMON(
.Clk                        (Clk_reg                    ),
.Reset                      (Reset                      ),
 //Tx_RMON                  (//Tx_RMON                  ),
.Tx_pkt_type_rmon           (Tx_pkt_type_rmon           ),
.Tx_pkt_length_rmon         (Tx_pkt_length_rmon         ),
.Tx_apply_rmon              (Tx_apply_rmon              ),
.Tx_pkt_err_type_rmon       (Tx_pkt_err_type_rmon       ),
 //Tx_RMON                  (//Tx_RMON                  ),
.Rx_pkt_type_rmon           (Rx_pkt_type_rmon           ),
.Rx_pkt_length_rmon         (Rx_pkt_length_rmon         ),
.Rx_apply_rmon              (Rx_apply_rmon              ),
.Rx_pkt_err_type_rmon       (Rx_pkt_err_type_rmon       ),
 //CPU                      (//CPU                      ),
.CPU_rd_addr                (CPU_rd_addr                ),
.CPU_rd_apply               (CPU_rd_apply               ),
.CPU_rd_grant               (CPU_rd_grant               ),
.CPU_rd_dout                (CPU_rd_dout                )
);
*/

Phy_int U_Phy_int(
.Reset                      (Reset                      ),
.MAC_rx_clk                 (MAC_rx_clk                 ),
.MAC_tx_clk                 (MAC_tx_clk                 ),
 //Rx interface             (//Rx interface             ),
.MCrs_dv                    (MCrs_dv                    ),
.MRxD                       (MRxD                       ),
.MRxErr                     (MRxErr                     ),
 //Tx interface             (//Tx interface             ),
.MTxD                       (MTxD                       ),
.MTxEn                      (MTxEn                      ),
.MCRS                       (MCRS                       ),
 //Phy interface            (//Phy interface            ),
.Tx_er                      (Tx_er                      ),
.Tx_en                      (Tx_en                      ),
.Txd                        (Txd                        ),
.Rx_er                      (Rx_er                      ),
.Rx_dv                      (Rx_dv                      ),
.Rxd                        (Rxd                        ),
.Crs                        (Crs                        ),
.Col                        (Col                        ),
 //host interface           (//host interface           ),
.Line_loop_en               (Line_loop_en               ),
.Speed                      (Speed                      )
);

Clk_ctrl U_Clk_ctrl(
.Reset                      (Reset                      ),
.Clk_125M                   (Clk_125M                   ),
 //host interface           (//host interface           ),
.Speed                      (Speed                      ),
 //Phy interface            (//Phy interface            ),
.Gtx_clk                    (Gtx_clk                    ),
.Rx_clk                     (Rx_clk                     ),
.Tx_clk                     (Tx_clk                     ),
 //interface clk            (//interface clk            ),
.MAC_tx_clk                 (MAC_tx_clk                 ),
.MAC_rx_clk                 (MAC_rx_clk                 ),
.MAC_tx_clk_div             (MAC_tx_clk_div             ),
.MAC_rx_clk_div             (MAC_rx_clk_div             )
);
/*
eth_miim U_eth_miim(                                        
.Clk                        (Clk_reg                    ),  
.Reset                      (Reset                      ),  
.Divider                    (Divider                    ),  
.NoPre                      (NoPre                      ),  
.CtrlData                   (CtrlData                   ),  
.Rgad                       (Rgad                       ),  
.Fiad                       (Fiad                       ),  
.WCtrlData                  (WCtrlData                  ),  
.RStat                      (RStat                      ),  
.ScanStat                   (ScanStat                   ),  
.Mdo                        (Mdo                        ),
.MdoEn                      (MdoEn                      ),
.Mdi                        (Mdi                        ),
.Mdc                        (Mdc                        ),  
.Busy                       (Busy                       ),  
.Prsd                       (Prsd                       ),  
.LinkFail                   (LinkFail                   ),  
.Nvalid                     (Nvalid                     ),  
.WCtrlDataStart             (WCtrlDataStart             ),  
.RStatStart                 (RStatStart                 ),  
.UpdateMIIRX_DATAReg        (UpdateMIIRX_DATAReg        )); 

Reg_int U_Reg_int(
.Reset	               		(Reset	                  	),    
.Clk_reg                  	(Clk_reg                 	), 
.CSB                        (CSB                        ),
.WRB                        (WRB                        ),
.CD_in                      (CD_in                      ),
.CD_out                     (CD_out                     ),
.CA                         (CA                         ),
 //Tx host interface        (//Tx host interface        ),
.Tx_Hwmark				    (Tx_Hwmark				    ),
.Tx_Lwmark				    (Tx_Lwmark				    ),
.pause_frame_send_en		(pause_frame_send_en		),
.pause_quanta_set		    (pause_quanta_set		    ),
.MAC_tx_add_en			    (MAC_tx_add_en			    ),
.FullDuplex         		(FullDuplex         		),
.MaxRetry	        	    (MaxRetry	        	    ),
.IFGset					    (IFGset					    ),
.MAC_tx_add_prom_data	    (MAC_tx_add_prom_data	    ),
.MAC_tx_add_prom_add		(MAC_tx_add_prom_add		),
.MAC_tx_add_prom_wr		    (MAC_tx_add_prom_wr		    ),
.tx_pause_en				(tx_pause_en				),
.xoff_cpu	        	    (xoff_cpu	        	    ),
.xon_cpu	            	(xon_cpu	            	),
 //Rx host interface 	    (//Rx host interface 	    ),
.MAC_rx_add_chk_en		    (MAC_rx_add_chk_en		    ),
.MAC_rx_add_prom_data	    (MAC_rx_add_prom_data	    ),
.MAC_rx_add_prom_add		(MAC_rx_add_prom_add		),
.MAC_rx_add_prom_wr		    (MAC_rx_add_prom_wr		    ),
.broadcast_filter_en	    (broadcast_filter_en	    ),
.broadcast_bucket_depth     (broadcast_bucket_depth     ),           
.broadcast_bucket_interval  (broadcast_bucket_interval  ),
.RX_APPEND_CRC			    (RX_APPEND_CRC			    ), 
.Rx_Hwmark       			(Rx_Hwmark					),
.Rx_Lwmark                  (Rx_Lwmark                  ),
.CRC_chk_en				    (CRC_chk_en				    ),
.RX_IFG_SET	  			    (RX_IFG_SET	  			    ),
.RX_MAX_LENGTH 			    (RX_MAX_LENGTH 			    ),
.RX_MIN_LENGTH			    (RX_MIN_LENGTH			    ),
 //RMON host interface      (//RMON host interface      ),
.CPU_rd_addr				(CPU_rd_addr				),
.CPU_rd_apply			    (CPU_rd_apply			    ),
.CPU_rd_grant			    (CPU_rd_grant			    ),
.CPU_rd_dout				(CPU_rd_dout				),
 //Phy int host interface   (//Phy int host interface   ),
.Line_loop_en			    (Line_loop_en			    ),
.Speed					    (Speed					    ),
 //MII to CPU               (//MII to CPU               ),
.Divider            		(Divider            		),
.CtrlData           		(CtrlData           		),
.Rgad               		(Rgad               		),
.Fiad               		(Fiad               		),
.NoPre              		(NoPre              		),
.WCtrlData          		(WCtrlData          		),
.RStat              		(RStat              		),
.ScanStat           		(ScanStat           		),
.Busy               		(Busy               		),
.LinkFail           		(LinkFail           		),
.Nvalid             		(Nvalid             		),
.Prsd               		(Prsd               		),
.WCtrlDataStart     		(WCtrlDataStart     		),
.RStatStart         		(RStatStart         		),
.UpdateMIIRX_DATAReg		(UpdateMIIRX_DATAReg		)
);
*/
endmodule

















