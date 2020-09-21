/***************************************************************************
 *                                                                         *
 *   wb_new_pci_mem.v - A module that connects a block of memory to the    *
 *     PCI Local Bus. The memory can work at different frequencies due to  *
 *     the use of asynchronous FIFOs.                                      *
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

// This module does most of the PCI decoding on the WB side reducing the
// number of async FIFOs needed.

// We use half-full detection since we don't know how much space in the FIFO
// is left when we have to decide the value of TRDY#. This is probably a good
// balance of size and performance.


// PCI memory commands.
`define	PCI_MEMREAD	4'b0110
`define	PCI_MEMWRITE	4'b0111


`timescale 1ns/100ps
module wb_new_pci_mem #(
	parameter	ADDRESS		= 10,
	parameter	HIGHZ		= 0,

	parameter	FIFOWIDTH	= 37,
	parameter	MSB		= (32 - ADDRESS - 2) - 1,
	parameter	ASB		= ADDRESS - 1,
	parameter	WFSIZE		= ADDRESS + 32 + 4,
	parameter	WSB		= WFSIZE - 1
) (
	input		pci_clk_i,
	input		pci_rst_ni,

	input		pci_frame_ni,
	output	reg	pci_devsel_no	= 1,
	input		pci_irdy_ni,
	output	reg	pci_trdy_no	= 1,

	output	reg	pci_stop_no	= 1,

	input	[3:0]	pci_cbe_ni,
	input	[31:0]	pci_ad_i,
	output	reg	[31:0]	pci_ad_o,

	output		active_o,
	output		selected_o,

	input		mm_enable_i,
	input	[MSB:0]	mm_addr_i,	// 4kB aligned, lower 12 bits not included

	output		bursting_o,

	input		wb_clk_i,
	input		wb_rst_i,
	output	reg	wb_cyc_o	= 0,
	output		wb_stb_o,
	output		wb_we_o,
	input		wb_ack_i,
	input		wb_rty_i,
	input		wb_err_i,
	output	[2:0]	wb_cti_o,
	output	[1:0]	wb_bte_o,
	output	[ASB:0]	wb_adr_o,
	output	[3:0]	wb_sel_o,
	output	[31:0]	wb_dat_o,
	input	[3:0]	wb_sel_i,
	input	[31:0]	wb_dat_i
);


`define PCIST_IDLE	3'b000
`define	PCIST_READ	3'b001
`define	PCIST_WRITE	3'b010
`define	PCIST_STOP	3'b100
reg	[2:0]	pci_st	= `PCIST_IDLE;
reg		f_rst_n	= 1;
reg	select_r	= 0;
wire	addr_match, mem_trans, pci_memop, pci_done;

wire	p2w_write, p2w_full, p2w_empty, p2w_half;
wire	[36:0]	p2w_from;
wire	w2p_read, w2p_write, w2p_full, w2p_empty, w2p_half;
wire	[3:0]	w2p_sel;
wire	[31:0]	w2p_dat;
wire		wb_end;


//---------------------------------------------------------------------------
//  PCI Clock Domain.
//
assign	#3 addr_match	= (pci_ad_i [31:(ADDRESS + 2)] == mm_addr_i [MSB:0]);
assign	#2 mem_trans	= (pci_cbe_ni == `PCI_MEMREAD || pci_cbe_ni == `PCI_MEMWRITE);
assign	#2 pci_memop	= !pci_frame_ni && addr_match && mem_trans && mm_enable_i;
assign	#2 pci_done	= ((pci_frame_ni || !pci_stop_no) && !pci_irdy_ni && !pci_trdy_no);

assign	#2 p2w_write	= (pci_memop && pci_st == `PCIST_IDLE) || (pci_st == `PCIST_WRITE && !pci_irdy_ni && !pci_trdy_no);

assign	#2 w2p_read	= !w2p_empty && !pci_irdy_ni;


assign	#2 selected_o	= (pci_st != `PCIST_IDLE) || select_r;
assign	#2 active_o	= (pci_st == `PCIST_READ);


always @(posedge pci_clk_i)
	if (!pci_rst_ni)	pci_st	<= #2 `PCIST_IDLE;
	else case (pci_st)
	
	`PCIST_IDLE: begin
		if (pci_memop) begin
			if (p2w_half)			pci_st	<= #2 `PCIST_STOP;
			else if (pci_cbe_ni [0])	pci_st	<= #2 `PCIST_WRITE;
			else				pci_st	<= #2 `PCIST_READ;
		end
	end
	
	// Wait for the data to be returned
	`PCIST_READ, `PCIST_WRITE: begin
		if (pci_done)
			pci_st	<= #2 `PCIST_IDLE;
	end
	
	// Issue a retry later. (DISCONNECT WITHOUT DATA?)
	`PCIST_STOP:	pci_st	<= #2 `PCIST_IDLE;
	
	endcase


always @(posedge pci_clk_i)
	if (!pci_rst_ni)	pci_devsel_no	<= #2 1;
	else case (pci_st)
	
	`PCIST_IDLE: begin
		if (pci_memop)	pci_devsel_no	<= #2 0;
		else		pci_devsel_no	<= #2 1;
	end
	
	`PCIST_READ, `PCIST_WRITE: begin
		if (pci_done)	pci_devsel_no	<= #2 1;
		else		pci_devsel_no	<= #2 0;
	end
	
	`PCIST_STOP:		pci_devsel_no	<= #2 1;
	
	endcase


always @(posedge pci_clk_i)
	if (!pci_rst_ni)		pci_trdy_no	<= #2 1;
	else case (pci_st)
	
	`PCIST_IDLE, `PCIST_STOP:	pci_trdy_no	<= #2 1;
	
	`PCIST_READ: begin
		if (pci_done)		pci_trdy_no	<= #2 1;
		else if (!w2p_empty)	pci_trdy_no	<= #2 0;
		else			pci_trdy_no	<= #2 1;
	end
	
	`PCIST_WRITE: begin
		if (pci_done)		pci_trdy_no	<= #2 1;
		else if (!p2w_half)	pci_trdy_no	<= #2 0;
		else			pci_trdy_no	<= #2 1;
	end
	
	endcase


// TODO: Untested! This is designed to issue a DISCONNECT WITH DATA if a PCI
// Master tries to issue a burst-read.
always @(posedge pci_clk_i)
	if (!pci_rst_ni)	pci_stop_no	<= #2 1;
	else case (pci_st)
	
	`PCIST_IDLE, `PCIST_WRITE:
		pci_stop_no	<= #2 1;
	
	`PCIST_STOP:
		pci_stop_no	<= #2 0;
	
	`PCIST_READ:
		if (!pci_frame_ni && !pci_irdy_ni && !w2p_empty)
			pci_stop_no	<= #2 0;
		else
			pci_stop_no	<= #2 1;
	
	endcase


always @(posedge pci_clk_i)
	case (pci_st)
	
	`PCIST_READ:
		if (!w2p_empty && !pci_irdy_ni)	pci_ad_o	<= #2 w2p_dat;
	
	endcase


always @(posedge pci_clk_i)
	if (!pci_rst_ni)	select_r	<= #2 0;
	else			select_r	<= #2 (pci_st != `PCIST_IDLE);


//---------------------------------------------------------------------------
//  Wishbone Clock Domain.
//  TODO: The `wb_rty_i' signal should cause the PCI STOP# signal to be
//    asserted. Also, the `wb_err_i' signal should be handled too.
//
reg	retry		= 0;
reg	wb_stb		= 0;
reg	wb_we		= 0;
reg	[ASB:0]	wb_adr;
reg	[31:0]	wb_dat;
reg	[3:0]	wb_sel;
reg	wb_frame	= 0;

wire		p2w_read;
wire		p2w_frame;
wire	[3:0]	p2w_cbe_n;
wire	[31:0]	p2w_data;

`define	WBST_IDLE	4'b0000
`define	WBST_ADDR	4'b0001
`define	WBST_READ	4'b0010
`define	WBST_WRITE	4'b0100
`define	WBST_WAIT	4'b1000
reg	[3:0]	wb_st	= `WBST_IDLE;

assign	#2 w2p_write	= (wb_stb && !wb_we_o && wb_ack_i);

assign	#3 p2w_read	= !p2w_empty && !retry && (wb_st == `WBST_IDLE || wb_st == `WBST_ADDR || (wb_st == `WBST_WRITE && wb_stb && wb_ack_i && !wb_frame) || wb_st == `WBST_WAIT);

assign	wb_stb_o	= HIGHZ ? (wb_cyc_o ? wb_stb : 'bz) : wb_stb ;
assign	wb_we_o		= HIGHZ ? (wb_cyc_o ? wb_we : 'bz) : wb_we ;
assign	wb_adr_o	= HIGHZ ? (wb_cyc_o ? wb_adr : 'bz) : wb_adr ;
assign	wb_sel_o	= HIGHZ ? (wb_st == `WBST_WRITE ? wb_sel : 'bz) : wb_sel ;
assign	wb_dat_o	= HIGHZ ? (wb_st == `WBST_WRITE ? wb_dat : 'bz) : wb_dat ;

assign	wb_cti_o	= HIGHZ ? (wb_cyc_o ? 0 : 'bz ) : 0 ;
assign	wb_bte_o	= HIGHZ ? (wb_cyc_o ? 0 : 'bz ) : 0 ;

assign	#2 wb_end	= (p2w_empty && wb_stb && wb_ack_i);


always @(posedge wb_clk_i)
	if (wb_rst_i)	wb_st	<= #2 `WBST_IDLE;
	else case (wb_st)
	
	`WBST_IDLE:
		if (!p2w_empty && p2w_frame) begin
			if (p2w_cbe_n == `PCI_MEMWRITE)
				wb_st	<= #2 `WBST_ADDR;
			else
				wb_st	<= #2 `WBST_READ;
		end
	
	// Wishbone requires address and data to be presented simultaneously
	// for writes.
	`WBST_ADDR:
		if (!p2w_empty)	wb_st	<= #2 `WBST_WRITE;
	
	// Burst reads unsupported.
	`WBST_READ:
		if (wb_end)	wb_st	<= #2 `WBST_IDLE;
	
	`WBST_WRITE:
		if (wb_stb && wb_rty_i)
			wb_st	<= #2 `WBST_WAIT;
		else if (wb_stb && wb_ack_i) begin
			if (wb_frame)
				wb_st	<= #2 `WBST_IDLE;
			else if (p2w_empty)
				wb_st	<= #2 `WBST_WAIT;
		end
	
	// If the PCI hasn't finished, WAIT for more data from the FIFO.
	`WBST_WAIT:
		if (!p2w_empty)	wb_st	<= #2 `WBST_WRITE;
	
	endcase


always @(posedge wb_clk_i)
	if (wb_rst_i)	wb_cyc_o	<= #2 0;
	else case (wb_st)
	
	`WBST_IDLE:
		if (!p2w_empty && wb_frame) begin
			if (p2w_cbe_n == `PCI_MEMREAD)
				wb_cyc_o	<= #2 1;
			else
				wb_cyc_o	<= #2 0;
		end else
			wb_cyc_o	<= #2 0;	// Needed?
	
	`WBST_ADDR:
		if (!p2w_empty)	wb_cyc_o	<= #2 1;
	
	
	`WBST_READ, `WBST_WRITE:
		if (wb_rty_i)
			wb_cyc_o	<= #2 0;
		else if (wb_stb && wb_ack_i) begin
			if (wb_frame || p2w_empty)
				wb_cyc_o	<= #2 0;
			else
				wb_cyc_o	<= #2 1;
		end else
			wb_cyc_o	<= #2 1;
	
	endcase


always @(posedge wb_clk_i)
	if (wb_rst_i)		wb_stb	<= #2 0;
	else case (wb_st)
	
	`WBST_IDLE:
		if (!p2w_empty && wb_frame) begin
			if (p2w_cbe_n == `PCI_MEMREAD)
				wb_stb	<= #2 1;
			else
				wb_stb	<= #2 0;
		end else
			wb_stb	<= #2 0;	// Needed?
	
	`WBST_ADDR:
		if (!p2w_empty)	wb_stb	<= #2 1;
	
	
	`WBST_READ:
		if (wb_ack_i)	wb_stb	<= #2 0;
		else		wb_stb	<= #2 1;
	
	`WBST_WRITE:
		if (wb_rty_i)
			wb_stb	<= #2 0;
		else if (!wb_stb && !p2w_empty)
			wb_stb	<= #2 1;
		else if (wb_stb && wb_ack_i) begin
			if (p2w_empty || wb_frame)	wb_stb	<= #2 0;
			else				wb_stb	<= #2 1;
		end
	
	`WBST_WAIT:	wb_stb	<= #2 0;
	
	endcase


always @(posedge wb_clk_i)
	case (wb_st)
	
	`WBST_IDLE:
		wb_adr	<= #2 p2w_data [ASB+2:2];
	
// 	`WBST_WRITE, `WBST_READ:
	`WBST_WRITE:
		if (wb_ack_i && wb_stb)
			wb_adr	<= #2 wb_adr + 1;
	
	// TODO: Address incrementing for PCI burst writes.
	
	endcase


wire	[3:0] #2 wb_sel_w	= ~p2w_cbe_n;
always @(posedge wb_clk_i)
	if (p2w_read)
		{wb_sel, wb_dat}	<= #2 {wb_sel_w, p2w_data};


always @(posedge wb_clk_i)
	if (wb_rst_i)
		wb_we	<= #2 0;
	else if (wb_st == `WBST_ADDR && !p2w_empty)
		wb_we	<= #2 1;
	else if (wb_stb && wb_ack_i && wb_frame)
		wb_we	<= #2 0;
	else if (wb_st == `WBST_WRITE && !p2w_empty)
		wb_we	<= #2 1;


always @(posedge wb_clk_i)
	if (wb_rst_i)		wb_frame	<= #2 0;
	else if (p2w_read)	wb_frame	<= #2 p2w_frame;


// If a write op was stopped, don't load new data until op completed.
always @(posedge wb_clk_i)
	if (wb_rst_i)
		retry	<= #2 0;
	else if (wb_st == `WBST_WRITE) begin
		if (wb_rty_i)
			retry	<= #2 1;
		else// if (wb_ack_i)
			retry	<= #2 0;
	end


//---------------------------------------------------------------------------
//  Cross Domain Async FIFOs.
//
wire	#2 pci_cmd	= pci_memop || pci_frame_ni;//(pci_st == `PCIST_IDLE);
afifo16 #(
	.WIDTH		(FIFOWIDTH)
) P2WFIFO (
	.reset_ni	(pci_rst_ni),
	
	// Dequeue write data and send to the memory.
	.rd_clk_i	(wb_clk_i),
	.rd_en_i	(p2w_read),
	.rd_data_o	({p2w_frame, p2w_cbe_n, p2w_data}),
	
	// Store incoming commands from the master.
	.wr_clk_i	(pci_clk_i),
	.wr_en_i	(p2w_write),
	.wr_data_i	({pci_cmd, pci_cbe_ni, pci_ad_i}),
	
	.wfull_o	(p2w_full),
	.rempty_o	(p2w_empty),
	.whalfish_o	(p2w_half)
);


afifo16 #(
	.WIDTH		(FIFOWIDTH-1)
) W2PFIFO (
	.reset_ni	(pci_rst_ni),
	
	// Dequeue write data and send to the memory.
	.rd_clk_i	(pci_clk_i),
	.rd_en_i	(w2p_read),
	.rd_data_o	({w2p_sel, w2p_dat}),
	
	// Store incoming commands from the master.
	.wr_clk_i	(wb_clk_i),
	.wr_en_i	(w2p_write),
	.wr_data_i	({wb_sel_i, wb_dat_i}),
	
	.wfull_o	(w2p_full),
	.rempty_o	(w2p_empty)
);


endmodule	// wb_new_pci_mem
