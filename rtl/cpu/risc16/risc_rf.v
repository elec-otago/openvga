/***************************************************************************
 *                                                                         *
 *   risc_rf.v - Register file suitable for a RISC, 2 read, 1 write port.  *
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
module risc_rf_async #(
	parameter	WIDTH	= 16,
	parameter	DEPTH	= 4,
	parameter	WORDS	= 1 << DEPTH,
	parameter	MSB	= WIDTH - 1,
	parameter	ISB	= DEPTH - 1
) (
	input		clock_i,
	
	input	[ISB:0]	p0_idx_i,
	output	[MSB:0]	p0_dat_o,
	
	input	[ISB:0]	p1_idx_i,
	output	[MSB:0]	p1_dat_o,
	
	input		wr_en_i,
	input	[ISB:0]	wr_idx_i,
	input	[MSB:0]	wr_dat_i
);

reg	[MSB:0]	bank0 [WORDS-1:0];
reg	[MSB:0]	bank1 [WORDS-1:0];

assign	#2 p0_dat_o	= bank0[p0_idx_i];
assign	#2 p1_dat_o	= bank1[p1_idx_i];

integer	ii;
initial	for (ii=0; ii<WORDS; ii=ii+1) {bank1[ii], bank0[ii]}	= 0;

always @(posedge clock_i)
	if (wr_en_i) begin
		bank0[wr_idx_i]	<= #2 wr_dat_i;
		bank1[wr_idx_i]	<= #2 wr_dat_i;
	end

endmodule	// risc_rf_async
