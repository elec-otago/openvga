/***************************************************************************
 *                                                                         *
 *   LUT4.v - Simulates the Xilinx primitive of the same name for use with *
 *     Icarus Verilog.                                                     *
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

module LUT4( I0, I1, I2, I3, O );
	
	input	I0, I1, I2, I3;
	output	O;
	
	parameter	INIT	= 16'h0000;
	
	//	Select bit 0-15
	assign	O	= INIT[{I3, I2, I1, I0}];
	
endmodule	//	LUT4
