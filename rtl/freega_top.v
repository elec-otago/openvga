/***************************************************************************
 *                                                                         *
 *   freega_top.v -                                                        *
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

// `define	__use_BRAM
`define	__use_RISC16

// Simulation and synthesis options:
//
// No processor means faster simulations and simpler testbenches.
`define	__use_no_processor
//
// No video means faster simulations and simpler testbenches.
// `define	__use_no_video
//
// No SDRAM means faster simulations and simpler testbenches.
// `define	__use_no_sdram
//
// No WBMUXes means faster simulations and simpler testbenches.
// `define	__use_no_wb_mux
//
// No DCM means faster simulations and simpler testbenches.
`ifdef __icarus
`define	__use_no_DCM
`endif


`timescale 1ns/100ps
module freega_top #(
	parameter	ADDRESS	= 22,	// 4Mx32 addressable (16 MB)
	parameter	HIGHZ	= 0,
	parameter	ASB	= ADDRESS - 2
) (
	input		clk50,	// synthesis attribute period of clk50 is "20 ns" ;
	
	output		pci_disable,
				// synthesis attribute buffer_type of pci_clk is ibufg ;
	input		pci_clk,// synthesis attribute period of pci_clk is "30 ns" ;
	input		pci_rst_n,
	input		pci_frame_n,
	output		pci_devsel_n,// synthesis attribute iob of pci_devsel_n is true ;
	input		pci_irdy_n,
	output		pci_trdy_n,// synthesis attribute iob of pci_trdy_n is true ;
	output		pci_stop_n,
	input		pci_idsel,
	input	[3:0]	pci_cbe_n,
	inout	[31:0]	pci_ad,// synthesis attribute iob of pci_ad* is true ;
	
	inout		pci_par,	// Unused PCI pins
	output		pci_inta_n,
	input		pci_gnt_n,
	output		pci_req_n,
`ifndef __use_BRAM
	output		sdr_clk,
	output		sdr_cke,
	output		sdr_cs_n,
	output		sdr_ras_n,
	output		sdr_cas_n,
	output		sdr_we_n,
	output	[1:0]	sdr_ba,
	output	[12:0]	sdr_a,
	output	[1:0]	sdr_dm,
	inout	[15:0]	sdr_dq,
`endif
	output		vga_clk,	// VGA only for now, DVI TODO
	output		vga_sync_n,
	output		vga_blank_n,
	output		vga_de,
	output		vga_hsync,
	output		vga_vsync,
	output	[7:0]	vga_r,
	output	[7:0]	vga_g,
	output	[7:0]	vga_b,
	
	output		rclk,		// For reading the SPROM
	input		din_do,
	
	output	[1:0]	leds
);


wire	dot_clk, mem_clk, cpu_clk, tta_clk;
wire	pci_enabled;
wire	cache_flush;
wire	clk100, clk150, wb_clk, wb_clk_n, wb_rst;

// Wishbone Signals. (Memory bus, 32-bit, 50 MHz)
wire	p_cyc, p_stb, p_we;		// PCI
wire	p_ack, p_rty, p_err;
wire	[2:0]	p_cti;
wire	[1:0]	p_bte;
wire	[ASB:0]	p_adr;
wire	[3:0]	p_sel_t, p_sel_f;
wire	[31:0]	p_dat_t, p_dat_f;

wire	m_cyc, m_stb, m_we;		// Main memory
wire	m_ack, m_rty, m_err;
wire	[2:0]	m_cti;
wire	[1:0]	m_bte;
wire	[ASB:0]	m_adr;
wire	[3:0]	m_sel_t, m_sel_f;
wire	[31:0]	m_dat_t, m_dat_f;

wire	r_cyc, r_stb, r_we;		// Redraw
wire	r_ack, r_rty, r_err;
wire	[2:0]	r_cti;
wire	[1:0]	r_bte;
wire	[ASB:0]	r_adr;
wire	[3:0]	r_sel_f;
wire	[31:0]	r_dat_f;

wire	d_cyc, d_stb, d_we;		// DMA
wire	d_ack, d_rty, d_err;
wire	[2:0]	d_cti;
wire	[1:0]	d_bte;
wire	[ASB:0]	d_adr;
wire	[3:0]	d_sel_t;
wire	[31:0]	d_dat_t;

wire	c_cyc, c_stb, c_we;		// CPU
wire	c_ack, c_rty, c_err;
wire	[2:0]	c_cti;
wire	[1:0]	c_bte;
wire	[ASB:0]	c_adr;
wire	[3:0]	c_sel_t, c_sel_f;
wire	[31:0]	c_dat_t, c_dat_f;

// Wishbone Signals (I/O bus, 16-bit, 50 MHz)
// TODO: Speed unimportant, make 25 MHz if clock issues?
wire	io_cyc, io_stb, io_we;
wire	io_ack, io_rty, io_err;
wire	[2:0]	io_cti;
wire	[1:0]	io_bte;
wire	[ASB:0]	io_adr;
wire	[1:0]	io_sel_t, io_sel_f;
wire	[15:0]	io_dat_t, io_dat_f;


assign	wb_rst		= ~pci_rst_n;
`ifdef __use_RISC16
// RISC16 operates at 100 MHz
assign	cpu_clk		= clk100;
`else
// TTA16 operates at 150 MHz
assign	cpu_clk		= clk100;
//assign	cpu_clk		= tta_clk;
`endif


//---------------------------------------------------------------------------
// CPU Top. Contains a TTA16 CPU, CACHE, DMA, and MMIO controller.
// Wishbone Master.
//
`ifdef __use_no_processor
assign	{c_cyc, c_stb, c_we, c_cti, c_bte, c_adr, c_sel_t, c_dat_t}	= 0;
assign	{io_cyc, io_stb, io_we, io_cti, io_bte, io_adr, io_sel_t, io_dat_t}	= 0;
`else // !__use_no_processor
`ifdef __use_RISC16
risc16_tile #(
`else
tta16_tile #(
`endif
	.ADDRESS	(ADDRESS+1)
) CPU0 (
	.wb_clk_i	(wb_clk),	// 50 MHz
	.wb_rst_i	(wb_rst),
	.cpu_clk_i	(cpu_clk),	// 150 MHz, sync with WB clock
	.cache_rst_i	(cache_flush),
	
	.mem_cyc_o	(c_cyc),
	.mem_stb_o	(c_stb),
	.mem_we_o	(c_we),
	.mem_ack_i	(c_ack),
	.mem_rty_i	(c_rty),
	.mem_err_i	(c_err),
	.mem_cti_o	(c_cti),
	.mem_bte_o	(c_bte),
	.mem_adr_o	(c_adr),
	.mem_sel_o	(c_sel_t),
	.mem_dat_o	(c_dat_t),
	.mem_sel_i	(c_sel_f),
	.mem_dat_i	(c_dat_f),
	
	.io_cyc_o	(io_cyc),
	.io_stb_o	(io_stb),
	.io_we_o	(io_we),
	.io_ack_i	(io_ack),
	.io_rty_i	(io_rty),
	.io_err_i	(io_err),
	.io_cti_o	(io_cti),
	.io_bte_o	(io_bte),
	.io_adr_o	(io_adr),
	.io_sel_o	(io_sel_t),
	.io_dat_o	(io_dat_t),
	.io_sel_i	(io_sel_f),
	.io_dat_i	(io_dat_f)
);
`endif	// !__use_no_processor


// Wishbone master.
wb_pci_top #(
	.HIGHZ		(HIGHZ),
	.ADDRESS	(ADDRESS-1)
) PCITOP0 (
	.pci_clk_i	(pci_clk),
	.pci_rst_ni	(pci_rst_n),
	.pci_frame_ni	(pci_frame_n),
	.pci_devsel_no	(pci_devsel_n),
	.pci_irdy_ni	(pci_irdy_n),
	.pci_trdy_no	(pci_trdy_n),
	.pci_idsel_i	(pci_idsel),
	.pci_cbe_ni	(pci_cbe_n),
	.pci_ad_io	(pci_ad),
	.pci_stop_no	(pci_stop_n),
	.pci_par_io	(pci_par),
	.pci_inta_no	(pci_inta_n),
	.pci_req_no	(pci_req_n),
	.pci_gnt_ni	(pci_gnt_n),
	
	.enable_i	(1'b1),
	.enabled_o	(pci_enabled),
	.pci_disable_o	(pci_disable),
	
	.wb_clk_i	(wb_clk),	// Wishbone Master
	.wb_rst_i	(wb_rst),
	
	.wb_cyc_i	(0),		// TODO:
	.wb_cyc_o	(p_cyc),
	.wb_stb_o	(p_stb),
	.wb_we_o	(p_we),
	.wb_ack_i	(p_ack),
	.wb_rty_i	(p_rty),
	.wb_err_i	(p_err),
	.wb_cti_o	(p_cti),
	.wb_bte_o	(p_bte),
	.wb_adr_o	(p_adr[ASB:0]),
	
	.wb_sel_o	(p_sel_t),
	.wb_dat_o	(p_dat_t),
	.wb_sel_i	(p_sel_f),
	.wb_dat_i	(p_dat_f)
);


// CRTC, redraw, colour conversion, SPROM, and LEDs.
freega_io #(
	.ADDRESS	(ADDRESS-1)
) IO0 (
	.wb_clk_i	(wb_clk),	// 50 MHz
	.wb_rst_i	(wb_rst),
	.clk50_i	(clk50),
	.pci_rst_ni	(pci_rst_n),
	
	.io_cyc_i	(io_cyc),
	.io_stb_i	(io_stb),
	.io_we_i	(io_we),
	.io_ack_o	(io_ack),
	.io_rty_o	(io_rty),
	.io_err_o	(io_err),
	.io_cti_i	(io_cti),
	.io_bte_i	(io_bte),
	.io_adr_i	(io_adr),
	.io_sel_i	(io_sel_t),
	.io_dat_i	(io_dat_t),
	.io_sel_o	(io_sel_f),
	.io_dat_o	(io_dat_f),
	
	.dma_cyc_o	(d_cyc),
	.dma_stb_o	(d_stb),
	.dma_we_o	(d_we),
	.dma_ack_i	(d_ack),
	.dma_rty_i	(d_rty),
	.dma_err_i	(d_err),
	.dma_cti_o	(d_cti),
	.dma_bte_o	(d_bte),
	.dma_adr_o	(d_adr),
	.dma_sel_o	(d_sel_t),
	.dma_dat_o	(d_dat_t),
	
	.cache_rst_o	(cache_flush),
	
	.rclk_o		(rclk),
	.din_do_o	(din_do),
	
`ifndef __use_no_video
	.rdr_cyc_o	(r_cyc),
	.rdr_stb_o	(r_stb),
	.rdr_we_o	(r_we),
	.rdr_ack_i	(r_ack),
	.rdr_rty_i	(r_rty),
	.rdr_err_i	(r_err),
	.rdr_cti_o	(r_cti),
	.rdr_bte_o	(r_bte),
	.rdr_adr_o	(r_adr),
	.rdr_sel_i	(r_sel_f),
	.rdr_dat_i	(r_dat_f),
	
	.vga_clk_o	(vga_clk),
	.vga_sync_no	(vga_sync_n),
	.vga_blank_no	(vga_blank_n),
	.vga_de_o	(vga_de),
	.vga_hsync_o	(vga_hsync),
	.vga_vsync_o	(vga_vsync),
	.vga_r_o	(vga_r),
	.vga_g_o	(vga_g),
	.vga_b_o	(vga_b),
`else	// !__use_no_video
	.rdr_ack_i	(0),
	.rdr_rty_i	(0),
	.rdr_err_i	(0),
	.rdr_sel_i	(0),
	.rdr_dat_i	(0),
`endif	// __use_no_video
	
	.leds_o		(leds)
);

`ifdef __use_no_video
assign	{r_cyc, r_stb, r_we, r_cti, r_bte, r_adr}	= 0;
assign	{vga_clk, vga_sync_n, vga_blank_n, vga_de}	= 0;
assign	{vga_hsync, vga_vsync, vga_r, vga_g, vga_b}	= 0;
`endif	// __use_no_video


//---------------------------------------------------------------------------
// Share the SDRAM amongst three other Wishbone masters.
//
`ifndef __use_no_wb_mux
wb_mux4to1_async #(
	.HIGHZ		(0),
	.WIDTH		(32),
	.ADDRESS	(ADDRESS-1)
) WBMUX0 (
	.wb_clk_i	(wb_clk),
	.wb_rst_i	(wb_rst),
	
	.a_cyc_i	(c_cyc),
	.a_stb_i	(c_stb),
	.a_we_i		(c_we),
	.a_ack_o	(c_ack),
	.a_rty_o	(c_rty),
	.a_err_o	(c_err),
	.a_cti_i	(c_cti),
	.a_bte_i	(c_bte),
	.a_adr_i	(c_adr),
	.a_sel_i	(c_sel_t),
	.a_dat_i	(c_dat_t),
	.a_sel_o	(c_sel_f),
	.a_dat_o	(c_dat_f),
	
	.b_cyc_i	(p_cyc),
	.b_stb_i	(p_stb),
	.b_we_i		(p_we),
	.b_ack_o	(p_ack),
	.b_rty_o	(p_rty),
	.b_err_o	(p_err),
	.b_cti_i	(p_cti),
	.b_bte_i	(p_bte),
	.b_adr_i	(p_adr),
	.b_sel_i	(p_sel_t),
	.b_dat_i	(p_dat_t),
	.b_sel_o	(p_sel_f),
	.b_dat_o	(p_dat_f),
	
	.c_cyc_i	(r_cyc),
	.c_stb_i	(r_stb),
	.c_we_i		(r_we),		// Always read
	.c_ack_o	(r_ack),
	.c_rty_o	(r_rty),
	.c_err_o	(r_err),
	.c_cti_i	(r_cti),
	.c_bte_i	(r_bte),
	.c_adr_i	(r_adr),
	.c_sel_i	(0),
	.c_dat_i	(0),
	.c_sel_o	(r_sel_f),
	.c_dat_o	(r_dat_f),
	
	.d_cyc_i	(d_cyc),
	.d_stb_i	(d_stb),
	.d_we_i		(d_we),
	.d_ack_o	(d_ack),
	.d_rty_o	(d_rty),
	.d_err_o	(d_err),
	.d_cti_i	(d_cti),
	.d_bte_i	(d_bte),
	.d_adr_i	(d_adr),
	.d_sel_i	(d_sel_t),
	.d_dat_i	(d_dat_t),
	.d_sel_o	(),
	.d_dat_o	(),
	
	.x_cyc_o	(m_cyc),
	.x_stb_o	(m_stb),
	.x_we_o		(m_we),
	.x_ack_i	(m_ack),
	.x_rty_i	(m_rty),
	.x_err_i	(m_err),
	.x_cti_o	(m_cti),
	.x_bte_o	(m_bte),
	.x_adr_o	(m_adr),
	.x_sel_i	(m_sel_f),
	.x_dat_i	(m_dat_f),
	.x_sel_o	(m_sel_t),
	.x_dat_o	(m_dat_t)
);
`else	// __use_no_wb_mux
assign	m_cyc	= p_cyc;
assign	m_stb	= p_stb;
assign	m_we	= p_we;
assign	p_ack	= m_ack;
assign	p_rty	= m_rty;
assign	p_err	= m_err;
assign	m_cti	= p_cti;
assign	m_bte	= p_bte;
assign	m_adr	= p_adr;
assign	p_sel_f	= m_sel_f;
assign	p_dat_f	= m_dat_f;
assign	m_sel_t	= p_sel_t;
assign	m_dat_t	= p_dat_t;
`endif	// __use_no_wb_mux


`ifdef __use_no_sdram
assign	{sdr_clk, sdr_cke, sdr_ba, sdr_a}	= 0;
assign	{sdr_cs_n, sdr_ras_n, sdr_cas_n, sdr_we_n, sdr_dm}	= 6'h3f;

wb_bram4k BRAM0 (
	.wb_clk_i	(wb_clk),
	.wb_rst_i	(wb_rst),
	.wb_cyc_i	(m_cyc),
	.wb_stb_i	(m_stb),
	.wb_we_i	(m_we),
	.wb_ack_o	(m_ack),
	.wb_rty_o	(m_rty),
	.wb_err_o	(m_err),
	.wb_cti_i	(m_cti),
	.wb_bte_i	(m_bte),
	.wb_adr_i	(m_adr[9:0]),
	.wb_sel_i	(m_sel_t),
	.wb_dat_i	(m_dat_t),
	.wb_sel_o	(m_sel_f),
	.wb_dat_o	(m_dat_f)
);
`else	// !__use_no_sdram

assign	sdr_a [12]	= 1'b0;
wb_sdram_ctrl #(
	.ADDRESS	(ADDRESS-1),	// 8 MB (2Mx32)
	.HIGHZ		(0),
`ifdef __icarus
	.RFC_PERIOD	(30),	// 100 MHz timings (off 50 MHz sys clock)
`else
	.RFC_PERIOD	(780),	// 100 MHz timings (off 50 MHz sys clock)
`endif
	.tRAS		(3),
	.tRC		(3),
	.tRFC		(3)
) SDRCTRL (
	.sdr_clk_i	(clk100),
	.wb_clk_i	(wb_clk),
	.wb_clk_ni	(wb_clk_n),
	.wb_rst_i	(wb_rst),
	.wb_cyc_i	(m_cyc),
	.wb_stb_i	(m_stb),
	.wb_we_i	(m_we),
	.wb_ack_o	(m_ack),
	.wb_rty_o	(m_rty),
	.wb_err_o	(m_err),
	.wb_cti_i	(m_cti),
	.wb_bte_i	(m_bte),
	.wb_adr_i	(m_adr),
	.wb_sel_i	(m_sel_t),
	.wb_dat_i	(m_dat_t),
	.wb_sel_o	(m_sel_f),
	.wb_dat_o	(m_dat_f),
	
	// SDRAM pins.
	.CLK		(sdr_clk),
	.CKE		(sdr_cke),
	.CS_n		(sdr_cs_n),
	.RAS_n		(sdr_ras_n),
	.CAS_n		(sdr_cas_n),
	.WE_n		(sdr_we_n),
	.BA		(sdr_ba),
	.A		(sdr_a[11:0]),
	.DM		(sdr_dm),
	.DQ		(sdr_dq)
);
`endif	// !__use_no_sdram


//---------------------------------------------------------------------------
//  Clocking stuff. Different phases of clocks are needed since there are
//  real-world delays, like IOB delays.
//
`ifdef __use_no_DCM
reg	clk2x	= 1;
reg	clk25	= 1;
always	#5 clk2x	<= ~clk2x;
always	#20 clk25	<= ~clk25;
assign	wb_clk	= clk50;
assign	wb_clk_n= ~clk50;
assign	tta_clk	= clk2x;
assign	dot_clk	= clk25;
assign	clk100	= clk2x;
`else
wire	GND	= 0;
wire	clk_out, clk90, clk180, clk270, clk25, clk2x, lock;

DCM #(
// 	.CLKIN_DIVIDE_BY_2	("TRUE"),
`ifdef __icarus
	.CLKDV_DIVIDE		(2),
`else
	.CLKDV_DIVIDE		(2.0),
`endif
	.CLKFX_MULTIPLY		(3),
	.CLKFX_DIVIDE		(1),
	.CLK_FEEDBACK		("1X"),
	.DLL_FREQUENCY_MODE	("LOW")
) dcm0 (
	.CLKIN	(clk50),
	.CLKFB	(wb_clk),
	.DSSEN	(GND),
	.PSEN	(GND),
	.RST	(1'b0),
	.CLK0	(clk_out),
	.CLK90	(clk90),
	.CLK180	(clk180),
	.CLK270	(clk270),
	.CLKDV	(clk25),
	.CLK2X	(clk2x),
	.CLKFX	(clk150),
	.LOCKED	(lock)
);

BUFG WBCLK_BUFG (
	.I	(clk_out),
	.O	(wb_clk)
);

BUFG WBCLKN_BUFG (
	.I	(clk180),
	.O	(wb_clk_n)
);

BUFG SDRCLK_BUFG (
	.I	(clk2x),
	.O	(clk100)
);

BUFG DOTCLK_BUFG (
	.I	(clk25),
	.O	(dot_clk)
);

BUFG TTACLK_BUFG (
	.I	(clk150),
	.O	(tta_clk)
);
`endif	// __use_no_DCM


endmodule	// freega_top
