/***************************************************************************
 *                                                                         *
 *   decode.v - RISC16 instruction decoder.                                *
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

`include "defines.v"

`timescale 1ns/100ps
module decode #(
	parameter	WIDTH	= 16,
	parameter	PCBITS	= 10,
	parameter	MSB	= WIDTH - 1,
	parameter	PSB	= PCBITS - 1
) (
	input		clock_i,
	input		reset_i,
	input		stall_ni,
	
	input	[2:0]	if_op_i,
	input	[2:0]	if_fn_i,
	input	[2:0]	if_cnd_i,
	input		if_mem_i,
	input		if_sf_i,
	input		if_cr_i,
	input	[3:0]	if_rd_i,
	input	[3:0]	if_rs0_i,
	input	[3:0]	if_rs1_i,
	input	[MSB:0]	if_imm_i,
	
	input	[MSB:0]	ex_bypass_i,	// TODO: Implement bypassing you bum!
	input		ex_byp_a_i,
	input		ex_byp_b_i,
	input	[MSB:0]	mm_bypass_i,
	input		mm_byp_a_i,
	input		mm_byp_b_i,
	
	input		rf_wr_i,
	input	[3:0]	rf_reg_i,
	input	[MSB:0]	rf_dat_i,
	
	output	reg	[3:0]	id_rd_o		= 0,	// Destination register
	output	reg	[1:0]	id_bit_o	= 0,	// AND, NAND, OR, XOR?
	output	reg		id_cr_o		= 0,	// Change regs?
	output	reg		id_sf_o		= 0,	// Set flags?
	output	reg	[1:0]	id_dst_o	= 0,	// Store {bits, prod, mem, diff}
	output	reg		id_sbb_o	= 0,	// Use borrow?
	output	reg		id_mul_o	= 0,	// Store upper?
	output	reg		id_bra_o	= 0,
	output	reg		id_bx_o		= 0,
	output	reg		id_mem_o	= 0,
	output	reg		id_msr_o	= 0,
	output	reg		id_st_o		= 0,
	output	reg	[2:0]	id_cnd_o	= 0,
	output	reg	[MSB:0]	id_a_o,
	output	reg	[MSB:0]	id_b_o,
	output	reg	[MSB:0]	id_dat_o	// Passes around ALU, not through
);

wire	[MSB:0]	rf_d0, rf_d1;
wire	[1:0]	if_a_src, if_b_src;
wire	[MSB:0]	if_a_dat, if_b_dat;


// TODO: Very long cominatorial delays!
assign	#2 if_a_src	= ex_byp_a_i ? 2'b10 :	// ALU Bypass has precedence
			  mm_byp_a_i ? 2'b11 :  // This is because stalls can mis-detect
			  (if_op_i==`RI || if_op_i==`BX) ? 2'b01 : 2'b00 ;
assign	#2 if_b_src	= ex_byp_b_i ? 2'b10 :
			  mm_byp_b_i ? 2'b11 :
			  (if_op_i==`SUBI || if_op_i==`LW || if_op_i==`SW) ? 2'b01 : 2'b00 ;


always @(posedge clock_i)
	if (reset_i)	id_rd_o	<= #2 0;
	else		id_rd_o	<= #2 if_rd_i;

always @(posedge clock_i)
	if (reset_i)	{id_bra_o, id_bx_o}	<= #2 0;
	else begin
		id_bra_o	<= #2 (if_op_i==`RR || if_op_i==`RI) && if_fn_i==`BR;
		id_bx_o		<= #2 (if_op_i==`BX);
		id_cnd_o	<= #2 if_cnd_i;
	end

// Memory
// TODO: Load/Store?
always @(posedge clock_i)
	if (reset_i)	id_mem_o	<= #2 0;
	else		id_mem_o	<= #2 if_mem_i;

wire	#2 msr	= (if_op_i==`RI || if_op_i == `RR) && (if_fn_i==`MSR);
always @(posedge clock_i)
	if (reset_i)	id_msr_o	<= #2 0;
	else		id_msr_o	<= #2 msr;

always @(posedge clock_i)
	if (reset_i)		id_st_o	<= #2 0;
	else if (stall_ni)	id_st_o	<= #2 (if_op_i==`SW);
	else			id_st_o	<= #2 0;

always @(posedge clock_i)
	id_dat_o	<= #2 rf_d1 ;	// TODO: Will this break BRA?

// ALU inputs.
always @(posedge clock_i)
	id_mul_o	<= #2 (if_fn_i==`MUL && if_sf_i);

always @(posedge clock_i)
	if (reset_i)
		{id_cr_o, id_sf_o}	<= #2 2'b00;
	else if (stall_ni) begin
		id_cr_o	<= #2 if_cr_i;
		id_sf_o	<= #2 (if_op_i==`I12) ? 1'b0 : if_sf_i ;
	end

always @(posedge clock_i)
	id_sbb_o	<= #2 (if_fn_i==`SBB);

always @(posedge clock_i)
	if (reset_i)
		id_dst_o	<= #2 0;
	else if (if_op_i==`LW)
		id_dst_o	<= #2 1;
	else if (if_op_i==`RI || if_op_i==`RR) begin
		if (if_fn_i==`MUL)
			id_dst_o	<= #2 2;
		else if (if_fn_i==`XOR || if_fn_i==`AND || if_fn_i==`OR)
			id_dst_o	<= #2 3;
		else
			id_dst_o	<= #2 0;
	end else
		id_dst_o	<= #2 0;

always @(posedge clock_i)
	if (!if_cr_i && if_fn_i[2:1]==2'b00)	// CMP operation
		id_bit_o	<= #2 2'b11;	// XOR
	else
		id_bit_o	<= #2 if_fn_i[1:0];

always @(posedge clock_i)
	id_a_o	<= #2 if_a_dat;

`ifdef __use_readable_MSR
// This allows data to pass through ALU unclobbered for MSR instructions.
always @(posedge clock_i)
	if (msr)	id_b_o	<= #2 0;
	else		id_b_o	<= #2 if_b_dat;
`else
always @(posedge clock_i)
	id_b_o	<= #2 if_b_dat;
`endif	// !__use_readable_MSR

risc_rf_async #(
	.WIDTH		(WIDTH),
	.DEPTH		(4)
) RF (
	.clock_i	(clock_i),
	
	.p0_idx_i	(if_rs0_i),
	.p0_dat_o	(rf_d0),
	
	.p1_idx_i	(if_rs1_i),
	.p1_dat_o	(rf_d1),
	
	.wr_en_i	(rf_wr_i),
	.wr_idx_i	(rf_reg_i),
	.wr_dat_i	(rf_dat_i)
);

mux4to1 #(WIDTH) MUXA (
	.in0_i	(rf_d0),
	.in1_i	(if_imm_i),
	.in2_i	(ex_bypass_i),
	.in3_i	(mm_bypass_i),
	.sel_i	(if_a_src),
	.out_o	(if_a_dat)
);

mux4to1 #(WIDTH) MUXB (
	.in0_i	(rf_d1),
	.in1_i	(if_imm_i),
	.in2_i	(ex_bypass_i),
	.in3_i	(mm_bypass_i),
	.sel_i	(if_b_src),
	.out_o	(if_b_dat)
);


endmodule	// decode
