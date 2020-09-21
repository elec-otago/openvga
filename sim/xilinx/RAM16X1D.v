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

`timescale 1ns / 100ps
module RAM16X1D(
	D,
	WE,
	WCLK,
	A0,
	A1,
	A2,
	A3,
	DPRA0,
	DPRA1,
	DPRA2,
	DPRA3,
	SPO,
	DPO
);

input	D;
input	WE;
input	WCLK;
input	A0;
input	A1;
input	A2;
input	A3;
input	DPRA0;
input	DPRA1;
input	DPRA2;
input	DPRA3;
output	SPO;
output	DPO;


//	16-bits of RAM, initialise to zero
reg		r_data[0:15];	//	Allowed?


//	Turn the incoming address bits into an address bus
wire	[3:0]	w_addr	= {A0, A1, A2, A3};
wire	[3:0]	r_addr	= {DPRA0, DPRA1, DPRA2, DPRA3};


//	Output the bit-values
assign	SPO	= r_data[w_addr];
assign	DPO	= r_data[r_addr];


//	Write incoming data to the dual-port RAM
always @(posedge WCLK)
begin
	if (WE)
		r_data[w_addr]	<= D;
	else
		r_data[w_addr]	<= r_data[w_addr];
end


initial begin : Init
	fill_mem(1);
end	//	Init


//	Used to intialise the memory for a test bench
task fill_mem;
	input	mode;
	integer	n, mode;

begin : Fill_Memory
	
	for (n = 0; n < 16; n = n+1)
	begin
		case (mode)
		default:	r_data[n] = 'b0;
		1:			r_data[n] = $random;
		2:			r_data[n] = 'b1;
		endcase
	end
end	//	Fill_Memory
endtask	//	fill_mem

endmodule	//	RAM16X1D
