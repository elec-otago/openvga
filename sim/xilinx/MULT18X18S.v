/***************************************************************************
 *                                                                         *
 *   MULT18X18S.v - Simulates the Xilinx primitive of the same name for    *
 *     use with Icarus Verilog.                                            *
 *                                                                         *
 *   Copyright (C) 2005 by Patrick Suggate                                 *
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

module MULT18X18S(
		A, B, P, C, CE, R
	);
	
	input	[17:0]	A, B;	//	2's complement integers
	output	[35:0]	P;		//	2's complement product
	
	input	C;				//	Clock
	input	CE;				//	Clock enable
	input	R;				//	Synchronous reset
	
	reg		[35:0]	P	= 0;
	
	always @(posedge C)
	begin
		if (R) begin
			P	<= 0;
		end
		else begin
			if (~CE)
				P	<= P;
			else
				P	<= A * B;
		end
	end
	
endmodule	//	MULT18X18S
