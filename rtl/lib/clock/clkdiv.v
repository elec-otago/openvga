/***************************************************************************
 *                                                                         *
 *   clkdiv.v - Divides an incoming clock by a power of two (>= 2).        *
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
module clkdiv (
	clk_i,
	rst_i,
	clk_o
);

parameter	CLKDIVLOG2	= 3;
parameter	MSB		= CLKDIVLOG2 - 1;

input	clk_i;
input	rst_i;
output	clk_o;

reg	[MSB:0]	cnt	= 0;

assign	clk_o	= cnt [MSB];

always @(posedge clk_i)
	if (rst_i)	cnt	<= #2 0;
	else		cnt	<= #2 cnt + 1;

endmodule	// clkdiv
