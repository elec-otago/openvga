module mux8to1_tb;
	
	reg		clock	= 1;
	always	#5	clock	<= ~clock;
	
	reg		[2:0]	sel	= 0;
	wire	[7:0]	out;
	
	initial begin : Sim
		$display ("Time CLK sel out");
		$monitor ("%5t  %b  %h  %h ", $time, clock, sel, out);
		
		#5
		sel	<= 1;
		
		#10
		sel	<= 2;
		
		#10
		sel	<= 7;
		
		#10
		sel	<= 5;
		
		#20
		$finish;
	end	//	Sim
	
	defparam	MUX0.WIDTH	= 8;
	mux8to1 MUX0 (
		.sel_i	(sel),
		
		.data0_i(7),
		.data1_i(6),
		.data2_i(5),
		.data3_i(4),
		.data4_i(3),
		.data5_i(2),
		.data6_i(1),
		.data7_i(0),
		
		.data_o	(out)
	);
	
endmodule	//	mux8to1_tb
