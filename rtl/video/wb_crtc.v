/***************************************************************************
 *                                                                         *
 *   wb_crtc.v - A Wishbone comliant interface to a CRT controller.        *
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

// A simple 16-bit wide CRTC that responds only with classic synchronous
// Wishbone cycles.

`timescale 1ns/100ps
module wb_crtc #(
	parameter	HIGHZ	= 0,
	parameter	WIDTH	= 16,
	parameter	ENABLES	= WIDTH / 8,
	parameter	MSB	= WIDTH - 1,
	parameter	ESB	= ENABLES - 1,
	parameter	RSB	= 10
) (
	input		wb_clk_i,	// 50 MHz max. on a Spartan III
	input		wb_rst_i,	// Wishbone system signals
	
	input		wb_cyc_i,	// Wishbone control signals
	input		wb_stb_i,
	input		wb_we_i,
	output		wb_ack_o,
	output		wb_rty_o,
	output		wb_err_o,
	input	[2:0]	wb_adr_i,	// Index into CRTC regs
	
	input	[ESB:0]	wb_sel_i,
	input	[MSB:0]	wb_dat_i,
	output	[ESB:0]	wb_sel_o,
	output	[MSB:0]	wb_dat_o,
	
	input		crtc_clk_i,	// Character clock
	input		crtc_rst_ni,
	
	output	[MSB:0]	crtc_row_o,
	output	[MSB:0]	crtc_col_o,
	
	output		crtc_de_o,
	output		crtc_hsync_o,
	output		crtc_vsync_o,
	output		crtc_hblank_o,
	output		crtc_vblank_o
);


reg	[RSB:0]	hsync_t	= 11;
reg	[RSB:0]	hbporch	= 17;
reg	[RSB:0]	hactive	= 97;
reg	[RSB:0]	hfporch	= 99;

reg	[RSB:0]	vsync_t	= 1;
reg	[RSB:0]	vbporch	= 34;
reg	[RSB:0]	vactive	= 514;
reg	[RSB:0]	vfporch	= 524;

reg	[MSB:0]	wb_dat;
reg	[MSB:0]	wb_sel;

reg	wb_ack	= 0;
reg	sel	= 0;


assign	#2 wb_ack_o	= HIGHZ ? (sel ? wb_ack : 'bz) : wb_ack ;
assign	#2 wb_rty_o	= HIGHZ ? (sel ? 0 : 'bz) : 0 ;
assign	#2 wb_err_o	= HIGHZ ? (sel ? 0 : 'bz) : 0 ;

assign	#2 wb_dat_o	= HIGHZ ? (sel ? wb_dat : 'bz) : wb_dat ;
assign	#2 wb_sel_o	= HIGHZ ? (sel ? 2'b11 : 'bz) : {sel, sel} ;


// The CRTC register indices.
`define	CRTC_REG_HSYNC_DURATION	0
`define	CRTC_REG_HBACK_PORCH	1
`define	CRTC_REG_HACTIVE	2
`define	CRTC_REG_HFRONT_PORCH	3

`define	CRTC_REG_VSYNC_DURATION	4
`define	CRTC_REG_VBACK_PORCH	5
`define	CRTC_REG_VACTIVE	6
`define	CRTC_REG_VFRONT_PORCH	7

always @(posedge wb_clk_i)
	if (wb_rst_i) begin
		hsync_t	<= #2 11;
		hbporch	<= #2 17;
		hactive	<= #2 97;
		hfporch	<= #2 99;
		
		vsync_t	<= #2 1;
		vbporch	<= #2 34;
		vactive	<= #2 514;
		vfporch	<= #2 524;
	end else if (wb_cyc_i && wb_stb_i && wb_we_i)
		case (wb_adr_i)
		
		`CRTC_REG_HSYNC_DURATION: begin
			if (wb_sel_i [0])	hsync_t [7:0]	<= #2 wb_dat_i [7:0];
			if (wb_sel_i [1])	hsync_t [RSB:8]	<= #2 wb_dat_i [RSB:8];
		end
		
		`CRTC_REG_HBACK_PORCH: begin
			if (wb_sel_i [0])	hbporch [7:0]	<= #2 wb_dat_i [7:0];
			if (wb_sel_i [1])	hbporch [RSB:8]	<= #2 wb_dat_i [RSB:8];
		end
		
		`CRTC_REG_HACTIVE: begin
			if (wb_sel_i [0])	hactive [7:0]	<= #2 wb_dat_i [7:0];
			if (wb_sel_i [1])	hactive [RSB:8]	<= #2 wb_dat_i [RSB:8];
		end
		
		`CRTC_REG_HFRONT_PORCH: begin
			if (wb_sel_i [0])	hfporch [7:0]	<= #2 wb_dat_i [7:0];
			if (wb_sel_i [1])	hfporch [RSB:8]	<= #2 wb_dat_i [RSB:8];
		end
		
		`CRTC_REG_VSYNC_DURATION: begin
			if (wb_sel_i [0])	vsync_t [7:0]	<= #2 wb_dat_i [7:0];
			if (wb_sel_i [1])	vsync_t [RSB:8]	<= #2 wb_dat_i [RSB:8];
		end
		
		`CRTC_REG_VBACK_PORCH: begin
			if (wb_sel_i [0])	vbporch [7:0]	<= #2 wb_dat_i [7:0];
			if (wb_sel_i [1])	vbporch [RSB:8]	<= #2 wb_dat_i [RSB:8];
		end
		
		`CRTC_REG_VACTIVE: begin
			if (wb_sel_i [0])	vactive [7:0]	<= #2 wb_dat_i [7:0];
			if (wb_sel_i [1])	vactive [RSB:8]	<= #2 wb_dat_i [RSB:8];
		end
		
		`CRTC_REG_VFRONT_PORCH: begin
			if (wb_sel_i [0])	vfporch [7:0]	<= #2 wb_dat_i [7:0];
			if (wb_sel_i [1])	vfporch [RSB:8]	<= #2 wb_dat_i [RSB:8];
		end
		
		endcase


always @(posedge wb_clk_i)
	if (wb_cyc_i && wb_stb_i && !wb_we_i)
		case (wb_adr_i)
		`CRTC_REG_HSYNC_DURATION:	wb_dat	<= #2 hsync_t;
		`CRTC_REG_HBACK_PORCH:		wb_dat	<= #2 hbporch;
		`CRTC_REG_HACTIVE:		wb_dat	<= #2 hactive;
		`CRTC_REG_HFRONT_PORCH:		wb_dat	<= #2 hfporch;
		`CRTC_REG_VSYNC_DURATION:	wb_dat	<= #2 vsync_t;
		`CRTC_REG_VBACK_PORCH:		wb_dat	<= #2 vbporch;
		`CRTC_REG_VACTIVE:		wb_dat	<= #2 vactive;
		`CRTC_REG_VFRONT_PORCH:		wb_dat	<= #2 vfporch;
/*		// The following are in a different clock domain.
		`CRTC_REG_ROW_COUNT:		wb_dat	<= #2 crtc_row_o;
		`CRTC_REG_COL_COUNT:		wb_dat	<= #2 crtc_col_o;
		`CRTC_REG_CONTROL:		wb_dat	<= #2 crtc_ctrl;*/
		endcase


