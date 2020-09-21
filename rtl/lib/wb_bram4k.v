/***************************************************************************
 *                                                                         *
 *   wb_bram4k.v - A Wishbone compliant interface to two Xilinx BRAMs.     *
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

// TODO: BTE support is required, but unimplemented.

`timescale 1ns/100ps
module wb_bram4k (
	wb_clk_i,	// 50 MHz typical with Spartan III
	wb_rst_i,
	
	wb_cyc_i,
	wb_stb_i,
	wb_we_i,
	wb_ack_o,
	wb_rty_o,	// TODO
	wb_err_o,	// Caused by unsupported `wb_sel_i'
	wb_cti_i,
	wb_bte_i,
	wb_adr_i,
	
	wb_sel_i,	// Spartan III FPGAs don't support this
	wb_dat_i,
	wb_sel_o,
	wb_dat_o
);

parameter	HIGHZ	= 0;

input		wb_clk_i;	// Wishbone system signals
input		wb_rst_i;

input		wb_cyc_i;	// Wishbone control signals
input		wb_stb_i;
input		wb_we_i;
output		wb_ack_o;
output		wb_rty_o;
output		wb_err_o;
input	[2:0]	wb_cti_i;
input	[1:0]	wb_bte_i;

input	[9:0]	wb_adr_i;	// Address/data signals
input	[3:0]	wb_sel_i;	// TODO: Check these and generate error
input	[31:0]	wb_dat_i;
output	[3:0]	wb_sel_o;
output	[31:0]	wb_dat_o;


reg	wb_ack	= 0;

reg	sel		= 0;
reg	burst		= 0;
reg	[9:0]	baddr	= 0;

wire	ack;
wire	[31:0]	data_out;
wire	[9:0]	addr;
wire	wren0, wren1, wren2, wren3;

assign	#2 wb_ack_o	= HIGHZ ? (wb_cyc_i && wb_stb_i ? wb_ack : 'bz) : wb_ack ;
assign	#2 wb_rty_o	= HIGHZ ? (wb_cyc_i && wb_stb_i ? 0 : 'bz) : 0 ;
assign	#2 wb_err_o	= HIGHZ ? (wb_cyc_i && wb_stb_i ? 0 : 'bz) : 0 ;
assign	#2 wb_dat_o	= HIGHZ ? (sel ? data_out : 'bz) : data_out ;
assign	#2 wb_sel_o	= HIGHZ ? (sel ? 4'hf : 'bz) : {4{sel}};

assign	#2 wren0	= wb_cyc_i && wb_stb_i && wb_ack && wb_we_i && wb_sel_i [0];
assign	#2 wren1	= wb_cyc_i && wb_stb_i && wb_ack && wb_we_i && wb_sel_i [1];
assign	#2 wren2	= wb_cyc_i && wb_stb_i && wb_ack && wb_we_i && wb_sel_i [2];
assign	#2 wren3	= wb_cyc_i && wb_stb_i && wb_ack && wb_we_i && wb_sel_i [3];


assign	#2 ack		= wb_cyc_i && wb_stb_i;
assign	#2 addr		= burst ? baddr : wb_adr_i ;


wire	#2 sel_w	= wb_cyc_i && wb_stb_i && !wb_we_i && !(wb_cti_i == 7);
always @(posedge wb_clk_i)
	if (wb_rst_i)	sel	<= #2 0;
	else		sel	<= #2 sel_w;

wire	#2 deassert_ack	= (wb_cti_i [2] == 1) || (wb_cti_i == 0);
always @(posedge wb_clk_i)
	if (wb_rst_i)		wb_ack	<= #2 0;
	else if (!wb_ack)	wb_ack	<= #2 ack;
	else if (deassert_ack)	wb_ack	<= #2 0;

wire	#2 burst_w	= wb_cyc_i && wb_stb_i && !wb_we_i && (wb_cti_i == 2);
always @(posedge wb_clk_i)
	if (wb_rst_i)	burst	<= #2 0;
	else		burst	<= #2 burst_w;

// TODO: Does this always work?
always @(posedge wb_clk_i)
	if (wb_cti_i == 7)	baddr	<= #2 wb_adr_i + 1;
	else if (wb_ack)	baddr	<= #2 baddr + 1;
	else			baddr	<= #2 wb_adr_i + 1;


RAMB16_S9_S9 BRAM0 (
	.DIA	(wb_dat_i [31:24]),
	.DIPA	(0),
	.ADDRA	({1'b0, addr}),	// TODO: Too slow?
	.ENA	(wb_stb_i),
	.WEA	(wren3),
	.SSRA	(wb_rst_i),	// TODO: Not needed?
	.CLKA	(wb_clk_i),
	.DOA	(data_out [31:24]),
	.DOPA	(),
	
	.DIB	(wb_dat_i [23:16]),
	.DIPB	(0),
	.ADDRB	({1'b1, addr}),
	.ENB	(wb_stb_i),
	.WEB	(wren2),
	.SSRB	(wb_rst_i),
	.CLKB	(wb_clk_i),
	.DOB	(data_out [23:16]),
	.DOPB	()
);


RAMB16_S9_S9 BRAM1 (
	.DIA	(wb_dat_i [15:8]),
	.DIPA	(0),
	.ADDRA	({1'b0, addr}),
	.ENA	(wb_stb_i),
	.WEA	(wren1),
	.SSRA	(wb_rst_i),
	.CLKA	(wb_clk_i),
	.DOA	(data_out [15:8]),
	.DOPA	(),
	
	.DIB	(wb_dat_i [7:0]),
	.DIPB	(0),
	.ADDRB	({1'b1, addr}),
	.ENB	(wb_stb_i),
	.WEB	(wren0),
	.SSRB	(wb_rst_i),
	.CLKB	(wb_clk_i),
	.DOB	(data_out [7:0]),
	.DOPB	()
);


endmodule	// wb_bram4k
