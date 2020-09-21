`timescale 1ns/100ps
module freega_tb;

reg		clock	= 1;
always	#15	clock	<= ~clock;	// 33 MHz PCI clock

reg		clk50	= 1;
always	#10	clk50	<= ~clk50;	// 50 MHz
// always	#3	clk50	<= ~clk50;	// 167 MHz

reg	reset_n	= 1;


// These are control signals for the PCI stress-testing module.
reg	start	= 0;
wire	done;

wire	rclk, din_do;

// PCI signals.
wire	pci_frame_n;
wire	pci_devsel_n;
wire	pci_irdy_n;
wire	pci_trdy_n;
wire	pci_idsel;
wire	pci_par;
wire	[3:0]	pci_cbe_n;
wire	[31:0]	pci_adz;

// assign (weak, weak)	adz	= 32'hFFFF_FFFF;
pullup	pcibus_pullups [31:0] (pci_adz);
pullup	devsel_pullup (pci_devsel_n);
pullup	trdy_pullup (pci_trdy_n);


// VGA signals.
wire	vga_clk, vga_blank_n, vga_sync_n, vga_hsync, vga_vsync, vga_de;
wire	[7:0]	vga_red, vga_green, vga_blue;


// SDRAM signals.
wire	sdr_clk, sdr_cke;
wire	sdr_cs_n, sdr_ras_n, sdr_cas_n, sdr_we_n;
wire	[1:0]	sdr_ba;
wire	[12:0]	sdr_a;
wire	[1:0]	sdr_dm;
wire	[15:0]	sdr_dq;


wire	[1:0]	leds;


initial begin : Sim
	$dumpfile ("tb.vcd");
	$dumpvars;
	
	#5	reset_n	<= 0;
	#600	reset_n	<= 1;
	
	#30	start	<= 1;
	
	#60
	start	<= 0;
	
	#60
	while (!done)	#30 ;
	
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


pci_testblock STRESSTEST0 (
// pci_stresstest STRESSTEST0 (
	.pci_clk_i	(clock),
	.pci_rst_ni	(reset_n),
	
	.start_i	(start),
	.done_o		(done),
	
	.pci_frame_no	(pci_frame_n),
	.pci_devsel_ni	(pci_devsel_n),
	.pci_irdy_no	(pci_irdy_n),
	.pci_trdy_ni	(pci_trdy_n),
	.pci_stop_ni	(1'b1),
	.pci_idsel_o	(pci_idsel),
	.pci_cbe_no	(pci_cbe_n),
	.pci_ad_io	(pci_adz)
);


//freega_top #(
//	.ADDRESS	(22)
freega_top FREEGA0 (
	.pci_clk	(clock),
	.pci_rst_n	(reset_n),
	
	.pci_frame_n	(pci_frame_n),
	.pci_devsel_n	(pci_devsel_n),
	.pci_irdy_n	(pci_irdy_n),
	.pci_trdy_n	(pci_trdy_n),
	.pci_cbe_n	(pci_cbe_n),
	.pci_ad		(pci_adz),
	.pci_idsel	(pci_idsel),
	.pci_stop_n	(),
	.pci_par	(pci_par),
	.pci_inta_n	(),
	.pci_req_n	(),
	.pci_gnt_n	(1'b1),
	
	.vga_clk	(vga_clk),
	.vga_blank_n	(vga_blank_n),
	.vga_sync_n	(vga_sync_n),
	.vga_hsync	(vga_hsync),
	.vga_vsync	(vga_vsync),
	.vga_de		(vga_de),
	.vga_r		(vga_red),
	.vga_g		(vga_green),
	.vga_b		(vga_blue),
	
	.sdr_clk	(sdr_clk),
	.sdr_cke	(sdr_cke),
	.sdr_cs_n	(sdr_cs_n),
	.sdr_ras_n	(sdr_ras_n),
	.sdr_cas_n	(sdr_cas_n),
	.sdr_we_n	(sdr_we_n),
	.sdr_ba		(sdr_ba),
	.sdr_a		(sdr_a),
	.sdr_dm		(sdr_dm),
	.sdr_dq		(sdr_dq),
	
	.rclk		(rclk),
	.din_do		(din_do),
	
	.clk50		(clk50),
	.leds		(leds)
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


endmodule	// freega_tb
