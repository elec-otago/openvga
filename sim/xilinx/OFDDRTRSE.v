/***************************************************************************
 *                                                                         *
 *   OFDDRTRSE.v - A dual edge triggered output flip-flop, with a tri-     *
 *     state output, which emulates the Xilinx primitive of the same name. *
 *     Data is output on both positive and negative clock edges. Uses      *
 *     include data transfers to DDR-SDRAMs.                               *
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

// TODO: Finish parameterizable delays.
`timescale 1ns/100ps
module OFDDRTRSE #(
	parameter	INIT	= 1'b0,
	parameter	ODELAY	= 7.0,
	parameter	ZDELAY	= 1.0
) (
	input	C0,
	input	C1,
	input	CE,
	input	D0,	// Data after a posedge
	input	D1,
	input	T,
	output	O,	// DDR output
	input	R,
	input	S
);

reg	O_r	= INIT;

assign	#ZDELAY O	= T ? 'bz : O_r ;

always @(posedge C0 or posedge C1)
	if (CE) begin
		if (R)		O_r	<= #ODELAY 0;
		else if (S)	O_r	<= #ODELAY 1;
		else if (C0)	O_r	<= #ODELAY D0;
		else		O_r	<= #ODELAY D1;
	end

endmodule	// OFDDRTRSE
