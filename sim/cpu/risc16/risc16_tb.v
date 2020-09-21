`timescale 1ns/100ps
module risc16_tb;

parameter	WIDTH	= 16;
parameter	ADDRESS	= 25;
parameter	MSB	= WIDTH - 1;

reg	cpu_clk	= 1;
always	#6 cpu_clk	= ~cpu_clk;

reg	wb_clk	= 1;
always	#12 wb_clk	= ~wb_clk;

reg	reset	= 0;


initial begin : Sim
	$dumpfile ("tb.vcd");
	$dumpvars;
	
	#2	reset	= 1;
	#24	reset	= 0;
	
	#300	$finish;
end	// Sim

// Dummy WB module.
wire	cyc, we;
reg	ack	= 0;
reg	[MSB:0]	dat;
always @(posedge cpu_clk)
	if (cyc && !ack)	ack	<= #2 1;
	else			ack	<= #2 0;

always @(posedge cpu_clk)
	dat	<= #2 $random;

risc16 #(
	.HIGHZ		(0),
	.WIDTH		(WIDTH),
	.INSTR		(WIDTH),
	.ADDRESS	(ADDRESS),
	.PCBITS		(10),
	.WBBITS		(WIDTH)
) RISC16 (
	.cpu_clk_i	(cpu_clk),
	.cpu_rst_i	(reset),
	
	.wb_clk_i	(cpu_clk),
	.wb_rst_i	(reset),
	.wb_cyc_o	(cyc),
	.wb_stb_o	(),
	.wb_we_o	(we),
	.wb_ack_i	(ack),
	.wb_rty_i	(0),
	.wb_err_i	(0),
	.wb_cti_o	(),
	.wb_bte_o	(),
	.wb_adr_o	(),
	.wb_sel_o	(),
	.wb_dat_o	(),
	.wb_sel_i	({ack, ack}),
	.wb_dat_i	(dat)
);


endmodule	// risc16_tb
