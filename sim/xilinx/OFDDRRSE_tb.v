`timescale 1ns/100ps
module OFDDRRSE_tb;
	
	reg	clock	= 1;
	always	#5	clock	<= ~clock;
	
	reg	clk_en	= 0;
	reg	reset	= 0;
	reg	set	= 0;
	
	reg	[1:0]	data	= 0;
	wire	ddr_data;
	
	wire	d0	= data [0];
	wire	d1	= data [1];
	
	initial begin : Sim
		
		$write ("%% ");
		$dumpfile ("test.vcd");
		$dumpvars;// (1, CNTRL0, ddr_cke);
		
		$display ("Time CLK RST SET CE  D0 D1 Q ");
		$monitor ("%5t  %b  %b  %b  %b  %b %b %b",
			$time, clock, reset, set, clk_en,
			d0, d1, ddr_data
		);
		
		
		reset	<= 1;
		clk_en	<= 1;
		
		#11
		reset	<= 0;
		
		#10
		data	<= 2'b01;
		
		#10
		data	<= 2'b10;
		
		#10
		data	<= 2'b11;
		
		#10
		data	<= 2'b00;
		
		#10
		set	<= 1;
		
		#10
		set	<= 0;
		
		#20
		$finish;
	end	// Sim
	
	defparam	odata_fddr.DELAY	= 3.0;
	OFDDRRSE odata_fddr (
		.Q	(ddr_data),
		.C0	(clock),
		.C1	(~clock),
		.CE	(clk_en),
		.D0	(data [0]),
		.D1	(data [1]),
		.R	(reset),
		.S	(set)
	);
	
endmodule	// OFDDRRSE_tb
