/***************************************************************************
 *                                                                         *
 *   risc_mem_wb.v - Lightweight CPU->WB interface.                        *
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

// TODO: Currently the `wb' and `cpu' clocks have to be the same.
// TODO: `HIGHZ'.
// TODO: Currently the bus-widths have to be the same.

`timescale 1ns/100ps
module risc_mem_wb #(
	parameter	HIGHZ	= 0,
	parameter	WIDTH	= 16,
	parameter	ADDRESS	= 25,
	parameter	WBBITS	= WIDTH,
// 	parameter	WBBITS	= 32,
	parameter	ENABLES	= WBBITS / 8,
	parameter	MSB	= WIDTH - 1,
	parameter	ESB	= ENABLES - 1,
	parameter	ASB	= ADDRESS - 1,
	parameter	WSB	= WBBITS - 1
) (
	input		cpu_clk_i,
	input		cpu_rst_i,
	
	input		frame_i,
	input		write_i,
	output		ready_o,
	input	[ASB:0]	addr_i,
	input	[MSB:0]	data_i,
	output	[MSB:0]	data_o,
	
	output	reg	wb_cyc_o	= 0,
	output	reg	[1:0]	wb_stb_o	= 0,
	output	reg	wb_we_o		= 0,
	input		wb_ack_i,
	input		wb_rty_i,
	input		wb_err_i,
	output	[2:0]	wb_cti_o,	// Single-word transfers
	output	[1:0]	wb_bte_o,
	output	reg	[ASB:0]	wb_adr_o,
	output	[ESB:0]	wb_sel_o,
	output	reg	[WSB:0]	wb_dat_o,
	input	[ESB:0]	wb_sel_i,
	input	[WSB:0]	wb_dat_i
);

assign	data_o	= wb_dat_i;
assign	ready_o	= wb_ack_i;

assign	wb_cti_o	= 0;
assign	wb_bte_o	= 0;
assign	wb_sel_o	= {ENABLES{1'b1}};

always @(posedge cpu_clk_i)
	if (cpu_rst_i)
		{wb_cyc_o, wb_stb_o, wb_we_o}	<= #2 4'b0000;
	else if (!wb_cyc_o) begin
		wb_cyc_o	<= #2 frame_i;
		if (frame_i)
			wb_stb_o	<= #2 addr_i[ASB] ? 2'b10 : 2'b01 ;
		else
			wb_stb_o	<= #2 0;
		wb_we_o		<= #2 write_i;
		wb_adr_o	<= #2 addr_i;
		wb_dat_o	<= #2 data_i;
	end else if (wb_ack_i) begin
		wb_cyc_o	<= #2 0;
		wb_stb_o	<= #2 0;
		wb_we_o		<= #2 0;
	end

endmodule	// risc_mem_wb
