/***************************************************************************
 *                                                                         *
 *   pci_gencmds.v - Generates PCI commands that can be used as part of a  *
 *     PCI testbench. Supports burst transfers to/from memory.             *
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

// State machine state defines.
`define	PCIGEN_IDLE	3'b000
`define	PCIGEN_CFGRD	3'b110
`define	PCIGEN_CFGWR	3'b111
`define	PCIGEN_IORD	3'b010
`define	PCIGEN_IOWR	3'b011
`define	PCIGEN_MEMRD	3'b100
`define	PCIGEN_MEMWR	3'b101

`timescale 1ns/100ps
module pci_gencmds (
	pci_clk_i,
	pci_rst_ni,
	
	cmd_cfg_i,	// Only one of these three should be asserted
	cmd_io_i,
	cmd_mem_i,
	cmd_write_i,
	cmd_burst_i,
	
	cmd_idle_o,
	cmd_write_o,
	cmd_full_o,
	cmd_ready_o,
	
	cmd_addr_i,
	cmd_bes_ni,
	cmd_data_i,
	cmd_data_o,
	
	pci_frame_no,
	pci_devsel_ni,
	pci_irdy_no,
	pci_trdy_ni,
	pci_stop_ni,
	pci_idsel_o,
	
	pci_cbe_no,
	pci_ad_i,
	pci_ad_o
);

input	pci_clk_i;
input	pci_rst_ni;

// Commands from, and results for, the testbench.
input	cmd_cfg_i;	// Request config. space op.
input	cmd_io_i;	// Request I/O space op.
input	cmd_mem_i;	// Request memory op.
input	cmd_burst_i;	// Data to be written to next address is present
input	cmd_write_i;	// Requested PCI op. is to be a write

output	cmd_idle_o;
output	cmd_write_o;
output	cmd_full_o;	// Cannot take more data/addresses
output	cmd_ready_o;

input	[31:0]	cmd_addr_i;
input	[3:0]	cmd_bes_ni;
input	[31:0]	cmd_data_i;
output	[31:0]	cmd_data_o;

// PCI signals to/from the PCI target.
output	pci_frame_no;
input	pci_devsel_ni;
output	pci_irdy_no;
input	pci_trdy_ni;
input	pci_stop_ni;
output	pci_idsel_o;

output	[3:0]	pci_cbe_no;
input	[31:0]	pci_ad_i;
output	[31:0]	pci_ad_o;


reg	[2:0]	state	= `PCIGEN_IDLE;

reg	pci_frame_no	= 1;
reg	pci_irdy_no	= 1;
reg	pci_idsel_o	= 0;
reg	[3:0]	pci_cbe_no;

reg	cmd_ready_o	= 0;
reg	[31:0]	cmd_data_o;

// Registered command inputs.
reg	[31:0]	addr;
reg	[3:0]	bes_n;
reg	[31:0]	data;

reg	cmdstart	= 0;
wire	pcisend;

// FIFO status signals.
wire	more_data;
wire	fifo_full;

// Number of queued memory reads during a burst transfer.
reg	[31:0]	tpending	= 0;
wire	last_transfer;

// Burst byte enables and data.
wire	[3:0]	fifo_besn;
wire	[31:0]	fifo_data;

wire	#2 transfer	= (!pci_irdy_no && !pci_trdy_ni);
wire	#2 load_fifo	= (cmd_burst_i && (state == `PCIGEN_MEMWR));

reg	bursting	= 0;

wire	[31:0]	data_out;


assign	#2 cmd_idle_o	= (state == `PCIGEN_IDLE);
assign	cmd_write_o	= pcisend;
assign	#2 cmd_full_o	= fifo_full | (tpending > 2040);

assign	#2 last_transfer	= !cmd_burst_i && ((tpending == 2 && transfer) || (tpending == 1));

// Putting address/data on the PCI bus while this is high.
assign	#2 pcisend	= cmdstart | (state == `PCIGEN_CFGWR || state == `PCIGEN_IOWR || state == `PCIGEN_MEMWR);

// At the start of a command, place the address on the PCI bus since
// the data and address are multiplexed.
assign	#2 data_out	= cmdstart ? addr : data;

assign	#2 pci_ad_o	= pcisend ? data_out : 'bz;


always @(posedge pci_clk_i)
begin
	if (!pci_rst_ni)
		state	<= #2 `PCIGEN_IDLE;
	else
	begin
		case (state)
		
		`PCIGEN_IDLE:
		begin
			case ({cmd_mem_i, cmd_io_i, cmd_cfg_i})
			3'b000:	state	<= #2 `PCIGEN_IDLE;
			3'b001:	if (cmd_write_i)	state	<= #2 `PCIGEN_CFGWR;
				else			state	<= #2 `PCIGEN_CFGRD;
			3'b010:	if (cmd_write_i)	state	<= #2 `PCIGEN_IOWR;
				else			state	<= #2 `PCIGEN_IORD;
			3'b100:	if (cmd_write_i)	state	<= #2 `PCIGEN_MEMWR;
				else			state	<= #2 `PCIGEN_MEMRD;
			default:
				$display ("@%5t:  ERROR: Invalid command.", $time);
			endcase
		end
		
		`PCIGEN_MEMWR:
		begin
			if ((tpending == 1) && transfer && !cmd_burst_i)
				state	<= #2 `PCIGEN_IDLE;
/*			
			// After the FIFO has been emptied, return to IDLE.
			if (transfer && !more_data)
				state	<= `PCIGEN_IDLE;*/
		end
		
		`PCIGEN_MEMRD:
		begin
			if (((tpending == 1) && transfer && !cmd_burst_i) || !pci_stop_ni)
				state	<= #2 `PCIGEN_IDLE;
		end
		
		// Currently there are no burst transfers on config.
		// space and I/O operations.
		`PCIGEN_CFGWR, `PCIGEN_CFGRD, `PCIGEN_IOWR, `PCIGEN_IORD:
		begin
			// Transfer occurred, if so return to idle?
			if (transfer)
				state	<= #2 `PCIGEN_IDLE;
		end
		
		endcase
	end
