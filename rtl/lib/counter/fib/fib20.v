/***************************************************************************
 *                                                                         *
 *   fib20.v - A 20-bit Fibonacchi counter.                                *
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

`timescale 1ns/100ps
module fib20 (
	count_i,
	count_o
);

input	[19:0]	count_i;
output	[19:0]	count_o;

wire	[19:0]	b	= count_i;

assign	count_o[0]	= ~b[0] | b[1];
assign	count_o[1]	= (~b[0] & b[1] & ~b[2]) | (b[0] & ~b[1]);

// TODO: `generate' block here.
// TODO: Icarus bug?
/*
genvar	ii;
generate
for (ii=2; ii<18; ii=ii+1)
begin : Fib_bits
	bi FIBBIT(b[(ii-2)], b[(ii-1)], b[ii], b[ii+1], count_o[ii]);
end
endgenerate
*/

bi FIBBITS[17:2] (
	.b0	(b[15:0]),
	.b1	(b[16:1]),
	.b2	(b[17:2]),
	.b3	(b[18:3]),
	.bi	(count_o[17:2])
);


assign	count_o[18]	= (~b[19] & b[18] & ~b[17]) | (~b[18] & b[17] & b[16]);
assign	count_o[19]	= b[19] | (b[18] & b[17]);

endmodule	// fib20


module bi (b0, b1, b2, b3, bi);

input	b0, b1, b2, b3;
output	bi;

assign	bi	= (b0 & b1 & ~b2) | (~b1 & b2 & ~b3);

endmodule	// bi
