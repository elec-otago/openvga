/***************************************************************************
 *                                                                         *
 *   vga16.v - Drives a VGA monitor in 16-bit mode.                        *
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

`timescale 1ns/100ps
module vga16 (
	input		clk_i,
	input		rst_i,
	
	input		hsync_i,
	input		vsync_i,
	input		hblank_i,
	input		vblank_i,
	input		de_i,
	output		read_o,
	input	[31:0]	data_i,
	
	output	reg	[7:0]	r_o,
	output	reg	[7:0]	g_o,
	output	reg	[7:0]	b_o,
	output	reg	vsync_o	= 1,
	output	reg	hsync_o	= 1,
	output	reg	de_o	= 0
);


reg	[15:0]	upper_word;
reg		odd	= 1;


// assign	addr_o [ASB:FBSIZE]	= FBOFF;
assign	#2 read_o	= (de_i && odd);


// Make sure all output signals are free from combinatorial delays and
// therefore in phase.
always @(posedge clk_i)
	if (rst_i)
		{hsync_o, vsync_o, de_o}	<= #2 3'b110;
	else begin
		hsync_o	<= #2 hsync_i;
		vsync_o	<= #2 vsync_i;
		de_o	<= #2 de_i;
	end


//---------------------------------------------------------------------------
//  Display DATAPATH:
//	The memory controller fetches data with a width of 32-bits, but the
//	display uses 16-bit colour data.
always @(posedge clk_i)
	if (rst_i)		odd	<= #2 0;
	else if (hsync_i)	odd	<= #2 0;
	else if (de_i)		odd	<= #2 ~odd;

always @(posedge clk_i)
	if (!odd)	upper_word	<= #2 data_i [31:16];

always @(posedge clk_i)
	if (hblank_i || vblank_i)
		{r_o, g_o, b_o}	<= #2 0;
	else begin
		b_o	<= #2 {odd ? upper_word [15:11] : data_i [15:11], 3'b000};
		g_o	<= #2 {odd ? upper_word [10:5] : data_i [10:5], 2'b00};
		r_o	<= #2 {odd ? upper_word [4:0] : data_i [4:0], 3'b000};
	end


endmodule	// vga16
