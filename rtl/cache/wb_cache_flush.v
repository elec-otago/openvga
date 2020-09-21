/***************************************************************************
 *                                                                         *
 *   wb_cache_flush.v - Cache memory stored in Xilinx Block RAMs.          *
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
module wb_cache_flush #(
	parameter	HIGHZ	= 0
) (
	input		wb_clk_i,
	input		wb_rst_i,
	
	input		wb_cyc_i,
	input		wb_stb_i,
	input		wb_we_i,
	output		wb_ack_o,
	output		wb_rty_o,
	output		wb_err_o,
	
	output	reg	flush_o	= 0
);

reg	sel	= 0;

assign	#2 wb_ack_o	= HIGHZ ? (sel ? 1'b1 : 1'bz) : sel ;
assign	#2 wb_rty_o	= HIGHZ ? (sel ? 1'b0 : 1'bz) : 1'b0 ;
assign	#2 wb_err_o	= HIGHZ ? (sel ? 1'b0 : 1'bz) : 1'b0 ;

always @(posedge wb_clk_i)
	if (wb_rst_i)				sel	<= #2 1'b0;
	else if (wb_cyc_i && wb_stb_i && ~sel)	sel	<= #2 1'b1;
	else					sel	<= #2 1'b0;

always @(posedge wb_clk_i)
	if (wb_rst_i)
		flush_o	<= #2 0;
	else if (wb_cyc_i && wb_stb_i && ~sel && wb_we_i)
		flush_o	<= #2 1;
	else
		flush_o	<= #2 0;

endmodule	// wb_cache_flush
