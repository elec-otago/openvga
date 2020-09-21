/***************************************************************************
 *                                                                         *
 *   FDDRRSE.v - A dual edge triggered output flip-flop which emulates     *
 *     the Xilinx primitive of the same name. Data is output on both       *
 *     positive and negative clock edges. Uses include data transfers to   *
 *     DDR-SDRAMs.                                                         *
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
module FDDRRSE (
		C0,
		C1,
		CE,
		D0,
		D1,
		Q,
		R,
		S
	);
	
	parameter	INIT	= 1'b0;
	parameter	DELAY	= 0.0;
	
	input	C0;	// Clock 0
	input	C1;
	input	CE;	// Clock enable
	
	input	D0;	// Data after a posedge
	input	D1;
	
	input	R;	// Reset
	input	S;
	
	output	Q;	// DDR output
	
	reg	Q	= INIT;
	always @(posedge C0 or posedge C1)
	begin
		if (R)
			Q	<= #DELAY 0;
		else if (S)
			Q	<= #DELAY 1;
		else if (CE)
		begin
			if (C0)
				Q	<= #DELAY D0;
			else
				Q	<= #DELAY D1;
		end
	end
	
endmodule	// FDDRRSE
