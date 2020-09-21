/***************************************************************************
 *                                                                         *
 *   pci_stresstest.v - Runs through a series of tests to test the         *
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

// `define	TEST_COUNT	1024
// `define	TEST_COUNT	256
// `define	TEST_COUNT	128
// `define	TEST_COUNT	64
// `define	TEST_COUNT	32
`define	TEST_COUNT	16


// TODO: This may have to be synthesized. Make sure all the RTL is
// synthesizable.
`timescale 1ns/100ps
module pci_stresstest (
	pci_clk_i,
	pci_rst_ni,
	
	start_i,
	done_o,
	
	pci_frame_no,
	pci_devsel_ni,
	pci_irdy_no,
	pci_trdy_ni,
	pci_stop_ni,
	pci_idsel_o,
	pci_cbe_no,
	pci_ad_io
);

input	pci_clk_i;
input	pci_rst_ni;

input	start_i;
output	done_o;

output	pci_frame_no;
input	pci_devsel_ni;
output	pci_irdy_no;
input	pci_trdy_ni;
input	pci_stop_ni;
output	pci_idsel_o;
output	[3:0]	pci_cbe_no;
inout	[31:0]	pci_ad_io;


`define	STST_IDLE	4'b0000
`define	STST_START	4'b0001
`define	STST_SEQ_RW	4'b1000
`define	STST_SEQ_RD	4'b1001
`define	STST_SEQ_WR	4'b1010
`define	STST_SLOW_RW	4'b0010
`define	STST_FAST_RW	4'b0011
`define	STST_BURST_W	4'b0100
`define	STST_BURST_R	4'b0101
`define	STST_BURST_RW	4'b0110
`define	STST_RAND_RW	4'b0111
reg	[3:0]	state	= `STST_IDLE;

reg	cfg	= 0;
reg	io	= 0;
reg	mem	= 0;
reg	write	= 0;
reg	burst	= 0;

reg	[31:0]	addr;
reg	[3:0]	bes_n;
reg	[31:0]	data_to;

reg	[2:0]	cfg_state	= 0;

integer	count	= 0;
reg	read_done	= 1;
reg	[31:0]	randn;

reg	done_o	= 0;

wire	idle;
wire	full;
wire	ready;
wire	frame_n;
wire	irdy_n;
wire	idsel;
wire	[3:0]	cbe_n;
wire	[31:0]	adz;
wire	[31:0]	data_from;

wire	busy	= (state != `STST_IDLE);
wire	pci_frame_no	= busy ? frame_n : 'bz;
wire	devsel_n	= busy ? pci_devsel_ni : 'bz;
wire	pci_irdy_no	= busy ? irdy_n : 'bz;
wire	trdy_n		= busy ? pci_trdy_ni : 'bz;
wire	pci_idsel_o	= busy ? idsel : 'bz;

wire	pciidle		= idle && !cfg && !mem && !io;


assign	pci_cbe_no	= busy ? cbe_n : 'bz;
// assign	pci_ad_io	= busy ? adz : 'bz;
// assign	adz		= busy ? pci_ad_io : 'bz;


always @(posedge pci_clk_i)
	randn	<= $random;


reg	burst_rd_xfer	= 0;
always @(posedge pci_clk_i)
	if (!pci_rst_ni)
		burst_rd_xfer	<= #2 0;
	else if (state == `STST_BURST_R && !pci_irdy_no && !pci_trdy_ni)
		burst_rd_xfer	<= #2 1;
	else
		burst_rd_xfer	<= #2 0;


always @(posedge pci_clk_i)
begin
	if (!pci_rst_ni)
	begin
		state	<= `STST_IDLE;
		done_o	<= 0;
		
		cfg	<= 0;
		io	<= 0;
		mem	<= 0;
		write	<= 0;
	end
	else
	case (state)
	
	`STST_IDLE: begin
		if (start_i)
		begin
			state	<= `STST_START;
			done_o	<= 0;
		end
	end
	
	// Initialise the device using configuration-space accesses.
	`STST_START: begin
		if (pciidle)
		begin
			if (state < 15)
				cfg_state	<= cfg_state + 1;
			
			case (cfg_state)
			
			0: begin	// Read device ID
				cfg	<= 1;
				addr	<= 0;
			end
			
			1: begin	// Set Base Address Register (BAR)
				cfg	<= 1;
				write	<= 1;
				addr	<= 'h10;
				data_to	<= 32'h0100_0000;
				bes_n	<= 0;
			end
			
			2: begin	// Read back the BAR
				cfg	<= 1;
				addr	<= 'h10;
			end
			
			3: begin	// Enable the MMIO
				cfg	<= 1;
				write	<= 1;
				addr	<= 32'h0_0004;
				data_to	<= 32'h0000_0002;
			end
			
			default: begin
// 				state	<= `STST_BURST_W;
				state	<= `STST_SEQ_WR;
				read_done	<= 1;
				addr	<= #2 32'h0100_0000;
				bes_n	<= #2 4'h7;
// 				bes_n	<= #2 4'b0011;
				count	<= 0;
			end
			
			endcase
		end
		else
		begin
			cfg	<= 0;
			io	<= 0;
			mem	<= 0;
			write	<= 0;
		end
	end
	
	// Burst write 16 values, then read 'em back.
	`STST_BURST_W: begin
		if (pciidle && count < `TEST_COUNT) begin
			mem	<= 1;
			burst	<= 1;
			write	<= 1;
			bes_n	<= 0;
			data_to	<= count;
/*			bes_n	<= {bes_n [2:0], bes_n [3]};
			data_to	<= {count [7:0], count [7:0], count [7:0], count [7:0]};*/
			count	<= count + 1;
		end else if (count < `TEST_COUNT) begin
			mem	<= 0;
			if (!full) begin
				bes_n	<= 0;
				data_to	<= count;
				count	<= count + 1;
/*				bes_n	<= {bes_n [2:0], bes_n [3]};
				data_to	<= {count [7:0], count [7:0], count [7:0], count [7:0]};*/
			end
		end else begin
			write	<= 0;
			burst	<= 0;
			count	<= 0;
			read_done	<= 0;
// 			state	<= `STST_BURST_R;
			state	<= `STST_SEQ_RD;
		end
	end
	
	// Burst write 16 values, then read 'em back.
	`STST_BURST_R: begin
		count	<= count + (burst_rd_xfer && read_done);
		
		if (pciidle && count < `TEST_COUNT) begin
			read_done	<= 1;
			mem	<= 1;
			burst	<= 1;
			bes_n	<= 0;
		end else if (count == `TEST_COUNT) begin
			count	<= 0;
			burst	<= 0;
			done_o	<= 1;
			state	<= #60 `STST_IDLE;
		end else begin
			mem	<= 0;
			write	<= 0;
		end
	end
	
	// Test single writes and reads to random locations.
	`STST_SEQ_WR: begin
		// Perform 100 single reads and writes
		if (count < `TEST_COUNT) begin
			if (pciidle) begin
				mem	<= 1;
				write	<= 1;
				bes_n	<= ~bes_n;
				bes_n	<= {bes_n [2:0], bes_n [3]};
