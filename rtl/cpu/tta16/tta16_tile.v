/***************************************************************************
 *                                                                         *
 *   tta16_tile.v - A blazingly fast, ridiculously simple, impossible to   *
 *     program, 16-bit processor.                                          *
 *        The complete CPU `tile' contains a cache and DMA to allow TTA16  *
 *     to work efficiently with a low-latency memory.                      *
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

// Resource usage summary:
//  - 2x BRAM for instructions
//  - BRAM for cache
//  - MULT for CPU multiply
//
// This means four BRAM/MULTs are used, of an available 12 for FreeGA.
//

// Two  WishBone interfaces, one for mem and one for I/O.
// I/O is 16-bits, mem is 32-bits.

`timescale 1ns/100ps
module tta16_tile #(
	parameter	ADDRESS	= 23,
	parameter	ASB	= ADDRESS - 3
) (
	input		wb_rst_i,
	input		wb_clk_i,	// 50 MHz
	input		cpu_clk_i,	// 150 MHz, sync with WB clock
	input		cache_rst_i,
	
	output		mem_cyc_o,	// Master only
	output		mem_stb_o,
	output		mem_we_o,
	input		mem_ack_i,
	input		mem_rty_i,
	input		mem_err_i,
	output	[2:0]	mem_cti_o,
	output	[1:0]	mem_bte_o,
	output	[ASB:0]	mem_adr_o,
	output	[3:0]	mem_sel_o,
	output	[31:0]	mem_dat_o,
	input	[3:0]	mem_sel_i,
	input	[31:0]	mem_dat_i,
	
	output		io_cyc_o,
	output		io_stb_o,
	output		io_we_o,
	input		io_ack_i,
	input		io_rty_i,
	input		io_err_i,
	output	[2:0]	io_cti_o,
	output	[1:0]	io_bte_o,
	output	[ASB:0]	io_adr_o,
	output	[1:0]	io_sel_o,
	output	[15:0]	io_dat_o,
	input	[1:0]	io_sel_i,
	input	[15:0]	io_dat_i
);


wire	cpu_cyc, cpu_stb, cpu_we, cpu_ack, cpu_rty, cpu_err;
wire	[2:0]	cpu_cti;
wire	[1:0]	cpu_bte;
wire	[ASB+2:0]	cpu_adr;
wire	[1:0]	cpu_sel;
wire	[15:0]	cpu_dat;

wire	cache_reset, cache_stb, cache_ack, cache_rty, cache_err;
wire	[1:0]	cache_sel;
wire	[15:0]	cache_dat;

wire	sync_stb, sync_ack, sync_rty, sync_err;
wire	[1:0]	sync_sel;
wire	[15:0]	sync_dat;

wire	[1:0]	mux_sel;
wire	[15:0]	mux_dat;

reg	mux_src	= 0;


// TODO: Too slow!
// assign	#2 sync_stb	= cpu_stb && (cpu_adr[ASB+2] == 1);
// assign	#2 cache_stb	= cpu_stb && (cpu_adr[ASB+2] == 0);

assign	#2 mux_sel	= mux_src ? sync_sel : cache_sel ;
assign	#2 mux_dat	= mux_src ? sync_dat : cache_dat ;

assign	#2 cpu_ack	= cache_ack || sync_ack ;
assign	#2 cpu_rty	= cache_rty || sync_rty ;
assign	#2 cpu_err	= cache_err || sync_err ;


always @(posedge cpu_clk_i)
	if (wb_rst_i)	mux_src	<= #2 0;
	else		mux_src	<= #2 sync_stb;


tta16 #(
	.HIGHZ		(0),
	.WIDTH		(16),
	.INSTR		(32),
	.ADDRESS	(ADDRESS),
	.PCBITS		(10),
	.PCINIT		(1),
	.WBBITS		(16)
) CPU (
	.cpu_clk_i	(cpu_clk_i),
	.cpu_rst_i	(wb_rst_i),
	
	.wb_cyc_o	(cpu_cyc),
	.wb_stb_o	({sync_stb, cache_stb}),
// 	.wb_stb_o	(cpu_stb),
	.wb_we_o	(cpu_we),
	.wb_ack_i	(cpu_ack),
	.wb_rty_i	(cpu_rty),
	.wb_err_i	(cpu_err),
	.wb_cti_o	(cpu_cti),
	.wb_bte_o	(cpu_bte),
	.wb_adr_o	(cpu_adr),
	.wb_sel_o	(cpu_sel),
	.wb_dat_o	(cpu_dat),
	.wb_sel_i	(mux_sel),
	.wb_dat_i	(mux_dat)
);


//---------------------------------------------------------------------------
// Data cache only caches memory contents, I/O isn't cached.
//
wb_simple_cache #(
	.HIGHZ		(0),
	.ADDRESS	(ADDRESS-2),
	.CWIDTH		(16),
	.WWIDTH		(32),
	.SIZE		(10)		// 2kB (32x512)
) CACHE0 (
	.wb_clk_i	(wb_clk_i),
	.wb_rst_i	(cache_rst_i),
	
	.cpu_clk_i	(cpu_clk_i),	// Dual (but syncronous) clocks
	.cpu_cyc_i	(cpu_cyc),	// Master drives this from the hi-side
// 	.cpu_stb_i	(cpu_stb),
	.cpu_stb_i	(cache_stb),
	.cpu_we_i	(cpu_we),
	.cpu_ack_o	(cache_ack),
	.cpu_rty_o	(cache_rty),
	.cpu_err_o	(cache_err),
	.cpu_cti_i	(cpu_cti),
	.cpu_bte_i	(cpu_bte),
	.cpu_adr_i	(cpu_adr[ASB+1:0]),
	
	.cpu_sel_i	(cpu_sel),
	.cpu_dat_i	(cpu_dat),
	.cpu_sel_o	(cache_sel),
	.cpu_dat_o	(cache_dat),
	
	.mem_cyc_o	(mem_cyc_o),
	.mem_stb_o	(mem_stb_o),
	.mem_we_o	(mem_we_o),
	.mem_ack_i	(mem_ack_i),
	.mem_rty_i	(mem_rty_i),
	.mem_err_i	(mem_err_i),
	.mem_cti_o	(mem_cti_o),
	.mem_bte_o	(mem_bte_o),
	.mem_adr_o	(mem_adr_o),
	.mem_sel_o	(mem_sel_o),
	.mem_dat_o	(mem_dat_o),
	.mem_sel_i	(mem_sel_i),
	.mem_dat_i	(mem_dat_i)
);


// Synchronise external 50 MHz I/O with internal 150 MHz I/O.
wb_sync #(
	.HIGHZ		(0),
	.CWIDTH		(16),
	.WWIDTH		(16),
	.ADDRESS	(ADDRESS-2)
) SYNC0 (
	.wb_rst_i	(wb_rst_i),
	
	.a_clk_i	(cpu_clk_i),
	.a_cyc_i	(cpu_cyc),
	.a_stb_i	(sync_stb),
	.a_we_i		(cpu_we),
	.a_ack_o	(sync_ack),
	.a_rty_o	(sync_rty),
	.a_err_o	(sync_err),
	.a_cti_i	(0),	// Single-word transfers
	.a_bte_i	(0),
	.a_adr_i	(cpu_adr[ASB:0]),
	.a_sel_i	(cpu_sel),
	.a_dat_i	(cpu_dat),
	.a_sel_o	(sync_sel),
	.a_dat_o	(sync_dat),
	
	.b_clk_i	(wb_clk_i),
	.b_cyc_o	(io_cyc_o),
	.b_stb_o	(io_stb_o),
	.b_we_o		(io_we_o),
	.b_ack_i	(io_ack_i),
	.b_rty_i	(io_rty_i),
	.b_err_i	(io_err_i),
	.b_cti_o	(io_cti_o),	// Single-word transfers
	.b_bte_o	(io_bte_o),
	.b_adr_o	(io_adr_o),
	.b_sel_i	(io_sel_i),
	.b_dat_i	(io_dat_i),
	.b_sel_o	(io_sel_o),
	.b_dat_o	(io_dat_o)
);


endmodule	// tta16_tile
