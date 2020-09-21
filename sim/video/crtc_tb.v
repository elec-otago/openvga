`timescale 1ns/100ps
module crtc_tb;

parameter	WIDTH	= 10;
parameter	MSB	= WIDTH - 1;

reg	clock	= 1;
always	#5 clock	<= ~clock;

reg	reset_n	= 1;

wire	vsync, hsync;
wire	vblank, hblank;
wire	de;

wire	[MSB:0]	row, col;


initial begin : Sim
	$write ("%% ");
	$dumpfile ("tb.vcd");
	$dumpvars;// (1, CNTRL0, ddr_cke);
	
	#5	reset_n	<= 0;
	#20	reset_n	<= 1;
	
	#60000
	$finish;
end	// Sim


crtc #(
	.WIDTH	(WIDTH)
) CRTC0 (
	.clock_i	(clock),	// Character clock
	.reset_ni	(reset_n),
	.enable_i	(1'b1),
/*	
	.hsynct_i	(1),
	.hbporch_i	(2),
	.hactive_i	(11),
	.hfporch_i	(12),
	
	.vsynct_i	(1),
	.vbporch_i	(2),
	.vactive_i	(11),
	.vfporch_i	(12),
	*/
	.hsynct_i	(11),
	.hbporch_i	(17),
	.hactive_i	(97),
	.hfporch_i	(99),	// h-total too
	
	.vsynct_i	(1),
	.vbporch_i	(34),
	.vactive_i	(514),
	.vfporch_i	(524),
	
	.row_o		(row),
	.col_o		(col),
	
	.de_o		(de),
	.hsync_o	(hsync),
	.vsync_o	(vsync),
	.hblank_o	(hblank),
	.vblank_o	(vblank)
);


endmodule	// crtc_tb
