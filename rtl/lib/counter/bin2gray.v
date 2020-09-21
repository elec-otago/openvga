/***************************************************************************
 *                                                                         *
 *   bin2gray.v - Converts binary numbers of parameterizable width,        *
 *     `WIDTH', to gray encoded numbers.                                   *
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

// Where:
//	g_n	= b_n
//	g_i	= b_i ^ b_(i+1)        | i < n

`timescale 1ns/100ps
module bin2gray (
		bin_i,
		gray_o
	);
	
	parameter	WIDTH	= 4;
	
	input	[WIDTH-1:0]	bin_i;
	output	[WIDTH-1:0]	gray_o;
	
	wire	[WIDTH-2:0]	lower	= bin_i [WIDTH-2:0];
	wire	[WIDTH-2:0]	upper	= bin_i [WIDTH-1:1];
	wire	[WIDTH-2:0]	gray;
	
// `define	__nasty_hack
`ifdef	__nasty_hack
	// This version of Icarus doesn't like arrays of instances. :(
	bin2gray_digit B2G0 (
		.b0_i	(lower [0]),
		.b1_i	(upper [0]),
		.g_o	(gray [0])
	);
	
	bin2gray_digit B2G1 (
		.b0_i	(lower [1]),
		.b1_i	(upper [1]),
		.g_o	(gray [1])
	);
	
	bin2gray_digit B2G2 (
		.b0_i	(lower [2]),
		.b1_i	(upper [2]),
		.g_o	(gray [2])
	);
	
`else
	// Array of instances of digit conversions.
	bin2gray_digit B2G [WIDTH-2:0] (
		.b0_i	(lower),
		.b1_i	(upper),
		.g_o	(gray)
	);
`endif
	
	assign	gray_o	= {bin_i [WIDTH-1], gray};
	
endmodule	// bin2gray


// This is so an array-of-instances can be used.
module bin2gray_digit (
		b0_i,
		b1_i,
		g_o
	);
	
	input	b0_i;
	input	b1_i;
	output	g_o;
	
	assign	g_o	= b0_i ^ b1_i;
	
endmodule	// bin2gray_digit
