/***************************************************************************
 *                                                                         *
 *   FDRSE.v - Replicates the functionality of the Xilinx primitive of the *
 *     same name.                                                          *
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

// D-type Flip-flop with reset, set and clock enable.
`timescale 1ns/100ps
module FDRSE ( C, D, Q, R, S, CE );

input	C;
input	D;
output	Q;
input	R;
input	S;
input	CE;

parameter	INIT	= 1'b0;
reg		Q = INIT;

always @(posedge C)
	if (R)
		Q	<= #1 1'b0;
	else if (S)
		Q	<= #1 1'b1;
	else if (CE)
		Q	<= #1 D;

endmodule	//	FDRSE
