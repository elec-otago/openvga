module RAMB16_S9_S36_testbench;
	
	
	reg		clock = 1;
	reg		reset = 1;
	
	reg		[7:0]	dia;
	reg		[10:0]	addra;
	reg		ena;
	reg		wea;
	wire	[7:0]	doa;
	
	reg		[31:0]	dib;
	reg		[8:0]	addrb;
	reg		enb;
	reg		web;
	wire	[31:0]	dob;
	
	
	always #5 clock <= ~clock;
	
	
	integer	count;
		
	initial begin : Init
		$display("Time CLK RESET DI_A ADDR_A EN_A WE_A DO_A");
		$monitor("%5t %1b %1b %1b %h %1b %1b %h", $time, clock, reset,
			dia, addra, ena, wea, doa);
		
		#5
		reset <= 0;
		
		dia <= 8'hA5;
		addra <= 0;
		ena <= 1;
		wea <= 1;
		
		enb <= 0;
		web <= 0;
		
/*		dib <= 32'h0F3C_A5F0;
		addrb <= 0;
		enb <= 1;
		web <= 1;*/
		
		
		for (count = 32; count; count = count - 1)
		begin
			#10
			dia <= ~dia;
			addra <= addra + 1;
		end
		
		#10
		enb <= 0;
		web <= 0;
		ena <= 1;
		wea <= 0;
		addra <= 0;
		
		for (count = 32; count; count = count - 1)
		begin
			#10
			addra <= addra + 1;
		end
		
		#20
		$finish;
	end
	
	
	RAMB16_S9_S36 block_ram0 (
		.DIA(dia),    //insert 1-bit data_in
		.DIPA(1'bz),
		.ADDRA(addra[10:0]),  //insert 14-bit address bus ([13:0])
		.ENA(ena),    //insert enable signal
		.WEA(wea),    //insert write enable signal
		.SSRA(reset),   //insert set/reset signal
		.CLKA(clock),   //insert clock signal
		.DOA(doa),    //insert 1-bit data_out 
		//.DOPA(),
		
		.DIB(dib),    //insert 32-bit data_in bus ([31:0]) 
		.DIPB(4'bzzzz),   //insert 4-bit parity data_in bus (35:32])
		.ADDRB(addrb[8:0]),  //insert 9-bit address bus ([8:0])
		.ENB(enb),    //insert enable signal
		.WEB(web),    //insert write enable signal
		.SSRB(reset),   //insert set/reset signal
		.CLKB(clock),   //insert clock signal
		.DOB(dob)
		//.DOPB()    //insert 4-bit parity data_out bus ([35:32])
	);
	
endmodule	//	RAMB16_S9_S36_testbench
