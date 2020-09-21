`timescale 1ns/100ps
module RAMB16_S9_S36_testbench;
	
	
	reg	clock = 1;
	reg	reset = 1;
	
	reg	[7:0]	dia	= 8'h0;
	reg	[10:0]	addra	= 10'h0;
	reg	ena	= 0;
	reg	wea	= 0;
	wire	[7:0]	doa;
	wire	dopa;
	
	reg	[7:0]	dib	= 8'hFF;
	reg	[10:0]	addrb	= 1;
	reg	enb	= 1;
	reg	web	= 0;
	wire	[7:0]	dob;
	wire	dopb;
	
	always #5 clock <= ~clock;
	
	initial begin : Init
		$display("Time CLK RESET ADDRA WE DiA DiB DoA DoB");
		$monitor("%5t  %b  %b    %d    %b %h  %h  %h  %h ",
			$time, clock, reset, addra, wea, dia, dib, doa, dob
		);
		
		#5
		ena	<= 1;
		enb	<= 1;
		reset	<= 0;
		
		#10
		wea	<= 1;
		web	<= 1;
		dia	<= 8'hf3;
		dib	<= 8'ha5;
		
		#10
		wea	<= 0;
		web	<= 0;
		
		#10
		$display("%% doa = %h", doa);
		
		#10
		$finish;
	end
	
	RAMB16_S9_S9 lut0 (
		.DIA(dia),
		.DIPA(1'b0),
		.ADDRA(addra),
		.ENA(ena),
		.WEA(wea),
		.SSRA(0),
		.CLKA(clock),
		.DOA(doa),
		.DOPA(dopa),
		
		.DIB(dib),
		.DIPB(1'b0),
		.ADDRB(addrb),
		.ENB(enb),
		.WEB(web),
		.SSRB(0),
		.CLKB(clock),
		.DOB(dob),
		.DOPB(dopb)
	);
	
endmodule	//	RAMB16_S9_S36_testbench
