/***************************************************************************
 *                                                                         *
 *   prefetch.v - Prefetches display data for redrawing the screen.        *
 *                                                                         *
 *   Copyright (C) 2008 by Patrick Suggate                                 *
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
module prefetch (
	mem_clk_i,
	dot_clk_i,
	reset_ni,
	enable_i,
	
	// Dot clock domain
	d_vsync_i,
	d_read_i,
	d_data_o,
	
	// Memory clock domain
	m_read_o,
	m_rack_i,
	m_ready_i,
	m_addr_o,
	m_data_i
);

parameter	WIDTH	= 32;
parameter	ADDRESS	= 21;	// 2 Mega-Words (8MB)
parameter	MSB	= WIDTH - 1;
parameter	ASB	= ADDRESS - 1;

input		mem_clk_i;
input		dot_clk_i;
input		reset_ni;
input		enable_i;

input		d_vsync_i;
input		d_read_i;
output	[MSB:0]	d_data_o;

output		m_read_o;
input		m_rack_i;
input		m_ready_i;
output	[ASB:0]	m_addr_o;	// 1024 MB RAM!
input	[MSB:0]	m_data_i;


reg		vsync1	= 1;
reg		vsync0	= 1;
reg	[ASB:0]	mem_ptr	= 0;
wire		rdone, rst_mem_ptr;
wire		half;

`define	RDRAW_IDLE	2'b00
`define	RDRAW_READ	2'b01
`define	RDRAW_WAIT	2'b10
reg	[1:0]	state	= `RDRAW_IDLE;


assign	m_read_o	= (state == `RDRAW_READ);
assign	m_addr_o	= mem_ptr;

assign	#2 rdone	= (m_ready_i && mem_ptr [2:0] == 7);
assign	#2 rst_mem_ptr	= (vsync1 | vsync0);


// Synchronise vsync to the memory clock domain.
always @(posedge mem_clk_i)
	if (!reset_ni)	{vsync1, vsync0}	<= #2 3;
	else		{vsync1, vsync0}	<= #2 {vsync0, d_vsync_i};


//---------------------------------------------------------------------------
//  Memory fetching when the re-draw FIFO is below half full.
//
always @(posedge mem_clk_i)
	if (!reset_ni || rst_mem_ptr)
		state	<= #2 `RDRAW_IDLE;
	else case (state)
	`RDRAW_IDLE: if (!half)		state	<= #2 `RDRAW_READ;
	`RDRAW_READ: if (m_rack_i)	state	<= #2 `RDRAW_WAIT;
	`RDRAW_WAIT: if (rdone)		state	<= #2 `RDRAW_IDLE;
	endcase


// The memory pointer starts at zero after every vsync. The display is only
// 16-bit colour at the moment, so one read is data for 16 pixels.
wire	[ASB-3:0]	#3 next_ptr	= mem_ptr [ASB:3] + 1;
always @(posedge mem_clk_i)
	if (!reset_ni)		mem_ptr	<= #2 0;
	else if (rst_mem_ptr)	mem_ptr	<= #2 0;
	else if (m_ready_i) begin
		mem_ptr [2:0]	<= #2 mem_ptr [2:0] + 1;
		if (rdone)	
			mem_ptr [ASB:3]	<= #2 mem_ptr [ASB:3] + 1;
	end


// Prefetch plenty of data so that the redraw logic doesn't run out.
afifo2k #(
	.WIDTH		(WIDTH),
	.ADDRESS	(9)
) FIFO0 (
	.reset_ni	(~rst_mem_ptr),
	
	.rd_clk_i	(dot_clk_i),
	.rd_en_i	(d_read_i),
	.rd_data_o	(d_data_o),
	
	.wr_clk_i	(mem_clk_i),
	.wr_en_i	(m_ready_i),
	.wr_data_i	(m_data_i),
	
	.wfull_o	(),
	.rempty_o	(),
	.whalfish_o	(half)
);


endmodule	// prefetch
