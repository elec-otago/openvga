/***************************************************************************
 *                                                                         *
 *   LUT6.v - Simulates the Xilinx (Virtex5) primitive of the same name    *
 *     for use with Icarus Verilog.                                        *
 *                                                                         *
 *   WILL NOT SYNTHESISE!                                                  *
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

`timescale 1ns/100ps
module LUT6 (O, I0, I1, I2, I3, I4, I5);

parameter	INIT	= 64'h0000_0000_0000_0000;
output	O;
input	I0, I1, I2, I3, I4, I5;

reg	O;
reg	lut_rom [0:63];

integer	i;
initial begin : Init
	for (i=0; i<64; i=i+1)
		lut_rom [i]	= INIT [i];
end	// Init

always @(I5, I4, I3, I2, I1, I0)
	O	<= lut_rom [{I5, I4, I3, I2, I1, I0}];

endmodule	// LUT6
