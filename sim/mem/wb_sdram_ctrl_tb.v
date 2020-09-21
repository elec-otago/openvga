`timescale 1ns/100ps
module wb_sdram_ctrl_tb;

reg		clk50	= 1;
always	#10	clk50	<= ~clk50;	// 50 MHz

reg		clk100	= 1;
always	#5	clk100	<= ~clk100;

reg	reset	= 1;

reg	m_cyc	= 0;
reg	m_stb	= 0;
reg	m_we	= 0;
wire	m_ack, m_rty, m_err;
reg	[2:0]	m_cti	= 0;
reg	[1:0]	m_bte	= 0;
reg	[20:0]	m_adr	= 0;
reg	[3:0]	m_sel_t	= 0;
reg	[31:0]	m_dat_t	= 0;
wire	[3:0]	m_sel_f;
wire	[31:0]	m_dat_f;


// SDRAM signals.
wire	sdr_clk, sdr_cke;
wire	sdr_cs_n, sdr_ras_n, sdr_cas_n, sdr_we_n;
wire	[1:0]	sdr_ba;
wire	[12:0]	sdr_a;
wire	[1:0]	sdr_dm;
wire	[15:0]	sdr_dq;


integer	ii;
initial begin : Sim
	$dumpfile ("tb.vcd");
	$dumpvars;
	
	#2	reset	= 1;
	#20	reset	= 0;
	
	// Wait for the SDRAM to finish initialising.
	while (!m_ack) begin
		m_cyc	= 0; m_stb	= 0;
		
		#20	m_cyc	= 1; m_stb	= 1;
		while (!m_ack && !m_rty)	#20 ;
	end
	m_cyc	= 0; m_stb	= 0;
	
	// Write 16 words.
	#40 m_cti	= 3'b010;
	m_cyc	= 1;
	m_stb	= 1;
	m_we	= 1;
	m_adr	= 0;
	m_sel_t	= 4'b1111;
	m_dat_t	= $random;
	for (ii=1; ii<16; ii=ii+1) begin
		#20 ;
		while (!m_ack)	#20 ;
		if (ii==15)	m_cti	= 3'b111;
		m_adr[3:0]	= ii[3:0];
		m_dat_t	= $random;
	end
	#20	m_cyc	= 0; m_stb	= 0; m_we	= 0;
	
	// Read back 16 words.
	#40 m_cti	= 3'b010;
	m_cyc	= 1;
	m_stb	= 1;
	m_we	= 0;
	m_adr	= 0;
	for (ii=1; ii<16; ii=ii+1) begin
		#20 ;
		while (!m_ack)	#20 ;
		if (ii==15)	m_cti	= 3'b111;
		m_adr[3:0]	= ii[3:0];
	end
	#20	m_cyc	= 0; m_stb	= 0;
	
	// Read just one word.
	#20	m_cti	= 0;
	m_cyc	= 1; m_stb	= 1; m_we	= 0; m_adr	= 0;
	while (!m_ack)	#20 ;
	m_cyc	= 0; m_stb	= 0;
	
	
	#600
	$display ("Test completed.");
	$finish;
end


initial begin : Safety_Net
	#750000
// 	#27500
	$display ("ERROR: Unclean exit");
	$finish;
end	// Safety_Net


assign	sdr_a[12]	= 0;
wb_sdram_ctrl #(
	.ADDRESS	(21),	// 8 MB (2Mx32)
	.HIGHZ		(0),
	.RFC_PERIOD	(30),	// 100 MHz timings (off 50 MHz sys clock)
// 	.RFC_PERIOD	(780),	// 100 MHz timings (off 50 MHz sys clock)
	.tRAS		(3),
	.tRC		(3),
	.tRFC		(3)
) SDRCTRL (
	.sdr_clk_i	(clk100),
	.wb_clk_i	(clk50),
	.wb_clk_ni	(~clk50),
	.wb_rst_i	(reset),
	.wb_cyc_i	(m_cyc),
	.wb_stb_i	(m_stb),
	.wb_we_i	(m_we),
	.wb_ack_o	(m_ack),
	.wb_rty_o	(m_rty),
	.wb_err_o	(m_err),
	.wb_cti_i	(m_cti),
	.wb_bte_i	(m_bte),
	.wb_adr_i	(m_adr),
	.wb_sel_i	(m_sel_t),
	.wb_dat_i	(m_dat_t),
	.wb_sel_o	(m_sel_f),
	.wb_dat_o	(m_dat_f),
	
	// SDRAM pins.
	.CLK		(sdr_clk),
	.CKE		(sdr_cke),
	.CS_n		(sdr_cs_n),
	.RAS_n		(sdr_ras_n),
	.CAS_n		(sdr_cas_n),
	.WE_n		(sdr_we_n),
	.BA		(sdr_ba),
	.A		(sdr_a[11:0]),
	.DM		(sdr_dm),
	.DQ		(sdr_dq)
);


mt48lc4m16a2 MEM0 (
	.Dq	(sdr_dq),
	.Addr	(sdr_a[11:0]),
	.Ba	(sdr_ba),
	.Clk	(sdr_clk),
	.Cke	(sdr_cke),
	.Cs_n	(sdr_cs_n),
	.Ras_n	(sdr_ras_n),
	.Cas_n	(sdr_cas_n),
	.We_n	(sdr_we_n),
	.Dqm	(sdr_dm)
);


endmodule	// wb_sdram_ctrl_tb
