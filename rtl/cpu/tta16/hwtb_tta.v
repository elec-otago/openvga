/***************************************************************************
 *                                                                         *
 *   hwtb_tta.v - Run some instructions, and flash an LED, to show that it *
 *     actually sorta works!                                               *
 *                                                                         *
 *   Copyright (C) 2008 by Patrick Suggate                                 *
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

`define	__use_TTA

`timescale 1ns/100ps
module hwtb_tta #(
	parameter	HIGHZ	= 0,
	parameter	ADDRESS	= 25,
	parameter	CWIDTH	= 16,
	parameter	WWIDTH	= 32,
	parameter	BSIZE	= 9,	// BRAM size (2^BSIZE entries at WWDITH)
	parameter	PCBITS	= 10,
	parameter	ENABLES	= CWIDTH / 8,
	parameter	SELECTS	= WWIDTH / 8,
	parameter	MSB	= CWIDTH - 1,
	parameter	WSB	= WWIDTH - 1,
	parameter	ASB	= ADDRESS - 1,
	parameter	ESB	= ENABLES - 1,
	parameter	SSB	= SELECTS - 1
) (
	input		clk50,	// Dual (but syncronous) clocks
	input		pci_rst_n,
	output	[1:0]	leds
);


wire	cpu_cyc, cpu_stb, cpu_we, cpu_ack, cpu_rty, cpu_err;
wire	[2:0]	cpu_cti;
wire	[1:0]	cpu_bte;
wire	[ASB:0]	cpu_adr;
wire	[ESB:0]	cpu_sel_t, cpu_sel_f;
wire	[MSB:0]	cpu_dat_t, cpu_dat_f;


`ifdef __use_TTA
tta16 #(
`else
risc16 #(
`endif
	.HIGHZ		(0),
	.WIDTH		(CWIDTH),
`ifdef __use_TTA
	.INSTR		(WWIDTH),
`else
	.INSTR		(CWIDTH),
`endif
	.ADDRESS	(ADDRESS),
	.PCBITS		(PCBITS),
	.PCINIT		(1),
	.WBBITS		(CWIDTH)
) CPU (
	.cpu_clk_i	(clk50),
	.cpu_rst_i	(~pci_rst_n),
	
	.wb_clk_i	(clk50),	// 16-bit CPU-to-cache WB interface
	.wb_rst_i	(~pci_rst_n),
	.wb_cyc_o	(cpu_cyc),
	.wb_stb_o	(cpu_stb),
	.wb_we_o	(cpu_we),
	.wb_ack_i	(cpu_ack),
	.wb_rty_i	(cpu_rty),
	.wb_err_i	(cpu_err),
	.wb_cti_o	(cpu_cti),
	.wb_bte_o	(cpu_bte),
	.wb_adr_o	(cpu_adr),
	.wb_sel_o	(cpu_sel_t),
	.wb_dat_o	(cpu_dat_t),
	.wb_sel_i	(cpu_sel_f),
	.wb_dat_i	(cpu_dat_f)
);


wire	[MSB-2:0]	x_filler;
wb_leds #(
	.HIGHZ		(HIGHZ),
	.WIDTH		(CWIDTH),
	.LEDS		(2)
) LEDS (
	.wb_clk_i	(clk50),
	.wb_rst_i	(~pci_rst_n),
	
	.wb_cyc_i	(cpu_cyc),
	.wb_stb_i	(cpu_stb),
	.wb_we_i	(cpu_we),
	.wb_ack_o	(cpu_ack),
	.wb_rty_o	(cpu_rty),
	.wb_err_o	(cpu_err),
	.wb_sel_i	(cpu_sel_t),
	.wb_dat_i	(cpu_dat_t),
	.wb_sel_o	(cpu_sel_f),
	.wb_dat_o	(cpu_dat_f),
	
	.leds_o		({x_filler, leds})
);	// wb_leds


endmodule	// hwtb_tta
