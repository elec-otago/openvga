/***************************************************************************
 *                                                                         *
 *   pci_testblock.v - Runs through a series of tests to test the          *
 *     robustness of a PCI module.                                         *
 *                                                                         *
 *   Copyright (C) 2007 by Patrick Suggate                                 *
 *   patrick@physics.otago.ac.nz                                           *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/

// `define	TEST_COUNT	16384
`define	TEST_COUNT	4096
// `define	TEST_COUNT	1024
// `define	TEST_COUNT	256
// `define	TEST_COUNT	128
// `define	TEST_COUNT	64
// `define	TEST_COUNT	32
// `define	TEST_COUNT	16
// `define	TEST_COUNT	4

// `define __test_single_read_writes
`define __test_burst_write_single_reads
// `define __test_single_write_burst_reads
// `define __test_VGA_ports

`timescale 1ns/100ps
module pci_testblock (
	input		pci_clk_i,
	input		pci_rst_ni,
	
	input		start_i,
	output	reg	done_o	= 0,
	
	output		pci_frame_no,
	input		pci_devsel_ni,
	output		pci_irdy_no,
	input		pci_trdy_ni,
	input		pci_stop_ni,
	output		pci_idsel_o,
	output	[3:0]	pci_cbe_no,
	inout	[31:0]	pci_ad_io
);


reg	[31:0]	block [`TEST_COUNT-1:0];

reg	cfg	= 0;
reg	io	= 0;
reg	mem	= 0;
reg	write	= 0;
reg	burst	= 0;
reg	[3:0]	bes_n;
reg	[31:0]	data_to, addr, base_ad;
reg	init	= 0;

wire	idle, full, ready;
wire	[31:0]	data_from;

reg	b_frame_n	= 1;
reg	b_irdy_n	= 1;
reg	b_idsel		= 1;
reg	[3:0]	b_cbe_n	= 4'hf;
reg	[31:0]	b_ad	= 32'bz;

integer	lsb;
integer	ii;
initial begin : Init
	
	// Wait for reset#
	while (!init)	#30 ;
	while (!pci_rst_ni)	#30 ;
	
	#30 while (!idle)	#30 ;	// Read ID
		cfg = 1; write = 0; addr = 0;
	#30	cfg = 0;
	
	#30 while (!idle)	#30 ;	// Set BAR0
		cfg = 1; write = 1; addr = 'h10; data_to = 32'hffff_ffff; bes_n = 4'h0;
	#30	cfg = 0; write = 0;
	
	#30 while (!idle)	#30 ;	// Read back BAR0
		cfg = 1; write = 0; addr = 'h10;
	#30	cfg = 0;
	
	while (!ready)	#30;	// Latch read data
	base_ad = data_from;
	
	lsb = 0;		// Look for lsb
	while (lsb < 32 && base_ad[lsb] == 0)
		lsb = lsb + 1;
	base_ad	= 1 << lsb;
	
	#30 while (!idle)	#30 ; // Set base address
		cfg = 1; write = 1; addr = 'h10; data_to = base_ad; bes_n = 4'h0;
	#30	cfg = 0; write = 0;
	
	#30 while (!idle)	#30 ;	// Enable MMIO
		cfg = 1; write = 1; addr = 'h4; data_to = 32'h0000_0002; bes_n = 4'h0;
	#30	cfg = 0; write = 0;
	

`ifdef __test_VGA_ports
	/////////////////////////////////////////////////////////////////////
	#30 while (!idle)	#30 ;	// VGA Port access
		io = 1; write = 1; addr = 'h03c0; data_to = $random; bes_n = 4'hE;
	#30	io = 0; write = 0;
	
	#30 while (!idle)	#30 ;	// VGA Port access
		io = 1; write = 0; addr = 'h03c0; data_to = $random; bes_n = 4'hE;
	#30	io = 0; write = 0;
	/////////////////////////////////////////////////////////////////////
`endif	// __test_VGA_ports
	
	
`ifdef __test_single_read_writes
	//-- Run Test --
	// Write first
	#30 while (!idle)	#30 ;
	bes_n = 4'h0; burst = 0;
	for (ii=0; ii<`TEST_COUNT; ii=ii+1) begin
		#30 mem = 1; write = 1; addr = base_ad | (ii << 2); data_to = block[ii];
		$display ("@%8t: Data written %x (@%x)", $time, data_to, addr);
		#30 mem = 0; write = 0;
		while (!idle)	#30 ;
	end
	
	// Read back
	for (ii=0; ii<`TEST_COUNT; ii=ii+1) begin
		#30 mem = 1; write = 0; addr = base_ad | (ii << 2);
		#30 mem = 0;
		while (!ready)	#30 ;
		if (data_from != block[ii])
			$display ("@%8t: ERROR: Data read %x (@%x) should be %x",
				$time, data_from, addr, block[ii]);
/*		else
			$display ("@%8t: Data read %x (@%x)",
				$time, data_from, addr);*/
		while (!idle)	#30 ;
	end
	#60 $display ("@%5t: Single read/writes completed (%0d words)", $time, ii);
