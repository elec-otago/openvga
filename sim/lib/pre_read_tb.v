`timescale 1ns/100ps
module pre_read_tb;

reg	a_clk	= 1;
reg	b_clk	= 1;
reg	reset	= 0;

always	#5 a_clk	<= ~a_clk;
always	#10 b_clk	<= ~b_clk;

reg	a_wr	= 0;
reg	[8:0]	a_adr	= 0;

reg	b_rd	= 0;
wire	b_en;
wire	[8:0]	b_adr;

initial begin : Sim
	$dumpfile("tb.vcd");
	$dumpvars();
	
	#2	reset	= 1;
	#30	reset	= 0;
	
	#10	a_wr	= 1;
	#10	a_wr	= 0;
	
	#40	a_wr	= 1;
	#10	a_wr	= 0;
	
	#40	a_wr	= 1;
	#10	a_wr	= 0;
	
	#20	b_rd	= 1;
	#60	b_rd	= 0;
	
	#40	a_wr	= 1;
	#10	a_wr	= 0;
	
	#300	$finish;
end	// Sim

initial begin
	#4000	$display ("Emergency exit!");
		$finish;
end

always @(posedge a_clk)
	if (a_wr)	a_adr	<= #2 a_adr + 1;

pre_read #(
	.ADDRESS	(9),
	.INIT		(0)
) PR0 (
	.reset_i	(reset),
	
	.a_clk_i	(a_clk),
	.a_wr_i		(a_wr),
	
	.b_clk_i	(b_clk),
	.b_rd_i		(b_rd),
	.b_en_ao	(b_en),
	.b_adr_ao	(b_adr)
);

endmodule	// pre_read_tb