always @(posedge wb_clk_i)
	if (wb_rst_i)		wb_ack	<= #2 0;
	else if (!wb_ack)	wb_ack	<= #2 (wb_cyc_i && wb_stb_i);
	else			wb_ack	<= #2 0;


always @(posedge wb_clk_i)
	if (wb_rst_i)	sel	<= #2 0;
	else		sel	<= #2 (wb_cyc_i && wb_stb_i && !wb_we_i);


assign	crtc_row_o [MSB:RSB+1]	= 0;
assign	crtc_col_o [MSB:RSB+1]	= 0;
crtc #(
	.WIDTH	(RSB+1)
) CRTC0 (
	.clock_i	(crtc_clk_i),	// Character clock
	.reset_ni	(crtc_rst_ni),
	.enable_i	(1'b1),		// TODO
	
	.hsynct_i	(hsync_t),
	.hbporch_i	(hbporch),
	.hactive_i	(hactive),
	.hfporch_i	(hfporch),	// h-total too
	
	.vsynct_i	(vsync_t),
	.vbporch_i	(vbporch),
	.vactive_i	(vactive),
	.vfporch_i	(vfporch),
	
	.row_o		(crtc_row_o [RSB:0]),
	.col_o		(crtc_col_o [RSB:0]),
	
	.de_o		(crtc_de_o),
	.hsync_o	(crtc_hsync_o),
	.vsync_o	(crtc_vsync_o),
	.hblank_o	(crtc_hblank_o),
	.vblank_o	(crtc_vblank_o)
);


endmodule	// wb_crtc
