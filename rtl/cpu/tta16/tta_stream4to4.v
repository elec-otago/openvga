/***************************************************************************
 *                                                                         *
 *   tta_stream4to4_async.v - An asynchronous TTA inputs to outputs MUX,   *
 *     and source and destination selects unit.                            *
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
module tta_stream4to4_async #(
	parameter	WIDTH	= 18,
	parameter	MSB	= WIDTH - 1
) (
	input		enable_i,
	
	input	[1:0]	src_i,
	input	[1:0]	dst_i,
	
	input	[MSB:0]	data0_i,
	input	[MSB:0]	data1_i,
	input	[MSB:0]	data2_i,
	input	[MSB:0]	data3_i,
	
	output	reg [3:0]	srcsels_o,
	output	reg [3:0]	dstsels_o,
	output	reg [1:0]	dstpack_o,
	output	reg [MSB:0]	data_o
);


always @* begin
	case (src_i)
	0:	srcsels_o	<= #1 1;
	1:	srcsels_o	<= #1 2;
	2:	srcsels_o	<= #1 4;
	3:	srcsels_o	<= #1 8;
	endcase
	
	case (src_i)
	0:	data_o		<= #1 data0_i;
	1:	data_o		<= #1 data1_i;	
	2:	data_o		<= #1 data2_i;
	3:	data_o		<= #1 data3_i;
	endcase
	
	case (dst_i)
	0:	dstsels_o	<= #1 1;
	1:	dstsels_o	<= #1 2;
	2:	dstsels_o	<= #1 4;
	3:	dstsels_o	<= #1 8;
	endcase
end


endmodule	// tta_stream4to4_async


module tta_stream4to4_sync #(
	parameter	WIDTH	= 18,
	parameter	MSB	= WIDTH - 1,
	parameter	ENCLR	= 1
) (
	input		clock_i,
	input		enable_i,
	
	input	[1:0]	src_i,
	input	[1:0]	dst_i,
	
	input	[MSB:0]	data0_i,
	input	[MSB:0]	data1_i,
	input	[MSB:0]	data2_i,
	input	[MSB:0]	data3_i,
	
	output	reg [3:0]	srcsels_o,
	output	reg [3:0]	dstsels_o,
	output	reg [1:0]	dstpack_o,
	output	reg [MSB:0]	data_o
);


always @(posedge clock_i)
	if (enable_i) begin
		case (src_i)
		0:	srcsels_o	<= #1 1;
		1:	srcsels_o	<= #1 2;
		2:	srcsels_o	<= #1 4;
		3:	srcsels_o	<= #1 8;
		endcase
		
		case (src_i)
		0:	data_o		<= #1 data0_i;
		1:	data_o		<= #1 data1_i;	
		2:	data_o		<= #1 data2_i;
		3:	data_o		<= #1 data3_i;
		endcase
		
		case (dst_i)
		0:	dstsels_o	<= #1 1;
		1:	dstsels_o	<= #1 2;
		2:	dstsels_o	<= #1 4;
		3:	dstsels_o	<= #1 8;
		endcase
		
		dstpack_o	<= #2 dst_i;
	end else begin
		srcsels_o	<= #2 ENCLR ? 0 : srcsels_o;
		dstsels_o	<= #2 ENCLR ? 0 : dstsels_o;
		dstpack_o	<= #2 ENCLR ? 0 : dstpack_o;
	end


endmodule	// tta_stream4to4_sync
