/***************************************************************************
 *                                                                         *
 *   wb_redraw.v - Prefetches display data for redrawing the screen.       *
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

// TODO: This is incomplete.

`timescale 1ns/100ps
module wb_redraw #(
	parameter	HIGHZ	= 0,
	parameter	WIDTH	= 32,
	parameter	BURST	= 7,	// 128 words is the default
	parameter	ENABLES	= WIDTH / 8,
	parameter	ADDRESS	= 21,	// 2 Mega-Words (8MB)
	parameter	MSB	= WIDTH - 1,
	parameter	ESB	= ENABLES - 1,
	parameter	ASB	= ADDRESS - 1,
	parameter	CSB	= BURST - 1
) (
	// Dot clock domain.
	input		d_clk_i,
	input		d_rst_ni,
	input		d_vsync_i,
	input		d_read_i,
	output	[MSB:0]	d_data_o,
	
	// Wishbone clock domain.
	input		wb_clk_i,
	input		wb_rst_i,
	input		wb_cyc_i,
	output		wb_cyc_o,
	output		wb_stb_o,
	output		wb_we_o,
	input		wb_ack_i,
	input		wb_rty_i,
	input		wb_err_i,
	output	[2:0]	wb_cti_o,
	output	[1:0]	wb_bte_o,
	output	[ASB:0]	wb_adr_o,
	input	[ESB:0]	wb_sel_i,
	input	[MSB:0]	wb_dat_i
);


reg		vsync1	= 1;
reg		vsync0	= 1;
reg	[ASB:0]	mem_ptr	= 0;
reg		rstart	= 0;
reg		rlast	= 0;
reg	[2:0]	cti	= 3'b010;
reg		inc_hi	= 0;
wire		rst_mem_ptr;
wire		half, read, rlast_w;
wire	[CSB:0]	next_mem_ptr_lo;
wire	[ASB:BURST]	next_mem_ptr_hi;

`define	RDRAW_IDLE	1'b0
`define	RDRAW_READ	1'b1
reg	state	= `RDRAW_IDLE;

assign	#2 read	= (state == `RDRAW_READ);

assign	#2 wb_cyc_o	= HIGHZ ? (read ? 1'b1 : 1'bz) : read ;
assign	#2 wb_stb_o	= HIGHZ ? (read ? 1'b1 : 1'bz) : read ;
assign	#2 wb_we_o	= HIGHZ ? (read ? 1'b0 : 1'bz) : 1'b0 ;
assign	#2 wb_cti_o	= HIGHZ ? (read ? cti : 3'bz) : cti ;
assign	#2 wb_bte_o	= HIGHZ ? (read ? 2'b00 : 2'bz) : 2'b00 ;
assign	#2 wb_adr_o	= HIGHZ ? (read ? mem_ptr : 'bz) : mem_ptr ;	// TODO

assign	#2 rst_mem_ptr	= (vsync1 | vsync0);
assign	#2 next_mem_ptr_lo	= mem_ptr[CSB:0] + 1;
assign	#3 next_mem_ptr_hi	= mem_ptr[ASB:BURST] + inc_hi;
assign	#3 rlast_w	= mem_ptr[CSB:1] == {(BURST-1){1'b1}};


// Synchronise vsync to the memory clock domain.
always @(posedge wb_clk_i)
	if (wb_rst_i)	{vsync1, vsync0}	<= #2 3;
	else		{vsync1, vsync0}	<= #2 {vsync0, d_vsync_i};


//---------------------------------------------------------------------------
//  Memory fetching when the re-draw FIFO is below half full. Keep fetching
//  until either 128 words have been fetched or a Wishbone RTY command is
//  issued.
//
always @(posedge wb_clk_i)
	if (wb_rst_i || rst_mem_ptr)
		state	<= #2 `RDRAW_IDLE;
	else case (state)
	`RDRAW_IDLE:
		if (!half && !wb_cyc_i)
			state	<= #2 `RDRAW_READ;
	`RDRAW_READ:
		if (wb_rty_i || (rlast && wb_ack_i))
			state	<= #2 `RDRAW_IDLE;
	endcase


// The memory pointer starts at zero after every vsync.
always @(posedge wb_clk_i)
	if (wb_rst_i)
		mem_ptr	<= #2 0;
	else if (rst_mem_ptr)
		mem_ptr	<= #2 0;
	else if (read && wb_ack_i)
		mem_ptr	<= #2 {next_mem_ptr_hi, next_mem_ptr_lo};


always @(posedge wb_clk_i)
	if (wb_rst_i)	rlast	<= #2 0;
	else		rlast	<= #2 rlast_w;


always @(posedge wb_clk_i)
	if (wb_rst_i)	cti	<= #2 3'b010;
	else		cti	<= #2 rlast_w ? 3'b111 : 3'b010 ;


always @(posedge wb_clk_i)
	if (wb_rst_i)	inc_hi	<= #2 0;
	else		inc_hi	<= #2 (rlast && wb_ack_i);


// Prefetch plenty of data so that the redraw logic doesn't run out.
afifo2k #(
	.WIDTH		(WIDTH),
	.ADDRESS	(9)
) FIFO0 (
	.reset_ni	(~d_vsync_i),
	
	.rd_clk_i	(d_clk_i),
	.rd_en_i	(d_read_i),
	.rd_data_o	(d_data_o),
	
	.wr_clk_i	(wb_clk_i),
	.wr_en_i	(read && wb_ack_i),
	.wr_data_i	(wb_dat_i),
	
	.wfull_o	(),
	.rempty_o	(),
	.whalfish_o	(half)
);


endmodule	// wb_redraw
