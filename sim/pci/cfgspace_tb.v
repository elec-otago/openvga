module cfgspace_tb;
	
	reg		clock	= 1;
	always	#15	clock	<= ~clock;
	
	reg		reset_n	= 1;
	
	
	reg		frame_n	= 1;
	wire	devsel_n;
	reg		irdy_n	= 1;
	wire	trdy_n;
	reg		[3:0]	cbe_n	= 4'hF;
	reg		[31:0]	ad;
	wire	[31:0]	data;
	reg		idsel	= 0;
	
	wire	active;			//	Controls the output muxes and tri-states
	wire	memen;			//	Requested memory is configured?
	wire	[19:0]	addr;	//	Configured base address
	
	wire	[31:0]	adz	= active ? data : ad;
	
	
`define	PCI_CFGREAD		4'b1010
`define	PCI_CFGWRITE	4'b1011
	
	
	initial begin : Sim
		$display ("Time CLK RST# FRAME# DEVSEL# IRDY# TRDY# C/BE# AD IDSEL active memen addr");
		$monitor ("%5t  %b  %b   %b     %b      %b    %b    %b    %h %b    %b     %b    %h",
			$time, clock, reset_n,
			frame_n, devsel_n, irdy_n, trdy_n, cbe_n, adz, idsel,
			active, memen, addr
		);
		
		#10
		reset_n	<= 0;
		ad		<= 0;
		
		#30
		reset_n	<= 1;
		
		
		//	Read device ID
		#30
		frame_n	<= 0;
		cbe_n	<= `PCI_CFGREAD;
		idsel	<= 1;
		ad		<= 0;
		
		#30
		frame_n	<= 1;
		cbe_n	<= 4'b0;
		idsel	<= 0;
		irdy_n	<= 0;
		
		#60
		irdy_n	<= 1;
		
		
		//	Configure the device base address
		#30
		frame_n	<= 0;
		cbe_n	<= `PCI_CFGWRITE;
		idsel	<= 1;
		ad		<= 32'h0_0010;
		
		#30
		frame_n	<= 1;
		cbe_n	<= 4'b0;
		idsel	<= 0;
		ad		<= 32'h000D_E000;	//	Use x86 baseaddr DE00:0000
		irdy_n	<= 0;
		
		#60
		irdy_n	<= 1;
		
		
		//	Read back the base address
		#30
		frame_n	<= 0;
		cbe_n	<= `PCI_CFGREAD;
		idsel	<= 1;
		ad		<= 32'h0_0010;
		
		#30
		frame_n	<= 1;
		cbe_n	<= 4'b0;
		idsel	<= 0;
		irdy_n	<= 0;
		
		#60
		irdy_n	<= 1;
		
		
		//	Enable the device
		#30
		frame_n	<= 0;
		cbe_n	<= `PCI_CFGWRITE;
		idsel	<= 1;
		ad		<= 32'h0_0004;
		
		#30
		frame_n	<= 1;
		cbe_n	<= 4'b0;
		idsel	<= 0;
		ad		<= 32'h0000_0002;
		irdy_n	<= 0;
		
		#60
		irdy_n	<= 1;
		
		
		//	Finished
		#90
		$finish;
	end	//	Sim
	
	
	cfgspace CFG0 (
		.pci_clk_i		(clock),
		.pci_rst_ni		(reset_n),
		
		.pci_frame_ni	(frame_n),
		.pci_devsel_no	(devsel_n),
		.pci_irdy_ni	(irdy_n),
		.pci_trdy_no	(trdy_n),
		
		.pci_cbe_ni		(cbe_n),
		.pci_ad_i		(ad),
		.pci_ad_o		(data),
		
		.pci_idsel_i	(idsel),
		
		.active_o		(active),
		.memen_o		(memen),
		.addr_o			(addr)
	);
	
	
endmodule	//	cfgspace_tb
