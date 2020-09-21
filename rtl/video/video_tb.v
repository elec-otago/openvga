`timescale 1ns/100ps
module video_tb;

parameter	WIDTH	= 32;
parameter	ADDRESS	= 21;
parameter	FBSIZE	= 18;

parameter	MSB	= WIDTH - 1;
parameter	ASB	= ADDRESS - 1;


reg	clock	= 1;
always	#10	clock	<= ~clock;	// 50 MHz

reg	mem_clk	= 1;
always	#7.5	mem_clk	<= ~mem_clk;	// 66.667 MHz

reg	cpu_clk	= 1;
always	#3	cpu_clk	<= ~cpu_clk;	// 167 MHz

wire	dot_clk, chr_clk;
reg	reset_n	= 1;

wire	hsync, vsync, de;
wire	[7:0]	red, green, blue;


initial begin : Sim
	$write ("%% ");
	$dumpfile ("tb.vcd");
	$dumpvars;// (1, CNTRL0, ddr_cke);
	
	#5	reset_n	<= 0;
	#200	reset_n	<= 1;
	
	#60000
	$finish;
end	// Sim


wire	v_read, v_rack, v_ready;
wire	[ASB:0]	v_addr;
wire	[MSB:0]	v_data_from;

vga_top #(
	.WIDTH		(WIDTH),
	.ADDRESS	(ADDRESS),
	.FBSIZE		(FBSIZE)
) VGATOP0 (
	.sys_clk_i	(clock),
	.cpu_clk_i	(cpu_clk),
	.mem_clk_i	(mem_clk),
	.dot_clk_o	(dot_clk),
	.chr_clk_o	(chr_clk),
	.reset_ni	(reset_n),
	
	.mem_read_o	(v_read),
	.mem_rack_i	(v_rack),
	.mem_ready_i	(v_ready),
	.mem_addr_o	(v_addr),
	.mem_data_i	(v_data_from),
	
	.hsync_o	(hsync),
	.vsync_o	(vsync),
	.red_o		(red),
	.green_o	(green),
	.blue_o		(blue),
	.de_o		(de)
);


wire	b_read, b_write, b_rack, b_wack, b_busy;
wire	[3:0]	b_bes_n;
wire	[ASB:0]	b_addr;
wire	[MSB:0]	b_data_to;
reg		b_ready	= 0;
reg	[MSB:0]	b_data_from;

burst_ctrl #(
	.WIDTH		(WIDTH),
	.ADDRESS	(ADDRESS),
	.BURST		(8),
	.BBITS		(3)
) BC0 (
	.clock_i	(mem_clk),
	.reset_ni	(reset_n),
	
	.usr_read_i	(v_read),
	.usr_write_i	(0),
	.usr_rack_o	(v_rack),
	.usr_wack_o	(),
	.usr_ready_o	(v_ready),
	.usr_busy_o	(),
	.usr_addr_i	(v_addr),
	.usr_bes_ni	(4'hF),
	.usr_data_i	(0),
	.usr_data_o	(v_data_from),
	
	.mem_read_o	(b_read),
	.mem_write_o	(b_write),
	.mem_rack_i	(b_rack),
	.mem_wack_i	(b_wack),
	.mem_ready_i	(b_ready),
	.mem_busy_i	(b_busy),
	.mem_addr_o	(b_addr),
	.mem_bes_no	(b_bes_n),
	.mem_data_o	(b_data_to),
	.mem_data_i	(b_data_from)
);


// Random data makeriser!!
assign	b_rack	= b_read;
assign	b_wack	= b_write;	// Bottomless trap hole
assign	b_busy	= 0;

always @(posedge mem_clk)
	if (!reset_n)	b_ready	<= #2 0;
	else		b_ready	<= #2 b_read;

always @(posedge mem_clk)
	if (!reset_n)		b_data_from	<= #2 0;
	else if (b_read)	b_data_from	<= #2 $random;


endmodule	// video_tb
