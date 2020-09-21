/***************************************************************************
 *                                                                         *
 *   RAM16X1S.v - Emulates the functionality of the Xilinx primitive of the*
 *     same name. This a really poor partial implementation so do not use  *
 *     as it is only designed to do some very basic things.                *
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

`timescale 1ns / 100ps
module RAM16X1S(
	input	D,
	input	WE,
	input	WCLK,
	input	A0,
	input	A1,
	input	A2,
	input	A3,
	output	O
);

reg		dat	[15:0];
wire	[3:0]	addr	= {A0, A1, A2, A3};

assign	O	= dat[addr];

// Write incoming data to the RAM.
always @(posedge WCLK)
	if (WE)	dat[addr]	<= D;

integer	ii;
initial begin : Init
	for (ii=0; ii<16; ii=ii+1)
		dat[ii]	= 0;
end	// Init

endmodule	// RAM16X1S
