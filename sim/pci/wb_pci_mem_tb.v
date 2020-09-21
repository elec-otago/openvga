`define	PCI_MEMREAD	4'b0110
`define	PCI_MEMWRITE	4'b0111

`timescale 1ns/100ps
module wb_pci_mem_tb;

parameter	ADDRESS	= 10;
parameter	ASB	= ADDRESS - 1;

reg	wb_clk	= 1;
always	#10 wb_clk	<= ~wb_clk;

reg	pci_clk	= 1;
always #15 pci_clk	<= ~pci_clk;


// PCI signals.
reg		pci_rst_n	= 1;
reg		pci_frame_n	= 1;
reg		pci_irdy_n	= 1;
wire		pci_devsel_n, pci_trdy_n, pci_stop_n;
reg	[3:0]	pci_cbe_n	= 0;
reg	[31:0]	pci_ad_t	= 32'bz;
wire	[31:0]	pci_ad_f;


// GP signals.
reg	mm_en	= 0;
reg	[30-ADDRESS-1:0]	mm_ad	= 0;
wire	active, select;
wire	burst;

// Wishbone signals.
reg	wb_rst	= 0;
reg	wb_cyc_t	= 0;
reg	wb_stb_t	= 0;
reg	wb_we_t		= 0;
reg	[2:0]	wb_cti_t	= 0;
reg	[1:0]	wb_bte_t;
reg	[ASB:0]	wb_adr_t;
wire	wb_cyc_f, wb_stb_f, wb_we_f;
wire	wb_ack_f, wb_rty_f, wb_err_f;

wire	[ASB:0]	wb_adr_f;
wire	[2:0]	wb_cti_f;
wire	[1:0]	wb_bte_f;

wire	wb_ack_t, wb_rty_t, wb_err_t;

wire	[31:0]	wb_dat_t;
wire	[3:0]	wb_sel_t;

wire	[31:0]	wb_dat_f;
wire	[3:0]	wb_sel_f;


initial begin : Sim
	$write ("%% ");
	$dumpfile ("tb.vcd");
	$dumpvars;
	
	#2 wb_rst	= 1;
	pci_rst_n	= 0;
	#20 wb_rst	= 0;
	#10 pci_rst_n	= 1;
	#30 mm_en = 1; mm_ad = 0;
	
	// Write a couple of words.
	#60 pci_frame_n = 0; pci_ad_t = 32'h0; pci_cbe_n = `PCI_MEMWRITE;
	#30 pci_irdy_n	= 0; pci_ad_t = $random; pci_cbe_n = 4'hc;
	
	while (pci_trdy_n) #30 ;
	pci_irdy_n	= 0; pci_ad_t = $random; pci_frame_n = 1;
	while (pci_trdy_n) #30 ;
	#30 pci_irdy_n	= 1;
	
	// Read back a word.
	#150 pci_frame_n = 0; pci_ad_t = 32'h0; pci_cbe_n = `PCI_MEMREAD;
	#30 pci_irdy_n = 0; pci_ad_t = $random; pci_cbe_n = 4'hf; pci_frame_n = 1; 
	
	while (pci_trdy_n) #30 ;
	pci_irdy_n	= 1;
	
	#800	$finish;
end	// Sim


// Slave device.
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


wb_new_pci_mem #(
	.ADDRESS	(ADDRESS),
	.HIGHZ		(0)
) PCIMEM0 (
	.pci_clk_i	(pci_clk),
	.pci_rst_ni	(pci_rst_n),
	
	.pci_frame_ni	(pci_frame_n),
	.pci_devsel_no	(pci_devsel_n),
	.pci_irdy_ni	(pci_irdy_n),
	.pci_trdy_no	(pci_trdy_n),
	.pci_stop_no	(pci_stop_n),
	.pci_cbe_ni	(pci_cbe_n),
	.pci_ad_i	(pci_ad_t),
	.pci_ad_o	(pci_ad_f),
	
	.active_o	(active),
	.selected_o	(select),
	
	.mm_enable_i	(mm_en),
	.mm_addr_i	(mm_ad),	// 4kB aligned
	
	.bursting_o	(burst),
	
	.wb_clk_i	(wb_clk),
	.wb_rst_i	(wb_rst),
	
	.wb_cyc_i	(wb_cyc_t),
	.wb_stb_i	(wb_stb_t),
	.wb_we_i	(wb_we_t),
	.wb_ack_o	(wb_ack_f),
	.wb_rty_o	(wb_rty_f),
	.wb_err_o	(wb_err_f),
	.wb_cti_i	(wb_cti_t),
	.wb_bte_i	(wb_bte_t),
	.wb_adr_i	(wb_adr_t),
	
	.wb_cyc_o	(wb_cyc_f),
	.wb_stb_o	(wb_stb_f),
	.wb_we_o	(wb_we_f),
	.wb_ack_i	(wb_ack_t),
	.wb_rty_i	(wb_rty_t),
	.wb_err_i	(wb_err_t),
	.wb_cti_o	(wb_cti_f),
	.wb_bte_o	(wb_bte_f),
	.wb_adr_o	(wb_adr_f),
	
	.wb_sel_i	(wb_sel_t),
	.wb_dat_i	(wb_dat_t),
	.wb_sel_o	(wb_sel_f),
	.wb_dat_o	(wb_dat_f)
);


endmodule	// wb_pci_mem_tb
