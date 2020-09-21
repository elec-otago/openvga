/***************************************************************************
 *                                                                         *
 *   FDCE.v - Emulates the functionality of the Xilinx primitive of the    *
 *     same name. This a really poor partial implementation so do not use  *
 *     as it is only designed to do some very basic things.                *
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

`timescale 1ns/100ps
module FDCE(
	C,	// Clock
	CE,	// Clock enable
	CLR,	// Asynchronous clear
	D,	// Data in
	Q	// Data out
);

input	C;
input	CE;
input	CLR;
input	D;
output	Q;

parameter	INIT	= 1'b0;
reg		Q	= INIT;

always @(posedge C or posedge CLR)
	if (CLR)
		Q	<= #1 1'b0;
	else if (CE)
		Q	<= #1 D;
	else
		Q	<= #1 Q;

endmodule	//	FDCE
