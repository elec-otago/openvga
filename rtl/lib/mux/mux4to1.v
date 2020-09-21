/***************************************************************************
 *                                                                         *
 *   mux4to1.v - A simple combinatorial four-to-one multiplexer.           *
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
module mux4to1 #(
	parameter	WIDTH	= 16,
	parameter	MSB	= WIDTH - 1
) (
	input	[1:0]	sel_i,
	
	input	[MSB:0]	in0_i,
	input	[MSB:0]	in1_i,
	input	[MSB:0]	in2_i,
	input	[MSB:0]	in3_i,
	
	output	reg	[MSB:0]	out_o
);

always @*
	case (sel_i)
		2'b00:	out_o	<= #3 in0_i;
		2'b01:	out_o	<= #3 in1_i;
		2'b10:	out_o	<= #3 in2_i;
		2'b11:	out_o	<= #3 in3_i;
	endcase

endmodule	//	mux4to1
