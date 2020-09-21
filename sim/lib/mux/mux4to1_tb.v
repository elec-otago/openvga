module mux4to1_tb;
	
	reg		clock	= 1;
	always	#5	clock	<= ~clock;
	
	wire	[7:0]	a	= 8'h45;
	wire	[7:0]	b	= 8'h1a;
	wire	[7:0]	c	= 8'h6d;
	wire	[7:0]	d	= 8'h30;
	wire	[7:0]	out;
	
	reg		[1:0]	sel	= 0;
	
	initial begin : Sim
		$display ("Time CLK a b c d sel out");
		$monitor ("%5t %b %h %h %h %h %b %h", $time, clock, a, b, c, d, sel, out);
		
		#5
		sel	<= 1;
		
		#10
		sel	<= 2;
		
		#10
		sel	<= 3;
		
		#10
		$finish;
	end	//	Sim
	
	mux4to1 #(8) MUX0 (
		.select_i	(sel),
		
		.input0_i	(a),
		.input1_i	(b),
		.input2_i	(c),
		.input3_i	(d),
		
		.output_o	(out)
	);
	
endmodule	//	mux4to1_tb