// 				data_to	<= $random;
// 				data_to	<= {addr [15:0], addr [15:0]};
				data_to	<= {4{addr [7:0]}};
				count	<= count + 1;
			end else begin
				mem	<= 0;
				write	<= 0;
				if (mem) addr [11:0]	<= addr [11:0] + 1;
			end
		end
		else
		begin
			count	<= 0;
// 			read_done	<= 1;
			addr [11:0]	<= 12'hFFC;
			state	<= `STST_SEQ_RD;
// 			done_o	<= #600 1;
		end
	end
	
	// Test single writes and reads to random locations.
	`STST_SEQ_RD: begin
		// Perform 100 single reads and writes
		if (count < `TEST_COUNT + 1) begin
// 		if (count < `TEST_COUNT/4 + 1) begin
			if (pciidle) begin
				mem	<= 1;
				bes_n	<= {bes_n [2:0], bes_n [3]};
				count	<= count + 1;
			end else begin
				mem	<= 0;
				write	<= 0;
				if (mem) addr [11:0]	<= addr [11:0] + 4;
			end
		end
		else
		begin
			count	<= 0;
			read_done	<= 1;
			state	<= `STST_IDLE;
			done_o	<= #600 1;
		end
	end
	
	// Test single writes and reads to random locations.
	`STST_SEQ_RW: begin
		// Perform 100 single reads and writes
		if (count < `TEST_COUNT)
		begin
			if (pciidle && read_done)
			begin
				mem	<= 1;
				addr	<= addr + 1;
				data_to	<= $random;
				bes_n	<= {bes_n [2:0], bes_n [3]};
				write	<= 1;
				read_done	<= 0;
			end
			else if (pciidle)
			begin
				// Use the same address for the read.
				// TODO: Check the return values.
				mem	<= 1;
				read_done	<= 1;
				count	<= count + 1;
			end
			else
			begin
				mem	<= 0;
				write	<= 0;
			end
		end
		else
		begin
			count	<= 0;
			read_done	<= 1;
			state	<= `STST_FAST_RW;
		end
	end
	
	// Test single writes and reads to random locations.
	`STST_SLOW_RW: begin
		// Perform 100 single reads and writes
		if (count < `TEST_COUNT)
		begin
			if (pciidle && read_done)
			begin
				mem	<= 1;
