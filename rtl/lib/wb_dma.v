/***************************************************************************
 *                                                                         *
 *   wb_dma.v - Allows buffered DMA transfers between modules. Basically   *
 *     just a synchronous FIFO plus some extra logic.                      *
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
// NOTE: If an odd number of 16-bit words is written, since the WB transfers
// are 32-bit, then the last 16-bit word is essentially random.
// If this is a problem, write an even umber of words.
//

// Memory mapped addresses:
// 0:	Data
// 1:	Address lo
// 2:	Address hi
// 3:	Control

// Control register bit fields:
// 1-0:	Select bits ANDN mask. (Zero means unchanged.)
// 3-2: Select bits OR mask. (Zero means unchanged.)
// 7:	Write contents to memory (busy if set when read).

// NOTE: If a DMA write is issued when there is zero data in the DMA, 2 kB of
// the previous contents will be written to to the destination address.
// Useful for block writes/erases?


`timescale 1ns/100ps
module wb_dma #(
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
	parameter	ASB	= ADDRESS - 1
) (
	input		wb_rst_i,
	
	// 16-bit, 150 MHz, atomic transfers only
	input		a_clk_i,
	input		a_cyc_i,
	input		a_stb_i,
	input		a_we_i,
	output		a_ack_o,
	output		a_rty_o,
	output		a_err_o,
	input	[2:0]	a_cti_i,
	input	[1:0]	a_bte_i,
	input	[1:0]	a_adr_i,
	input	[ESB:0]	a_sel_i,
	input	[MSB:0]	a_dat_i,
	output	[ESB:0]	a_sel_o,
	output	[MSB:0]	a_dat_o,
	
	// 32-bit, 50 MHz, burst transfers supported
	input		b_clk_i,
	output		b_cyc_o,
	output		b_cyc_ao,
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


`define	DMAST_IDLE	2'b00
`define	DMAST_BUSY	2'b01
`define	DMAST_DONE	2'b10

// Read data latch delay.
`define	LATCH_MSB	2

reg	a_wr	= 0;
reg	a_ack	= 0;
reg	a_rty	= 0;
wire	[ESB:0]	a_sel	= {ENABLES{1'b1}};
reg	[MSB:0]	a_dat	= 0;

reg	b_cyc	= 0;
reg	[MSB:0]	addr_lo	= 0, addr_hi	= 0;
reg	[ASB:0]	b_adr;
reg	[2:0]	b_cti	= 3'b010;
reg	[1:0]	b_bte	= 2'b00;
wire	[SSB:0]	b_sel;
wire	[WSB:0]	b_dat;

reg	[3:0]	state	= `DMAST_IDLE;

reg	[9:0]	wr_ptr	= 0;
// reg	[8:0]	rd_ptr	= 0;
wire	[8:0]	rd_ptr;

reg		b_ack_r	= 0;
wire	[8:0]	b_cnt;
reg	[1:0]	sels_andn_mask	= 2'b00;
reg	[1:0]	sels_or_mask	= 2'b00;

wire	busy, do_stuff, ctrl_write, start_dma;

// CLK B domain.
wire		#2 dma_xfer	= (state == `DMAST_BUSY);
reg		dma_done	= 0;
reg		dma_start	= 0;

wire	data_write, adlo_write, adhi_write, ctrl_read;
wire	a_rty_w, a_ack_w;


assign	#2 busy	= (state != `DMAST_IDLE);

assign	a_ack_o	= HIGHZ ? (a_ack ? 1'b1 : 1'bz) : a_ack ;
assign	a_rty_o	= HIGHZ ? (a_rty ? 1'b1 : 1'bz) : a_rty ;
assign	a_err_o	= HIGHZ ? (a_stb_i ? 1'b0 : 1'bz) : 1'b0 ;
assign	a_sel_o	= HIGHZ ? (busy ? a_sel : 'bz) : a_sel ;
assign	a_dat_o	= HIGHZ ? (busy ? a_dat : 'bz) : a_dat ;

assign	b_cyc_o	= HIGHZ ? (busy ? b_cyc : 1'bz) : b_cyc ;
assign	b_stb_o	= HIGHZ ? (busy ? b_cyc : 1'bz) : b_cyc ;
assign	b_we_o	= HIGHZ ? (busy ? 1'b1 : 1'bz) : 1'b1 ;
assign	b_cti_o	= HIGHZ ? (busy ? b_cti : 1'bz) : b_cti ;
assign	b_bte_o	= HIGHZ ? (busy ? b_bte : 1'bz) : b_bte ;
assign	b_adr_o	= HIGHZ ? (busy ? b_adr : 'bz) : b_adr ;
assign	b_sel_o	= HIGHZ ? (busy ? b_sel : 'bz) : b_sel ;
assign	b_dat_o	= HIGHZ ? (busy ? b_dat : 'bz) : b_dat ;

assign	#2 do_stuff	= a_stb_i;
assign	#2 data_write	= a_stb_i && a_we_i && a_adr_i == 2'b00;
assign	#2 adlo_write	= a_stb_i && a_we_i && a_adr_i == 2'b01;
assign	#2 adhi_write	= a_stb_i && a_we_i && a_adr_i == 2'b10;
assign	#2 ctrl_write	= a_stb_i && a_we_i && a_adr_i == 2'b11;
assign	#2 ctrl_read	= a_stb_i && !a_we_i && a_adr_i == 2'b11;
assign	#2 start_dma	= a_stb_i && a_we_i && a_adr_i == 2'b11 && a_dat_i[7];


always @(posedge a_clk_i)
	if (wb_rst_i)	state	<= #2 0;
	else case (state)
	
	`DMAST_IDLE: begin
		if (start_dma)
			state	<= #2 `DMAST_BUSY;
	end
	
	`DMAST_BUSY: begin
		if (dma_done)
			state	<= #2 `DMAST_DONE;
	end
	
	`DMAST_DONE:	state	<= #2 `DMAST_IDLE;
	
	endcase



assign	#2 a_rty_w	= (state != `DMAST_IDLE) && start_dma && !(a_ack || a_rty);
assign	#2 a_ack_w	= !((state != `DMAST_IDLE) && start_dma)
			  && do_stuff && !(a_ack || a_rty);

always @(posedge a_clk_i)
	if (wb_rst_i)	{a_rty, a_ack}	<= #2 0;
	else		{a_rty, a_ack}	<= #2 {a_rty_w, a_ack_w};

/*
always @(posedge a_clk_i)
	if (wb_rst_i)	{a_rty, a_ack}	<= #2 0;
	else if (do_stuff && !a_rty && !a_ack)
		case (state)
		`DMAST_BUSY, `DMAST_DONE:
			if (start_dma)	a_rty	<= #2 1;
			else		a_ack	<= #2 1;
		default:	a_ack	<= #2 1;
		endcase
	else
		{a_rty, a_ack}	<= #2 0;
*/

