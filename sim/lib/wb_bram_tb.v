`timescale 1ns/100ps
module wb_bram_tb;

reg	clock	= 1;
always	#5 clock	<= ~clock;

reg	reset	= 0;

reg	cyc	= 0;
reg	stb	= 0;
reg	write	= 0;
reg	[2:0]	cti	= 0;
reg	[8:0]	adr;
wire	ack, err;

reg	[31:0]	data_to;
reg	[3:0]	bes_to;

wire	[31:0]	data_from;
wire	[3:0]	bes_from;


initial begin : Sim
	$write ("%% ");
	$dumpfile ("tb.vcd");
	$dumpvars;
	
	#2	reset	= 1;
	#20	reset	= 0;
	
	#10	cyc = 1; stb = 1; write = 1; cti = 2; adr = 0; data_to = $random; bes_to = 4'hf;
	#10	;
	#10	cti = 7; adr = 1; stb = 0; data_to = $random;
	#10	stb = 1;
	#20	cyc = 0; stb = 0;
	
	#20	cyc = 1; stb = 1; write = 0; cti = 2; adr = 0;
	#20	cti = 7; adr = 1;
	#10	cyc = 0; stb = 0;
	
	#800	$finish;
end	// Sim


wb_bram #(
	.HIGHZ		(1)
) BRAM (
	.wb_clk_i	(clock),
	.wb_rst_i	(reset),
	.wb_cyc_i	(cyc),
	.wb_stb_i	(stb),
	.wb_we_i	(write),
	.wb_ack_o	(ack),
	.wb_err_o	(err),
	.wb_cti_i	(cti),
	.wb_bte_i	(0),
	.wb_adr_i	(adr),
	.wb_sel_i	(bes_to),
	.wb_dat_i	(data_to),
	.wb_sel_o	(bes_from),
	.wb_dat_o	(data_from)
);


endmodule	// wb_bram_tb
