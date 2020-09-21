`timescale 1ns/100ps
module RAMB36SDP_tb;

reg	clock	= 1;
always	#5	clock	<= ~clock;

reg	reset	= 0;

reg	read	= 0;
reg	write	= 0;
reg	regce	= 0;
reg	[8:0]	rdaddr	= 0;
reg	[8:0]	wraddr	= 0;
reg	[71:0]	datato	= 0;
wire	[71:0]	datafrom;

wire	[7:0]	wes	= {write, write, write, write, write, write, write, write};


initial begin : Sim
	$write ("%% ");
	$dumpfile ("tb.vcd");
	$dumpvars;
	
	#5
	reset	<= 1;
	
	#10
	reset	<= 0;
	
	#10
	write	<= 1;
	wraddr	<= 1;
	datato	<= $random;
	
	#10
	datato	<= 'bx;
	write	<= 0;
	read	<= 1;
	rdaddr	<= 0;
	
	#10
	rdaddr	<= 1;
	
	#10
	regce	<= 1;
	read	<= 0;
	
	#10
	regce	<= 0;
	
	#30
	$finish;
end	// Sim


RAMB36SDP ram0 (
	.RDCLK	(clock),		// 1-bit read port clock
	.WRCLK	(clock),		// 1-bit write port clock
	.SSR	(reset),		// 1-bit synchronous output set/reset input
	.WE	({1'bx, wes [6:0]}),			// 8-bit write enable input
	.WREN	(write),		// 1-bit write port enable
	.RDEN	(read),			// 1-bit read port enable
	.REGCE	(regce),		// 1-bit register enable input
	.RDADDR	(rdaddr),		// 9-bit read port address input
	.WRADDR	(wraddr),		// 9-bit write port address input
	.DI	(datato [63:0]),	// 64-bit data input
	.DIP	(datato [71:64]),	// 8-bit parity data input
	.DO	(datafrom [63:0]),	// 64-bit data output
	.DOP	(datafrom [71:64])	// 8-bit parity data output
);


endmodule	// RAMB36SDP
