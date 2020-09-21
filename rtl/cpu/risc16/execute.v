/***************************************************************************
 *                                                                         *
 *   execute.v - Execute pipeline stage for a RISC CPU.                    *
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
module execute #(
	parameter	WIDTH	= 16,
	parameter	PCBITS	= 10,
	parameter	MSB	= WIDTH - 1,
	parameter	PSB	= PCBITS - 1
) (
	input		clock_i,
	input		reset_i,
	input		stall_ni,
	
	input	[3:0]	id_rd_i,
	input	[1:0]	id_bit_i,
	input		id_cr_i,
	input		id_sf_i,
	input	[1:0]	id_dst_i,
	input		id_sbb_i,
	input		id_mul_i,
	input		id_mem_i,
	input		id_msr_i,
	input		id_bra_i,
	input		id_st_i,
	input	[MSB:0]	id_a_i,
	input	[MSB:0]	id_b_i,
	input	[MSB:0]	id_dat_i,
	
	output	reg	ex_cr_o		= 0,
	output	reg	ex_sf_o		= 0,
	output	reg	ex_mul_o	= 0,
	output	reg	ex_mem_o	= 0,
	output	reg	ex_msr_o	= 0,
	output	reg	ex_bra_o	= 0,
	output	reg	ex_st_o		= 0,
	output	reg	[1:0]	ex_dst_o	= 0,
	output	reg	[3:0]	ex_rd_o		= 0,
	output	reg	[MSB:0]	ex_dat_o,
	output		ex_zf_o,
	output		ex_cf_o,
	output		ex_nf_o,
	output		[WIDTH*2-1:0]	ex_prod_o,
	output	reg	[MSB:0]	ex_alu_o
);


always @(posedge clock_i)
	{ex_mul_o, ex_sf_o, ex_st_o}	<= #2 {id_mul_i, id_sf_i, id_st_i};

// TODO: Needs to source from 3 places.
always @(posedge clock_i)
	ex_dat_o	<= #2 id_dat_i ;
// 	ex_dat_o	<= #2 (id_rd_i == ex_rd_o) ? ex_alu_o : id_dat_i ;

always @(posedge clock_i)
	if (reset_i)	{ex_msr_o, ex_mem_o}	<= #2 0;
	else		{ex_msr_o, ex_mem_o}	<= #2 {id_msr_i, id_mem_i};

// If a branch is taken, prevent reg/mem from being changed.
always @(posedge clock_i)
	if (reset_i)	ex_cr_o	<= #2 0;
	else		ex_cr_o	<= #2 id_cr_i & stall_ni;

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
always @(posedge clock_i)
	if (id_bra_i || id_msr_i)
		ex_dst_o	<= #2 1;
	else if (id_dst_i == 2)
		ex_dst_o	<= #2 {1'b1, id_mul_i};
	else if (id_dst_i == 0 || id_dst_i == 3)
		ex_dst_o	<= #2 0;
/*
always @(posedge clock_i)
	ex_dst_o	<= #2 id_dst_i;
*/

always @(posedge clock_i)
	if (reset_i)	ex_bra_o	<= #2 0;
	else		ex_bra_o	<= #2 id_bra_i;

always @(posedge clock_i)
	ex_rd_o	<= #2 id_rd_i;

reg	[WIDTH+MSB:0]	prod_r;

reg	nf_r	= 0;
reg	cf_r	= 0;
reg	zf_r	= 1;

wire	nf, cf, zf;
wire	[MSB:0]	bits_n, diff;
wire	[WIDTH+MSB:0]	prod;


assign	ex_prod_o	= prod_r;

assign	ex_nf_o	= nf_r;
assign	ex_cf_o	= cf_r;
assign	ex_zf_o	= zf_r;


always @(posedge clock_i)
	if (reset_i)
		{nf_r, cf_r, zf_r}	<= #2 1;
	else if (id_sf_i)
		{nf_r, cf_r, zf_r}	<= #2 {nf, cf, zf};
	
always @(posedge clock_i)
	prod_r	<= #2 prod;

always @(posedge clock_i)
	ex_alu_o	<= #2 id_dst_i[1] ? ~bits_n : diff ;


risc_alu_async #(WIDTH) ALU (
	.cf_i		(ex_cf_o & id_sbb_i),
	.bit_i		(id_bit_i),
	.a_i		(id_a_i),
	.b_i		(id_b_i),
	
	.prod_o		(prod),
	.bits_no	(bits_n),
	.diff_o		(diff),
	
	.cf_o		(cf),
	.zf_o		(zf),
	.nf_o		(nf)
);


endmodule	// execute
