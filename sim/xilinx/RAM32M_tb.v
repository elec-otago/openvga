`timescale 1ns/100ps
module RAM32M_tb;

reg	wclk	= 1;
always	#5 wclk	<= ~wclk;

reg	write	= 0;
reg	[4:0]	aa, ab, ac, ad;
reg	[1:0]	da, db, dc, dd;

wire	[1:0]	oa, ob, oc, od;

initial begin : Sim
	$write ("%% ");
	$dumpfile ("tb.vcd");
	$dumpvars;
	
	#5
	write	<= 1;
	aa	<= 2;
	ab	<= 3;
	ac	<= 4;
	ad	<= 5;
	
	da	<= $random;
	db	<= $random;
	dc	<= $random;
	dd	<= $random;
	
	#10
	aa	<= 6;
	ab	<= 7;
	ac	<= 8;
	ad	<= 9;
	
	da	<= $random;
	db	<= $random;
	dc	<= $random;
	dd	<= $random;
	
	#10
	write	<= 0;
	
	
	#30
	$finish;
end	// Sim


RAM32M ram0 (
	.WCLK	(wclk),
	.WE	(write),
	.ADDRA	(aa),
	.ADDRB	(ab),
	.ADDRC	(ac),
	.ADDRD	(ad),
	.DIA	(da),
	.DIB	(db),
	.DIC	(dc),
	.DID	(dd),
	.DOA	(oa),
	.DOB	(ob),
	.DOC	(oc),
	.DOD	(od)
);

endmodule	// RAM32M_tb