`endif	// __test_single_read_writes
	
	
`ifdef __test_burst_write_single_reads
	// Burst write
	// `gencmds' is a little gammy, so just bit-bang the xfer.
	#30 while (!idle)	#30 ;
	init = 0; b_idsel = 0;
	#30 b_frame_n = 0; b_ad = base_ad; b_cbe_n = 4'h7;
	#30 b_irdy_n = 0; b_ad = block[0]; b_cbe_n = 4'h0;
	for (ii=1; ii<`TEST_COUNT-1; ii=ii+1) begin
		while (pci_trdy_ni)	#30 ;
		b_ad = block[ii];
		#30 ;
	end
	while (pci_trdy_ni)	#30 ;
	b_frame_n = 1; b_ad = block[ii];
	#30 while (pci_trdy_ni)	#30 ;
	b_irdy_n = 1; ii=ii+1;
	#30 init = 1; b_idsel = 1;
	
	// Read back
	for (ii=0; ii<`TEST_COUNT; ii=ii+1) begin
		#30 mem = 1; write = 0; addr = base_ad | (ii << 2);
		#30 mem = 0;
		while (!ready)	#30 ;
		if (data_from != block[ii])
			$display ("@%8t: ERROR: Data read %x (@%x) should be %x",
				$time, data_from, addr, block[ii]);
		else
			$display ("From PCI: %x Mem[%0d]: %x", data_from, ii, block[ii]);
/*		else
			$display ("@%8t: Data read %x (@%x)",
				$time, data_from, addr);*/
		while (!idle)	#30 ;
	end
	#60 $display ("@%5t: Burst-writes/single-reads completed (%0d words)", $time, ii);
`endif	// __test_burst_write_single_reads
	
	
`ifdef __test_single_write_burst_reads
	// Turns out the current PCI Logic Core will assert STOP# if an
	// attempt is made to burst read.  :)
	
	// Write
	#30 while (!idle)	#30 ;
	bes_n = 4'h0; burst = 0;
	for (ii=0; ii<`TEST_COUNT; ii=ii+1) begin
		#30 mem = 1; write = 1; addr = base_ad | (ii << 2); data_to = block[ii];
		#30 mem = 0; write = 0;
		while (!idle)	#30 ;
	end
	
	// Burst Read
	// `gencmds' is a little gammy, so just bit-bang the xfer.
	#30 while (!idle)	#30 ;
	init = 0; b_idsel = 0;
	#30 b_frame_n = 0; b_ad = base_ad; b_cbe_n = 4'h6;
	#30 b_irdy_n = 0; b_ad = 32'bz; b_cbe_n = 4'bz;
	for (ii=1; ii<`TEST_COUNT-1; ii=ii+1) begin
		while (pci_trdy_ni)	#30 ;
		if (data_from != block[ii])
			$display ("@%8t: ERROR: Data read %x (@%x) should be %x",
				$time, data_from, addr, block[ii]);
		else
			$display ("From: %x Mem[%0d]: %x", data_from, ii, block[ii]);
		#30 ;
	end
	while (pci_trdy_ni)	#30 ;
	b_frame_n = 1;
	#30 while (pci_trdy_ni)	#30 ;
	if (data_from != block[ii])
		$display ("@%8t: ERROR: Data read %x (@%x) should be %x",
			$time, data_from, addr, block[ii]);
	b_irdy_n = 1; ii=ii+1;
	#30 init = 1; b_idsel = 1;
	
	#60 $display ("@%5t: Single-write/burst-reads completed (%0d words)", $time, ii);
`endif	// __test_single_write_burst_reads
	
	
	#60	done_o	= 1;
	$display ("@%5t: Test completed (%0d words)", $time, ii);
// 	#300	$finish;
end	// Init


// initial
// 	#3000	$finish;


always @(posedge pci_clk_i)
	if (!pci_rst_ni)	init	= 1;


wire	gen_frame_n, gen_irdy_n, gen_idsel;
wire	[3:0]	gen_cbe_n;
wire	[31:0]	gen_ad;

assign	#2 pci_frame_no	= init ? gen_frame_n	: b_frame_n;
wire	#2 gen_devsel_n	= init ? pci_devsel_ni	: 1'b1;
assign	#2 pci_irdy_no	= init ? gen_irdy_n	: b_irdy_n;
wire	#2 gen_trdy_n	= init ? pci_trdy_ni	: 1'b1;
wire	#2 gen_stop_n	= init ? pci_stop_ni	: 1'b1;
assign	#2 pci_idsel_o	= init ? gen_idsel	: b_idsel;
assign	#2 pci_cbe_no	= init ? gen_cbe_n	: b_cbe_n;
wire	gen_assert;
assign	#2 pci_ad_io	= init ? (gen_assert ? gen_ad : 'bz) : b_ad;


pci_gencmds PCIGEN0 (
	.pci_clk_i	(pci_clk_i),
	.pci_rst_ni	(pci_rst_ni),
	
	.cmd_cfg_i	(cfg),
	.cmd_io_i	(io),
	.cmd_mem_i	(mem),
	.cmd_write_i	(write),
	.cmd_burst_i	(burst),
	
	.cmd_idle_o	(idle),
	.cmd_write_o	(gen_assert),
	.cmd_full_o	(full),
	.cmd_ready_o	(ready),
	
	.cmd_addr_i	(addr),
	.cmd_bes_ni	(bes_n),
	.cmd_data_i	(data_to),
	.cmd_data_o	(data_from),
	
	.pci_frame_no	(gen_frame_n),
	.pci_devsel_ni	(gen_devsel_n),
	.pci_irdy_no	(gen_irdy_n),
	.pci_trdy_ni	(gen_trdy_n),
	.pci_stop_ni	(gen_stop_n),
	.pci_idsel_o	(gen_idsel),
	
	.pci_cbe_no	(gen_cbe_n),
	.pci_ad_i	(pci_ad_io),
	.pci_ad_o	(gen_ad)
);


initial begin : Setup_Mem
	for (ii=0; ii<`TEST_COUNT; ii=ii+1)
		block[ii]	= $random;
end	// Setup_Mem


endmodule	// pci_testblock
