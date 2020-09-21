/***************************************************************************
 *                                                                         *
 *   memory.v - Memory load/store unit for a RISC CPU.                     *
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

`timescale 1ns/100ps
module memory #(
	parameter	HIGHZ	= 0,
	parameter	WIDTH	= 16,
	parameter	INSTR	= 16,
	parameter	ADDRESS	= 25,
	parameter	PCBITS	= 11,
	parameter	WBBITS	= WIDTH,	// TODO: See below
	parameter	ENABLES	= WBBITS / 8,
	parameter	SEGBITS	= ADDRESS - WIDTH,
	parameter	PSB	= PCBITS - 1,
	parameter	MSB	= WIDTH - 1,
	parameter	ISB	= INSTR - 1,
	parameter	WSB	= WBBITS - 1,
	parameter	ESB	= ENABLES - 1,
	parameter	ASB	= ADDRESS - 1,
	parameter	SSB	= SEGBITS - 1
) (
	input		clock_i,
	input		reset_i,
	input		stall_ni,
	
	input		ex_cr_i,
	input		ex_sf_i,
	input		ex_mul_i,
	input		ex_mem_i,
	input		ex_msr_i,
	input		ex_bra_i,
	input		ex_st_i,
	input	[1:0]	ex_dst_i,	// {bits(3), prod(2), mem(1), rest(0)}
	input	[3:0]	ex_rd_i,
	input	[MSB:0]	ex_dat_i,
	input	[MSB:0]	ex_alu_i,
	input	[WIDTH+MSB:0]	ex_prod_i,
	
	output	reg		mu_cr_o		= 0,
	output	reg	[3:0]	mu_rd_o		= 0,
	output	reg		mu_dst_o	= 0,
	output	reg	[MSB:0]	mu_alu_o,
	
	output	reg		mu_mem_o	= 0,
	output	reg		mu_rdy_o	= 0,
	output	reg	[MSB:0]	mu_dat_o,

	output		wb_cyc_o,
	output	[1:0]	wb_stb_o,	// I/O and memory strobes
	output		wb_we_o,
	input		wb_ack_i,
	input		wb_rty_i,
	input		wb_err_i,
	output	[2:0]	wb_cti_o,
	output	[1:0]	wb_bte_o,
	output	[ASB:0]	wb_adr_o,
	output	[ESB:0]	wb_sel_o,
	output	[WSB:0]	wb_dat_o,
	input	[ESB:0]	wb_sel_i,
	input	[WSB:0]	wb_dat_i
);


reg	[SSB:0]	dseg	= 0;	// Data segment
reg	[SSB:0]	sseg	= 0;	// Stack segment
reg	wr_inhibit	= 0;

wire	mu_rdy_w;
wire	[MSB:0]	mu_dat_w;
wire	[MSB:0]	mu_alu_w;

// wire	[MSB:0]	prod	= ex_mul_i ? ex_prod_i[WIDTH+MSB:WIDTH] : ex_prod_i[MSB:0];
// assign	#2 mu_alu_w	= ex_dst_i != 2 ? ex_alu_i : prod ;
/*
assign	#4 mu_alu_w	= ex_bra_i && ex_cr_i ? ex_dat_i :
			  ex_dst_i == 2 &&  ex_mul_i ? ex_prod_i[WIDTH+MSB:WIDTH] :
			  ex_dst_i == 2 && !ex_mul_i ? ex_prod_i[MSB:0] :
			  ex_alu_i ;
*/

// Incoming encoding:
//	00 - Sub
//	01 - Mem
//	10 - Mul
//	11 - bits
// Outoing encoding:
//	00 - ALU
//	01 - dat
//	10 - plo
//	11 - phi
assign	#4 mu_alu_w	= (ex_dst_i == 0) ? ex_alu_i :
			  (ex_dst_i == 1) ? ex_dat_i :
			  (ex_dst_i == 2) ? ex_prod_i[MSB:0] :
			  ex_prod_i[WIDTH+MSB:WIDTH] ;

always @(posedge clock_i)
	mu_alu_o	<= #2 mu_alu_w;

