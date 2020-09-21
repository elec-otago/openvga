`timescale 1ns/100ps
module fib20_tb;

integer	fibs [0:21];

reg	clock	= 1;
always	#5 clock	<= ~clock;

wire	[19:0]	next_n;
reg	[19:0]	n	= 0;

always @(posedge clock)
	n	<= next_n;

initial	#1000 $finish;

always @* begin
	disp_fib (n);
end

fib20 FIB0 (
	.count_i	(n),
	.count_o	(next_n)
);

integer	ii;
initial begin
	fibs[0]	= 0;
	fibs[1]	= 1;
	for (ii=2; ii<22; ii=ii+1) begin
		fibs[ii]	= fibs[ii-2] + fibs[ii-1];
	end
end

task	disp_fib;
input	[31:0]	fib;
integer	jj, num;
begin
	num	= 0;
	for (jj=0; jj<20; jj=jj+1)
	begin
		num	= num + ((((1<<jj) & fib) >> jj) * fibs[jj+2]);
	end
	$display ("%d", num);
end
endtask

endmodule	// fib20_tb
