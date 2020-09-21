`timescale 1ns/100ps
module clkdiv_tb;

reg	clock	= 1;
always	#5 clock	<= ~clock;

reg	reset	= 0;

wire	sclk;

initial begin : Sim
	$write ("%% ");
	$dumpfile ("tb.vcd");
	$dumpvars;
	
	#2	reset	= 1;
	#20	reset	= 0;
	
	#800	$finish;
end	// Sim

clkdiv CLKDIV0 (
	.clk_i	(clock),
	.rst_i	(reset),
	.clk_o	(sclk)
);

endmodule	// clkdiv_tb