// 				addr	<= {22'h0003_20, randn [9:0]};
				data_to	<= $random;
				bes_n	<= 0;//$random;
				write	<= 1;
				read_done	<= 0;
			end
			else if (pciidle)
			begin
				// Use the same address for the read.
				// TODO: Check the return values.
				mem	<= 1;
				read_done	<= 1;
				count	<= count + 1;
			end
			else
			begin
				if (mem && read_done)	addr	<= addr + 4;
				
				mem	<= 0;
				write	<= 0;
			end
		end
		else
		begin
			count	<= 0;
			read_done	<= 1;
			state	<= `STST_FAST_RW;
		end
	end
	
	`STST_FAST_RW: begin
		// Perform 100 back-to-back read/writes.
		if (count < `TEST_COUNT)
		begin
			// At the end of the last transfer, start a new write
			// straight away.
			if (!trdy_n && !devsel_n && frame_n)
			begin
				if (read_done)
				begin
					mem	<= 1;
					addr	<= {22'h0003_20, randn [9:0]};
					data_to	<= $random;
					bes_n	<= $random;
					write	<= 1;
					read_done	<= 0;
				end
				else
				begin
					mem	<= 1;
					read_done	<= 1;
					count	<= count + 1;
				end
			end
			else
			begin
				mem	<= 0;
				write	<= 0;
			end
		end
		else
		begin
			state	<= `STST_IDLE;
			done_o	<= 1;
		end
	end
	
	endcase
end


reg	reading	= 0;
reg	writing	= 0;
reg	[31:0]	pciaddr	= 0;
reg	prev_idle	= 0;
always @(posedge pci_clk_i)
	prev_idle	<= pciidle;

always @(posedge pci_clk_i)
	if (mem && prev_idle) begin
		writing	<= write;
		reading	<= ~write;
		pciaddr	<= addr;
	end else if (pciidle)
		{writing, reading}	<= 0;


always @(posedge pci_clk_i)
	if (!pci_irdy_no && !pci_trdy_ni) begin
		if (writing)
			$display ("@t=%8t: Writing %8x to %8x", $time, pci_ad_io, pciaddr);
		else if (reading)
			$display ("@t=%8t: Reading %8x from %8x", $time, pci_ad_io, pciaddr);
		pciaddr	<= pciaddr + 4;
	end

/*
reg	[31:0]	prev_data	= 32'hFFFF_FFFF;
wire	[31:0]	next_data	= prev_data + 1;
always @(posedge pci_clk_i)
	if (!pci_irdy_no && !pci_trdy_ni && reading) begin
		if (pci_ad_io != next_data)
			$display ("@t=%8t: ERROR: Reading %8x from %8x", $time, pci_ad_io, pciaddr);
		pciaddr	<= pciaddr + 4;
		prev_data	<= pci_ad_io;
	end
*/

/*
always @(posedge pci_clk_i)
	if (pciidle && (data_from != 32'hFFFF_FFFF) && (addr > 32'h000C_8000) && (state == `STST_SEQ_RD)) begin
		$display ("%7t: ERROR: Data doesn't match at address: %x", $time, addr);
		#100
		$finish;
	end
*/

pci_gencmds PCIGEN0 (
	.pci_clk_i	(pci_clk_i),
	.pci_rst_ni	(pci_rst_ni),
	
	.cmd_cfg_i	(cfg),
	.cmd_io_i	(io),
	.cmd_mem_i	(mem),
	.cmd_write_i	(write),
	.cmd_burst_i	(burst),
	
	.cmd_idle_o	(idle),
	.cmd_full_o	(full),
	.cmd_ready_o	(ready),
	
	.cmd_addr_i	(addr),
	.cmd_bes_ni	(bes_n),
	.cmd_data_i	(data_to),
	.cmd_data_o	(data_from),
	
	.pci_frame_no	(frame_n),
	.pci_devsel_ni	(devsel_n),
	.pci_irdy_no	(irdy_n),
	.pci_trdy_ni	(trdy_n),
	.pci_stop_ni	(pci_stop_ni),
	.pci_idsel_o	(idsel),
	
	.pci_cbe_no	(cbe_n),
	.pci_ad_io	(pci_ad_io)
);


endmodule	// pci_stresstest
