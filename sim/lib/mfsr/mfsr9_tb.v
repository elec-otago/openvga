module mfsr9_tb;
	
	reg		clock	= 1;
	always	#5	clock	<= ~clock;
	
	reg		reset	= 0;
	
	//reg		[8:0]	count;
	wire	[8:0]	count_w, count_i;
	
	integer	count;
	initial begin : Sim
		$display ("Time CLK RST count countW countI");
		$monitor ("%5t  %b  %b  %d    %d     %d    ",
			$time, clock, reset,
			count, count_w, count_i
		);
		
		#5
		reset	<= 1;
		
		#10
		reset	<= 0;
		
		for (count=1; count<512; count=count+1)	#10;
		
		#20
		$finish;
	end
	
	mfsr9 MFSR0 (
		.count_i	(count [8:0]),
		.count_o	(count_w)
	);
	
	imfsr9 MFSR1 (
		.count_i	(count_w),
		.count_o	(count_i)
	);
	
endmodule	//	mfsr4_tb
