/***************************************************************************
 *                                                                         *
 *   fetch_wb.v - Fetches a cacheline from a memory connected by a         *
 *     Wishbone bus.                                                       *
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
module fetch_wb #(
	parameter	WIDTH	= 32,
	parameter	ENABLES	= WIDTH / 8,
	parameter	ADDRESS	= 27,
	parameter	CNTBITS	= 4,
	parameter	CNTMAX	= (1<<CNTBITS) - 1,
	parameter	MSB	= WIDTH - 1,
	parameter	ASB	= ADDRESS - 1,
	parameter	TSB	= ASB - 8,
	parameter	ESB	= ENABLES - 1,
	parameter	CSB	= CNTBITS - 1
) (
	// Wishbone clock domain.
	input			wb_clk_i,
	input			wb_rst_i,
	output	reg		wb_cyc_o	= 0,
	output	reg		wb_stb_o	= 0,
	output	reg		wb_we_o		= 0,
	input			wb_ack_i,
	input			wb_rty_i,
	input			wb_err_i,
	output	reg	[2:0]	wb_cti_o	= 3'b010,
	output	reg	[1:0]	wb_bte_o	= 2'b00,
	output		[ASB:0]	wb_adr_o,
	input		[ESB:0]	wb_sel_i,
	input		[MSB:0]	wb_dat_i,
	output	reg	[ESB:0]	wb_sel_o,
	output	reg	[MSB:0]	wb_dat_o,
	
	// Sync. with WB clock, but can be many times faster.
	input		clk_i,
	input		write_i,	// Pass writes through from CPU domain
	output	reg	wack_o	= 0,
	output		wack_ao,
	input	[ESB:0]	bes_i,
	input	[MSB:0]	data_i,
	input		miss_i,
	output	reg	ack_o	= 0,	// Diff. domains, so sync needed
	output	reg	ready_o	= 0,	// NOTE: This is CPU domain
	output		done_o,		// NOTE: This is WB domain
	output		busy_o,
	input	[ASB:0]	addr_i,
	
	output		u_write_o,
	output		u_vld_o,
	output	[7:0]	u_addr_o,	// TODO: Parameterise
	output	[MSB:0]	u_data_o
);


reg	[CSB:0]	cnt	= 0;
reg	[ASB:CNTBITS]	wb_adr	= 0;
reg	wb_rdy	= 0;
reg	once	= 0;
reg	wack_1s	= 0;


assign	wb_adr_o	= {wb_adr [ASB:CNTBITS], cnt};
assign	busy_o		= wb_cyc_o;

assign	#2 u_write_o	= (wb_cyc_o && wb_stb_o && wb_ack_i);
assign	u_vld_o		= u_write_o;
assign	u_addr_o	= wb_adr_o [7:0];
assign	u_data_o	= wb_dat_i;	// TODO: `wb_sel' support.

assign	done_o		= wb_rdy;


always @(posedge wb_clk_i)
	if (wb_rst_i)			ack_o	<= #2 0;
	else if (!wb_cyc_o && miss_i)	ack_o	<= #2 1;
	else				ack_o	<= #2 0;


always @(posedge wb_clk_i)
	if (wb_rst_i) begin
		wb_cyc_o	<= #2 0;
		wb_stb_o	<= #2 0;
	end else
	if (!wb_cyc_o && (miss_i || write_i)) begin
		wb_cyc_o	<= #2 1;
		wb_stb_o	<= #2 1;
		wb_adr[ASB:CNTBITS]	<= #2 addr_i[ASB:CNTBITS];
	end else
	if (wb_cyc_o && wb_stb_o && wb_ack_i && cnt == CNTMAX) begin
		wb_cyc_o	<= #2 0;
		wb_stb_o	<= #2 0;
	end else
	if (wb_cyc_o && wb_stb_o && wb_we_o && wb_ack_i) begin
		wb_cyc_o	<= #2 0;
		wb_stb_o	<= #2 0;
	end else
	if (wb_cyc_o && wb_stb_o && wb_we_o && wb_rty_i) begin
		wb_cyc_o	<= #2 0;
		wb_stb_o	<= #2 0;
	end else
	if (wb_cyc_o && wb_stb_o && wb_we_o && wb_err_i) begin
		wb_cyc_o	<= #2 0;
		wb_stb_o	<= #2 0;
	end


always @(posedge wb_clk_i)
	if (wb_rst_i)	wb_we_o				<= #2 0;
	else		{wb_we_o, wb_sel_o, wb_dat_o}	<= #2 {write_i, bes_i, data_i};


always @(posedge wb_clk_i)
	if (wb_rst_i)
		wb_cti_o	<= #2 3'b010;
	else if (write_i)
		wb_cti_o	<= #2 3'b000;
	else if (wb_ack_i && cnt == CNTMAX - 1)
		wb_cti_o	<= #2 3'b111;
	else
		wb_cti_o	<= #2 3'b010;


always @(posedge wb_clk_i)
	if (wb_rst_i)
		cnt	<= #2 0;
	else if (!wb_cyc_o) begin
		if (write_i)	cnt	<= #2 addr_i[CNTBITS-1:0];
		else		cnt	<= #2 0;
	end else if (wb_cyc_o && wb_ack_i)
		cnt	<= #2 cnt + 1;


always @(posedge wb_clk_i)
	if (wb_rst_i)
		wb_rdy	<= #2 0;
	else if (wb_cyc_o && !wb_we_o && wb_ack_i && cnt == CNTMAX)
		wb_rdy	<= #2 1;
	else
		wb_rdy	<= #2 0;


always @(posedge clk_i)
	if (wb_rst_i)
		{once, ready_o}	<= #2 0;
	else if (!ready_o && wb_rdy && !once)
		{once, ready_o}	<= #2 2'b11;
	else if (!wb_rdy)
		once	<= #2 0;
	else
		ready_o	<= #2 0;


assign	#2 wack_ao	= write_i && wb_ack_i;	// Naughty, mixing 50 + 150 MHz sigs
always @(posedge clk_i)
	if (wb_rst_i)
		{wack_1s, wack_o}	<= #2 0;
	else if (!wack_o && !wack_1s && write_i && wb_ack_i) begin
		wack_o	<= #2 1;
		wack_1s	<= #2 1;
	end else begin
		if (!write_i)	wack_1s	<= #2 0;
		wack_o	<= #2 0;
	end

endmodule	// fetch_wb
