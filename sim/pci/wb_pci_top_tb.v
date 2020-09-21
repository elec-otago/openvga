//`define	_use_SRAM
`timescale 1ns/100ps
module wb_pci_top_tb;

parameter	ADDRESS	= 25;
parameter	ASB	= ADDRESS - 1;

reg		clk33	= 1;
always	#15	clk33	<= ~clk33;

reg		clk50	= 1;
always	#10	clk50	<= ~clk50;


wire	pci_clk	= clk33;
wire	wb_clk	= clk50;


// These are control signals for the PCI stress-testing module.
reg	start	= 0;
wire	done;


// PCI signals.
reg	pci_rst_n	= 1;
wire	pci_frame_n, pci_devsel_n;
wire	pci_irdy_n, pci_trdy_n;
wire	pci_stop_n, pci_idsel;
wire	[3:0]	pci_cbe_n;
wire	[31:0]	pci_adz;

// Wishbone Signals.
reg	wb_rst	= 0;
wire	wb_cyc_f, wb_stb_f, wb_we_f;
wire	wb_ack_t, wb_rty_t, wb_err_t;
wire	[2:0]	wb_cti_f;
wire	[1:0]	wb_bte_f;
wire	[ASB:0]	wb_adr_f;
wire	[3:0]	wb_sel_f, wb_sel_t;
wire	[31:0]	wb_dat_f, wb_dat_t;


initial begin : Sim
	$dumpfile ("tb.vcd");
	$dumpvars;
	
	#2 pci_rst_n	<= 0; wb_rst	<= 1;
	#60 pci_rst_n	<= 1; wb_rst	<= 0;
	
	#30 start	<= 1;
	#60 start	<= 0;
	
	#60
	while (!done)	#30 ;
	
	#60
	$display ("Test completed.");
	$finish;
end


initial begin : Safety_Net
	#15000
	$display ("ERROR: Unclean exit");
	$finish;
end	// Safety_Net


// Simulation PCI master.
pci_stresstest STRESSTEST0 (
	.pci_clk_i	(pci_clk),
	.pci_rst_ni	(pci_rst_n),
	
	.start_i	(start),
	.done_o		(done),
	
	.pci_frame_no	(pci_frame_n),
	.pci_devsel_ni	(pci_devsel_n),
	.pci_irdy_no	(pci_irdy_n),
	.pci_trdy_ni	(pci_trdy_n),
	.pci_stop_ni	(pci_stop_n),
	.pci_idsel_o	(pci_idsel),
	.pci_cbe_no	(pci_cbe_n),
	.pci_ad_io	(pci_adz)
);


// Wishbone slave device.
wb_bram4k #(
	.HIGHZ		(0)
) BRAM (
	.wb_clk_i	(wb_clk),
	.wb_rst_i	(wb_rst),
	.wb_cyc_i	(wb_cyc_f),
	.wb_stb_i	(wb_stb_f),
	.wb_we_i	(wb_we_f),
	.wb_ack_o	(wb_ack_t),
	.wb_err_o	(wb_err_t),
	.wb_cti_i	(wb_cti_f),
	.wb_bte_i	(wb_bte_f),
	.wb_adr_i	(wb_adr_f),
	.wb_sel_i	(wb_sel_f),
	.wb_dat_i	(wb_dat_f),
	.wb_dat_o	(wb_dat_t),
	.wb_sel_o	(wb_sel_t)
);


wb_pci_top #(
	.ADDRESS	(ADDRESS)
) PCITOP0 (
	.pci_clk_i	(pci_clk),
	.pci_rst_ni	(pci_rst_n),
	.pci_frame_ni	(pci_frame_n),
	.pci_devsel_no	(pci_devsel_n),
	.pci_irdy_ni	(pci_irdy_n),
	.pci_trdy_no	(pci_trdy_n),
	.pci_idsel_i	(pci_idsel),
	.pci_cbe_ni	(pci_cbe_n),
	.pci_ad_io	(pci_adz),
	.pci_stop_no	(pci_stop_n),
	.pci_par_io	(pci_par),
	.pci_inta_no	(pci_inta_n),
	.pci_req_no	(pci_req_n),
	.pci_gnt_ni	(pci_gnt_n),
	
	.enable_i	(1'b1),
	.enabled_o	(pci_enabled),
	.pci_disable_o	(pci_disable),
	
	.wb_clk_i	(wb_clk),	// Wishbone Master
	.wb_rst_i	(wb_rst),
	
	.wb_cyc_o	(wb_cyc_f),
	.wb_stb_o	(wb_stb_f),
	.wb_we_o	(wb_we_f),
	.wb_ack_i	(wb_ack_t),
	.wb_rty_i	(wb_rty_t),
	.wb_err_i	(wb_err_t),
	.wb_cti_o	(wb_cti_f),
	.wb_bte_o	(wb_bte_f),
	.wb_adr_o	(wb_adr_f),
	
	.wb_sel_o	(wb_sel_f),
	.wb_dat_o	(wb_dat_f),
	.wb_sel_i	(wb_sel_t),
	.wb_dat_i	(wb_dat_t)
);


endmodule	// wb_pci_top_tb
