module fastbits_tb;

parameter	WIDTH	= 16;
parameter	MSB	= WIDTH - 1;

reg	[MSB:0]	a	= 0;
reg	[MSB:0]	b	= 0;
reg	[1:0]	m	= 0;
wire	[MSB:0]	b_n;
wire		z;

initial begin : Sim
	$dumpfile ("tb.vcd");
	$dumpvars;
	
	#10 a = 1;
	#10 b = 1;
	#10 $finish;
end	// Sim

fastbits #(
	.WIDTH	(WIDTH)
) FB (
	.a_i	(a),
	.b_i	(b),
	.m_i	(m),
	.b_no	(b_n),
	.z_o	(z)
);

endmodule	// fastbits_tb
