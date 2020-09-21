/***************************************************************************
 *                                                                         *
 *   wb_simple_cache.v - A Wishbone compliant data cache (can be used for  *
 *      instructions too, but has more features than needed).              *
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

// Linesize is 16 bytes.
// Upon miss, fetches the requested line plus the following line. TODO
// Number of registers required is fewer since WB address remain constant
// until `ACK'.

// TODO: No support for write-back yet.


`timescale 1ns/100ps
module wb_simple_cache #(
	parameter	HIGHZ	= 0,
	parameter	ADDRESS	= 21,
	parameter	CWIDTH	= 16,
	parameter	WWIDTH	= 32,
	parameter	ASSOC	= 1,
	parameter	SIZE	= 10,		// 2kB (16x1024)
	parameter	WSIZE	= 1,		// 16-bit
	parameter	LSIZE	= 6,		// 64-bytes
	parameter	ENABLES	= CWIDTH / 8,
	parameter	SELECTS	= WWIDTH / 8,
	// Components of address fields {TAG, IDX, OFF}.
	parameter	TAGSIZE	= ADDRESS - SIZE - WSIZE + ASSOC,
	parameter	INDEX	= SIZE - ASSOC - LSIZE + WSIZE,
	parameter	OFFSET	= LSIZE - WSIZE,
	// Bit-select helpers.
	parameter	MSB	= CWIDTH - 1,
	parameter	WSB	= WWIDTH - 1,
	parameter	ESB	= ENABLES - 1,
	parameter	SSB	= SELECTS - 1,
	parameter	CSB	= ADDRESS + WWIDTH / CWIDTH - 2,
	parameter	ASB	= ADDRESS - 1,
	parameter	TSB	= TAGSIZE - 1,
	parameter	ISB	= INDEX - 1,
	parameter	OSB	= OFFSET - 1
) (
	input		wb_clk_i,
	input		wb_rst_i,
	
	input		cpu_clk_i,	// Dual (but syncronous) clocks
	input		cpu_cyc_i,	// Master drives this from the hi-side
	input		cpu_stb_i,
	input		cpu_we_i,
	output		cpu_ack_o,
	output		cpu_rty_o,
	output		cpu_err_o,
	input	[2:0]	cpu_cti_i,
	input	[1:0]	cpu_bte_i,
	input	[CSB:0]	cpu_adr_i,
	
	input	[ESB:0]	cpu_sel_i,
	input	[MSB:0]	cpu_dat_i,
	output	[ESB:0]	cpu_sel_o,
	output	[MSB:0]	cpu_dat_o,
	
	output		mem_cyc_o,	// Drives the memory controller
	output		mem_stb_o,
	output		mem_we_o,
	input		mem_ack_i,
	input		mem_rty_i,
	input		mem_err_i,
	output	[2:0]	mem_cti_o,
	output	[1:0]	mem_bte_o,
	output	[ASB:0]	mem_adr_o,
	input	[SSB:0]	mem_sel_i,
	input	[WSB:0]	mem_dat_i,
	output	[SSB:0]	mem_sel_o,
	output	[WSB:0]	mem_dat_o
);


`define	WBCACHE_IDLE	3'b000
`define	WBCACHE_LOOK	3'b001
`define	WBCACHE_MISS	3'b010
`define	WBCACHE_WAIT	3'b100

reg	[2:0]	state	= `WBCACHE_IDLE;
reg	bank	= 0;
reg	[6:0]	evict_prev	= 1;
reg	p_vld0	= 0;
reg	p_vld1	= 0;
reg	[TSB:0]	p_tag0	= 0, p_tag1	= 0;
reg	[ISB:0]	p_idx	= 0;
reg	cpu_ack	= 0;

// TODO: Parameterise.
wire	[ISB:0]	t_idx	= cpu_adr_i[SIZE-ASSOC-1:LSIZE-WSIZE];
wire	[OSB:0]	t_off	= cpu_adr_i[OSB:0];
wire	[TSB:0]	t_dat	= cpu_adr_i[CSB:SIZE-1];
wire	[TSB:0]	tag0, tag1;
wire	m0, m1, vld0, vld1, hit, miss, vld;

wire	[6:0]	evict;
wire	fetched, done_slow;
wire	u_tags, update, u_bank;
wire	[7:0]	u_addr;
wire	[WSB:0]	u_data;
wire	wack, hit_r, hit_w, l_write;
reg	wack_r	= 0;


// FIXME: Doesn't correctly spupport writes
assign	cpu_ack_o	= hit_r;
assign	cpu_rty_o	= 0;
assign	cpu_err_o	= 0;
assign	cpu_sel_o	= 2'b11;	// TODO: store `sel's in BRAM?

assign	l_write	= !wack_r && hit_r;
assign	u_bank	= evict_prev[1];

assign	#3 m0	= (p_tag0 == t_dat);
assign	#3 m1	= ({p_vld1, p_tag1} == {1'b1, t_dat});
assign	#2 vld	= ({cpu_stb_i, 1'b0, p_idx} == {1'b1, cpu_we_i, t_idx});
assign	#2 hit_w= (m0 && p_vld0) || m1;


always @(posedge cpu_clk_i)
	if (wb_rst_i)	state	<= #2 `WBCACHE_IDLE;
	else case (state)
	
	`WBCACHE_IDLE:
		if (cpu_stb_i && !cpu_we_i)	state	<= #2 `WBCACHE_LOOK;
		else if (cpu_stb_i && cpu_we_i)	state	<= #2 `WBCACHE_WAIT;
	
	`WBCACHE_LOOK:
		if (hit_w)	state	<= #2 `WBCACHE_WAIT;
		else		state	<= #2 `WBCACHE_MISS;
	
	`WBCACHE_MISS:
		if (u_tags)	state	<= #2`WBCACHE_WAIT;
	
	`WBCACHE_WAIT:
		if (hit_r)	state	<= #2 `WBCACHE_IDLE;
	
	endcase


always @(posedge cpu_clk_i)
// 	if (wb_rst_i)	{p_idx, p_tag0, p_tag1}	<= #2 0;
	if ((cpu_stb_i && !cpu_we_i) || l_write) begin
		p_idx	<= #2 t_idx;
		p_tag0	<= #2 tag0;
		p_vld0	<= #2 vld0;
		p_tag1	<= #2 tag1;
		p_vld1	<= #2 vld1;
	end


always @(posedge cpu_clk_i)
	if (hit_r)	evict_prev	<= #2 evict;
// 	if (fetched)	evict_prev	<= #2 evict;


always @(posedge cpu_clk_i)
	if (wb_rst_i)	wack_r	<= #2 0;
	else		wack_r	<= #2 wack;


FDRSE hit_ff (
	.D	(hit_w),				// LUT3
	.R	(!wack && (hit_r || wb_rst_i || !vld)),	// LUT4
	.S	(wack),
	.Q	(hit_r),
	.C	(cpu_clk_i),
	.CE	(1'b1)
);


tag_ram #(
	.TWIDTH		(TAGSIZE),
	.IBITS		(INDEX)
) TAGS (
// TODO: This has an unpredictable effect.
	.clock_i	(wb_clk_i),
	.reset_i	(wb_rst_i),
	
// 	.u_write_i	(fetched),
	.u_write_i	(done_slow),
	.u_bank_i	(u_bank),
	.u_data_i	(t_dat),
	
	.index_i	(t_idx),
	
	.tag0_o		(tag0),
	.vld0_o		(vld0),
	.tag1_o		(tag1),
	.vld1_o		(vld1)
);


wire	[SIZE-1:0]	l_addr	= {m1, t_idx, t_off};
// wire	[SIZE-1:0]	l_addr	= {m1 && p_vld1, t_idx, t_off};
cache_bram BRAM (
	.reset_i	(wb_rst_i),
	
	.u_clk_i	(wb_clk_i),
	.u_write_i	(update),
	.u_addr_i	({u_bank, u_addr}),
	.u_data_i	(u_data),
	
	.l_clk_i	(cpu_clk_i),
	.l_write_i	(l_write),
	.l_addr_i	(l_addr),
	.l_data_o	(cpu_dat_o),
	.l_data_i	(cpu_dat_i)
);


mfsr7 EVICT (
	.count_i	(evict_prev),
	.count_o	(evict)
);


wire	[3:0] #2 wr_thru_sels	= cpu_adr_i[0] ? {cpu_sel_i, 2'b00} : {2'b00, cpu_sel_i};
fetch_wb #(
	.WIDTH		(WWIDTH),
	.ADDRESS	(ADDRESS),
	.CNTBITS	(LSIZE-2)	// 32-bit fetch
) FETCH (
	// Wishbone clock domain.
	.wb_clk_i	(wb_clk_i),
	.wb_rst_i	(wb_rst_i),
	.wb_cyc_o	(mem_cyc_o),
	.wb_stb_o	(mem_stb_o),
	.wb_we_o	(mem_we_o),
	.wb_ack_i	(mem_ack_i),
	.wb_rty_i	(mem_rty_i),
	.wb_err_i	(mem_err_i),
	.wb_cti_o	(mem_cti_o),
	.wb_bte_o	(mem_bte_o),
	.wb_adr_o	(mem_adr_o),
	.wb_sel_i	(mem_sel_i),
	.wb_dat_i	(mem_dat_i),
	.wb_sel_o	(mem_sel_o),
	.wb_dat_o	(mem_dat_o),
	
	// Sync. with WB clock, but can be many times faster.
	.clk_i		(cpu_clk_i),
	.miss_i		(state == `WBCACHE_MISS),
	.write_i	(cpu_stb_i && cpu_we_i),
	.wack_o		(wack),
// 	.wack_ao	(wack),
	.bes_i		(wr_thru_sels),
	.data_i		({cpu_dat_i, cpu_dat_i}),
	.ack_o		(u_tags),
	.ready_o	(fetched),
	.done_o		(done_slow),	// WB domain
	.busy_o		(),
	.addr_i		(cpu_adr_i[CSB:1]),
	
	.u_write_o	(update),
	.u_vld_o	(),
	.u_addr_o	(u_addr),
	.u_data_o	(u_data)
);


endmodule	// wb_simple_cache
