`timescale 1ns/100ps
module wb_sync_tb;


reg	clka	= 1;
always	#5 clka	= ~clka;

reg	clkb	= 1;
always	#15 clkb	= ~clkb;

reg	wb_rst	= 0;

wire	b_cyc, b_stb, b_we;
wire	[24:0]	b_adr;
wire	[3:0]	b_sel;
wire	[31:0]	b_dat;
reg	b_ack	= 0;

wire	a_ack;
wire	[1:0]	self;
wire	[15:0]	datf;
reg	a_stb	= 0;
reg	a_we	= 0;
reg	[1:0]	a_sel	= 4'b11;
reg	[15:0]	a_dat;
reg	[25:0]	a_adr;


initial begin : Sim
	$dumpfile ("tb.vcd");
	$dumpvars;
	
	#2	wb_rst	= 1;
	#20	wb_rst	= 0;
	
	#20	a_stb	= 1;
	while (!a_ack)	#10;
	a_stb	= 0;
	
	#10	a_stb	= 1;
	while (!a_ack)	#10;
	a_stb	= 0;
	
	#10	a_stb	= 1;	a_we	= 1;
	while (!a_ack)	#10;
	a_stb	= 0;	a_we	= 0;
	
	#10	a_stb	= 1;	a_we	= 1;
	while (!a_ack)	#10;
	a_stb	= 0;	a_we	= 0;
	
	#300	$finish;
end	// Sim

initial	#4000	$finish;


always @(posedge a_stb)
	a_dat	<= #2 $random;

always @(posedge a_stb)
	a_adr	<= #2 $random;


// Another dummy WB module.
always @(posedge clkb)
	if (!b_ack && b_cyc && b_stb)
		b_ack	<= #32 1;
	else
		b_ack	<= #2 0;


wb_sync #(
	.HIGHZ		(0),
	.CWIDTH		(16),
	.WWIDTH		(32),
	.ADDRESS	(25)
) SYNC0 (
	.wb_rst_i	(wb_rst),
	
	.a_clk_i	(clka),
	.a_cyc_i	(a_stb),
	.a_stb_i	(a_stb),
	.a_we_i		(a_we),
	.a_ack_o	(a_ack),
	.a_rty_o	(),
	.a_err_o	(),
	.a_cti_i	(0),	// Single-word transfers
	.a_bte_i	(0),
	.a_adr_i	(a_adr),
	.a_sel_i	(a_sel),
	.a_dat_i	(a_dat),
	.a_sel_o	(self),
	.a_dat_o	(datf),
	
	.b_clk_i	(clkb),
	.b_cyc_o	(b_cyc),
	.b_stb_o	(b_stb),
	.b_we_o		(b_we),
	.b_ack_i	(b_ack),
	.b_rty_i	(0),
	.b_err_i	(0),
	.b_cti_o	(),	// Single-word transfers
	.b_bte_o	(),
	.b_adr_o	(b_adr),
	.b_sel_i	(0),
	.b_dat_i	(0),
	.b_sel_o	(b_sel),
	.b_dat_o	(b_dat)
);


endmodule	// wb_sync_tb
