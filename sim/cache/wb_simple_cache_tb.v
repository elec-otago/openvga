`timescale 1ns/100ps
module wb_simple_cache_tb;


parameter	WIDTH	= 16;
parameter	WWIDTH	= WIDTH*2;
parameter	ADDRESS	= 18;
parameter	MEMSIZE	= (1<<ADDRESS);
parameter	ASB	= ADDRESS - 1;
parameter	MSB	= WIDTH - 1;
parameter	WSB	= WWIDTH - 1;
parameter	ENABLES	= WIDTH / 8;
parameter	SELECTS	= WWIDTH / 8;
parameter	ESB	= ENABLES - 1;
parameter	SSB	= SELECTS - 1;


reg	cpu_clk	= 1;
always	#6 cpu_clk	= ~cpu_clk;

reg	wb_clk	= 1;
always	#12 wb_clk	= ~wb_clk;

reg	reset	= 0;


// So we can do error-tests.
reg	[WSB:0]	mem[MEMSIZE-1:0];


reg	ccyc	= 0;
reg	cwe	= 0;
wire	cack;
reg	[ADDRESS:0]	cadr	= 0;
wire	[ESB:0]	cself;
wire	[MSB:0]	cdatf;
reg	[ESB:0]	csel2;
reg	[MSB:0]	cdat2;

wire	rcyc, rstb, rwe;
reg	rack	= 0;
wire	[2:0]	rcti;
wire	[ASB:0]	radr;
reg	[SSB:0]	rsel;
wire	[WSB:0]	rdat;


initial begin : Sim
	$dumpfile("tb.vcd");
	$dumpvars();
	
	#14	reset	= 1;	// Clear all the `valid's
	for (cadr=0; cadr<512; cadr=cadr+32)	#12 ;
	#12	reset	= 0; cadr = 0;
	
	#12	ccyc	= 1; cadr = 10;
	while (!cack)	#12 ;
	ccyc	= 0;
	
	#12	ccyc	= 1; cadr = 11;
	while (!cack)	#12 ;
	ccyc	= 0;
	
	#12	ccyc	= 1; cadr = 40;
	while (!cack)	#12 ;
	ccyc	= 0;
	
	#12	ccyc	= 1; cadr = 41;
	while (!cack)	#12 ;
	ccyc	= 0;
	
	#12	ccyc	= 1; cadr = 10;
	while (!cack)	#12 ;
	ccyc	= 0;
	
	#12	ccyc	= 1; cadr = 11; cwe = 1; cdat2 = $random; csel2 = 2'b11;
	while (!cack)	#12 ;
	ccyc	= 0; cwe = 0;
	
	#12	ccyc	= 1; cadr = 12; cwe = 1; cdat2 = $random; csel2 = 2'b11;
	while (!cack)	#12 ;
	ccyc	= 0; cwe = 0;
	
	#12	ccyc	= 1; cadr = 10;
	while (!cack)	#12 ;
	ccyc	= 0;
	
	#12	ccyc	= 1; cadr = 11;
	while (!cack)	#12 ;
	ccyc	= 0;
	
	#240	$finish;
end	// Sim


initial	#2000	$finish;


assign	rdat	= mem[radr];
always @(posedge wb_clk)
	if (rstb) begin
		rack	<= #2 !(rack && (rcti==7 || rcti==0));
		rsel	<= #2 4'hf;
	end else
		{rsel, rack}	<= #2 0;

wire	[ASB:0]	wadr	= cadr[ADDRESS:1];
wire	[3:0]	wsel	= {csel2[1]&cadr[0], csel2[0]&cadr[0], csel2[1]&~cadr[0], csel2[0]&~cadr[0]};
wire	[31:0]	wdat	= (mem[wadr] & ~keep_mask) | ({cdat2, cdat2} & keep_mask);
wire	[31:0]	keep_mask	= {{8{wsel[3]}}, {8{wsel[2]}}, {8{wsel[1]}}, {8{wsel[0]}}};
wire	[31:0]	mdat	= mem[wadr];

always @(posedge wb_clk)
	if (ccyc && cwe && cack)
		mem[wadr]	<= #2 wdat;

wb_simple_cache #(
	.HIGHZ		(0),
	.ADDRESS	(ADDRESS),
	.CWIDTH		(WIDTH),
	.WWIDTH		(WIDTH*2),
	.SIZE		(10)		// 16-bit x 1024 words
) DCACHE (
	.wb_clk_i	(wb_clk),
	.wb_rst_i	(reset),
	
	.cpu_clk_i	(cpu_clk),
	.cpu_cyc_i	(ccyc),
	.cpu_stb_i	(ccyc),
	.cpu_we_i	(cwe),
	.cpu_ack_o	(cack),
	.cpu_rty_o	(),
	.cpu_err_o	(),
	.cpu_cti_i	(0),
	.cpu_bte_i	(0),
	.cpu_adr_i	(cadr),
	
	.cpu_sel_i	(csel2),
	.cpu_dat_i	(cdat2),
	.cpu_sel_o	(cself),	// TODO
	.cpu_dat_o	(cdatf),
	
	.mem_cyc_o	(rcyc),
	.mem_stb_o	(rstb),
	.mem_we_o	(rwe),
	.mem_ack_i	(rack),
	.mem_rty_i	(0),
	.mem_err_i	(0),
	.mem_cti_o	(rcti),
	.mem_bte_o	(),
	.mem_adr_o	(radr),
	
	.mem_sel_i	(rsel),
	.mem_dat_i	(rdat)
);


integer	ii;
initial begin : Init
	for (ii=0; ii<MEMSIZE; ii=ii+1)
		mem[ii]	= $random;
end	// Init


endmodule	// wb_simple_cache_tb
