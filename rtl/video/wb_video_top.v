/***************************************************************************
 *                                                                         *
 *   wb_video_top.v - Top level module of the display logic, outputs VGA   *
 *     and DVI data, 32-bit Wishbone interface to the famebuffer.          *
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

`timescale 1ns/100ps
module wb_video_top #(
	parameter	ADDRESS	= 21,
	parameter	ASB	= ADDRESS - 1
) (
	input		wb_rst_i,
	input		wb_clk_i,	// 50 MHz
	input		clk50_i,
	input		pci_rst_ni,
	
	input		crt_cyc_i,
	input		crt_stb_i,
	input		crt_we_i,
	output		crt_ack_o,
	output		crt_rty_o,
	output		crt_err_o,
	input	[2:0]	crt_cti_i,
	input	[1:0]	crt_bte_i,
	input	[2:0]	crt_adr_i,
	input	[1:0]	crt_sel_i,
	input	[15:0]	crt_dat_i,
	output	[1:0]	crt_sel_o,
	output	[15:0]	crt_dat_o,
	
	input		vid_cyc_i,
	input		vid_stb_i,
	input		vid_we_i,
	output		vid_ack_o,
	output		vid_rty_o,
	output		vid_err_o,
	input	[2:0]	vid_cti_i,
	input	[1:0]	vid_bte_i,
	input	[2:0]	vid_adr_i,
	input	[1:0]	vid_sel_i,
	input	[15:0]	vid_dat_i,
	output	[1:0]	vid_sel_o,
	output	[15:0]	vid_dat_o,
	
	output		rdr_cyc_o,
	output		rdr_stb_o,
	output		rdr_we_o,
	input		rdr_ack_i,
	input		rdr_rty_i,
	input		rdr_err_i,
	output	[2:0]	rdr_cti_o,
	output	[1:0]	rdr_bte_o,
	output	[ASB:0]	rdr_adr_o,
	input	[3:0]	rdr_sel_i,
	input	[31:0]	rdr_dat_i,
	
	output		vga_clk_o,
	output		vga_sync_no,
	output		vga_blank_no,
	output		vga_de_o,
	output		vga_hsync_o,
	output		vga_vsync_o,
	output	[7:0]	vga_r_o,
	output	[7:0]	vga_g_o,
	output	[7:0]	vga_b_o
);


wire	v_vsync, v_hsync, v_vblnk, v_hblnk, v_de, v_rd;
wire	[31:0]	v_dat;
wire	chr_clk;


assign	vga_sync_no	= 1;
assign	vga_blank_no	= 1;


// Wishbone bus is only 16-bits wide for the CRTC.
wb_crtc #(
	.HIGHZ		(0),
	.WIDTH		(16)
) CRTC0 (
	.wb_clk_i	(wb_clk_i),
	.wb_rst_i	(wb_rst_i),
	
	.wb_cyc_i	(crt_cyc_i),
	.wb_stb_i	(crt_stb_i),
	.wb_we_i	(crt_we_i),
	.wb_ack_o	(crt_ack_o),
	.wb_rty_o	(crt_rty_o),
	.wb_err_o	(crt_err_o),
	.wb_adr_i	(crt_adr_i),
	
	.wb_sel_o	(crt_sel_o),
	.wb_dat_o	(crt_dat_o),
	.wb_sel_i	(crt_sel_i),
	.wb_dat_i	(crt_dat_i),
	
	.crtc_clk_i	(chr_clk),
	.crtc_rst_ni	(pci_rst_ni),
	.crtc_row_o	(),
	.crtc_col_o	(),
	
	.crtc_de_o	(v_de),
	.crtc_hsync_o	(v_hsync),
	.crtc_vsync_o	(v_vsync),
	.crtc_hblank_o	(v_hblnk),
	.crtc_vblank_o	(v_vblnk)
);


wb_vga_ctrl #(
	.HIGHZ		(0),
	.WIDTH		(16)
) VIDC0 (
	.wb_clk_i	(wb_clk_i),
	.wb_rst_i	(wb_rst_i),
	
	.wb_cyc_i	(vid_cyc_i),
	.wb_stb_i	(vid_stb_i),
	.wb_we_i	(vid_we_i),
	.wb_ack_o	(vid_ack_o),
	.wb_rty_o	(vid_rty_o),
	.wb_err_o	(vid_err_o),
	.wb_adr_i	(vid_adr_i),
	
	.wb_sel_i	(vid_sel_i),
	.wb_dat_i	(vid_dat_i),
	.wb_sel_o	(vid_sel_o),
	.wb_dat_o	(vid_dat_o),
	
	.hsync_i	(v_hsync),
	.vsync_i	(v_vsync),
	
	.vga_rst_o	(),	// TODO:
	.clk50_i	(clk50_i),
	.dot_clk_o	(vga_clk_o),
	.chr_clk_o	(chr_clk)
);


// TODO: Add support for multiple pages.
wb_redraw #(
	.HIGHZ		(0),
	.ADDRESS	(ADDRESS)	// Max 8 MB framebuffer
) REDRAW0 (
	.d_clk_i	(vga_clk_o),
	.d_rst_ni	(pci_rst_ni),
	.d_vsync_i	(v_vsync),
	.d_read_i	(v_rd),
	.d_data_o	(v_dat),
	
	.wb_clk_i	(wb_clk_i),
	.wb_rst_i	(wb_rst_i),
	
	.wb_cyc_i	(0),
	.wb_cyc_o	(rdr_cyc_o),
	.wb_stb_o	(rdr_stb_o),
	.wb_we_o	(rdr_we_o),
	.wb_ack_i	(rdr_ack_i),
	.wb_rty_i	(rdr_rty_i),
	.wb_err_i	(rdr_err_i),
	.wb_cti_o	(rdr_cti_o),
	.wb_bte_o	(rdr_bte_o),
	.wb_adr_o	(rdr_adr_o),
	
	.wb_sel_i	(rdr_sel_i),
	.wb_dat_i	(rdr_dat_i)
);


vga16 VGA16 (
	.clk_i		(vga_clk_o),
	.rst_i		(wb_rst_i),	// TODO: Should come from `wb_vga_ctrl'
	
	.hsync_i	(v_hsync),
	.vsync_i	(v_vsync),
	.hblank_i	(v_hblnk),
	.vblank_i	(v_vblnk),
	.de_i		(v_de),
	.read_o		(v_rd),
	.data_i		(v_dat),
	
	.r_o		(vga_r_o),
	.g_o		(vga_g_o),
	.b_o		(vga_b_o),
	.vsync_o	(vga_vsync_o),
	.hsync_o	(vga_hsync_o),
	.de_o		(vga_de_o)
);


endmodule	// wb_video_top
