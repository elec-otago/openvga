`timescale 1ns/100ps
module wb_dma_tb;

reg	clka	= 1;
always	#5 clka	= ~clka;

reg	clkb	= 1;
always	#15 clkb	= ~clkb;

reg	wb_rst	= 0;

wire	b_cyc, b_stb, b_we;
wire	[24:0]	b_adr;
wire	[3:0]	b_sel;
wire	[31:0]	b_dat;
wire	[2:0]	b_cti;
wire	[1:0]	b_bte;
reg	b_ack	= 0;

// Async signals.
wire	b_cyc_w;

wire	a_ack, a_rty;
wire	[1:0]	self;
wire	[15:0]	datf;
reg	a_stb	= 0;
reg	a_we	= 0;
reg	[1:0]	a_sel	= 4'b11;
reg	[15:0]	a_dat;
reg	[1:0]	a_adr;


initial begin : Sim
	$dumpfile ("tb.vcd");
	$dumpvars;
	
	#2	wb_rst	= 1;
	#20	wb_rst	= 0;
	
	// Set ANDN bit mask
	#20	a_stb	= 1; a_adr = 3; a_dat = 4'h1; a_sel = 2'b11; a_we = 1;
	while (!a_ack)	#10;
	a_stb	= 0;
	
	// Set an address
	#10	a_stb	= 1; a_adr = 1; a_dat = $random;
	while (!a_ack)	#10;
	a_stb	= 0;
	
	#10	a_stb	= 1; a_adr = 2; a_dat = $random;
	while (!a_ack)	#10;
	a_stb	= 0;
	
	// Write a word
	#10	a_stb	= 1; a_adr = 0; a_dat = $random;
	while (!a_ack)	#10;
	a_stb	= 0;
	
	#10	a_stb	= 1; a_dat = $random;
	while (!a_ack)	#10;
	a_stb	= 0;
	
	#10	a_stb	= 1; a_dat = $random;
	while (!a_ack)	#10;
	a_stb	= 0;
	
	#10	a_stb	= 1; a_dat = $random;
	while (!a_ack)	#10;
	a_stb	= 0;
	
	#10	a_stb	= 1; a_dat = $random;
	while (!a_ack)	#10;
	a_stb	= 0;
	
/*	#10	a_stb	= 1; a_dat = $random;
	while (!a_ack)	#10;
	a_stb	= 0;	a_we	= 0;
	*/
	// Start DMA
	#10	a_stb	= 1; a_we = 1; a_dat = 16'h0080; a_adr = 3;
	while (!a_ack)	#10;
	a_stb	= 0;	a_we	= 0;
	
	// Spam the DMA
	#10	a_stb	= 1; a_we = 1; a_dat = $random; a_adr = 0;
	#10 while (a_rty)	begin
		#10	a_stb	= 0;
		#10	a_stb	= 1;
	end
	
	// Try a single word xfer.
	#200	a_stb	= 1; a_adr = 0; a_dat = $random; a_we = 1;
	while (!a_ack)	#10;
	a_stb	= 0;
	
	#10	a_stb	= 1; a_we = 1; a_dat = 16'h0080; a_adr = 3;
	while (!a_ack)	#10;
	a_stb	= 0;	a_we	= 0;
	
	#300	$finish;
end	// Sim

initial	begin
	#8000
	$display ("Social Safety Net!");
	$finish;
end

// Another dummy WB module.
// Basically just a sycophant, just says "yes" to everything.
always @(posedge clkb)
	if (!b_ack && b_cyc && b_stb) begin
		b_ack	<= #32 1;
		if (b_we)
			$display ("%5t: DMA write to mem.", $time);
	end else if (b_cti == 2 && b_bte == 0 && b_cyc && b_stb) begin
		b_ack	<= #32 1;
		if (b_we)
			$display ("%5t: DMA write to mem.", $time);
	end
	else
		b_ack	<= #2 0;


wb_dma #(
	.HIGHZ		(0),
	.CWIDTH		(16),
	.WWIDTH		(32),
	.ADDRESS	(25)
) DMA0 (
	.wb_rst_i	(wb_rst),
	
	.a_clk_i	(clka),
	.a_cyc_i	(a_stb),
	.a_stb_i	(a_stb),
	.a_we_i		(a_we),
	.a_ack_o	(a_ack),
	.a_rty_o	(a_rty),
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
	.b_cyc_ao	(b_cyc_w),
	.b_stb_o	(b_stb),
	.b_we_o		(b_we),
	.b_ack_i	(b_ack),
	.b_rty_i	(0),
	.b_err_i	(0),
	.b_cti_o	(b_cti),	// Single-word transfers
	.b_bte_o	(b_bte),
	.b_adr_o	(b_adr),
	.b_sel_i	(0),
	.b_dat_i	(0),
	.b_sel_o	(b_sel),
	.b_dat_o	(b_dat)
);


endmodule	// wb_dma_tb
