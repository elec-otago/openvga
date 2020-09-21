/***************************************************************************
 *                                                                         *
 *   wb_mux4to1.v - Connects to WB modules to look as one externally, but  *
 *     only supports atomic transfers.                                     *
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

// NOTE: Port A has the highest priority, Port D the lowest.
// TODO: Optimise? A 4-1 MUX is very slow.
// TODO: The high-impedance logic is very slow if used.

`timescale 1ns/100ps
module wb_mux4to1_async #(
	parameter	HIGHZ	= 0,
	parameter	WIDTH	= 32,
	parameter	ADDRESS	= 25,
	parameter	ENABLES	= WIDTH / 8,
	parameter	MSB	= WIDTH - 1,
	parameter	ESB	= ENABLES - 1,
	parameter	ASB	= ADDRESS - 1,
	parameter	TOTAL	= 8 + ADDRESS + ENABLES + WIDTH,
	parameter	TSB	= TOTAL - 1
) (
	input		wb_clk_i,
	input		wb_rst_i,
	
	input		a_cyc_i,
	input		a_stb_i,
	input		a_we_i,
	output		a_ack_o,
	output		a_rty_o,
	output		a_err_o,
	input	[2:0]	a_cti_i,
	input	[1:0]	a_bte_i,
	input	[ASB:0]	a_adr_i,
	input	[ESB:0]	a_sel_i,
	input	[MSB:0]	a_dat_i,
	output	[ESB:0]	a_sel_o,
	output	[MSB:0]	a_dat_o,
	
	input		b_cyc_i,
	input		b_stb_i,
	input		b_we_i,
	output		b_ack_o,
	output		b_rty_o,
	output		b_err_o,
	input	[2:0]	b_cti_i,
	input	[1:0]	b_bte_i,
	input	[ASB:0]	b_adr_i,
	input	[ESB:0]	b_sel_i,
	input	[MSB:0]	b_dat_i,
	output	[ESB:0]	b_sel_o,
	output	[MSB:0]	b_dat_o,
	
	input		c_cyc_i,
	input		c_stb_i,
	input		c_we_i,
	output		c_ack_o,
	output		c_rty_o,
	output		c_err_o,
	input	[2:0]	c_cti_i,
	input	[1:0]	c_bte_i,
	input	[ASB:0]	c_adr_i,
	input	[ESB:0]	c_sel_i,
	input	[MSB:0]	c_dat_i,
	output	[ESB:0]	c_sel_o,
	output	[MSB:0]	c_dat_o,
	
	input		d_cyc_i,
	input		d_stb_i,
	input		d_we_i,
	output		d_ack_o,
	output		d_rty_o,
	output		d_err_o,
	input	[2:0]	d_cti_i,
	input	[1:0]	d_bte_i,
	input	[ASB:0]	d_adr_i,
	input	[ESB:0]	d_sel_i,
	input	[MSB:0]	d_dat_i,
	output	[ESB:0]	d_sel_o,
	output	[MSB:0]	d_dat_o,
	
	output		x_cyc_o,
	output		x_stb_o,
	output		x_we_o,
	input		x_ack_i,
	input		x_rty_i,
	input		x_err_i,
	output	[2:0]	x_cti_o,
	output	[1:0]	x_bte_o,
	output	[ASB:0]	x_adr_o,
	input	[ESB:0]	x_sel_i,
	input	[MSB:0]	x_dat_i,
	output	[ESB:0]	x_sel_o,
	output	[MSB:0]	x_dat_o
);


wire	a_sel, b_sel, c_sel, d_sel;
wire	a_ack, b_ack, c_ack, d_ack;
wire	a_rty, b_rty, c_rty, d_rty;
wire	a_err, b_err, c_err, d_err;

wire	x_cyc, x_stb, x_we;
wire	[2:0]	x_cti;
wire	[1:0]	x_bte;
wire	[ASB:0]	x_adr;
wire	[ESB:0]	x_sel;
wire	[MSB:0]	x_dat;

`define	M4ST_PORTA	2'b00
`define	M4ST_PORTB	2'b01
`define	M4ST_PORTC	2'b10
`define	M4ST_PORTD	2'b11
reg	[1:0]	mux4_st	= `M4ST_PORTA;
wire	busy;

wire	[TSB:0]	a_sig	= {a_cyc_i, a_stb_i, a_we_i, a_cti_i, a_bte_i, a_adr_i, a_sel_i, a_dat_i};
wire	[TSB:0]	b_sig	= {b_cyc_i, b_stb_i, b_we_i, b_cti_i, b_bte_i, b_adr_i, b_sel_i, b_dat_i};
wire	[TSB:0]	c_sig	= {c_cyc_i, c_stb_i, c_we_i, c_cti_i, c_bte_i, c_adr_i, c_sel_i, c_dat_i};
wire	[TSB:0]	d_sig	= {d_cyc_i, d_stb_i, d_we_i, d_cti_i, d_bte_i, d_adr_i, d_sel_i, d_dat_i};

assign	#2 a_sel	= a_cyc_i && a_stb_i;
assign	#2 b_sel	= b_cyc_i && b_stb_i;
assign	#2 c_sel	= c_cyc_i && c_stb_i;
assign	#2 d_sel	= d_cyc_i && d_stb_i;
assign	#2 busy		= a_sel || (mux4_st != `M4ST_PORTA);

// TODO: Not strictly needed to meet WB spec? Sending ACKs to all modules
// should be safe?
assign	#2 a_ack	= (mux4_st == `M4ST_PORTA) ? x_ack_i : 1'b0 ;
assign	#2 b_ack	= (mux4_st == `M4ST_PORTB) ? x_ack_i : 1'b0 ;
assign	#2 c_ack	= (mux4_st == `M4ST_PORTC) ? x_ack_i : 1'b0 ;
assign	#2 d_ack	= (mux4_st == `M4ST_PORTD) ? x_ack_i : 1'b0 ;

assign	#2 a_ack_o	= HIGHZ ? (mux4_st == `M4ST_PORTA ? a_ack : 1'bz) : a_ack ;
assign	#2 b_ack_o	= HIGHZ ? (mux4_st == `M4ST_PORTB ? b_ack : 1'bz) : b_ack ;
assign	#2 c_ack_o	= HIGHZ ? (mux4_st == `M4ST_PORTC ? c_ack : 1'bz) : c_ack ;
assign	#2 d_ack_o	= HIGHZ ? (mux4_st == `M4ST_PORTD ? d_ack : 1'bz) : d_ack ;

assign	#2 a_rty	= (mux4_st == `M4ST_PORTA) ? x_rty_i : 1'b0 ;
assign	#2 b_rty	= (mux4_st == `M4ST_PORTB) ? x_rty_i : 1'b0 ;
assign	#2 c_rty	= (mux4_st == `M4ST_PORTC) ? x_rty_i : 1'b0 ;
assign	#2 d_rty	= (mux4_st == `M4ST_PORTD) ? x_rty_i : 1'b0 ;

assign	#2 a_rty_o	= HIGHZ ? (mux4_st == `M4ST_PORTA ? a_rty : 1'bz) : a_rty ;
assign	#2 b_rty_o	= HIGHZ ? (mux4_st == `M4ST_PORTB ? b_rty : 1'bz) : b_rty ;
assign	#2 c_rty_o	= HIGHZ ? (mux4_st == `M4ST_PORTC ? c_rty : 1'bz) : c_rty ;
assign	#2 d_rty_o	= HIGHZ ? (mux4_st == `M4ST_PORTD ? d_rty : 1'bz) : d_rty ;

assign	#2 a_err	= (mux4_st == `M4ST_PORTA) ? x_err_i : 1'b0 ;
assign	#2 b_err	= (mux4_st == `M4ST_PORTB) ? x_err_i : 1'b0 ;
assign	#2 c_err	= (mux4_st == `M4ST_PORTC) ? x_err_i : 1'b0 ;
assign	#2 d_err	= (mux4_st == `M4ST_PORTD) ? x_err_i : 1'b0 ;

assign	#2 a_err_o	= HIGHZ ? (mux4_st == `M4ST_PORTA ? a_err : 1'bz) : a_err ;
assign	#2 b_err_o	= HIGHZ ? (mux4_st == `M4ST_PORTB ? b_err : 1'bz) : b_err ;
assign	#2 c_err_o	= HIGHZ ? (mux4_st == `M4ST_PORTC ? c_err : 1'bz) : c_err ;
assign	#2 d_err_o	= HIGHZ ? (mux4_st == `M4ST_PORTD ? d_err : 1'bz) : d_err ;

assign	a_sel_o	= x_sel_i;
assign	b_sel_o	= x_sel_i;
assign	c_sel_o	= x_sel_i;
assign	d_sel_o	= x_sel_i;

assign	a_dat_o	= x_dat_i;
assign	b_dat_o	= x_dat_i;
assign	c_dat_o	= x_dat_i;
assign	d_dat_o	= x_dat_i;

assign	#2 x_cyc_o	= HIGHZ ? (busy ? x_cyc : 1'bz) : x_cyc ;
assign	#2 x_stb_o	= HIGHZ ? (busy ? x_stb : 1'bz) : x_stb ;
assign	#2 x_we_o	= HIGHZ ? (busy ? x_we  : 1'bz) : x_we ;
assign	#2 x_cti_o	= HIGHZ ? (busy ? x_cti : 1'bz) : x_cti ;
assign	#2 x_bte_o	= HIGHZ ? (busy ? x_bte : 1'bz) : x_bte ;
assign	#2 x_adr_o	= HIGHZ ? (busy ? x_adr : 1'bz) : x_adr ;
assign	#2 x_sel_o	= HIGHZ ? (busy ? x_sel : 1'bz) : x_sel ;
assign	#2 x_dat_o	= HIGHZ ? (busy ? x_dat : 1'bz) : x_dat ;


// TODO: Detect last transfer, will save a cycle of latency.
always @(posedge wb_clk_i)
	if (wb_rst_i)
		mux4_st	<= #2 `M4ST_PORTA;
	else case (mux4_st)
	`M4ST_PORTA:
		if (!a_sel) begin
			if (b_sel)	mux4_st	<= #2 `M4ST_PORTB;
			else if (c_sel)	mux4_st	<= #2 `M4ST_PORTC;
			else if (d_sel)	mux4_st	<= #2 `M4ST_PORTD;
		end
	
	`M4ST_PORTB:
		if (!b_sel) begin
			if (a_sel)	mux4_st	<= #2 `M4ST_PORTA;
			else if (c_sel)	mux4_st	<= #2 `M4ST_PORTC;
			else if (d_sel)	mux4_st	<= #2 `M4ST_PORTD;
			else		mux4_st	<= #2 `M4ST_PORTA;
		end
	
	`M4ST_PORTC:
		if (!c_sel) begin
			if (a_sel)	mux4_st	<= #2 `M4ST_PORTA;
			else if (b_sel)	mux4_st	<= #2 `M4ST_PORTB;
			else if (d_sel)	mux4_st	<= #2 `M4ST_PORTD;
			else		mux4_st	<= #2 `M4ST_PORTA;
		end
	
	`M4ST_PORTD:
		if (!d_sel) begin
			if (a_sel)	mux4_st	<= #2 `M4ST_PORTA;
			else if (b_sel)	mux4_st	<= #2 `M4ST_PORTB;
			else if (c_sel)	mux4_st	<= #2 `M4ST_PORTC;
			else		mux4_st	<= #2 `M4ST_PORTA;
		end
	
	endcase


mux4to1 #(
	.WIDTH	(TOTAL)
) MUX0 (
	.sel_i	(mux4_st),
	.in0_i	(a_sig),
	.in1_i	(b_sig),
	.in2_i	(c_sig),
	.in3_i	(d_sig),
	.out_o	({x_cyc, x_stb, x_we, x_cti, x_bte, x_adr, x_sel, x_dat})
);


endmodule	// wb_mux4to1