always @(posedge a_clk_i)
	if (wb_rst_i)
		{sels_or_mask, sels_andn_mask}	<= #2 0;
	else if (ctrl_write)
		{sels_or_mask, sels_andn_mask}	<= #2 a_dat_i[3:0];


always @(posedge a_clk_i)
	if (wb_rst_i)			a_wr	<= #2 0;
	else if (data_write && !a_wr)	a_wr	<= #2 1;
	else				a_wr	<= #2 0;

// TODO: Use MFSR?
always @(posedge a_clk_i)
	if (wb_rst_i)	wr_ptr	<= #2 0;
	else if (a_wr)	wr_ptr	<= #2 wr_ptr + 1;


wire	[3:0]	masks	= {sels_or_mask, sels_andn_mask};
always @(posedge a_clk_i)
	if (do_stuff && !a_we_i) begin
		case (a_adr_i)
		2'b01:	a_dat	<= #2 addr_lo;
		2'b10:	a_dat	<= #2 addr_hi;
		2'b11:	a_dat	<= #2 {8'h0, (state != `DMAST_IDLE), 3'h0, masks};
		default:a_dat	<= #2 'bx;
		endcase
	end

// Enable address to be set (32-bit aligned).
always @(posedge a_clk_i)
	if (wb_rst_i)		addr_lo	<= #2 0;
	else if (adlo_write)	addr_lo	<= #2 a_dat_i;

always @(posedge a_clk_i)
	if (wb_rst_i)		addr_hi	<= #2 0;
	else if (adhi_write)	addr_hi	<= #2 a_dat_i;


always @(posedge a_clk_i)
	if (wb_rst_i)		b_ack_r	<= #2 0;
	else if (!b_ack_r)	b_ack_r	<= #2 b_ack_i;
	else			b_ack_r	<= #2 0;


always @(posedge a_clk_i)
	if (wb_rst_i)		dma_start	<= #2 0;
	else if (start_dma)	dma_start	<= #2 1;
	else if (b_cyc)		dma_start	<= #2 0;


//---------------------------------------------------------------------------
//  WishBone Bus Clock Domain.
//

wire	#2 dma_done_w	= (b_cnt == 1 && b_ack_i);
always @(posedge b_clk_i)
	if (wb_rst_i)
		dma_done	<= #2 0;
	else if (dma_done_w)
		dma_done	<= #2 1;
	else
		dma_done	<= #2 0;


assign	#2 b_cyc_ao	= dma_start || b_cyc;

always @(posedge b_clk_i)
	if (wb_rst_i)		b_cyc	<= #2 0;
	else if (dma_done_w)	b_cyc	<= #2 0;
	else if (dma_start)	b_cyc	<= #2 1;


// TODO:
always @(posedge b_clk_i)
	if (state == `DMAST_IDLE)
		b_adr	<= #2 {addr_hi, addr_lo};
	else if (b_ack_i)
		b_adr	<= #2 b_adr + 1;


