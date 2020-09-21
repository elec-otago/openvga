/***************************************************************************
 *                                                                         *
 *   wb_sync.v - Synchronises Wishbone transfers accross different domains *
 *      with synchronous clocks.                                           *
 *                                                                         *
 *   Copyright (C) 2009 by Patrick Suggate                                 *
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

// TODO: Change from hard-coded to parameterisable.

`timescale 1ns/100ps
module wb_sync #(
	parameter	HIGHZ	= 0,
	parameter	ADDRESS	= 25,
	parameter	CWIDTH	= 16,
	parameter	WWIDTH	= 32,
	parameter	ENABLES	= CWIDTH / 8,
	parameter	SELECTS	= WWIDTH / 8,
	parameter	DIFF	= WWIDTH / CWIDTH - 1,
	// Bit-select helpers.
	parameter	MSB	= CWIDTH - 1,
	parameter	WSB	= WWIDTH - 1,
	parameter	ESB	= ENABLES - 1,
	parameter	SSB	= SELECTS - 1,
	parameter	ASB	= ADDRESS - 1,
	parameter	LSEL	= DIFF > 0 ? ENABLES : 0,
	parameter	LDAT	= DIFF > 0 ? CWIDTH : 0
) (
	input		wb_rst_i,
	
	input		a_clk_i,
	input		a_cyc_i,
	input		a_stb_i,
	input		a_we_i,
	output		a_ack_o,
	output		a_rty_o,
	output		a_err_o,
	input	[2:0]	a_cti_i,
	input	[1:0]	a_bte_i,
	input	[ASB+DIFF:0]	a_adr_i,
	input	[ESB:0]	a_sel_i,
	input	[MSB:0]	a_dat_i,
	output	[ESB:0]	a_sel_o,
	output	[MSB:0]	a_dat_o,
	
	input		b_clk_i,
	output		b_cyc_o,
	output		b_stb_o,
	output		b_we_o,
	input		b_ack_i,
	input		b_rty_i,
	input		b_err_i,
	output	[2:0]	b_cti_o,
	output	[1:0]	b_bte_o,
	output	[ASB:0]	b_adr_o,
	input	[SSB:0]	b_sel_i,
	input	[WSB:0]	b_dat_i,
	output	[SSB:0]	b_sel_o,
	output	[WSB:0]	b_dat_o
);


`define	SYNCST_IDLE	4'b0000
`define	SYNCST_BUSY	4'b0001
`define	SYNCST_DONE	4'b0010
`define	SYNCST_FACK	4'b0100
`define	SYNCST_WAIT	4'b1000

// Read data latch delay.
`define	LATCH_MSB	2

reg	a_ack	= 0;
reg	a_rty	= 0;
reg	a_err	= 0;
reg	[ESB:0]	a_sel	= 0;
reg	[MSB:0]	a_dat	= 0;
reg	b_ack_r	= 0;
reg	b_rty_r	= 0;
reg	b_err_r	= 0;
reg	[ASB+DIFF:0]	a_adr;
reg	[ESB:0]	a_sel_r;
reg	[MSB:0]	a_dat_r;

reg	b_cyc	= 0;
reg	b_we	= 0;
reg	[ASB:0]	b_adr;
reg	[SSB:0]	b_sel;
reg	[WSB:0]	b_dat;

reg	[`LATCH_MSB:0]	a_latch	= 0;
reg	[3:0]	state	= `SYNCST_IDLE;

wire	busy;

assign	#2 busy	= (state != `SYNCST_IDLE);

assign	a_ack_o	= HIGHZ ? (a_ack ? 1'b1 : 1'bz) : a_ack ;
assign	a_rty_o	= HIGHZ ? (a_rty ? 1'b1 : 1'bz) : a_rty ;
assign	a_err_o	= HIGHZ ? (a_err ? 1'b1 : 1'bz) : a_err ;
assign	a_sel_o	= HIGHZ ? (busy ? a_sel : 'bz) : a_sel ;
assign	a_dat_o	= HIGHZ ? (busy ? a_dat : 'bz) : a_dat ;

assign	b_cyc_o	= HIGHZ ? (busy ? b_cyc : 1'bz) : b_cyc ;
assign	b_stb_o	= HIGHZ ? (busy ? b_cyc : 1'bz) : b_cyc ;
assign	b_we_o	= HIGHZ ? (busy ? b_we : 1'bz) : b_we ;
assign	b_adr_o	= HIGHZ ? (busy ? b_adr : 'bz) : b_adr ;
assign	b_sel_o	= HIGHZ ? (busy ? b_sel : 'bz) : b_sel ;
assign	b_dat_o	= HIGHZ ? (busy ? b_dat : 'bz) : b_dat ;


//---------------------------------------------------------------------------
// State machine logic.
//
always @(posedge a_clk_i)
	a_latch	<= #2 {a_latch[`LATCH_MSB:1], b_ack_i};

always @(posedge a_clk_i)
	if (wb_rst_i)
		{b_ack_r, b_rty_r, b_err_r}	<= #2 0;
	else if (state == `SYNCST_IDLE)
		{b_ack_r, b_rty_r, b_err_r}	<= #2 0;
	else if (b_ack_r || b_rty_r || b_err_r)
		{b_ack_r, b_rty_r, b_err_r}	<= #2 0;
	else if (state == `SYNCST_BUSY || state == `SYNCST_FACK)
		{b_ack_r, b_rty_r, b_err_r}	<= #2 {b_ack_i, b_rty_i, b_err_i};

always @(posedge a_clk_i)
	if (wb_rst_i)	state	<= #2 `SYNCST_IDLE;
	else case (state)
	`SYNCST_IDLE:
		if (a_stb_i) begin
			if (a_we_i)	state	<= #2 `SYNCST_FACK;
			else		state	<= #2 `SYNCST_BUSY;
		end
	
	`SYNCST_BUSY:
		if (b_ack_r)
			state	<= #2 `SYNCST_WAIT;
	
	`SYNCST_DONE:	state	<= #2 `SYNCST_WAIT;

	`SYNCST_FACK:	// Can Fast ACKnowledge writes.
		if (b_ack_r)	state	<= #2 	`SYNCST_WAIT;
	
	`SYNCST_WAIT:
		if (!a_ack && !b_ack_r)	state	<= #2 `SYNCST_IDLE;
	
	endcase


//---------------------------------------------------------------------------
// Port A logic.
//
always @(posedge a_clk_i)
	if (wb_rst_i)
		a_ack	<= #2 0;
	else if (a_ack)
		a_ack	<= #2 0;
	else if (state == `SYNCST_IDLE && a_stb_i && a_we_i)	// FACK
		a_ack	<= #2 1;
	else if (b_ack_r && (state == `SYNCST_BUSY || state == `SYNCST_WAIT))
		a_ack	<= #2 1;
	else
		a_ack	<= #2 0;


always @(posedge a_clk_i)
	if (state == `SYNCST_IDLE && a_stb_i)	a_adr	<= #2 a_adr_i;

always @(posedge a_clk_i)
	if (state == `SYNCST_IDLE && a_stb_i)
		{a_sel_r, a_dat_r}	<= #2 {a_sel_i, a_dat_i};


// Sample the LSB of `a_adr' to determine which word to latch.
wire	[MSB:0]	dat_f	= a_adr_i[0] ? b_dat_i[WSB:LDAT] : b_dat_i[MSB:0] ;
wire	[MSB:0]	sel_f	= a_adr_i[0] ? b_sel_i[SSB:LSEL] : b_sel_i[ESB:0] ;
always @(posedge a_clk_i)
	if (CWIDTH == WWIDTH) begin
		if (a_latch)	{a_sel, a_dat}	<= #2 {b_sel_i, b_dat_i};
	end else
		if (a_latch)	{a_sel, a_dat}	<= #2 {sel_f, dat_f};


//---------------------------------------------------------------------------
// Port B logic.
//
always @(posedge b_clk_i)
	if (wb_rst_i)
		b_cyc	<= #2 0;
	else if (b_ack_i)
		b_cyc	<= #2 0;
	else if (state != `SYNCST_IDLE)
		b_cyc	<= #2 1;

always @(posedge b_clk_i)
	if (wb_rst_i)	b_we	<= #2 0;
	else		b_we	<= #2 (state == `SYNCST_FACK);

always @(posedge b_clk_i)
	b_adr	<= #2 a_adr[ASB+DIFF:DIFF];


wire	[WSB:0]	dat_t	= {a_dat_r, a_dat_r} ;
wire	[WSB:0]	sel_t	= a_adr[0] ?	{a_sel_r, {ENABLES{1'b0}}} :
					{{ENABLES{1'b0}}, a_sel_r} ;
always @(posedge b_clk_i)
	if (CWIDTH == WWIDTH)
		{b_sel, b_dat}	<= #2 {a_sel_r, a_dat_r};
	else
		{b_sel, b_dat}	<= #2 {sel_t, dat_t};


endmodule	// wb_sync
