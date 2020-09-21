/***************************************************************************
 *                                                                         *
 *   RAM16X1D.v - Emulates the functionality of the Xilinx primitive of the*
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
module RAM32M (
	WCLK,
	WE,
	ADDRA,
	ADDRB,
	ADDRC,
	ADDRD,
	DIA,
	DIB,
	DIC,
	DID,
	DOA,
	DOB,
	DOC,
	DOD
);

parameter	INIT_A	= 64'h0000_0000_0000_0000;
parameter	INIT_B	= 64'h0000_0000_0000_0000;
parameter	INIT_C	= 64'h0000_0000_0000_0000;
parameter	INIT_D	= 64'h0000_0000_0000_0000;

input	WCLK;
input	WE;
input	[4:0]	ADDRA;
input	[4:0]	ADDRB;
input	[4:0]	ADDRC;
input	[4:0]	ADDRD;
input	[1:0]	DIA;
input	[1:0]	DIB;
input	[1:0]	DIC;
input	[1:0]	DID;
output	[1:0]	DOA;
output	[1:0]	DOB;
output	[1:0]	DOC;
output	[1:0]	DOD;


// synthesis attribute ram_style of distram is distributed ;
// pragma attribute distram ram_block FALSE ;
reg	[1:0]	distram [0:127];


assign	DOA	= distram [{ADDRA, 2'b00}];
assign	DOB	= distram [{ADDRB, 2'b01}];
assign	DOC	= distram [{ADDRC, 2'b10}];
assign	DOD	= distram [{ADDRD, 2'b11}];


always @(posedge WCLK)
begin
	if (WE)
	begin
		distram [{ADDRD, 2'b00}]	<= DIA;
		distram [{ADDRD, 2'b01}]	<= DIB;
		distram [{ADDRD, 2'b10}]	<= DIC;
		distram [{ADDRD, 2'b11}]	<= DID;
	end
end


integer	ii, idx0, idx1;
initial begin : Init
	for (ii=0; ii<32; ii=ii+1)
	begin
		idx0	= {ii,1'b0};
		idx1	= {ii,1'b1};
		distram [{ii, 2'b00}]	= {INIT_A [idx1], INIT_A [idx0]};
		distram [{ii, 2'b01}]	= {INIT_B [idx1], INIT_B [idx0]};
		distram [{ii, 2'b10}]	= {INIT_C [idx1], INIT_C [idx0]};
		distram [{ii, 2'b11}]	= {INIT_D [idx1], INIT_D [idx0]};
	end
end	// Init


endmodule	// RAM32M