// Set the burst type.
always @(posedge b_clk_i)
	if (wb_rst_i)
		{b_cti, b_bte}	<= #2 {3'b111, 2'b00};
	else if ((b_cnt == 2 && b_ack_i) || b_cnt < 2)
		{b_cti, b_bte}	<= #2 {3'b111, 2'b00};
	else
		{b_cti, b_bte}	<= #2 {3'b010, 2'b00};	// Standard incrementing burst


// Pipelined BRAM reads.
wire	b_en;
pre_read #(
	.ADDRESS	(9),
	.INIT		(0)
) PR0 (
	.reset_i	(wb_rst_i),
	
	.a_clk_i	(a_clk_i),
	.a_wr_i		(a_wr && wr_ptr[0]),
	
	.b_clk_i	(b_clk_i),
	.b_rd_i		(b_ack_i),
	.b_cnt_o	(b_cnt),
	.b_en_ao	(b_en),
	.b_adr_ao	(rd_ptr)
);


wire	[1:0] #2 sels_w	= (a_sel_i & ~sels_andn_mask) | sels_or_mask;
RAMB16_S18_S36 RAM1 (
	.CLKA	(a_clk_i),
	.ENA	(1'b1),
	.SSRA	(1'b0),
	.WEA	(a_wr),
	.ADDRA	(wr_ptr),
	.DIA	(a_dat_i),
	.DIPA	(sels_w),
	.DOA	(),
	.DOPA	(),
	
	.CLKB	(b_clk_i),
	.ENB	(b_en),
	.SSRB	(1'b0),
	.WEB	(1'b0),
	.ADDRB	(rd_ptr),
	.DIB	(4'b1111),
	.DIPB	(32'hffffffff),
	.DOB	(b_dat),
	.DOPB	(b_sel)
);


`ifdef __icarus
always @(posedge a_clk_i)
	if (a_ack) begin
		if (data_write)		$display ("%5t: Data start.", $time);
		if (adlo_write)		$display ("%5t: Low address written.", $time);
		if (adhi_write)		$display ("%5t: High address written.", $time);
		if (start_dma)		$display ("%5t: DMA start.", $time);
		else if (ctrl_write)	$display ("%5t: Control write.", $time);
	end
`endif


endmodule	// wb_dma
