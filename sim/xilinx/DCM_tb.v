`timescale 1ns/100ps
module DCM_tb;


reg	clk100	= 1;
always	#5 clk100	<= ~clk100;

wire	clock, locked, clock90, clock180, clock270, clock2x, clockdv;


initial begin : Sim
	$write ("%% ");
	$dumpfile ("tb.vcd");
	$dumpvars;
	
	#1000
	$finish;
end	// Sim


DCM dcm0 (
	.CLKIN	(clk100),
	.CLKFB	(clock),
	.CLK0	(clock),
	.CLK90	(clock90),
	.CLK180	(clock180),
	.CLK270	(clock270),
	.CLK2X	(clock2x),
	.CLKDV	(clockdv),
	.LOCKED	(locked)
);


endmodule	// DCM_tb
