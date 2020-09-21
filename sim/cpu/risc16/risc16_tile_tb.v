`timescale 1ns/100ps
module risc16_tile_tb;

`define	IO_DECODE_BITS	20:18
`define	IO_FLUSH	3'b1_10__
`define	IO_DMA		3'b1_00__
`define	IO_CRTC		3'b0_00__
`define	IO_SPROM	3'b0_01__
`define	IO_LEDS		3'b0_10__

reg	wb_clk	= 1;
reg	cpu_clk	= 1;
reg	reset	= 0;
reg	cache_reset	= 0;

always	#15 wb_clk	= ~wb_clk;
always	#5 cpu_clk	= ~cpu_clk;


wire	mem_cyc, mem_stb, mem_we;
reg	mem_ack	= 0;
reg	mem_rty	= 0;
reg	mem_err	= 0;
wire	[2:0]	mem_cti;
wire	[1:0]	mem_bte;
wire	[20:0]	mem_adr;
wire	[3:0]	mem_sel_f;
wire	[31:0]	mem_dat_f;
reg	[3:0]	mem_sel_t;
reg	[31:0]	mem_dat_t;

wire	io_cyc, io_stb, io_we;
reg	io_ack	= 0;
reg	io_rty	= 0;
reg	io_err	= 0;
wire	[2:0]	io_cti;
wire	[1:0]	io_bte;
wire	[20:0]	io_adr;
wire	[1:0]	io_sel_f;
wire	[15:0]	io_dat_f;
reg	[1:0]	io_sel_t;
reg	[15:0]	io_dat_t;


initial begin : Sim
	$dumpfile ("tb.vcd");
	$dumpvars;
	
	#22	reset	= 1;
	#160	reset	= 0;
	
	#2400
	$display ("Test Completed.");
	$finish;
end	// Sim


initial begin : Safety_Net
	#15000
	$display ("ERROR: Unclean exit");
	$finish;
end	// Safety_Net


always @(posedge wb_clk)
	if (reset)
		mem_ack	<= #2 0;
	else if (mem_cyc && mem_stb) begin
		// Atomic transaction or end of burst.
		if (mem_ack && (mem_cti == 3'b000 || mem_cti == 3'b111))
			mem_ack	<= #2 0;
		else
			mem_ack	<= #2 1;
	end


always @(posedge wb_clk)
	if (reset)
		io_ack	<= #2 0;
	else if (io_cyc && io_stb && !io_ack)	// Atomic only
		io_ack	<= #2 1;
	else
		io_ack	<= #2 0;

always @(posedge wb_clk)
	if (reset)
		cache_reset	<= #2 0;
	else if (io_cyc && io_stb && (io_adr[`IO_DECODE_BITS] == `IO_FLUSH) && !cache_reset)
		cache_reset	<= #2 1;
	else
		cache_reset	<= #2 0;


risc16_tile #(
	.ADDRESS	(23)
) TTA0 (
	.wb_rst_i	(reset),
	.wb_clk_i	(wb_clk),	// 50 MHz
	.cpu_clk_i	(cpu_clk),	// 150 MHz, sync with WB clock
	.cache_rst_i	(cache_reset),
	
	.mem_cyc_o	(mem_cyc),
	.mem_stb_o	(mem_stb),
	.mem_we_o	(mem_we),
	.mem_ack_i	(mem_ack),
	.mem_rty_i	(mem_rty),
	.mem_err_i	(mem_err),
	.mem_cti_o	(mem_cti),
	.mem_bte_o	(mem_bte),
	.mem_adr_o	(mem_adr),
	.mem_sel_o	(mem_sel_f),
	.mem_dat_o	(mem_dat_f),
	.mem_sel_i	(mem_sel_t),
	.mem_dat_i	(mem_dat_t),
	
	.io_cyc_o	(io_cyc),
	.io_stb_o	(io_stb),
	.io_we_o	(io_we),
	.io_ack_i	(io_ack),
	.io_rty_i	(io_rty),
	.io_err_i	(io_err),
	.io_cti_o	(io_cti),
	.io_bte_o	(io_bte),
	.io_adr_o	(io_adr),
	.io_sel_o	(io_sel_f),
	.io_dat_o	(io_dat_f),
	.io_sel_i	(io_sel_t),
	.io_dat_i	(io_dat_t)
);


endmodule	// risc16_tile_tb
