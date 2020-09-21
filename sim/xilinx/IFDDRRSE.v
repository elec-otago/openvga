/***************************************************************************
 *                                                                         *
 *   IFDDRRSE.v - A dual edge triggered input flip-flop which emulates the *
 *     Xilinx primitive of the same name. Data is received on both         *
 *     positive and negative clock edges.                                  *
 *                                                                         *
 *   Copyright (C) 2007 by Patrick Suggate                                 *
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

// TODO: Implement parameterizable delays.
`timescale 1ns/100ps
module IFDDRRSE (
	C0,
	C1,
	CE,
	D,
	R,
	S,
	Q0,
	Q1
);

parameter	INIT	= 2'b00;
parameter	DELAY	= 2.0;

input	C0;	// Clock 0
input	C1;
input	CE;	// Clock enable

input	D;	// Data valid on both edges

input	R;	// Reset
input	S;

output	Q0;	// Posedge data
output	Q1;

reg	Q0	= INIT [0];
reg	Q1	= INIT [1];

always @(posedge C0)
	if (R)		Q0	<= #DELAY 0;
	else if (S)	Q0	<= #DELAY 1;
	else if (CE)	Q0	<= #DELAY D;

always @(posedge C1)
	if (R)		Q1	<= #DELAY 0;
	else if (S)	Q1	<= #DELAY 1;
	else if (CE)	Q1	<= #DELAY D;

endmodule	// OFDDRRSE
