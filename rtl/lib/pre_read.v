/***************************************************************************
 *                                                                         *
 *   pre_read.v - Hides a cycle of latency when using a registered block   *
 *     RAM, like with a large synchronous FIFO.                            *
 *                                                                         *
 *   Copyright (C) 2009 by Patrick Suggate                                 *
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

// The goal is to keep the data on the outputs for the address one before the
// current input address, thereby pipelining the synchronous reading of the
// BRAM.

`timescale 1ns/100ps
module pre_read #(
	parameter	ADDRESS	= 1,
	parameter	INIT	= 0,
	parameter	ASB	= ADDRESS - 1
) (
	input		reset_i,
	
	input		a_clk_i,
	input		a_wr_i,
	
	input		b_clk_i,
	input		b_rd_i,
	output	[ASB:0]	b_cnt_o,
	output		b_en_ao,
	output	[ASB:0]	b_adr_ao
);

reg		primed	= 0;
reg	[ASB:0]	count	= 0;
reg	[ASB:0]	b_adr	= INIT - 1;
reg		oneshot	= 0;
reg		first	= 0;
reg		a_wr_r	= 0;

wire	#2 first_w	= !primed && a_wr_r;
wire	#2 empty_w	= (count == 0);
wire	#2 inc_ad	= first || ((count > 1) && b_rd_i);

assign	b_cnt_o		= count;
assign	#2 b_en_ao	= (b_rd_i && primed) || first;
assign	#3 b_adr_ao	= b_adr + 1;

// Clk B domain.
// TODO: Make synchronous?
always @(posedge b_clk_i or posedge a_wr_i)
	if (a_wr_i)	oneshot	<= #2 1;
	else		oneshot	<= #2 0;

always @(posedge b_clk_i)
	if (reset_i)			a_wr_r	<= #2 0;
	else if (oneshot && !a_wr_r)	a_wr_r	<= #2 1;
	else				a_wr_r	<= #2 0;
/*
always @(posedge b_clk_i)
	if (reset_i)	first	<= #2 0;
	else		first	<= #2 first_w;
*/
always @(posedge b_clk_i)
	if (reset_i)			count	<= #2 0;
	else if (a_wr_r && b_rd_i)	count	<= #2 count;
	else if (a_wr_r)		count	<= #2 count + 1;
	else if (b_rd_i)		count	<= #2 count - 1;

always @(posedge b_clk_i)
	if (reset_i)
		primed	<= #2 0;
	else if (first_w)
		primed	<= #2 1;
	else if (count == 1 && b_rd_i && !a_wr_r)
		primed	<= #2 0;

always @(posedge b_clk_i)
	if (reset_i)			first	<= #2 0;
	else if (a_wr_r && !primed)	first	<= #2 1;
	else				first	<= #2 0;

always @(posedge b_clk_i)
	if (reset_i)		b_adr	<= #2 INIT - 1;
	else if (inc_ad)	b_adr	<= #2 b_adr_ao;

endmodule	// pre_read
