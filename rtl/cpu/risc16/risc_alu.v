/***************************************************************************
 *                                                                         *
 *   risc_alu.v - A simple and extremely fast ALU suitable for a RISC CPU. *
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

// This is 200 MHz, on a Spartan III, capable.
// TODO: Should be only 34 LUTs?

`timescale 1ns/100ps
module risc_alu_sync #(
	parameter	WIDTH	= 16,
	parameter	MSB	= WIDTH - 1
) (
	input		clock_i,
	input		reset_i,
	input		stall_ni,
	
	input		sf_i,
	input		cf_i,
	input	[1:0]	bit_i,
	input	[MSB:0]	a_i,
	input	[MSB:0]	b_i,
	
	output	reg	[WIDTH*2-1:0]	prod_o,
	output	reg	[MSB:0]	bits_no,
	output	reg	[MSB:0]	diff_o,
	
	output	reg	zf_o	= 1,
	output	reg	cf_o	= 0,
	output	reg	nf_o	= 0
);

wire	zf;
wire	[MSB:0]	bits_n;
wire	[MSB+2:0]	diff;


assign	#3 diff	= {a_i, 1'b0} - {b_i, cf_i};
// assign	#3 diff	= {a_i, cf_i} - {b_i, 1'b1};	// TODO: These are equiv?


always @(posedge clock_i)
	if (stall_ni) begin
		prod_o	<= #3 a_i * b_i;
		diff_o	<= #2 diff[WIDTH:1];
		bits_no	<= #2 bits_n;
	end

always @(posedge clock_i)
	if (reset_i)	{cf_o, nf_o, zf_o}	<= #2 3'b001;
	else if (sf_i)	{cf_o, nf_o, zf_o}	<= #2 {diff[WIDTH+1:WIDTH], zf};


fastbits #(WIDTH) BITS (
	.a_i	(b_i),
	.b_i	(a_i),
	.m_i	(bit_i),
	.b_no	(bits_n),
	.z_o	(zf)
);


endmodule	// risc_alu_sync


module risc_alu_async #(
	parameter	WIDTH	= 16,
	parameter	MSB	= WIDTH - 1
) (
	input		cf_i,
	input	[1:0]	bit_i,
	input	[MSB:0]	a_i,
	input	[MSB:0]	b_i,
	
	output	[WIDTH*2-1:0]	prod_o,
	output	[MSB:0]	bits_no,
	output	[MSB:0]	diff_o,
	
	output	zf_o,
	output	cf_o,
	output	nf_o
);

wire	[MSB+2:0]	diff;

assign	diff	= {a_i, 1'b0} - {b_i, cf_i};
// assign	#3 diff	= {a_i, cf_i} - {b_i, 1'b1};	// TODO: These are equiv?

assign	#3 prod_o	= a_i * b_i;
assign	#3 diff_o	= diff[WIDTH:1];
assign	#3 {cf_o, nf_o}	= diff[WIDTH+1:WIDTH];

fastbits #(WIDTH) BITS (
	.a_i	(b_i),
	.b_i	(a_i),
	.m_i	(bit_i),
	.b_no	(bits_no),
	.z_o	(zf_o)
);

endmodule	// risc_alu_async
