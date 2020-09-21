/***************************************************************************
 *                                                                         *
 *   crtc.v - A CRT/LCD controller for a VGA.                              *
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

`timescale 1ns / 100ps
module crtc (
	clock_i,	// Character clock
	reset_ni,
	enable_i,
	
	hsynct_i,
	hbporch_i,
	hactive_i,
	hfporch_i,
	
	vsynct_i,
	vbporch_i,
	vactive_i,
	vfporch_i,
	
	row_o,
	col_o,
	
	de_o,
	hsync_o,
	vsync_o,
	hblank_o,
	vblank_o
);

parameter	WIDTH	= 11;
parameter	MSB	= WIDTH - 1;

input		clock_i;
input		reset_ni;
input		enable_i;

input	[MSB:0]	hsynct_i;	// 0-HSYNCT
input	[MSB:0]	hbporch_i;	// 0-HBPORCH
input	[MSB:0]	hactive_i;	// 0-HACTIVE
input	[MSB:0]	hfporch_i;	// 0-HFPORCH

input	[MSB:0]	vsynct_i;
input	[MSB:0]	vbporch_i;
input	[MSB:0]	vactive_i;
input	[MSB:0]	vfporch_i;

output	[MSB:0]	row_o;
output	[MSB:0]	col_o;

output		de_o;
output		hsync_o;
output		vsync_o;
output		hblank_o;
output		vblank_o;


// reg	de_o	= 0;

reg	[MSB:0]	hcnt	= 0;
reg	[MSB:0]	vcnt	= 0;

`define	CRT_SYNC	4'b0001
`define	CRT_BPORCH	4'b0010
`define	CRT_ACTIVE	4'b0100
`define	CRT_FPORCH	4'b1000
reg	[3:0]	hstate	= `CRT_SYNC;
reg	[3:0]	vstate	= `CRT_SYNC;


assign	#2 col_o	= hcnt;
assign	#2 row_o	= vcnt;

assign	#2 de_o		= (hstate == `CRT_ACTIVE) && (vstate == `CRT_ACTIVE);
assign	#2 hsync_o	= (hstate == `CRT_SYNC);
assign	#2 vsync_o	= (vstate == `CRT_SYNC);

assign	#2 hblank_o	= (hstate != `CRT_ACTIVE);
assign	#2 vblank_o	= (vstate != `CRT_ACTIVE);


always @(posedge clock_i)
	if (!reset_ni)
		hstate	<= #2 `CRT_SYNC;
	else if (enable_i) case (hstate)
	`CRT_SYNC:	if (hcnt == hsynct_i)	hstate	<= #2 `CRT_BPORCH;
	`CRT_BPORCH:	if (hcnt == hbporch_i)	hstate	<= #2 `CRT_ACTIVE;
	`CRT_ACTIVE:	if (hcnt == hactive_i)	hstate	<= #2 `CRT_FPORCH;
	`CRT_FPORCH:	if (hcnt == hfporch_i)	hstate	<= #2 `CRT_SYNC;
	endcase


always @(posedge clock_i)
	if (!reset_ni)
		vstate	<= #2 `CRT_SYNC;
	else if (enable_i) case (vstate)
	`CRT_SYNC:	if (vcnt == vsynct_i)	vstate	<= #2 `CRT_BPORCH;
	`CRT_BPORCH:	if (vcnt == vbporch_i)	vstate	<= #2 `CRT_ACTIVE;
	`CRT_ACTIVE:	if (vcnt == vactive_i)	vstate	<= #2 `CRT_FPORCH;
	`CRT_FPORCH:	if (vcnt == vfporch_i)	vstate	<= #2 `CRT_SYNC;
	endcase

/*
wire	hdraw	= (hstate == `CRT_ACTIVE);
wire	vdraw	= (vstate == `CRT_ACTIVE);
always @(posedge clock_i)
	if (!reset_ni)		de_o	<= #2 0;
	else if (enable_i)	de_o	<= #2 hdraw && vdraw;
	else			de_o	<= #2 0;
*/

wire	#2 rst_hcnt	= (hcnt == hfporch_i);
always @(posedge clock_i)
	if (!reset_ni)		hcnt	<= #2 0;
	else if (rst_hcnt)	hcnt	<= #2 0;
	else if (enable_i)	hcnt	<= #2 hcnt + 1;


wire	#2 rst_vcnt	= (vcnt == vfporch_i);
wire	#2 inc_vcnt	= (hcnt == hfporch_i);
always @(posedge clock_i)
	if (!reset_ni || rst_vcnt)	vcnt	<= #2 0;
	else if (enable_i && inc_vcnt)	vcnt	<= #2 vcnt + 1;


endmodule	// crtc
