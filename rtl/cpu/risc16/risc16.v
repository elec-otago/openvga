/***************************************************************************
 *                                                                         *
 *   risc16.v - Basically just useful for generating marketing numbers.    *
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

// TODO: Build a list of TODOs
// TODO: Trim some latency off memory read/writes.

// Useful RISC Instructions:
//
//	(rr)	add	Rd, Rs
//	(ri)	add	Rd, #imm
//
//	(rr)	xor	Rd, Rs
//	(ri)	or	Rd, #imm
//	(rri)	lea	Rd, #imm(Rs)
//
//	ALU:	add, sub, inc, dec
//		and, or xor, not
//		neg, mul, imul
//	MEM:	lw, lb, sw, sb, push, pop
//	BRA:	jz, jnz, jc, jnc, jr, call, ret
//
// TTA FUs to implement same behaviour:
//	SUB, COM, AND, OR, NOT, XOR, PUSH, POP
//


// EXAMPLE: Optimised for code-size, arguments on the stack, register
// clobbering handled elsewhere.
// memcpy:
//	lw	$r3, #-4($r14)	; `dst*'
//	lw	$r1, #-2($r14)	; `n'
//	lw	$r2, #-3($r14)	; `src*'
//	sub	$r3, $r3, #1	; We are gonna use pre-increment and update in loop
// loop:
//	lw	$r4, ($r2)	; $r4 <= mem[src]
//	sub	$r2, $r2, #-1	; src++
//	sub	$r1, $r1, #1	; Avoid wait-state between LOAD and STORE
//	sw	#1($r3), $r4	; mem[dst++]	<= $r4
//	bnz	loop
//	
//	br	$r15		; ret
//	

// x86:
// memcpy:
//	mov	cx, [bp-4]
//	mov	si, [bp-6]
//	mov	di, [bp-8]
//	rep	movsw
//	ret


// ALU src a can be:
//	rd
//	imm
//	bypass0
//	bypass1
//
// ALU src b can be:
//	rd/rs
//	imm
//	bypass0
//	bypass1
//

// LD, ST:
//	[100/101|SEG|RD|RS|IMM4]
//
// MSR:
//	[000|F|RD|MSR|011|C]	; load msr into rd
//	[001|F|MSR|011|C|IMM4]	; msr	:= imm
//

`include "defines.v"

`timescale 1ns/100ps
module risc16 #(
	parameter	HIGHZ	= 0,
	parameter	WIDTH	= 16,
	parameter	INSTR	= 16,
	parameter	ADDRESS	= 25,
	parameter	PCBITS	= 10,
	parameter	PCINIT	= 1,
	parameter	WBBITS	= WIDTH,
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
	input		cpu_clk_i,
	input		cpu_rst_i,
	
	output		wb_cyc_o,
	output	[1:0]	wb_stb_o,
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


reg	mem_stall_n	= 1;
reg	ilock_inhibit	= 0;
reg	ilock_n	= 1;		// Locks the fetching
reg	byp0_a	= 0;
reg	byp0_b	= 0;
reg	byp1_a	= 0;
reg	byp1_b	= 0;
wire	branching;
wire	[PSB:0]	pc;
wire	[MSB:0]	bypass1;	// TODO
wire	[PSB:0]	pc_prev, pc_next;

wire	if_mem_w, if_haz_w;	// Detect memory/register hazards
wire	if_mem, if_sf, if_cr;
wire	[2:0]	if_op, if_fn, if_cnd;
wire	[3:0]	if_rd, if_rs0, if_rs1, if_rd_w, if_rs0_w, if_rs1_w;
wire	[MSB:0]	if_imm;
wire	if_chk_rs0, if_chk_rs1;
wire	if_haz_poss;

wire	id_cr, id_sf, id_sbb, id_mul, id_bra, id_bx, id_mem, id_msr, id_st;
wire	[MSB:0]	id_a, id_b, id_dat;
wire	[3:0]	id_rd;
wire	[2:0]	id_cnd;
wire	[1:0]	id_dst, id_bit;

wire	ex_nf, ex_cf, ex_zf;			// CPU Flags
wire	ex_cr, ex_sf, ex_mul, ex_mem, ex_msr, ex_st, ex_bra;
wire	[1:0]	ex_dst;
wire	[3:0]	ex_rd;
wire	[MSB:0]	ex_dat, ex_alu;
wire	[WIDTH*2-1:0]	ex_prod;

wire	mm_cr, mm_mem, mm_rdy, mm_dst;
wire	[3:0]	mm_rd;
wire	[MSB:0]	mm_alu, mm_mdat;

wire		up_wr;
wire	[3:0]	up_rd;
wire	[MSB:0]	up_dat_w;


//---------------------------------------------------------------------------
//  CPU Control (CC).
//

reg	en_pc	= 1;
reg	en_if	= 1;
reg	en_id	= 1;
reg	en_ex	= 1;
reg	en_ma	= 1;
reg	en_wr	= 1;
reg	nop_if	= 1;
reg	nop_id	= 1;
reg	nop_ma	= 1;
reg	wb_busy	= 0;

always @(posedge cpu_clk_i)
begin
// 	en_if	<= #2 branching || (!wb_busy && !haz0);
	en_pc	<= #2 (wb_ack_i || !wb_busy) && !if_haz_w;
	en_if	<= #2 (wb_ack_i || !wb_busy) && !if_haz_w;
	en_id	<= #2 !wb_busy && !if_haz_w;
	nop_id	<= #2 if_haz_w;
	nop_ma	<= #2 wb_busy;
	en_ex	<= #2 !wb_busy;
end

always @(posedge cpu_clk_i)
	if (cpu_rst_i || wb_ack_i)	wb_busy	<= #2 0;
	else if (id_mem && en_id)	wb_busy	<= #2 1;


// Since it is hard to stall an entire CPU, just produce NOPs for a while
// after a memory instruction.
always @(posedge cpu_clk_i)
	if (cpu_rst_i)		mem_stall_n	<= #2 1;
// 	else if (id_mem)	mem_stall_n	<= #2 0;
	else if (wb_ack_i)	mem_stall_n	<= #2 1;
	else if (if_mem_w)	mem_stall_n	<= #2 0;

// Don't interlock when stalling is due to memory access.
always @(posedge cpu_clk_i)
	if (cpu_rst_i)
		ilock_inhibit	<= #2 0;
	else if (!mem_stall_n || if_mem_w || branching)
		ilock_inhibit	<= #2 1;
	else
		ilock_inhibit	<= #2 0;

always @(posedge cpu_clk_i)
	if (cpu_rst_i || !ilock_n || ilock_inhibit)
		ilock_n	<= #2 1;
	else
		ilock_n	<= #2 ~if_haz_w;


always @(posedge cpu_clk_i)
/*	if (cpu_rst_i)
		{byp1_b, byp1_a, byp0_b, byp0_a}	<= #2 0;
	else*/
	if (!mem_stall_n)
		{byp1_b, byp1_a, byp0_b, byp0_a}	<= #2 0;
	else if (!ilock_n) begin
		byp0_a	<= #2 byp0_a;
		byp0_b	<= #2 byp0_b;
		
		byp1_a	<= #2 0;
		byp1_b	<= #2 0;
	end else begin
		byp0_a	<= #2 (if_chk_rs0 && if_rs0_w==id_rd && id_cr);
		byp0_b	<= #2 (if_chk_rs1 && if_rs1_w==id_rd && id_cr);
		
		byp1_a	<= #2 (if_chk_rs0 && if_rs0_w==ex_rd && ex_cr);
		byp1_b	<= #2 (if_chk_rs1 && if_rs1_w==ex_rd && ex_cr);
	end


