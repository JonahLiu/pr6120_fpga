module eeprom_emu(
	input clk_i,
	input rst_i,

	input sk_i,
	input cs_i,
	input di_i,
	output do_o,
	output do_oe_o,

	output [7:0] read_addr,
	output read_enable,
	input [15:0] read_data
);

reg sk_0;
reg [10:0] data_in;
reg [5:0] data_cnt;
reg [15:0] data_out;
reg do_oe_r;
reg read_enable_r;

wire clk_rise;

assign clk_rise = !sk_0 && sk_i;
assign do_o = data_out[15];
assign do_oe_o = do_oe_r;
assign read_addr = data_in[7:0];
assign read_enable = read_enable_r;

always @(posedge clk_i, posedge rst_i)
begin
	if(rst_i) begin
		sk_0 <= 1'b0;
	end
	else begin
		sk_0 <= sk_i;
	end
end

always @(posedge clk_i, posedge rst_i)
begin
	if(rst_i) begin
		data_in <= 'b0;
		data_cnt <= 'b0;
	end
	else if(!cs_i) begin
		data_in <= 'b0;
		data_cnt <= 'b0;
	end
	else if(cs_i && clk_rise) begin
		data_in <= {data_in, di_i};
		data_cnt <= data_cnt+1;
	end
end

always @(posedge clk_i, posedge rst_i)
begin
	if(rst_i) begin
		do_oe_r <= 1'b0;
	end
	else if(data_cnt==11 && data_in[10:8]==3'b110) begin
		do_oe_r <= 1'b1;
	end
	else if(data_cnt==28 || !cs_i) begin
		do_oe_r <= 1'b0;
	end
end

always @(posedge clk_i, posedge rst_i)
begin
	if(rst_i) begin
		data_out <= 'b0;
	end
	else if(cs_i && clk_rise) begin
		if(data_cnt==11 && data_in[10:8]==3'b110) begin
			data_out <= read_data;
		end
		else begin
			data_out <= {data_out, 1'b0};
		end
	end
	else if(!cs_i) begin
		data_out <= 'b0;
	end
end

always @(posedge clk_i, posedge rst_i)
begin
	if(rst_i) begin
		read_enable_r <= 1'b0;
	end
	else if(data_cnt==11 && data_in[10:8]==3'b110) begin
		read_enable_r <= 1'b1;
	end
	else begin
		read_enable_r <= 1'b0;
	end
end

endmodule
