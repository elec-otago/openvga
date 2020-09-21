/***************************************************************************
 *                                                                         *
 *   OBUF.v - An output buffer of a Xilinx FPGA.                           *
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
module OBUF (I, O);
input	I;
output	O;

parameter	SLEW		= "SLOW" ;
parameter	IOSTANDARD	= "LVCMOS33" ;
parameter	DRIVE		= 12 ;

parameter	ODELAY	= 7.0;	// SSTL2_II output delay is about 4.6 ns?

reg	O;
always @(I)
	O	<= #ODELAY I;

endmodule	// OBUFT