`ifdef __use_readable_MSR
wire	[MSB:0]	#2 mu_msr_w	= {{(MSB-SSB){1'b0}}, ex_alu_i[0] ? sseg : dseg };
// TODO: Use bits# as well.
always @(posedge clock_i)
	if (reset_i)	{sseg, dseg}	<= #2 0;
	else if (ex_msr_i && !ex_cr_i)
		case (ex_alu_i[1:0])	// Write MSRs
		0:	dseg	<= #2 ex_dat_i[SSB:0];
		1:	sseg	<= #2 ex_dat_i[SSB:0];
		endcase
`else
always @(posedge clock_i)
	if (reset_i)	{sseg, dseg}	<= #2 0;
	else if (ex_msr_i) begin
		if (ex_sf_i)	sseg	<= #2 ex_alu_i[SSB:0];
		else		dseg	<= #2 ex_alu_i[SSB:0];
/*		if (ex_sf_i)	sseg	<= #2 ex_dat_i[SSB:0];
		else		dseg	<= #2 ex_dat_i[SSB:0];*/
	end
`endif	// !__use_readable_MSR

always @(posedge clock_i)
	if (reset_i)		mu_mem_o	<= #2 0;
	else if (ex_mem_i)	mu_mem_o	<= #2 1;
	else if (mu_rdy_w)	mu_mem_o	<= #2 0;

always @(posedge clock_i)
	if (mu_mem_o) begin
		mu_rd_o		<= #2 mu_rd_o;
		mu_dst_o	<= #2 mu_dst_o;
	end else begin
		mu_rd_o		<= #2 ex_rd_i;
`ifdef __use_readable_MSR
		mu_dst_o	<= #2 ex_mem_i | ex_msr_i;
`else
		mu_dst_o	<= #2 ex_mem_i;
`endif	// ! __use_readable_MSR
// 		mu_dst_o	<= #2 (ex_dst_i == 1);
// 		mu_dst_o	<= #2 ex_dst_i[0] | ex_bra_i;
	end

always @(posedge clock_i)
	if (reset_i)	mu_rdy_o	<= #2 0;
	else		mu_rdy_o	<= #2 mu_rdy_w;

always @(posedge clock_i)
	if (reset_i)		wr_inhibit	<= #2 0;
	else if (ex_mem_i)	wr_inhibit	<= #2 1;
	else if (wb_ack_i)	wr_inhibit	<= #2 0;

`ifdef __use_readable_MSR
always @(posedge clock_i)
	if (ex_msr_i)	mu_dat_o	<= #2 mu_msr_w;
	else		mu_dat_o	<= #2 mu_dat_w;
`else
// TODO: Remove extra latency!
always @(posedge clock_i)
	mu_dat_o	<= #2 mu_dat_w;
`endif	// !__use_readable_MSR

always @(posedge clock_i)
	if (reset_i)			mu_cr_o	<= #2 0;
	else if (wb_ack_i && !wb_we_o)	mu_cr_o	<= #2 1;
	else if (ex_mem_i)		mu_cr_o	<= #2 0;
	else if (!mu_mem_o)		mu_cr_o	<= #2 ex_cr_i;


risc_mem_wb #(
	.HIGHZ		(HIGHZ),
	.WIDTH		(WIDTH),
	.ADDRESS	(ADDRESS)
) MEM (
	.cpu_clk_i	(clock_i),
	.cpu_rst_i	(reset_i),
	
	.frame_i	(ex_mem_i),
	.write_i	(ex_st_i),
	.ready_o	(mu_rdy_w),
	.addr_i		({ex_sf_i ? sseg : dseg, ex_alu_i}),
	.data_i		(ex_dat_i),
	.data_o		(mu_dat_w),
	
	.wb_cyc_o	(wb_cyc_o),
	.wb_stb_o	(wb_stb_o),
	.wb_we_o	(wb_we_o),
	.wb_ack_i	(wb_ack_i),
	.wb_rty_i	(wb_rty_i),
	.wb_err_i	(wb_err_i),
	.wb_cti_o	(wb_cti_o),
	.wb_bte_o	(wb_bte_o),
	.wb_adr_o	(wb_adr_o),
	.wb_sel_o	(wb_sel_o),
	.wb_dat_o	(wb_dat_o),
	.wb_sel_i	(wb_sel_i),
	.wb_dat_i	(wb_dat_i)
);


endmodule	// memory
