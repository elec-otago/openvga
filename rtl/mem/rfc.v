/***************************************************************************
 *                                                                         *
 *   rfc.v - Generates the refreshes for a SDRAM or DDR SDRAM or DDR2      *
 *     SDRAM low-level controller.                                         *
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
module rfc (
	clk_i,
	rst_i,
	en_i,
	req_o,
	gnt_i,
	rfc_o
);

parameter	INIT		= 1;
parameter	RFC_TIMER	= 780;	// 50 MHz
parameter	TIMER_BITS	= 10;
parameter	tRFC		= 4;	// 64 ns refresh
parameter	TSB		= TIMER_BITS - 1;

input	clk_i;
input	rst_i;
input	en_i;
output	req_o;
input	gnt_i;
output	rfc_o;

reg	rfc_o	= INIT;
reg	[TSB:0]	cnt	= 0;
reg	[2:0]	trfc	= 0;
reg	[1:0]	owing	= 2;

assign	#2 req_o	= (owing != 0);


// Refresh event logic.
wire	#2 rfc_trigger	= (cnt == RFC_TIMER - 1);
always @(posedge clk_i)
	if (rst_i)		cnt	<= #2 0;
	else if (rfc_trigger)	cnt	<= #2 0;
	else			cnt	<= #2 cnt + 1;

always @(posedge clk_i)
	if (rst_i)	owing	<= #2 2;
	else if (gnt_i && trfc == 0) begin
		if (!rfc_trigger)
			owing	<= #2 owing - 1;
	end else if (rfc_trigger)
		owing	<= #2 owing + 1;

always @(posedge clk_i)
	if (trfc != 0)	trfc	<= #2 trfc - 1;
	else if (gnt_i)	trfc	<= #2 tRFC - 1;

always @(posedge clk_i)
	if (rst_i)			rfc_o	<= #2 0;
	else if (gnt_i && trfc == 0)	rfc_o	<= #2 1;
	else if (trfc == 0)		rfc_o	<= #2 0;

endmodule	// rfc
