`timescale 1ns/100ps
module IFDDRRSE_tb;
	
	reg	clock	= 1;
	always	#5	clock	<= ~clock;
	
	reg	clk_en	= 0;
	reg	reset	= 0;
	reg	set	= 0;
	
	wire	[1:0]	data;
	reg	ddr_data	= 0;
	
	initial begin : Sim
		
		$write ("%% ");
		$dumpfile ("test.vcd");
		$dumpvars;// (1, CNTRL0, ddr_cke);
		
/*		$display ("Time CLK RST  start read last  RAS# CAS# WE# AP");
		$monitor ("%5t  %b  %b   %b    %b   %b    %b   %b   %b  %b",
			$time, clock, reset,
			cmd_start, cmd_read, cmd_last,
			ddr_ras_n, ddr_cas_n, ddr_we_n, ap
		);
		*/
		
		reset		<= 1;
		clk_en		<= 1;
		
		#10
		reset		<= 0;
		
		#5
		ddr_data	<= 1;
		
		#10
		ddr_data	<= 0;
		
		#11
		ddr_data	<= 1;
		
		#10
		set		<= 1;
		
		#10
		set		<= 0;
		
		#20
		$finish;
	end	// Sim
	
	
	IFDDRRSE odata_fddr (
		.C0	(clock),
		.C1	(~clock),
		.CE	(clk_en),
		.D	(ddr_data),
		.R	(reset),
		.S	(set),
		.Q0	(data [0]),
		.Q1	(data [1])
	);
	
endmodule	// IFDDRRSE_tb
