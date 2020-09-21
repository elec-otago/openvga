module RAM16X1D_tb;
	
	reg		data	= 0;
	wire	data_0;
	wire	data_1;
	reg		we		= 0;
	reg		wclk	= 1;
	reg		[3:0]	r_addr	= 0;
	reg		[3:0]	w_addr	= 0;
	
	
	always	#5	wclk	<= ~wclk;
	
	initial begin : Sim
		$display("Time WCLK D WE A DPRA SPO DPO");
		$monitor("%5t %b %b %b %h %h %b %b", $time, wclk, data,
			we, w_addr, r_addr, data_0, data_1);
		
		#2
		we		<= 1;
		data	<= 1;
		
		#10
		w_addr	<= w_addr + 1;
		data	<= 1;
		
		#20
		$finish;
	end	//	Sim
	
	//	16-bits of RAM, WOW!!
	RAM16X1D	ram0(
		.D(data),
		.WE(we),
		.WCLK(wclk),
		.A0(w_addr[0]),
		.A1(w_addr[1]),
		.A2(w_addr[2]),
		.A3(w_addr[3]),
		.DPRA0(r_addr[0]),
		.DPRA1(r_addr[1]),
		.DPRA2(r_addr[2]),
		.DPRA3(r_addr[3]),
		.SPO(data_0),
		.DPO(data_1)
	);
	
endmodule	//	RAM16X1D_tb
