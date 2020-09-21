/***************************************************************************
 *                                                                         *
 *   wb_sprom.v - A Wishbone comliant interface to a Xilinx Platorm Flash  *
 *     Serial PROM.                                                        *
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
module wb_sprom (
	wb_clk_i,
	wb_rst_i,
	wb_cyc_i,
	wb_stb_i,
	wb_we_i,
	wb_ack_o,
	wb_dat_o,
	wb_sel_o,
	
	sp_clk_o,
	sp_dat_i
);

parameter	WIDTH		= 32;
parameter	ENABLES		= WIDTH / 8;
parameter	PATTERN		= 32'h1234;
parameter	CLKDIVLOG2	= 3;	// 6.25 MHz when `(wb_clk_i == 50 MHz)'.
parameter	HIGHZ		= 0;	// When on a 3state bus, set to 1

parameter	MSB	= WIDTH - 1;
parameter	ESB	= ENABLES - 1;

input		wb_clk_i;
input		wb_rst_i;
input		wb_cyc_i;
input		wb_stb_i;
input		wb_we_i;	// TODO: Ignore writes or generate error?
output		wb_ack_o;
output	[MSB:0]	wb_dat_o;
output	[ESB:0]	wb_sel_o;

output		sp_clk_o;
input		sp_dat_i;


// States.
`define	SPST_SEARCH	4'b0000
`define	SPST_NEXT	4'b0001
`define	SPST_READY	4'b0010

reg		wb_ack_o	= 0;

reg		enable	= 0;
reg		sel	= 0;
reg	[MSB:0]	shftreg	= 0;
reg	[3:0]	state	= `SPST_SEARCH;
wire		match, read, done;

assign	#2 read		= (wb_cyc_i && wb_stb_i && !wb_we_i);
assign	#3 match	= (shftreg [MSB:0] == PATTERN [MSB:0]);

assign	#2 wb_dat_o	= HIGHZ ? (sel ? shftreg : 'bz) : shftreg;
assign	#2 wb_sel_o	= HIGHZ ? (sel ? {ENABLES{1'b1}} : 'bz) : {ENABLES{sel}};


// Controls the 3state logic.
always @(posedge wb_clk_i)
	if (wb_rst_i)	sel	<= #2 0;
	else		sel	<= #2 read;


always @(posedge wb_clk_i)
	if (wb_rst_i)	wb_ack_o	<= #2 0;
	else		wb_ack_o	<= #2 read && (state == `SPST_READY);


always @(posedge wb_clk_i)
	if (wb_rst_i)	state	<= #2 `SPST_SEARCH;
	else case (state)
	`SPST_SEARCH:	if (match)	state	<= #2 `SPST_NEXT;
	`SPST_NEXT:	if (done)	state	<= #2 `SPST_READY;
	`SPST_READY:	if (read)	state	<= #2 `SPST_NEXT;
	endcase


always @(posedge sp_clk_o)
	shftreg	<= #2 {shftreg[WIDTH-2:0], sp_dat_i};


clkdiv #(
	.CLKDIVLOG2	(CLKDIVLOG2)
) CLKDIV0 (
	.clk_i	(wb_clk_i),
	.rst_i	(enable),
	.clk_o	(sp_clk_o)
);


endmodule	// wb_sprom
