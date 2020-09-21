`timescale 1ns/100ps
module rfc_tb;

reg	clk	= 1;
always	#5 clk	<= ~clk;

reg	rst	= 0;

reg	en	= 0;
reg	gnt	= 0;

wire	req, rfc;

initial begin : Sim
	$write ("%% ");
	$dumpfile ("tb.vcd");
	$dumpvars;
	
	#2	rst	= 1;
	#20	rst	= 0;
	
	#10	en	= 1;
	
	while (rfc)	#10 ;
	gnt	= 1;
	#10	gnt	= 0;
	
	#800	$finish;
end	// Sim

rfc #(
	.INIT		(1),
	.RFC_TIMER	(10),
	.TIMER_BITS	(4),
	.tRFC		(3)
) RFC0 (
	.clk_i	(clk),
	.rst_i	(rst),
	.en_i	(en),
	.req_o	(req),
	.gnt_i	(gnt),
	.rfc_o	(rfc)
);

endmodule	// rfc_tb
