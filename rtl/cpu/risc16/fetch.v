/***************************************************************************
 *                                                                         *
 *   fetch.v - Fetch an instruction stored in some Block RAMs.             *
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
module fetch #(
	// TODO: These parameters have to be left at defaults.
	parameter	WIDTH	= 16,
	parameter	PCBITS	= 10,
	parameter	MSB	= WIDTH - 1,
	parameter	PSB	= PCBITS - 1
) (
	input		clock_i,
	input		reset_i,
	input		stall_ni,
	input		ilock_ni,
	input		branch_i,	// Currently only used for debugging
	
	input	[PSB:0]	pc_i,
	
	input	[1:0]	br_sel_i,
	input	[PSB:0]	br_adr_i,
	input	[MSB:0]	br_dat_i,
	
	output		if_mem_ao,	// Bring pipe to screaming halt!
	output		if_haz_ao,	// Register clash!
	output		if_haz_poss_o,
	output		if_chk_rs0_ao,
	output		if_chk_rs1_ao,
	output	reg	if_mem_o	= 0,
	output	[2:0]	if_op_o,
	output		if_sf_o,
	output	[2:0]	if_fn_o,
	output		if_cr_o,
	output	[2:0]	if_cnd_o,
	output	[3:0]	if_rd_o,
	output	[3:0]	if_rs0_o,
	output	[3:0]	if_rs1_o,
	output	[3:0]	if_rd_ao,
	output	[3:0]	if_rs0_ao,
	output	[3:0]	if_rs1_ao,
	output	[2:0]	if_op_ao,
	output	[MSB:0]	if_imm_o,
	output	reg	[PSB:0]	if_pc_o
);

always @(posedge clock_i)
// 	if (ilock_ni)	if_mem_o	<= #2 if_mem_ao;
	if (!stall_ni)		if_mem_o	<= #2 0;
	else if (ilock_ni)	if_mem_o	<= #2 if_mem_ao;


// Allow following of instructions for debugging.
always @(posedge clock_i)
	if (ilock_ni && stall_ni)	if_pc_o	<= #2 pc_i;


`ifndef __use_bram
reg	[MSB:0]	instr_w;
reg	[MSB:0]	bram[(1<<PCBITS)-1:0];

always @(posedge clock_i)
	if (reset_i)			instr_w	<= #2 0;
	else if (stall_ni && ilock_ni)	instr_w	<= #2 bram[pc_i];
	else				instr_w	<= #2 instr_w;


integer	ii;
initial begin : Init
	for (ii=0; ii<(1<<PCBITS); ii=ii+1)
		bram[ii]	= 0;	// nop
	// No neat way to load immediates into a reg.
/*	bram[2]	= {`RR, `NF, `R3, `R3, `XOR, `CR};
	bram[5]	= {`I12, `NF, 12'h567};
	bram[6]	= {`RI, `NF, `R3, `SUB, `CR, 4'h8};	// sub	#0x5678, $r3
	bram[10]= {`RI, `SF, `R3, `MSR, `NC, 4'h1};	// msr	$m1, $r3	; Set SS
*/	
	bram[2]	= {`SUBI, `SF, `R5, `R4, 4'hf};		// sub	$r5, $r4, #-1
	bram[3]	= {`I12, `NF, 12'hfff};
	bram[4]	= {`LW, `NF, `R4, `R5, 4'hf};		// lw	r4, [r5-#-1]
 	bram[5]	= {`RR, `SF, `R7, `R4, `OR, `CR};	// or	$r7, $r4
	bram[6]	= {`SW, `SF, `R7, `R4, 4'hf};		// sw	[$r4-#-1], $r7
	
/*	bram[2]	= {`SUBI, `NF, `R4, `R4, 4'h0};		// subi	$r4, $r4, #0
	bram[3]	= {`RI, `SF, `R3, `MSR, `CR, 4'h1};	// msr	$r3, $r3
	bram[4]	= {`RI, `NF, `RF, `BR, `CR, 4'h0};	// brl	pc->r15, r0->pc*/
	
end	// Init
`endif	// __use_bram


`ifdef __icarus
// Dissasembler.
integer	op, fn, rd, rs, sf, cr, imm;
always @(posedge clock_i)
	if (reset_i || !ilock_ni || !stall_ni || branch_i)
		$display("%5t:\t(%3x:%4x)\tnop (stall)", $time, if_pc_o, instr_w);
	else begin
		$write("%5t:\t(%3x:%4x)\t", $time, if_pc_o, instr_w);
		case (instr_w[15:13])
		`RR: begin
			fn	= instr_w[3:1];
			rd	= instr_w[11:8];
			rs	= instr_w[7:4];
			sf	= instr_w[12];
			cr	= instr_w[0];
			
			case (fn)	// Fn
			`SUB:	if (cr)
					$write("sub");
				else if (sf)
					$write("cmp");
				else
					$write("nop");
			`SBB:	$write("sbb");
			`MUL:	if (sf)
					$write("mlh");
				else
					$write("mll");
			`MSR:	$write("msr");
			`AND:	if (cr)
					$write("and");
				else
					$write("tst");
			`BR:	if (cr)
					$write("brl");
				else
					$write("br");
			`OR:	$write("or");
			`XOR:	$write("xor");
			endcase
			
			case (fn)	// Suffix
			`SBB, `AND, `OR, `XOR, `MSR: begin
				if (!sf)
					$write(".nf");
				if (!cr)
					$write(".nc");
				if (!sf && !cr)
					$write("\t");
			end
			`SUB:
				if (!sf && cr)
					$write(".nf");
				else
					$write("\t");
			default:
				$write("\t");
			endcase
			
			$write("\t");
			
			case (fn)
			`SUB:	if (!cr && !sf)
					$display;	// nop
				else
					$display("\t$r%1d, $r%1d", rd, rs);
			`SBB, `MUL, `AND, `OR, `XOR:
				$display("\t$r%1d, $r%1d", rd, rs);
			`BR:	if (cr)	// Write LR?
					$display("\t$r%1d, $r%1d", rd, rs);
				else
					$display("$r%1d", rd);
			endcase
			
		end	// RR
		
		`RI: begin
			fn	= instr_w[7:5];
			rd	= instr_w[11:8];
			rs	= rd;
			sf	= instr_w[12];
			cr	= instr_w[4];	// TODO
			imm	= instr_w[3:0];
			
			case (fn)	// Fn
			`SUB:	$write("sub");
			`SBB:	$write("sbb");
			`MUL:	if (sf)	$write("mlh");
				else	$write("mll");
			`MSR:	$write("msr");
			`AND:	$write("and");
			`BR:	$write("brl");
			`OR:	$write("or");
			`XOR:	$write("xor");
			endcase
			
			case (fn)	// Suffix
			`SUB, `SBB, `AND, `OR, `XOR, `MSR:
				if (!sf)	$write(".nf\t");
				else		$write("\t");
			default:
				$write("\t");
			endcase
			
			case (fn)	// Reg + Imm
			`MSR:
				$display("\t$m%1x, $r%1d", imm[3:0], rd);
			`BR:
				$display("\t$r%1d, #%1x", rd, imm[3:0]);
			default:
				$display("\t$r%1d, #%1x, $r%1d", rd, imm[3:0], rd);
			endcase
		end	// RR
		
		`SUBI: begin
			rd	= instr_w[11:8];
			rs	= instr_w[7:4];
			sf	= instr_w[12];
			cr	= 1;	// TODO
			imm	= instr_w[3:0];
			$write("sub");
			if (!sf)	$write(".nf");
			$display("\t\t$r%1d, $r%1d, #0x%x", rd, rs, imm[3:0]);
		end
		
		`I12: begin
			$display("i12\t\t#0x%x", instr_w[11:0]);
		end
		
		`LW, `SW: begin
			rd	= instr_w[11:8];
			rs	= instr_w[7:4];
			sf	= instr_w[12];
			cr	= 1;	// TODO
			imm	= instr_w[3:0];
			case (instr_w[15:13])
			`LW:	$write("lw");
			`SW:	$write("sw");
			endcase
			if (sf)	$write(".sf");
			$display("\t\t$r%1d, [$r%1d-#0x%1x]", rd, rs, imm[3:0]);
		end
		
		`BX: begin
			case (instr_w[12:10])
			`JNE:	$write("jne");
			`JE:	$write("je");
			`JL:	$write("jl");
			`JG:	$write("jg");
			`JB:	$write("jb");
			`JBE:	$write("jbe");
			`JA:	$write("ja");
			`JAE:	$write("jae");
			endcase
			$display("\t\t#0x%3x", instr_w[9:0]);
		end
		
		default:
			$display("nop");
		
		endcase
	end
`endif	// __icarus


`ifdef __use_bram
wire	[MSB:0]	instr_w;

RAMB16_S18_S18 #(
`include "risc_asm.v"
) RAM1 (
	.CLKA	(clock_i),
	.ENA	(stall_ni && ilock_ni),
	.SSRA	(reset_i),
	.WEA	(1'b0),
	.ADDRA	(pc_i),
	.DOA	(instr_w),
	.DIA	(8'hff),
	.DIPA	(1'b1),
	
	.CLKB	(clock_i),
	.ENB	(1'b1),
	.SSRB	(1'b0),
	.WEB	(|br_sel_i),
	.ADDRB	(br_adr_i),
	.DIB	(br_dat_i),
	.DIPB	(1'b1)
);
/*
RAMB16_S18_S18 RAM1 (
	.CLKB	(clock_i),
	.ENB	(stall_ni),
	.SSRB	(reset_i),
	.WEB	(1'b0),
	.ADDRB	(pc_i),
	.DOB	(instr_w[15:8]),
	.DIB	(8'hff),
	.DIPB	(1'b1),
	
	.CLKA	(clock_i),
	.ENA	(1'b1),
	.SSRA	(1'b1),
	.WEA	(br_sel_i[1]),
	.ADDRA	(br_adr_i),
	.DIA	(br_dat_i[15:8]),
	.DIPA	(1'b1)
);
*/
`endif

decode1 #(
	.WIDTH	(WIDTH),
	.PCBITS	(PCBITS)
) DECODE (
	.clock_i(clock_i),
	.reset_i(reset_i),
	.stall_ni(stall_ni),
	.ilock_ni(ilock_ni),
	.instr_i(instr_w),
	
	.mem_ao	(if_mem_ao),
	.haz_ao	(if_haz_ao),
	.haz_poss_o	(if_haz_poss_o),
	.chk_rs0_ao	(if_chk_rs0_ao),
	.chk_rs1_ao	(if_chk_rs1_ao),
	.op_o	({if_op_o, if_sf_o}),
	.fn_o	(if_fn_o),
	.cr_o	(if_cr_o),
	.cnd_o	(if_cnd_o),
	.rd_o	(if_rd_o),
	.rs0_o	(if_rs0_o),
	.rs1_o	(if_rs1_o),
	.rd_ao	(if_rd_ao),
	.rs0_ao	(if_rs0_ao),
	.rs1_ao	(if_rs1_ao),
	.op_ao	(if_op_ao),
	.imm_o	(if_imm_o)
);

endmodule	// fetch


// Some of the decoding is built into the fetch stage.
module decode1 #(
	parameter	WIDTH	= 16,
	parameter	PCBITS	= 10,
	parameter	MSB	= WIDTH - 1,
	parameter	PSB	= PCBITS - 1
) (
	input		clock_i,
	input		reset_i,
	input		stall_ni,
	input		ilock_ni,
	input	[15:0]	instr_i,
	
	output			mem_ao,
	output	reg		chk_rs0_ao,	// Async really
	output	reg		chk_rs1_ao,
	output	reg		haz_poss_o	= 0,
	output			haz_ao,		// Register hazard
	output	reg	[2:0]	fn_o	= 0,
	output	reg		cr_o	= 0,
	output	reg	[3:0]	op_o	= 0,
	output	reg	[2:0]	cnd_o	= 0,
	output	reg	[MSB:0]	imm_o	= 0,
	output	reg	[3:0]	rd_o	= 0,
	output	reg	[3:0]	rs0_o	= 0,
	output	reg	[3:0]	rs1_o	= 0,
	output	[3:0]	rd_ao,
	output	[3:0]	rs0_ao,
	output	[3:0]	rs1_ao,
	output	[2:0]	op_ao
);

reg	use_i12	= 0;
reg	[MSB-4:0]	i12;

wire	[2:0]	op	= instr_i[15:13];
wire	[3:0]	rs	= instr_i[7:4];
wire	[3:0]	rd	= instr_i[11:8];
wire	[2:0]	fn;
wire		cr;
wire	[MSB-4:0]	signs	= {(WIDTH-4){instr_i[3]}};
wire	[3:0]	rs0_w, rs1_w;


assign	#2 fn	= (op==`RI) ? instr_i[7:5] : instr_i[3:1];
assign	#2 mem_ao	= (op==`LW || op==`SW);
assign	#2 haz_ao	= haz_poss_o &&
			 ((rd==rd_o && (op==`RR || op==`RI)) ||
			  (rs==rd_o && (op==`RR || op==`SUBI || op==`LW || op==`SW)));

assign	#2 cr	=  (op==`RR) ? instr_i[0] :
		   (op==`RI) ? instr_i[4] :
		  !(op==`I12 || op==`BX || op==`I12 || op==`SW || op==`_free0_);

// TODO: Optimise this for max clock-rate.
assign	#2 rs0_w	= (op==`RR) ? rd : rs ;
assign	#2 rs1_w	= (op==`RR) ? rs : rd ;
assign	rd_ao		= rd;
assign	rs0_ao		= rs0_w;
assign	rs1_ao		= rs1_w;
assign	op_ao		= op;


always @(posedge clock_i)
	if (reset_i)		op_o	<= #2 0;
	else if (ilock_ni)	op_o	<= #2 {op, (op==`BX || op==`I12) ? 1'b0 : instr_i[12]};

always @(posedge clock_i)
	if (reset_i)		fn_o	<= #2 0;
	else if (ilock_ni)	fn_o	<= #2 fn;

always @(posedge clock_i)
	if (reset_i)		cr_o	<= #2 0;
	else if (ilock_ni)	cr_o	<= #2 cr;

always @(posedge clock_i)	// TODO: Check that this doesn't interlock!
	cnd_o	<= #2 instr_i[12:10];

always @(posedge clock_i)
	if (op==`BX)
		imm_o	<= #2 {{(MSB-PSB){1'b0}}, instr_i[9:0]};
	else if (ilock_ni)
		imm_o	<= #2 {use_i12 ? i12 : signs, instr_i[3:0]};

// Registers
always @(posedge clock_i)
	if (ilock_ni)		{rd_o, rs0_o, rs1_o}	<= #2 {rd, rs0_w, rs1_w};

// Long immediate support.
always @(posedge clock_i)	// TODO: Check that this doesn't interlock!
	if (op==`I12)	use_i12	<= #2 1;
	else		use_i12	<= #2 0;

always @(posedge clock_i)	// TODO: Check that this doesn't interlock!
	if (op==`I12)	i12	<= #2 instr_i[11:0];


// Dependency checking.
// Can the previous instruction cause a hazard?
// NOTE: lw + sw are left out becuase of the memory stall mechanism.
always @(posedge clock_i)
	if (ilock_ni) case (op_o[3:1])
	`RI, `RR, `SUBI:	// These ops can have write-backs
		if (cr)	haz_poss_o	<= #2 1;
		else	haz_poss_o	<= #2 0;
	default:
		haz_poss_o	<= #2 0;
	endcase

// TODO: Make sure combinational, not latch.
always @*
	case (op)
	`RI:	{chk_rs0_ao, chk_rs1_ao}	<= #2 {2'b01};	// RI
	`RR:	{chk_rs0_ao, chk_rs1_ao}	<= #2 {2'b11};	// RR
	`SUBI:	{chk_rs0_ao, chk_rs1_ao}	<= #2 {2'b10};	// RRI
	`LW:	{chk_rs0_ao, chk_rs1_ao}	<= #2 {2'b10};
	`SW:	{chk_rs0_ao, chk_rs1_ao}	<= #2 {2'b10};
	`MSR:	{chk_rs0_ao, chk_rs1_ao}	<= #2 {2'b10};
	`BX:	{chk_rs0_ao, chk_rs1_ao}	<= #2 {2'b00};	// IMM
	`I12:	{chk_rs0_ao, chk_rs1_ao}	<= #2 {2'b00};
	default:{chk_rs0_ao, chk_rs1_ao}	<= #2 {2'b00};
	endcase


endmodule	// decode1
