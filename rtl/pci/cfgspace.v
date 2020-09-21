/***************************************************************************
 *                                                                         *
 *   cfgspace.v - A PCI configuration space module that requests a small   *
 *     block of memory mapped I/O space below the 1 MB real-mode limit.    *
 *                                                                         *
 *   Copyright (C) 2006 by Patrick Suggate                                 *
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

`timescale 1ns/100ps
module cfgspace (
	pci_clk_i,
	pci_rst_ni,
	
	pci_frame_ni,
	pci_devsel_no,
	pci_irdy_ni,
	pci_trdy_no,
	
	pci_cbe_ni,
	pci_ad_i,
	pci_ad_o,
	
	pci_idsel_i,
	
	active_o,
	selected_o,
	memen_o,
	addr_o
);

parameter	ADDRESS	= 12;
parameter	ASB	= 32 - ADDRESS - 1;

input	pci_clk_i;
input	pci_rst_ni;

input	pci_frame_ni;
output	pci_devsel_no;
input	pci_irdy_ni;
output	pci_trdy_no;

input	[3:0]	pci_cbe_ni;
input	[31:0]	pci_ad_i;
output	[31:0]	pci_ad_o;

input	pci_idsel_i;

output	active_o;
output	selected_o;
output	memen_o;
output	[ASB:0]	addr_o;	//	The configured address


parameter DEVICE_ID = 16'h9500;
//	parameter DEVICE_ID = 16'hDff0;
parameter VENDOR_ID = 16'h106d;		// Sequent!
parameter DEVICE_CLASS = 24'hFF0000;	// Misc
parameter DEVICE_REV = 8'h01;
parameter SUBSYSTEM_ID = 16'h0001;	// Card identifier
parameter SUBSYSTEM_VENDOR_ID = 16'hBEBE; // Card identifier
parameter DEVSEL_TIMING = 2'b00;	// Fast!


`define	PCI_CFGREAD	4'b1010
`define	PCI_CFGWRITE	4'b1011

//	High when at the beginning of a PCI configuration mode access.
wire	cfg_access	= (((pci_cbe_ni == `PCI_CFGREAD) || (pci_cbe_ni == `PCI_CFGWRITE)) && pci_idsel_i && pci_ad_i[1:0] == 2'b00);


`define	ST_PCICFGIDLE	2'b00
`define	ST_PCICFGREAD	2'b01
`define	ST_PCICFGWRITE	2'b10
reg	[1:0]	state	= `ST_PCICFGIDLE;
reg	active_o	= 0;
reg	selected_o	= 0;
reg	transfer;
always @(posedge pci_clk_i)
begin
	if (~pci_rst_ni)
	begin
		active_o	<= 0;
		selected_o	<= 0;
		state		<= `ST_PCICFGIDLE;
	end
	else
	begin
		case (state)
			
			`ST_PCICFGIDLE:
			begin
				transfer	<= 0;
				if (cfg_access && ~pci_frame_ni)
				begin
					selected_o	<= 1;
					if (pci_cbe_ni[0])
					begin
						state		<= `ST_PCICFGWRITE;
						active_o	<= 0;
					end
					else
					begin
						state		<= `ST_PCICFGREAD;
						active_o	<= 1;
					end
				end
				else
				begin
					selected_o	<= 0;
					active_o	<= 0;
				end
			end
			
			`ST_PCICFGREAD, `ST_PCICFGWRITE:
			begin
				transfer	<= 1;
				if (pci_frame_ni && ~pci_irdy_ni && transfer)	//	Last transfer
					state	<= `ST_PCICFGIDLE;
			end
			
		endcase
	end
end


reg	pci_devsel_no;
reg	pci_trdy_no;
always @(posedge pci_clk_i)
begin
	if (~pci_rst_ni)
	begin
		pci_devsel_no	<= 1;
		pci_trdy_no		<= 1;
	end
	else
	begin
		case (state)
			
			`ST_PCICFGREAD, `ST_PCICFGWRITE:
			begin
				if (pci_frame_ni && ~pci_irdy_ni && transfer)
				begin
					pci_devsel_no	<= 1;
					pci_trdy_no		<= 1;
				end
				else
					pci_trdy_no		<= 0;
			end
			
			`ST_PCICFGIDLE:
			begin
				pci_trdy_no	<= 1;
				if (cfg_access && ~pci_frame_ni)
					pci_devsel_no	<= 0;
			end
			
		endcase
	end
end


reg		[5:0]	address;
always @(posedge pci_clk_i)
begin
	case (state)
		
		`ST_PCICFGREAD, `ST_PCICFGWRITE:
		begin
			if (~pci_irdy_ni && transfer)
				address	<= address + 1;
		end
		
		`ST_PCICFGIDLE:
		begin
			if (cfg_access && ~pci_frame_ni)
				address	<= pci_ad_i[7:2];
		end
		
	endcase
end


reg	[31:0]	pci_ad_o	= 0;
reg	[ASB:0]	baseaddr	= 0;
reg	memen_o	= 0;
always @(posedge pci_clk_i)
begin
	if (~pci_rst_ni)
	begin
		baseaddr	<= 0;
		memen_o		<= 0;
	end
	else
	case (state)
	
	`ST_PCICFGREAD:
	begin
		case (address)
		0:	pci_ad_o	<= { DEVICE_ID, VENDOR_ID };
		1:	pci_ad_o	<= { 5'b0, DEVSEL_TIMING, 9'b0,  14'b0, memen_o, 1'b0};
		2:	pci_ad_o	<= { DEVICE_CLASS, DEVICE_REV };
		4:	pci_ad_o	<= { baseaddr, {ADDRESS{1'b0}} };
// 		4:	pci_ad_o	<= { baseaddr, 8'b0, 4'b0000 };	// 4kB
		11:	pci_ad_o	<= {SUBSYSTEM_ID, SUBSYSTEM_VENDOR_ID };
// 		16:	pci_ad_o	<= { 12'b0, baseaddr };	// What's this for?!
		16:	pci_ad_o	<= { {ADDRESS{1'b0}}, baseaddr };
		default: pci_ad_o	<= 32'h0000_0000;
		endcase
	end
	
	// FIXME: Should byte enables be considered?
	`ST_PCICFGWRITE:
	begin
		case (address)
		4: baseaddr	<= pci_ad_i [31:ADDRESS];  // XXX examine pci_cbe_n
		1: memen_o	<= pci_ad_i [1];
		default:;
		endcase
	end
	
	default:;
	
	endcase
end


assign	addr_o	= baseaddr;


/*	wire	[31:0]	pci_adz	= active_o ? pci_ad_o : pci_ad_i;
	initial begin : Monitor
		$display ("Time CLK RST# FRAME# DEVSEL# IRDY# TRDY# C/BE# AD IDSEL active memen addr");
		$monitor ("%5t  %b  %b   %b     %b      %b    %b    %b    %h %b    %b     %b    %h",
			$time, pci_clk_i, pci_rst_ni,
			pci_frame_ni, pci_devsel_no, pci_irdy_ni, pci_trdy_no, pci_cbe_ni, pci_adz, pci_idsel_i,
			active_o, memen_o, addr_o
		);
	end
	*/
	
endmodule	// cfgspace