branch #(
	.INIT		(PCINIT),
	.ADDRESS	(PCBITS)
) BRA (
	.clock_i	(cpu_clk_i),
	.reset_i	(cpu_rst_i),
// 	.enable_i	(en_pc),
	.enable_i	(mem_stall_n && ilock_n),
	.pc_prev_o	(pc_prev),
	.pc_next_i	(pc_next),
	.b_rel_i	(id_bx),
	.b_abs_i	(id_bra),
	.flags_i	({ex_nf, ex_cf, ex_zf}),
	.cnd_i		(id_cnd),
	.addr_i		(id_a[PSB:0]),
	.branch_o	(branching),
	.pc_ao		(pc)
);

`ifdef __use_base2_pc
assign	#2 pc_next	= pc_prev + 1;
`else
mfsr10 PC_NEXT (
	.count_i	(pc_prev),
	.count_o	(pc_next)
);
`endif


//---------------------------------------------------------------------------
// Stage I: Instruction Fetch (IF).
//
wire	[2:0]	if_op_w;

fetch #(
	.PCBITS		(PCBITS)
) IF (
	.clock_i	(cpu_clk_i),
	.reset_i	(cpu_rst_i),
	.stall_ni	(mem_stall_n),
	.ilock_ni	(ilock_n),
	.branch_i	(branching),
	
	.pc_i		(pc),
	
	.br_sel_i	(0),
	.br_adr_i	(0),
	.br_dat_i	(0),
	
	.if_mem_ao	(if_mem_w),
	.if_haz_ao	(if_haz_w),
	.if_chk_rs0_ao	(if_chk_rs0),
	.if_chk_rs1_ao	(if_chk_rs1),
	.if_haz_poss_o	(if_haz_poss),
	.if_op_o	(if_op),
	.if_fn_o	(if_fn),
	.if_cnd_o	(if_cnd),
	.if_mem_o	(if_mem),
	.if_sf_o	(if_sf),
	.if_cr_o	(if_cr),
	.if_rd_o	(if_rd),
	.if_rs0_o	(if_rs0),
	.if_rs1_o	(if_rs1),
	.if_rd_ao	(if_rd_w),
	.if_rs0_ao	(if_rs0_w),
	.if_rs1_ao	(if_rs1_w),
	.if_op_ao	(if_op_w),
	.if_imm_o	(if_imm)
);


//---------------------------------------------------------------------------
// Stage II: Instruction Decode (ID).
//	Choose inputs, and mode, for the ALU.
//

// Hardcoded instruction decoder.
decode #(
	.WIDTH		(WIDTH),
	.PCBITS		(PCBITS)
) DECODE (
	.clock_i	(cpu_clk_i),
	.reset_i	(cpu_rst_i),
	.stall_ni	(ilock_n),
	
	.if_op_i	(if_op),
	.if_fn_i	(if_fn),
	.if_cnd_i	(if_cnd),
	.if_mem_i	(if_mem),
	.if_sf_i	(if_sf),
	.if_cr_i	(if_cr),
	.if_rd_i	(if_rd),
	.if_rs0_i	(if_rs0),
	.if_rs1_i	(if_rs1),
	.if_imm_i	(if_imm),
	
	.ex_bypass_i	(ex_alu),	// TODO
	.ex_byp_a_i	(byp0_a),
	.ex_byp_b_i	(byp0_b),
	.mm_bypass_i	(mm_alu),
	.mm_byp_a_i	(byp1_a),
	.mm_byp_b_i	(byp1_b),
	
	.rf_wr_i	(up_wr),
	.rf_reg_i	(up_rd),
	.rf_dat_i	(up_dat_w),
	
	.id_rd_o	(id_rd),
	.id_bit_o	(id_bit),
	.id_cr_o	(id_cr),
	.id_sf_o	(id_sf),
	.id_dst_o	(id_dst),
	.id_sbb_o	(id_sbb),
	.id_mul_o	(id_mul),
	.id_bra_o	(id_bra),
	.id_bx_o	(id_bx),
	.id_mem_o	(id_mem),
	.id_msr_o	(id_msr),
	.id_st_o	(id_st),
	.id_cnd_o	(id_cnd),
	.id_a_o		(id_a),
	.id_b_o		(id_b),
	.id_dat_o	(id_dat)
);


//---------------------------------------------------------------------------
// Stage III: Execute (EX).
//

execute #(
	.WIDTH		(WIDTH),
	.PCBITS		(PCBITS)
) EX (
	.clock_i	(cpu_clk_i),
	.reset_i	(cpu_rst_i),
	.stall_ni	(~branching),
	
	.id_rd_i	(id_rd),
	.id_bit_i	(id_bit),
	.id_cr_i	(id_cr),
	.id_sf_i	(id_sf),
	.id_dst_i	(id_dst),
	.id_sbb_i	(id_sbb),
	.id_mul_i	(id_mul),
	.id_mem_i	(id_mem),
	.id_msr_i	(id_msr),
	.id_bra_i	(id_bra),
	.id_st_i	(id_st),
	.id_a_i		(id_a),
	.id_b_i		(id_b),
	.id_dat_i	(id_bra ? pc_prev : id_dat),
	
	.ex_cr_o	(ex_cr),
	.ex_sf_o	(ex_sf),
	.ex_mul_o	(ex_mul),
	.ex_mem_o	(ex_mem),
	.ex_msr_o	(ex_msr),
	.ex_bra_o	(ex_bra),
	.ex_st_o	(ex_st),
	.ex_dst_o	(ex_dst),
	.ex_rd_o	(ex_rd),
	.ex_dat_o	(ex_dat),
	.ex_zf_o	(ex_zf),
	.ex_cf_o	(ex_cf),
	.ex_nf_o	(ex_nf),
	.ex_prod_o	(ex_prod),
	.ex_alu_o	(ex_alu)
);


//---------------------------------------------------------------------------
// Stage IV: Memory (MM).
//

memory #(
	.HIGHZ		(HIGHZ),
	.WIDTH		(WIDTH),
	.PCBITS		(PCBITS),
	.ADDRESS	(ADDRESS),
	.WBBITS		(WIDTH)
) MU (
	.clock_i	(cpu_clk_i),
	.reset_i	(cpu_rst_i),
	.stall_ni	(1'b1),
	
	.ex_cr_i	(ex_cr),
	.ex_sf_i	(ex_sf),
	.ex_mul_i	(ex_mul),
	.ex_mem_i	(ex_mem),
	.ex_msr_i	(ex_msr),
	.ex_bra_i	(ex_bra),
	.ex_st_i	(ex_st),
	.ex_dst_i	(ex_dst),
	.ex_rd_i	(ex_rd),
	.ex_dat_i	(ex_dat),
	.ex_prod_i	(ex_prod),
	.ex_alu_i	(ex_alu),
	
	.mu_cr_o	(mm_cr),
	.mu_rd_o	(mm_rd),
	.mu_dst_o	(mm_dst),
	.mu_alu_o	(mm_alu),
	.mu_mem_o	(mm_mem),
	.mu_rdy_o	(mm_rdy),
	.mu_dat_o	(mm_mdat),
	
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


//---------------------------------------------------------------------------
// Stage V: Update (UP).
//

assign	up_rd		= mm_rd;
// assign	#3 up_wr	= mm_cr && ((mm_dst && mm_rdy) || !mm_dst);
// TODO: Just keep writing until mem issues `ready'?
assign	#3 up_wr	= mm_cr;
assign	#2 up_dat_w	= mm_dst ? mm_mdat : mm_alu ;


endmodule	// risc16
