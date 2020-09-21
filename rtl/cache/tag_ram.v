/***************************************************************************
 *                                                                         *
 *   tag_ram.v - Does what it says on the tin.                             *
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
module tag_ram #(
	parameter	TWIDTH	= 16,
	parameter	IBITS	= 4,
	parameter	ISIZE	= (1<<IBITS),
	parameter	TSB	= TWIDTH - 1,
	parameter	ISB	= IBITS - 1
) (
	input		clock_i,
	input		reset_i,
	
	input		u_write_i,
	input		u_bank_i,
	input	[TSB:0]	u_data_i,
	
	input	[ISB:0]	index_i,
	
	output	[TSB:0]	tag0_o,
	output		vld0_o,
	output	[TSB:0]	tag1_o,
	output		vld1_o
);

// Two sinlge-port distributed RAM blocks.
reg	[TSB:0]	tags0	[ISIZE-1:0];
reg	[TSB:0]	tags1	[ISIZE-1:0];
// reg		vlds0	[ISIZE-1:0];
// reg		vlds1	[ISIZE-1:0];

// TODO: Why do I need to do this? Is XST or me doing something stupid?
wire	#2 wr_vlds0	= reset_i || (u_write_i && !u_bank_i);
wire	#2 valid	= ~reset_i;
RAM16X1S VLDS0 (
	.A0	(index_i[0]),
	.A1	(index_i[1]),
	.A2	(index_i[2]),
	.A3	(index_i[3]),
	.O	(vld0_o),
	.WCLK	(clock_i),
	.WE	(wr_vlds0),
	.D	(valid)
);

wire	#2 wr_vlds1	= reset_i || (u_write_i && u_bank_i);
RAM16X1S VLDS1 (
	.A0	(index_i[0]),
	.A1	(index_i[1]),
	.A2	(index_i[2]),
	.A3	(index_i[3]),
	.O	(vld1_o),
	.WCLK	(clock_i),
	.WE	(wr_vlds1),
	.D	(valid)
);

assign	#2 tag0_o	= tags0[index_i];
assign	#2 tag1_o	= tags1[index_i];

// assign	#2 vld0_o	= vlds0[index_i];
// assign	#2 vld1_o	= vlds1[index_i];

always @(posedge clock_i)
	if (u_write_i && !u_bank_i)
		tags0[index_i]	<= #2 u_data_i;

always @(posedge clock_i)
	if (u_write_i && u_bank_i)
		tags1[index_i]	<= #2 u_data_i;
/*
always @(posedge clock_i)
	if (reset_i)	vlds0[index_i]	<= #2 0;
	else if (u_write_i && !u_bank_i) begin
		tags0[index_i]	<= #2 u_data_i;
		vlds0[index_i]	<= #2 1'b1;
	end

always @(posedge clock_i)
	if (reset_i)	vlds1[index_i]	<= #2 0;
	else if (u_write_i && u_bank_i) begin
		tags1[index_i]	<= #2 u_data_i;
		vlds1[index_i]	<= #2 1'b1;
	end
*/

integer	ii;
initial begin : Init
	for (ii=0; ii<ISIZE; ii=ii+1)
		{tags1[ii], tags0[ii]}	<= # 2 0;
end	// Init

`ifdef __icarus
reg	prev_inco	= 1;
reg	[15:0]incoherent;
always @(posedge clock_i)
	if (u_write_i)
		incoherent[index_i]	<= #2 1'b1;
	else if (reset_i)
		incoherent[index_i]	<= #2 1'b0;

always @(posedge clock_i)
	if (u_write_i)	prev_inco	<= #2 1;
	else if (incoherent == 0 && prev_inco) begin
		$display ("%5t: Cache flushed.\n", $time);
		prev_inco	<= #2 0;
	end
`endif


endmodule	// tag_ram
