`timescale 1ns/100ps
module hwtb_risc_tb;

reg	clk50	= 1;
reg	rst_n	= 1;
wire	[1:0]	leds;

always	#10 clk50	<= ~clk50;

initial begin : Sim
	$dumpfile ("tb.vcd");
	$dumpvars;
	
	#2	rst_n	= 0;
	#40	rst_n	= 1;
	
	#5000	$finish;
end	// Sim

hwtb_risc TB0 (
	.clk50		(clk50),
	.pci_rst_n	(rst_n),
	.leds		(leds)
);


endmodule	// hwtb_tta_tb
