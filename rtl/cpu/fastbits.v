/***************************************************************************
 *                                                                         *
 *   fastbits.v - Performs logical bitwise operations, and sets the zero   *
 *     flag, using just 17 LUTs.                                           *
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
module fastbits #(
	parameter	WIDTH	= 16,
	parameter	MSB	= WIDTH - 1
) (
	input	[MSB:0]	a_i,
	input	[MSB:0]	b_i,
	input	[1:0]	m_i,
	output	[MSB:0]	b_no,
	output		z_o
);

wire	[WIDTH:0]	c;

assign	c[0]	= 1'b1;
assign	z_o	= c[WIDTH];

genvar	ii;
generate
for (ii=0; ii<WIDTH; ii=ii+1)
begin : FASTBITS
	single_bit SB (
		.a_i	(a_i[ii]),
		.b_i	(b_i[ii]),
		.c_i	(c[ii]),
		.m_i	(m_i),
		.b_no	(b_no[ii]),
		.c_o	(c[ii+1])
	);
end	// FASTBITS
endgenerate

endmodule	// fastbits

// This should fit with a single LE of a Spartan III.
module single_bit (
	input		a_i,
	input		b_i,
	input		c_i,
	input	[1:0]	m_i,
	output		b_no,
	output		c_o
);

assign	b_no	= m_i[1] ? (m_i[0] ? ~(a_i ^ b_i) : ~(a_i | b_i)) :	// XNOR : NOR
			   (m_i[0] ? (a_i & b_i) : ~(a_i & b_i)) ;	// AND : NAND
// assign	c_o	= b_no ? c_i : 1'b0 ;

MUXCY MUXCY (
	.DI	(1'b0),
	.CI	(c_i),
	.S	(b_no),
	.O	(c_o)
);

endmodule	// single_bit
