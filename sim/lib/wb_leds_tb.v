`timescale 1ns/100ps
module wb_leds_tb;

// parameter	WIDTH	= 32;
parameter	WIDTH	= 8;
parameter	ENABLES	= WIDTH/8;
parameter	MSB	= WIDTH - 1;
parameter	ESB	= ENABLES - 1;

reg	wb_clk	= 1;
always	#5 wb_clk	= ~wb_clk;

reg	wb_rst	= 0;

reg	wb_stb, wb_we;
wire	wb_ack;
reg	[ESB:0]	wb_sel2	= 2'b11;
reg	[MSB:0]	wb_dat2;
wire	[ESB:0]	wb_self;
wire	[MSB:0]	leds, wb_datf;

initial begin : Sim
	$dumpfile ("tb.vcd");
	$dumpvars;
	
	#2	wb_rst	= 1;
		wb_stb	= 0;	wb_we	= 0;
	#20	wb_rst	= 0;
	
	#20	wb_stb	= 1;	wb_we	= 1;	wb_dat2	= $random;
	while (!wb_ack)	#10;
	wb_stb	= 0;	wb_we	= 0;
	
	#20	wb_stb	= 1;	wb_we	= 1;	wb_dat2	= $random;
	while (!wb_ack)	#10;
	wb_stb	= 0;	wb_we	= 0;
	
	#10	wb_stb	= 1;
	while (!wb_ack)	#10;
	wb_stb	= 0;
	
	#300	$finish;
end	// Sim

initial	#400	$finish;

wb_leds #(
	.HIGHZ		(0),
	.WIDTH		(WIDTH)
) LEDS (
	.wb_clk_i	(wb_clk),
	.wb_rst_i	(wb_rst),
	
	.wb_cyc_i	(wb_stb),
	.wb_stb_i	(wb_stb),
	.wb_we_i	(wb_we),
	.wb_ack_o	(wb_ack),
	.wb_sel_i	(wb_sel2),
	.wb_dat_i	(wb_dat2),
	.wb_sel_o	(wb_self),
	.wb_dat_o	(wb_datf),
	
	.leds_o		(leds)
);	// wb_leds

endmodule	// wb_leds_tb
