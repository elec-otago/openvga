/***************************************************************************
 *                                                                         *
 *   DCM.v - Replicates the functionality of the Xilinx primitive of the   *
 *     same name. This a really poor partial implementation so do not use  *
 *     as it is only designed to do some very basic things.                *
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

`timescale 100ps/100ps
module DCM (
	CLKIN,
	RST,
	CLKFB,
	DSSEN,
	PSEN,
	
	CLK0,
	CLK90,
	CLK180,
	CLK270,
	
	CLKDV,
	CLK2X,
	CLK2X180,
	
	CLKFX,
	CLKFX180,
	
	LOCKED
);

parameter	CLK_FEEDBACK		= "1X" ;
parameter	DLL_FREQUENCY_MODE	= "LOW" ;
parameter	CLKIN_DIVIDE_BY_2	= "FALSE" ;
parameter	CLKDV_DIVIDE		= 2;

parameter	CLKFX_DIVIDE		= 1;	// Frequency synthesis params
parameter	CLKFX_MULTIPLY		= 4;

input	CLKIN;
input	RST;
input	CLKFB;
input	DSSEN;
input	PSEN;

output	CLK0;
output	CLK90;
output	CLK180;
output	CLK270;

output	CLKDV;
output	CLK2X;
output	CLK2X180;

output	CLKFX;
output	CLKFX180;

output	LOCKED;


// CLKIN can be pre-divided by two before it enters the rest of the DCM
// logic.
reg	CLKIN_half	= 0;
always @(posedge CLKIN)
	CLKIN_half	<= ~CLKIN_half;

wire	CLKIN_m	= (CLKIN_DIVIDE_BY_2 == "TRUE") ? CLKIN_half : CLKIN ;


reg	int_clk	= 1;
always	#1 int_clk	<= ~int_clk;


reg	cnt_period_rst	= 0, cnt_period_set	= 0;
integer	cnt_period	= 0;
always @(posedge int_clk or posedge CLKIN_m)
	if (!CLKIN_m) begin
		cnt_period_set	<= 0;
		cnt_period_rst	<= 0;
	end else if (!cnt_period_set && CLKIN_m) begin
		cnt_period_set	<= 1;
		cnt_period_rst	<= 1;
	end else
		cnt_period_rst	<= 0;


// Count the period between clocks.
always @(posedge int_clk)
	if (cnt_period_rst)
		cnt_period	<= 0;
	else
		cnt_period	<= cnt_period + 1;


integer	cnt_hi	= 0, cnt_lo	= 0;
always @(posedge int_clk)
	if (cnt_period_rst) begin
		cnt_hi	<= (cnt_period >> 1) + 1;
		cnt_lo	<= (cnt_period >> 1) + cnt_period [0];
	end


// Don't generate a LOCKED signal until jitter is within reasonable limits.
reg	LOCKED	= 0;
integer	prev_hi, prev_lo;
always @(posedge CLKIN_m or posedge RST)
	if (RST)
		LOCKED	<= #10 0;
	else begin
		prev_hi	<= #10 cnt_hi;
		prev_lo	<= #10 cnt_lo;
		
		// Pretty arbitrary jitter choice.
		if (prev_hi[31:2] == cnt_hi [31:2] && prev_lo [31:2] == cnt_lo [31:2] && cnt_lo > 15 && cnt_hi > 15)
			LOCKED	<= #10 1;
		else
			LOCKED	<= #10 0;
	end


// Generate CLK0
integer	cnt	= 0;
always @(posedge int_clk)
	if (cnt_period_rst || RST)
		cnt	<= #1 0;
	else
		cnt	<= #1 cnt + 1;

reg	CLK0	= 0, CLK180	= 1;
wire	clk0	= cnt < cnt_lo;
always @(posedge int_clk)
	if (RST)
		{CLK0, CLK180}	<= #2 1;
	else begin
		CLK0	<= #2 clk0;
		CLK180	<= #2 ~clk0;
	end


// Generate CLK90, CLK270
reg	CLK90	= 0, CLK270	= 1;
wire	clk270	= (cnt < cnt_lo [31:1]) || (cnt > (cnt_lo + cnt_hi [31:1]));
always @(posedge int_clk)
	if (!LOCKED || RST)
		{CLK90, CLK270}	<= #2 1;
	else if (DLL_FREQUENCY_MODE == "LOW") begin
		CLK90	<= #2 ~clk270;
		CLK270	<= #2 clk270;
	end else
		{CLK270, CLK90}	<= #2 'bx;


// Generate CLK2X
reg	CLK2X	= 0;
assign	CLK2X180	= ~CLK2X;
wire	clk2x	= ~clk270 ^ clk0;
always @(posedge int_clk)
	if (!LOCKED || RST)	CLK2X	<= #2 1;
	else			CLK2X	<= #2 clk2x;


// Generate CLKDV
reg	CLKDV	= 1;
wire	[31:0]	clkdv_period	= (cnt_hi + cnt_lo) * CLKDV_DIVIDE;
integer	clkdv_cnt	= 0;
wire	clkdv_rst	= (clkdv_cnt >= clkdv_period - 1);
wire	clkdv_hi	= clkdv_cnt > (clkdv_period >> 1);

always @(posedge int_clk)
	if (clkdv_rst)	clkdv_cnt	<= 0;
	else		clkdv_cnt	<= clkdv_cnt + 1;

always @(posedge int_clk)
	if (!LOCKED || RST)	CLKDV	<= #2 1;
	else			CLKDV	<= clkdv_hi;


reg	CLKFX		= 1;
wire	[31:0]	fx_lo	= cnt_lo * CLKFX_DIVIDE / CLKFX_MULTIPLY;
wire	[31:0]	fx_T	= (cnt_hi + cnt_lo) * CLKFX_DIVIDE / CLKFX_MULTIPLY;
integer	fx_cnt	= 0;
wire	clkfx_rst	= (fx_cnt >= fx_T - 1);
wire	clkfx_hi	= (fx_cnt > fx_lo);
always @(posedge int_clk)
	if (clkfx_rst)	fx_cnt	<= 0;
	else		fx_cnt	<= fx_cnt + 1;

always @(posedge int_clk)
	if (!LOCKED || RST)	CLKFX	<= #2 1;
	else			CLKFX	<= clkfx_hi;

assign	CLKFX180	= ~CLKFX;


endmodule	// DCM
