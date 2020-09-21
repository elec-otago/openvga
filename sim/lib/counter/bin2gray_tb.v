`define	WIDTH	5
`define	MSB	(`WIDTH-1)
module bin2gray_tb;
	
	reg	clock	= 1;
	always	#5	clock	<= ~clock;
	
	reg	reset	= 0;
	reg	[`MSB:0]	count_b	= 0;
	wire	[`MSB:0]	count_g;
	
	
	always @(posedge clock)
		if (reset)	count_b	<= 0;
		else		count_b	<= count_b + 1;
	
	
	initial begin : Sim
		$display ("%t:   Count = %d,  Gray = %b", $time, count_b, count_g);
		$monitor ("%t:   Count = %d,  Gray = %b", $time, count_b, count_g);
		
		#2
		reset	<= 1;
		
		#10
		reset	<= 0;
		
		#600
		$finish;
	end	// Sim
	
	
	bin2gray #(
		.WIDTH	(`WIDTH)
	) B2G0 (
		.bin_i	(count_b),
		.gray_o	(count_g)
	);
	
endmodule	// bin2gray_tb
