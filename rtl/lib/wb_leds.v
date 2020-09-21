/***************************************************************************
 *                                                                         *
 *   wb_leds.v - Wishbone bus connected LEDs.                              *
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

// `define __use_random

`timescale 1ns/100ps
module wb_leds #(
	parameter	HIGHZ	= 0,
	parameter	WIDTH	= 16,
	parameter	LEDS	= 2,
	parameter	ENABLES	= WIDTH / 8,
	parameter	MSB	= WIDTH - 1,
	parameter	ESB	= ENABLES - 1,
	parameter	LSB	= LEDS - 1
) (
	input		wb_clk_i,
	input		wb_rst_i,
	
	input		wb_cyc_i,
	input		wb_stb_i,
	input		wb_we_i,
	output		wb_ack_o,
	output		wb_rty_o,
	output		wb_err_o,
	input	[ESB:0]	wb_sel_i,
	input	[MSB:0]	wb_dat_i,
	output	[ESB:0]	wb_sel_o,
	output	[MSB:0]	wb_dat_o,
	
	output	[LSB:0]	leds_o
);

reg	ack	= 0;
reg	[MSB:0]	dat	= 0;


assign	leds_o	= dat[LSB:0];

assign	#2 wb_ack_o	= HIGHZ ? (ack ? 1'b1 : 'bz) : ack ;
assign	#2 wb_rty_o	= HIGHZ ? (ack ? 0 : 'bz) : 0 ;
assign	#2 wb_err_o	= HIGHZ ? (ack ? 0 : 'bz) : 0 ;
assign	#2 wb_sel_o	= HIGHZ ? (ack ? {ENABLES{ack}} : 'bz) : {ENABLES{ack}} ;
assign	#2 wb_dat_o	= HIGHZ ? (ack ? dat : 'bz) : dat ;


always @(posedge wb_clk_i)
	if (wb_rst_i)
		ack	<= #2 0;
	else if (wb_cyc_i && wb_stb_i && !ack)
		ack	<= #2 1;
	else
		ack	<= #2 0;


// TODO: Byte-enables
always @(posedge wb_clk_i)
	if (wb_rst_i)	dat	<= #2 0;
	else if (wb_cyc_i && wb_stb_i && wb_we_i) begin
`ifdef __use_random
		dat	<= #2 $random;
`else
 		dat	<= #2 wb_dat_i;
`endif
	end


endmodule	// wb_leds