end


// Generate the PCI commands, including the address.
always @(posedge pci_clk_i)
begin
	if (!pci_rst_ni) begin
		pci_frame_no	<= #2 1;
		pci_irdy_no	<= #2 1;
		pci_idsel_o	<= #2 0;
		
		cmdstart	<= #2 0;
		bursting	<= #2 0;
	end else begin
		case (state)
		`PCIGEN_IDLE: begin
			pci_frame_no	<= #2 ~(cmd_mem_i ^ cmd_io_i ^ cmd_cfg_i);
			pci_irdy_no	<= #2 1;
			pci_idsel_o	<= #2 cmd_cfg_i;
			
			addr	<= #2 cmd_addr_i;
			
			bursting	<= #2 0;
			cmdstart	<= #2 cmd_mem_i ^ cmd_io_i ^ cmd_cfg_i;
			
			case ({cmd_mem_i, cmd_io_i, cmd_cfg_i})
			3'b001:	pci_cbe_no	<= #2 {3'b101, cmd_write_i};
			3'b010:	pci_cbe_no	<= #2 {3'b001, cmd_write_i};
			3'b100:	pci_cbe_no	<= #2 {3'b011, cmd_write_i};
			default:
				pci_cbe_no	<= #2 'bx;
			endcase
		end
		
		`PCIGEN_CFGWR, `PCIGEN_CFGRD, `PCIGEN_IOWR, `PCIGEN_IORD: begin
			pci_idsel_o	<= #2 0;
// 			pci_irdy_no	<= ~transfer;
			pci_frame_no	<= #2 1;
			pci_irdy_no	<= #2 transfer;
			pci_cbe_no	<= #2 bes_n;
			cmdstart	<= #2 0; //pci_devsel_ni;
		end
		
		// Mem. ops are special since they support burst
		// transfers.
		`PCIGEN_MEMWR, `PCIGEN_MEMRD: begin
			if (transfer)
				addr	<= #2 addr + 1;
			
			if (cmd_burst_i)
				bursting	<= #2 1;
			
			// Last transfer pending.
			if (last_transfer || !pci_stop_ni)
				pci_frame_no	<= #2 1;
			
			if ((transfer && (tpending == 1) && !cmd_burst_i) || !pci_stop_ni)
				pci_irdy_no	<= #2 1;
			else
				pci_irdy_no	<= #2 0;
			
			cmdstart	<= #2 0; //pci_devsel_ni;
		end
		
		endcase
	end
end


// This handles the data flow.
always @(posedge pci_clk_i)
begin
	case (state)
	`PCIGEN_IDLE:
	begin
		data	<= #2 cmd_data_i;
		bes_n	<= #2 cmd_bes_ni;
		
		cmd_ready_o	<= #2 0;
		
		tpending	<= #2 cmd_mem_i;
	end
	
	`PCIGEN_IORD, `PCIGEN_CFGRD:
	begin
		if (transfer)
			cmd_data_o	<= #2 pci_ad_i;
		
		cmd_ready_o	<= #2 transfer;
	end
	
	`PCIGEN_MEMRD:
	begin
		// Byte enables are shared with the PCI command.
		pci_cbe_no	<= #2 bes_n;
		
		case ({cmd_burst_i, transfer})
		2'b10:	tpending	<= #2 tpending + 1;
		2'b01:	tpending	<= #2 tpending - 1;
		default:
			tpending	<= #2 tpending;
		endcase
		
		if (transfer)
			cmd_data_o	<= #2 pci_ad_i;
		
		cmd_ready_o	<= #2 transfer;
	end
	
	`PCIGEN_MEMWR:
	begin
		case ({cmd_burst_i, transfer})
		2'b10:	tpending	<= #2 tpending + 1;
		2'b01:	tpending	<= #2 tpending - 1;
		default:
			tpending	<= #2 tpending;
		endcase
		
		// If bursting, data output onto the PCI bus comes
		// from the FIFO, or else the data that was
		// registered at the start of the command is put onto
		// the bus.
		if (bursting && more_data && !pci_trdy_ni) begin
			data		<= #2 fifo_data;
			pci_cbe_no	<= #2 fifo_besn;
		end else if (!bursting)
			pci_cbe_no	<= #2 bes_n;
	end
	
	endcase
end


// Burst data is temporarily stored here until it is transferred
// across the PCI bus. This FIFO needs to be bigger than the FIFOs in
// the device being tested so that overflow cases can be tested.
wire	#2 read_fifo	= transfer && bursting;
wire	fempty;
assign	#2 more_data	= ~fempty;
sfifo2k #(
	.WIDTH	(36),
	.SIZE	(2048),
	.PWIDTH	(12)
) FIFO0 (
	.clock_i	(pci_clk_i),
	.reset_ni	(pci_rst_ni),
	
	.read_i		(read_fifo),
	.write_i	(load_fifo),
	.data_i		({cmd_bes_ni, cmd_data_i}),
	.data_o		({fifo_besn, fifo_data}),
	
	.full_ao	(fifo_full),
	.empty_ao	(fempty)
);


endmodule	// pci_gencmds
