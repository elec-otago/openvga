`timescale 1ns/100ps
module mfsr10_tb;

reg	clk	= 1;
always	#5 clk	<= ~clk;

reg	[9:0]	count	= 1;
wire	[9:0]	count_w;

initial begin : Sim
	#1 $display("%d", count);
	#200
	$finish;
end

always @(posedge clk)
	count	<= #2 count_w;

always @(count_w)
	$display("%d", count_w);

mfsr10 MFSR0 (
	.count_i	(count[9:0]),
	.count_o	(count_w)
);

endmodule	//	mfsr10_tb
