/***************************************************************************
 *                                                                         *
 *   cache_bram.v - Cache memory stored in Xilinx Block RAMs.              *
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

// Very low-tech wrapper to allow using different port widths.
`timescale 1ns/100ps
module cache_bram (
	input		reset_i,
	
	input		u_clk_i,
	input		u_write_i,	// TODO: Add eviction support
	input	[8:0]	u_addr_i,
	input	[31:0]	u_data_i,
	
	input		l_clk_i,
	input	[9:0]	l_addr_i,
	input		l_write_i,
	input	[15:0]	l_data_i,	// TODO
	output	[15:0]	l_data_o
);

RAMB16_S18_S36 BRAM0 (
	.CLKA	(l_clk_i),
	.ENA	(1'b1),
	.SSRA	(1'b0),
	.WEA	(l_write_i),
	.ADDRA	(l_addr_i),
	.DOA	(l_data_o),
	.DIA	(l_data_i),
	.DIPA	(2'b11),
	
	.CLKB	(u_clk_i),
	.ENB	(1'b1),
	.SSRB	(1'b0),
	.WEB	(u_write_i),
	.ADDRB	(u_addr_i),
	.DIB	(u_data_i),
	.DIPB	(4'b1111)
);

endmodule	// cache_bram
