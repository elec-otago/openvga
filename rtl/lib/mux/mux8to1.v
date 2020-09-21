/***************************************************************************
 *                                                                         *
 *   mux8to1.v - A simple MUX with a bus-width which can be set using a    *
 *     `defparam' statement.                                               *
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
module mux8to1 (
		sel_i,
		
		data0_i,
		data1_i,
		data2_i,
		data3_i,
		data4_i,
		data5_i,
		data6_i,
		data7_i,
		
		data_o
	);
	
	parameter	WIDTH	= 8;
	
//	This doesn't work with Icarus Verilog's preprocessor (if it has one)?
//`define	MUX_DATA_MSB	WIDTH - 1
	
	input	[2:0]	sel_i;
	
	input	[WIDTH-1:0]	data0_i;
	input	[WIDTH-1:0]	data1_i;
	input	[WIDTH-1:0]	data2_i;
	input	[WIDTH-1:0]	data3_i;
	input	[WIDTH-1:0]	data4_i;
	input	[WIDTH-1:0]	data5_i;
	input	[WIDTH-1:0]	data6_i;
	input	[WIDTH-1:0]	data7_i;
	
	output	reg	[WIDTH-1:0]	data_o;
	
	always @(sel_i, data0_i, data1_i, data2_i, data3_i, data4_i, data5_i, data6_i, data7_i)
	begin
		case (sel_i)
			3'b000:	data_o	<= data0_i;
			3'b001:	data_o	<= data1_i;
			3'b010:	data_o	<= data2_i;
			3'b011:	data_o	<= data3_i;
			3'b100:	data_o	<= data4_i;
			3'b101:	data_o	<= data5_i;
			3'b110:	data_o	<= data6_i;
			3'b111:	data_o	<= data7_i;
		endcase
	end
	
endmodule	//	mux8to1
