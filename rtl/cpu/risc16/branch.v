/***************************************************************************
 *                                                                         *
 *   branch.v - Updates the PC and by decoding the incoming instructions.  *
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

`include "defines.v"

`timescale 1ns/100ps
module branch #(
	parameter	INIT	= 0,
	parameter	ADDRESS	= 11,
	parameter	DELAYS	= 2,
	parameter	ASB	= ADDRESS - 1,
	parameter	DSB	= DELAYS - 1
) (
	input		clock_i,
	input		reset_i,
	input		enable_i,
	
	output	[ASB:0]	pc_prev_o,
	input	[ASB:0]	pc_next_i,
	input		b_rel_i,
	input		b_abs_i,
	input	[ASB:0]	addr_i,
	input	[2:0]	flags_i,	// {N, C, Z}
	input	[2:0]	cnd_i,
	output	branch_o,
	output	[ASB:0]	pc_ao
);

reg	[ASB:0]	pc	= INIT;
reg	[DSB:0]	branching	= 0;

wire	bra;

assign	pc_prev_o	= pc;
assign	#2 pc_ao	= bra ? addr_i : pc_next_i ;
assign	branch_o	= branching[DSB];

assign	#3 bra	= b_abs_i || (b_rel_i &&
		  ((cnd_i==`JNE && !flags_i[0]) ||	// Not Zero
		  (cnd_i==`JE && flags_i[0]) ||
		  (cnd_i==`JL && flags_i[2]) ||		// Neg
		  (cnd_i==`JG && !flags_i[2]) ||
		  (cnd_i==`JB && flags_i[1]) ||		// Carry
		  (cnd_i==`JBE && (flags_i[1] || flags_i[0])) ||
		  (cnd_i==`JA && (!flags_i[1] || !flags_i[0])) ||
		  (cnd_i==`JAE && !flags_i[1])));

// This causes the pipeline to throw away three instructions upon branch.
always @(posedge clock_i)
	if (reset_i)
		branching	<= #2 0;
	else if (enable_i) begin
		if (bra && !branching[DSB])
			branching	<= #2 {DELAYS{1'b1}};
		else
			branching	<= #2 {branching[DSB-1:0], 1'b0};
	end
// 	else begin
// 		if (bra && !branching[DSB])
// 			branching	<= #2 {DELAYS{1'b1}};
// 		else
// 			branching	<= #2 {branching[DSB-1:0], 1'b0};
// 	end

always @(posedge clock_i)
	if (reset_i)
		pc	<= #2 INIT;
	else if (enable_i)
		pc	<= #2 pc_ao;

endmodule	// branch
