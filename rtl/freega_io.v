/***************************************************************************
 *                                                                         *
 *   freega_io.v - Wrapper containing the SPROM, LEDs, and CRTC modules.   *
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

// TODO: Fix bouncing `ACK' issues.

// Address decoder:
// Half the I/O space is reserved for uses relating to the CPU allowing, with
// the default address size of 23, 2^21 I/O addresses available.
// This is done to simplify decoding (since the internal decoding operates at
// 150 MHz).
`define	IO_DECODE_BITS	ASB:(ADDRESS-3)
`define	IO_FLUSH	3'b110
`define	IO_DMA		3'b100
`define	IO_CRTC		3'b000
`define	IO_SPROM	3'b001
`define	IO_LEDS		3'b010
`define	IO_VIDC		3'b011


// TODO: Too slow.
// `define	__use_low_latency_io


`timescale 1ns/100ps
module freega_io #(
	parameter	HIGHZ	= 0,
	parameter	IWIDTH	= 16,
	parameter	MWIDTH	= 32,
	parameter	ENABLES	= IWIDTH / 8,
	parameter	SELECTS	= MWIDTH / 8,
	parameter	ADDRESS	= 21,
	parameter	MSB	= IWIDTH - 1,
	parameter	ESB	= ENABLES - 1,
	parameter	WSB	= MWIDTH - 1,
	parameter	SSB	= SELECTS - 1,
	parameter	ASB	= ADDRESS - 1
) (
	input		wb_clk_i,
	input		wb_rst_i,
	input		clk50_i,
	input		pci_rst_ni,	// TODO: Can obsolete this?
	
	input		io_cyc_i,
	input		io_stb_i,
	input		io_we_i	,
	output		io_ack_o,
	output		io_rty_o,
	output		io_err_o,
	input	[2:0]	io_cti_i,
	input	[1:0]	io_bte_i,
	input	[ASB:0]	io_adr_i,
	input	[ESB:0]	io_sel_i,
	input	[MSB:0]	io_dat_i,
	output	[ESB:0]	io_sel_o,
	output	[MSB:0]	io_dat_o,
	
	output		dma_cyc_o,
	output		dma_stb_o,
	output		dma_we_o,
	input		dma_ack_i,
	input		dma_rty_i,
	input		dma_err_i,
	output	[2:0]	dma_cti_o,
	output	[1:0]	dma_bte_o,
	output	[ASB:0]	dma_adr_o,
	output	[SSB:0]	dma_sel_o,
	output	[WSB:0]	dma_dat_o,
	
	output		rdr_cyc_o,
	output		rdr_stb_o,
	output		rdr_we_o,
	input		rdr_ack_i,
	input		rdr_rty_i,
	input		rdr_err_i,
	output	[2:0]	rdr_cti_o,
	output	[1:0]	rdr_bte_o,
	output	[ASB:0]	rdr_adr_o,
	input	[SSB:0]	rdr_sel_i,
	input	[WSB:0]	rdr_dat_i,
	
	output		cache_rst_o,
	
	output		rclk_o,
	input		din_do_o,
	
	output		vga_clk_o,
	output		vga_sync_no,
	output		vga_blank_no,
	output		vga_de_o,
	output		vga_hsync_o,
	output		vga_vsync_o,
	output	[7:0]	vga_r_o,
	output	[7:0]	vga_g_o,
	output	[7:0]	vga_b_o,
	
	output	[1:0]	leds_o
);


wire	ld_stb, ld_ack;
wire	[ESB:0]	ld_sel;
wire	[MSB:0]	ld_dat;

wire	sp_stb, sp_ack;
wire	[ESB:0]	sp_sel;
wire	[MSB:0]	sp_dat;

wire	cr_stb, cr_ack;
wire	[ESB:0]	cr_sel;
wire	[MSB:0]	cr_dat;

wire	vc_stb, vc_ack;
wire	[ESB:0]	vc_sel;
wire	[MSB:0]	vc_dat;

wire	fc_stb, fc_ack;

wire	dm_stb, dm_ack, dm_rty, dm_err;
wire	[ESB:0]	dm_sel;
wire	[MSB:0]	dm_dat;

reg		io_ack	= 0;
reg		io_rty	= 0;
reg		io_err	= 0;
reg	[ESB:0]	io_sel;
reg	[MSB:0]	io_dat;

wire		io_ack_w;
wire	[ESB:0]	io_sel_w;
wire	[MSB:0]	io_dat_w;

wire	[2:0]	io_adr_bits;

reg	ld_stb_r	= 0,
	cr_stb_r	= 0,
	vc_stb_r	= 0,
	dm_stb_r	= 0,
	fc_stb_r	= 0,
	sp_stb_r	= 0;


`define	IOST_IDLE	3'b100
`define	IOST_DMA	3'b000
`define	IOST_CRTC	3'b001
`define	IOST_SPROM	3'b010
`define	IOST_LEDS	3'b011
`define	IOST_FLUSH	3'b101
`define	IOST_VIDC	3'b111

reg	[2:0]	io_st	= `IOST_IDLE;


`ifdef __use_low_latency_io
// TODO: This is phatter than yr mama!
assign	io_ack_o	= ld_ack || cr_ack || sp_ack || dm_ack || fc_ack || vc_ack;
assign	io_sel_o	= io_sel_w;
assign	io_dat_o	= io_dat_w;
`else
// TODO: This might be faster (Fmax), but is also bigger, higher latency, and
// buggy.
assign	io_ack_w	= ld_ack || cr_ack || sp_ack || dm_ack || fc_ack || vc_ack;
assign	io_ack_o	= io_ack;
assign	io_rty_o	= io_rty;
assign	io_err_o	= io_err;
`endif	// __use_low_latency_io

assign	io_adr_bits	= io_adr_i[`IO_DECODE_BITS];

assign	#2 ld_stb	= (io_stb_i && io_adr_bits == `IO_LEDS);
assign	#2 sp_stb	= (io_stb_i && io_adr_bits == `IO_SPROM);
assign	#2 cr_stb	= (io_stb_i && io_adr_bits == `IO_CRTC);
assign	#2 vc_stb	= (io_stb_i && io_adr_bits == `IO_VIDC);
assign	#2 dm_stb	= (io_stb_i && io_adr_bits == `IO_DMA);
assign	#2 fc_stb	= (io_stb_i && io_adr_bits == `IO_FLUSH);


//---------------------------------------------------------------------------
// Wishbone I/O interface logic.
//
always @(posedge wb_clk_i)
	if (wb_rst_i)	io_st	<= #2 `IOST_IDLE;
	else case (io_st)
	`IOST_IDLE:
		if (io_ack)		io_st	<= #2 io_st;
		else if (dm_stb)	io_st	<= #2 `IOST_DMA;
		else if (cr_stb)	io_st	<= #2 `IOST_CRTC;
		else if (vc_stb)	io_st	<= #2 `IOST_VIDC;
		else if (ld_stb)	io_st	<= #2 `IOST_LEDS;
		else if (sp_stb)	io_st	<= #2 `IOST_SPROM;
		else if (fc_stb)	io_st	<= #2 `IOST_FLUSH;
	
	default:
		if (io_ack_w)		io_st	<= #2 `IOST_IDLE;
	endcase


always @(posedge wb_clk_i)
	if (wb_rst_i)
		io_ack	<= #2 0;
	else begin
		if (!io_ack)	io_ack	<= #2 io_ack_w;
		else		io_ack	<= #2 0;
		io_sel	<= #2 io_sel_w;
		io_dat	<= #2 io_dat_w;
	end


always @(posedge wb_clk_i)
	if (wb_rst_i)
		{io_rty, io_err}	<= #2 0;
	else if (io_st == `IOST_DMA)
		{io_rty, io_err}	<= #2 {dm_rty, dm_err};
	else
		{io_rty, io_err}	<= #2 0;


always @(posedge wb_clk_i)
	if (wb_rst_i) begin
		ld_stb_r	<= #2 0;
		cr_stb_r	<= #2 0;
		vc_stb_r	<= #2 0;
		sp_stb_r	<= #2 0;
		dm_stb_r	<= #2 0;
		fc_stb_r	<= #2 0;
	end else if (io_st == `IOST_IDLE && !io_ack_o) begin
		ld_stb_r	<= #2 ld_stb;
		cr_stb_r	<= #2 cr_stb;
		vc_stb_r	<= #2 vc_stb;
		sp_stb_r	<= #2 sp_stb;
		dm_stb_r	<= #2 dm_stb;
		fc_stb_r	<= #2 fc_stb;
	end else begin
		if (ld_ack)	ld_stb_r	<= #2 0;
		if (cr_ack)	cr_stb_r	<= #2 0;
		if (vc_ack)	vc_stb_r	<= #2 0;
		if (sp_ack)	sp_stb_r	<= #2 0;
		if (dm_ack)	dm_stb_r	<= #2 0;
		if (fc_ack)	fc_stb_r	<= #2 0;
	end


mux4to1 #(
	.WIDTH	(ENABLES+IWIDTH)
) MUX0 (
	.sel_i	(io_st[1:0]),
	.in0_i	({dm_sel, dm_dat}),
	.in1_i	({cr_sel, cr_dat}),
	.in2_i	({sp_sel, sp_dat}),
	.in3_i	({vc_sel, vc_dat}),
	.out_o	({io_sel_w, io_dat_w})
);


// Allow the CPU to manually empty the cache, needed to maintain coherency
// since the PCI module can change the memory contents without the CPU's
// cache noticing.
wb_cache_flush #(
	.HIGHZ		(0)
) FLUSH0 (
	.wb_clk_i	(wb_clk_i),
	.wb_rst_i	(wb_rst_i),
	
	.wb_cyc_i	(io_cyc_i),
	.wb_stb_i	(fc_stb_r),
	.wb_we_i	(io_we_i),
	.wb_ack_o	(fc_ack),
	.wb_rty_o	(),
	.wb_err_o	(),
	
	.flush_o	(cache_rst_o)
);


//---------------------------------------------------------------------------
// DMA allows the collection of multiple memory writes into a single burst.
//
wb_dma #(
	.HIGHZ		(0),
	.CWIDTH		(16),
	.WWIDTH		(32),
	.ADDRESS	(ADDRESS)
) DMA0 (
	.wb_rst_i	(wb_rst_i),
	
	.a_clk_i	(wb_clk_i),
	.a_cyc_i	(io_cyc_i),
	.a_stb_i	(dm_stb_r),
	.a_we_i		(io_we_i),
	.a_ack_o	(dm_ack),
	.a_rty_o	(dm_rty),
	.a_err_o	(dm_err),
	.a_cti_i	(0),		// Single-word transfers only
	.a_bte_i	(0),
	.a_adr_i	(io_adr_i[1:0]),
	.a_sel_i	(io_sel_i),
	.a_dat_i	(io_dat_i),
	.a_sel_o	(dm_sel),
	.a_dat_o	(dm_dat),
	
	.b_clk_i	(wb_clk_i),
	.b_cyc_o	(dma_cyc_o),
	.b_stb_o	(dma_stb_o),
	.b_we_o		(dma_we_o),
	.b_ack_i	(dma_ack_i),
	.b_rty_i	(0),
	.b_err_i	(0),
	.b_cti_o	(dma_cti_o),	// Single-word transfers
	.b_bte_o	(dma_bte_o),
	.b_adr_o	(dma_adr_o),
	.b_sel_i	(0),
	.b_dat_i	(0),
	.b_sel_o	(dma_sel_o),
	.b_dat_o	(dma_dat_o)
);


wb_leds #(
	.HIGHZ		(0),
	.WIDTH		(IWIDTH),
	.LEDS		(2)
) LEDS0 (
	.wb_clk_i	(wb_clk_i),
	.wb_rst_i	(wb_rst_i),
	
	.wb_cyc_i	(io_cyc_i),
	.wb_stb_i	(ld_stb_r),
	.wb_we_i	(io_we_i),
	.wb_ack_o	(ld_ack),
	.wb_sel_i	(io_sel_i),
	.wb_dat_i	(io_dat_i),
	.wb_sel_o	(ld_sel),
	.wb_dat_o	(ld_dat),
	
	.leds_o		(leds_o)
);


wb_sprom #(
	.WIDTH		(IWIDTH)
) SPROM0 (
	.wb_clk_i	(wb_clk_i),
	.wb_rst_i	(wb_rst_i),
	.wb_cyc_i	(io_cyc_i),
	.wb_stb_i	(sp_stb_r),
	.wb_we_i	(io_we_i),
	.wb_ack_o	(sp_ack),
	.wb_dat_o	(sp_dat),
	.wb_sel_o	(sp_sel),
	
	.sp_clk_o	(rclk_o),
	.sp_dat_i	(din_do_o)
);


wb_video_top #(
	.ADDRESS	(ADDRESS)
) VIDEO0 (
	.wb_clk_i	(wb_clk_i),
	.wb_rst_i	(wb_rst_i),
	.clk50_i	(clk50_i),
	.pci_rst_ni	(pci_rst_ni),
	
	.crt_cyc_i	(io_cyc_i),
	.crt_stb_i	(cr_stb_r),
	.crt_we_i	(io_we_i),
	.crt_ack_o	(cr_ack),
	.crt_rty_o	(),
	.crt_err_o	(),
	.crt_cti_i	(0),
	.crt_bte_i	(0),
	.crt_adr_i	(io_adr_i[2:0]),
	.crt_sel_i	(io_sel_i),
	.crt_dat_i	(io_dat_i),
	.crt_sel_o	(cr_sel),
	.crt_dat_o	(cr_dat),
	
	.vid_cyc_i	(io_cyc_i),
	.vid_stb_i	(vc_stb_r),
	.vid_we_i	(io_we_i),
	.vid_ack_o	(vc_ack),
	.vid_rty_o	(),
	.vid_err_o	(),
	.vid_cti_i	(0),
	.vid_bte_i	(0),
	.vid_adr_i	(io_adr_i[2:0]),
	.vid_sel_i	(io_sel_i),
	.vid_dat_i	(io_dat_i),
	.vid_sel_o	(vc_sel),
	.vid_dat_o	(vc_dat),
	
	.rdr_cyc_o	(rdr_cyc_o),
	.rdr_stb_o	(rdr_stb_o),
	.rdr_we_o	(rdr_we_o),
	.rdr_ack_i	(rdr_ack_i),
	.rdr_rty_i	(rdr_rty_i),
	.rdr_err_i	(rdr_err_i),
	.rdr_cti_o	(rdr_cti_o),
	.rdr_bte_o	(rdr_bte_o),
	.rdr_adr_o	(rdr_adr_o),
	.rdr_sel_i	(rdr_sel_i),
	.rdr_dat_i	(rdr_dat_i),
	
	.vga_clk_o	(vga_clk_o),
	.vga_sync_no	(vga_sync_no),
	.vga_blank_no	(vga_blank_no),
	.vga_de_o	(vga_de_o),
	.vga_hsync_o	(vga_hsync_o),
	.vga_vsync_o	(vga_vsync_o),
	.vga_r_o	(vga_r_o),
	.vga_g_o	(vga_g_o),
	.vga_b_o	(vga_b_o)
);


endmodule	// freega_io
