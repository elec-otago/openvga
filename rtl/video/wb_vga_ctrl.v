/***************************************************************************
 *                                                                         *
 *   wb_vga_ctrl.v - VGA control registers, controls dot-clock frequncy,   *
 *     disabling VGA, and reading the status.                              *
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


// Register descriptions:
//	0x00	Bit 0	- vsync, 1 = active
//		Bit 1	- hsync
//		Bit 2	- clock source, 0 = 25 MHz
//		Bit 3	- display disable, 1 = active	TODO
//


`timescale 1ns/100ps
module wb_vga_ctrl #(
	parameter	HIGHZ	= 0,
	parameter	WIDTH	= 16,
	parameter	ENABLES	= WIDTH / 8,
	parameter	MSB	= WIDTH - 1,
	parameter	ESB	= ENABLES - 1
) (
	input		wb_clk_i,	// 50 MHz max. on a Spartan III
	input		wb_rst_i,	// Wishbone system signals
	
	input		wb_cyc_i,	// Wishbone control signals
	input		wb_stb_i,
	input		wb_we_i,
	output	reg	wb_ack_o	= 0,
	output		wb_rty_o,
	output		wb_err_o,
	input	[2:0]	wb_adr_i,	// Index into CRTC regs
	
	input	[ESB:0]	wb_sel_i,
	input	[MSB:0]	wb_dat_i,
	output	[ESB:0]	wb_sel_o,
	output	[MSB:0]	wb_dat_o,
	
	input		hsync_i,	// Async, needs synchros
	input		vsync_i,	// Async, needs synchros
	
	output		vga_rst_o,	// TODO:
	input		clk50_i,
	output		dot_clk_o,
	output		chr_clk_o
);


// VGA status/control flags.
reg	f_vsync	= 0;
reg	f_hsync	= 0;
reg	f_clk40	= 0;

reg	vsync_sync	= 0;
reg	hsync_sync	= 0;

reg	[2:0]	chr_clk_div	= 0;


assign	wb_rty_o	= 0;
assign	wb_err_o	= 0;
assign	wb_sel_o	= 2'b11;
assign	wb_dat_o	= {13'b0, f_clk40, f_hsync, f_vsync};


always @(posedge wb_clk_i)
	if (wb_rst_i)	wb_ack_o	<= #2 0;
	else		wb_ack_o	<= #2 wb_stb_i && !wb_ack_o;


// Synchronise the incoming signals using single-bit, dual-flip-flop
// synchronisers. These signals are in the character clock (dot-clock)
// domain.
always @(posedge wb_clk_i)
	if (wb_rst_i)	{vsync_sync, f_vsync, hsync_sync, f_hsync}	<= #2 0;
	else begin
		{f_vsync, vsync_sync}	<= #2 {vsync_sync, vsync_i};
		{f_hsync, hsync_sync}	<= #2 {hsync_sync, hsync_i};
	end


// Allow the dot-clock source, 25 or 40 MHz, to be set.
always @(posedge wb_clk_i)
	if (wb_rst_i)
		f_clk40	<= #2 0;
	else if (wb_stb_i && wb_sel_i[0])
		f_clk40	<= #2 wb_dat_i[2];


//---------------------------------------------------------------------------
//  Clocking stuff. Different phases of clocks are needed since there are
//  real-world delays, like IOB delays.
//
wire	GND	= 0;
wire	clk_out, clk90, clk180, clk270, clk25, clk2x, clkfx, lock;

assign	chr_clk_o	= chr_clk_div[2];
always @(posedge dot_clk_o)
	chr_clk_div	<= #2 chr_clk_div + 1;

DCM #(
//  	.CLKIN_DIVIDE_BY_2	("TRUE"),
	.CLKDV_DIVIDE		(2),
	.CLKFX_MULTIPLY		(4),
	.CLKFX_DIVIDE		(5),
	.CLK_FEEDBACK		("1X"),
// 	.CLK_FEEDBACK		("NONE"),
	.DLL_FREQUENCY_MODE	("LOW")
) dcm0 (
	.CLKIN	(clk50_i),
	.CLKFB	(clk_out),
	.DSSEN	(GND),
	.PSEN	(GND),
	.RST	(1'b0),
	.CLK0	(clk_out),
	.CLK90	(clk90),
	.CLK180	(clk180),
	.CLK270	(clk270),
	.CLKDV	(clk25),
	.CLK2X	(clk2x),
	.CLKFX	(clkfx),
	.LOCKED	(lock)
);

BUFGMUX DOTCLK (
	.I0	(clk_out),
	.I1	(clkfx),
	.S	(f_clk40),
	.O	(dot_clk_o)
);


endmodule	// wb_vga_ctrl
