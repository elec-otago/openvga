`timescale 1ns/100ps
module OBUFT_tb;
	
	reg	clock	= 1;
	always	#5	clock	<= ~clock;
	
	reg	in	= 0;
	wire	out;
	reg	en	= 0;
	
	initial begin : Sim
		$display ("Time CLK EN IN OUT");
		$monitor ("%5t  %b  %b %b %b ", $time, clock, en, in, out);
		
		#10
		en	<= 1;
		
		#10
		in	<= 1;
		
		#10
		in	<= 0;
		
		#10
		in	<= 1;
		
		#10
		en	<= 0;
		
		#10
		$finish;
	end	// Sim
	
	OBUFT obuf0 (
		.I	(in),
		.O	(out),
		.T	(en)
	);
	
endmodule	// OBUFT_tb
