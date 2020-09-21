/***************************************************************************
 *                                                                         *
 *   tta16.v - A blazingly fast, ridiculously simple, impossible to        *
 *     program, 16-bit processor.                                          *
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


// TODO: Feature complete? Not fully tested?
// TODO: The incorrect link value is stored. Needs more logic?

//---------------------------------------------------------------------------
// Optional TTA16 Features:
//
// Choose between one or two pipeline stages
// `define __use_two_multiply_stages
//
// Use internal tri-states or multiplexers for connecting the outputs of the
// functional units to the transport buses? With the Xilinx Spartan III
// architecture, multiplexers are far smaller and faster.
`define __use_muxes_for_streams
//
// Whether the outputs of the BRAMs used for the instructions point inwards
// or outwards effects the speed of the processor, depending where the TTA16
// is placed within the FPGA.
// I hoped XST would figure out the nicest way to arrange the ports.  :(
`define __BRAMs_point_outwards
//
// Transfer the contents of the RF, upon read, straight onto the transports,
// meaning lower latency for write-to-read turnaround, or register first?
// `define __use_low_latency_RF
//
// Asynchronous transports make the TTA easier to program, and reduces pipe-
// line length by one stage, but significantly reduces the maximum clock
// rate.
// `define __use_async_transports
//
// Use an LFSR or a Base-2 incrementer for the PC?
`define __use_LFSR_for_synth
//
// The instruction BRAMs contain 1024 instructions. By dividing this into two
// pages, one page can be swapped while code is running from instructions
// stored in the other page. Required if more total instruction memory than
// 2kB is needed.
// TODO: Requires changes in the `tta16.xml' file to represent the different
// PC increment order.
// `define	__use_two_instruction_pages
//
// TODO: This isn't really ready to go live unless no reads a performed, and
// writes relatively scarce and well-spaced.
// Control logic is bloat! In a perfect, crime-free world there would be no
// CPU interlocks. Disabling control logic saves about 16 SLICEs. So that
// memory operations behave as expected would then require sampling flags, or
// a modified program counter.
// `define	__use_no_control_logic
//
// The long-immediate value has to share a register index bif-field. Use the
// R/W bit-field (default) or the RO bot-field as the overlapped field? 
`define __swap_reg_fields
//
// Use Xilinx BRAMs or try a more general approach?
`define __use_BRAMs
//
// For simulation, the instructions being executed (and register values) can
// be displayed.
`define __use_disassembler
//
//---------------------------------------------------------------------------


`define	NOP	0

// Instruction Formats:
// MSB						LSB
// [SA|DA, SB|DB, |SC|DC, COM, BANK, REG0, REG1, IMM8]
// [SA|DA, SB|DB, |SC|DC, COM, BANK, REG0, IMM11]
//

// Stream A (Memory and branching)
`define	SA_COM	2'b00
`define	SA_IMM	2'b01
`define	SA_REG	2'b10
`define	SA_MEM	2'b11
`define	DA_NOP	3'b000
`define	DA_BRA	3'b001
`define	DA_RAD	3'b010
`define	DA_WAD	3'b011
`define	DA_JB	3'b100
`define	DA_JNB	3'b101
`define	DA_JZ	3'b110
`define	DA_JNZ	3'b111

// Stream B (ALU functions)
`define	SB_COM	2'b00
`define	SB_IMM	2'b01
`define	SB_REG	2'b10
`define	SB_MEM	2'b11
`define	DB_NOP	3'b000
`define	DB_SUB	3'b001
`define	DB_SBB	3'b010
`define	DB_CMP	3'b011
`define	DB_NAND	3'b100
`define	DB_AND	3'b101
`define	DB_OR	3'b110
`define	DB_XOR	3'b111

// Stream C (Register setting)
// TODO: NOP?
`define	SC_COM	2'b00
`define	SC_DIFF	2'b01
`define	SC_REG	2'b10
`define	SC_PC	2'b11
`define	DC_NOP	2'b00
`define	DC_MEM	2'b00
`define	DC_REG	2'b01
`define	DC_MUL	2'b10
`define	DC_MSR	2'b11

// Common stream
`define	C_NOP	3'b000
`define	C_COM	3'b000
`define	C_IMM	3'b001
`define	C_REG	3'b010
`define	C_MEM	3'b011
`define	C_DIFF	3'b100
`define	C_BITS	3'b101
`define	C_PLO	3'b110
`define	C_PHI	3'b111


`timescale 1ns/100ps
module tta16 #(
`ifndef __use_LFSR_for_synth
	// Base 2 PC
	parameter	PCINIT	= 0,
`else
	// LFSR for PC
	parameter	PCINIT	= 1,
`endif
	parameter	HIGHZ	= 0,
	parameter	WIDTH	= 16,
	parameter	INSTR	= 36,
	parameter	ADDRESS	= 23,
	parameter	PCBITS	= 10,
// 	parameter	STROBES	= 3,		// Some initial address decoding
	parameter	WBBITS	= WIDTH,	// TODO
	parameter	ENABLES	= WBBITS / 8,
	parameter	SEGBITS	= ADDRESS - WIDTH,	// Allow >16-bit addressing
// 	parameter	STB	= (1<<STROBES)-1,
	parameter	PSB	= PCBITS - 1,
	parameter	MSB	= WIDTH - 1,
	parameter	ISB	= INSTR - 1,
	parameter	ESB	= ENABLES - 1,
	parameter	ASB	= ADDRESS - 1,
	parameter	WSB	= WBBITS - 1,
	parameter	SSB	= SEGBITS - 1
) (
	input		cpu_clk_i,
	input		cpu_rst_i,
	
	output	reg		wb_cyc_o	= 0,
 	output	reg	[1:0]	wb_stb_o	= 0,
// 	output			wb_stb_o,
	output	reg		wb_we_o		= 0,
	input			wb_ack_i,
	input			wb_rty_i,
	input			wb_err_i,
	output		[2:0]	wb_cti_o,
	output		[1:0]	wb_bte_o,
// 	output	reg	[ASB:0]	wb_adr_o,
	output		[ASB:0]	wb_adr_o,
	output		[ESB:0]	wb_sel_o,
	output		[WSB:0]	wb_dat_o,
// 	output	reg	[WSB:0]	wb_dat_o,
	input		[ESB:0]	wb_sel_i,
	input		[WSB:0]	wb_dat_i
);	// tta16


// Stall upon memory access, resume upon `wb_ack_i'.
reg	mem_stl_n	= 1;
wire	mem_op;
wire	bra_inhibit;

wire	bram0_wr, bram1_wr;
`ifndef __use_BRAMs
reg	[ISB:0]	bram[(1<<PCBITS)-1:0];
reg	[ISB:0]	instr	= `NOP;
`else
wire	[ISB:0]	instr;
`endif	// __use_BRAMs

reg	[PSB:0]	iadr	= 0;	// Used to modify instructions

reg	[MSB:0]	rf[15:0];	// Register file
reg	[MSB:0]	t_reg0, t_reg1;
reg	[PSB:0]	pc_prev	= PCINIT;
wire	[PSB:0]	pc, pc_next;
wire	[MSB-PCBITS:0]	pc_pad	= 0;


// TODO: Very low-tech Wishbone bus interface at the moment.
// assign	wb_stb_o	= wb_cyc_o;
assign	wb_cti_o	= 0;
assign	wb_bte_o	= 0;
assign	wb_sel_o	= {ENABLES{1'b1}};


// Initialise all instructions to NOPs, and REGs to 0, for simulation.
`ifndef __use_BRAMs
integer	ii;
initial	for (ii=0; ii<16; ii=ii+1)		rf[ii]	= 0;
initial	for (ii=0; ii<(1<<PCBITS); ii=ii+1)	bram[ii]= 0;
`endif


// Fetch pipeline stage signals.
wire	[1:0]	f_src_a, f_src_b, f_src_c, f_dst_c;
wire	[2:0]	f_dst_a, f_dst_b, f_com;
wire	[3:0]	f_reg0, f_reg1;
wire	[MSB:0]	f_immed, f_limm;

// Transport pipeline stage signals.
wire	[MSB:0]	t_data_a, t_data_b, t_data_c, t_com;
wire	[7:0]	t_sels_a, t_sels_b;
wire	[2:0]	t_pack_a, t_pack_b;
wire	[3:0]	t_sels_c;
wire	[1:0]	t_pack_c;

// Execute pipeline stage signals.
reg	x_zf	= 1;
reg	x_bf	= 0;
reg	[MSB:0]	x_diff, x_plo, x_phi, x_bits_n, x_mem;


//---------------------------------------------------------------------------
//  CPU Control (CC).
//

`ifndef __use_no_control_logic
// TODO: Does this need to detect an existing stall?
assign	#2 mem_op	= (f_dst_a == `DA_RAD || f_dst_a == `DA_WAD);

// `define __use_expr_control_logic
`ifdef __use_expr_control_logic
reg	f_stall_n	= 1;
reg	t_stall_n	= 1;
reg	x_stall_n	= 1;

always @(posedge cpu_clk_i)
	if (cpu_rst_i)		f_stall_n	<= #2 1;
	else if (wb_ack_i)	f_stall_n	<= #2 1;
	else if (mem_op)	f_stall_n	<= #2 0;

always @(posedge cpu_clk_i)
	{x_stall_n, t_stall_n}	<= #2 {t_stall_n, f_stall_n};

`else
reg	mem_op_r	= 0;
always @(posedge cpu_clk_i)
	mem_op_r	<= #2 mem_op;

wire	f_stall_n	= mem_stl_n;
wire	t_stall_n	= mem_stl_n;
wire	x_stall_n	= mem_stl_n;

always @(posedge cpu_clk_i)
	if (cpu_rst_i)		mem_stl_n	<= #2 1;
	else if (wb_ack_i)	mem_stl_n	<= #2 1;
	else if (mem_op)	mem_stl_n	<= #2 0;
// 	else if (mem_op_r)	mem_stl_n	<= #2 0;
`endif
`endif


//---------------------------------------------------------------------------
//  Stage I: Fetch (F).
//

`ifdef __use_BRAMs
wire	[ISB:0]	instr_w;

`ifdef	__BRAMs_point_outwards
RAMB16_S18_S18 #(
`include "tta_asm0.v"
) RAM0 (
	.CLKB	(cpu_clk_i),
	.ENB	(f_stall_n),
	.SSRB	(cpu_rst_i),
	.WEB	(1'b0),
	.ADDRB	(pc),
	.DOB	(instr[15:0]),
	.DIB	(16'hffff),
	.DIPB	(2'b11),
	
	.CLKA	(cpu_clk_i),
	.ENA	(1'b1),
	.SSRA	(1'b0),
	.WEA	(bram0_wr),
	.ADDRA	(iadr),
	.DIA	(t_com),
	.DIPA	(2'b11)
);
`else
RAMB16_S18_S18 #(
`include "tta_asm0.v"
) RAM0 (
	.CLKA	(cpu_clk_i),
	.ENA	(f_stall_n),
	.SSRA	(cpu_rst_i),
	.WEA	(1'b0),
	.ADDRA	(pc),
	.DOA	(instr[15:0]),
	.DIA	(16'hffff),
	.DIPA	(2'b11),
	
	.CLKB	(cpu_clk_i),
	.ENB	(1'b1),
	.SSRB	(1'b0),
	.WEB	(bram0_wr),
	.ADDRB	(iadr),
	.DIB	(t_com),	// TODO: Byte selects
	.DIPB	(2'b11)
);

RAMB16_S18_S18 #(
`include "tta_asm1.v"
) RAM1 (
	.CLKB	(cpu_clk_i),
	.ENB	(f_stall_n),
	.SSRB	(cpu_rst_i),
	.WEB	(1'b0),
	.ADDRB	(pc),
	.DOB	(instr[31:16]),
	.DIB	(16'hffff),
	.DIPB	(2'b11),
	
	.CLKA	(cpu_clk_i),
	.ENA	(1'b1),
	.SSRA	(1'b0),
	.WEA	(bram1_wr),
	.ADDRA	(iadr),
	.DIA	(t_com),	// TODO: Byte selects
	.DIPA	(2'b11)
);

`endif	// !__BRAMs_point_outwards
`ifdef	__BRAMs_point_outwards
RAMB16_S18_S18 #(
`include "tta_asm1.v"
) RAM1 (
	.CLKA	(cpu_clk_i),
	.ENA	(f_stall_n),
	.SSRA	(cpu_rst_i),
	.WEA	(1'b0),
	.ADDRA	(pc),
	.DOA	(instr[31:16]),
	.DIA	(16'hffff),
	.DIPA	(1'b1),
	
	.CLKB	(cpu_clk_i),
	.ENB	(1'b1),
	.SSRB	(1'b0),
	.WEB	(bram1_wr),
	.ADDRB	(iadr),
	.DIB	(t_com),
	.DIPB	(2'b11)
);
`endif	// __BRAMs_point_outwards

`else	// __use_BRAMs

always @(posedge cpu_clk_i)
	if (cpu_rst_i)
		instr	<= #2 0;
	else begin
		if (f_stall_n)
			instr	<= #2 bram[pc];
		
		if (bram0_wr)
			bram[iadr]	<= #2 {bram[iadr][31:16], t_data_c};
		if (bram1_wr)
			bram[iadr]	<= #2 {t_data_c, bram[iadr][15:0]};
	end
`endif	// !__use_BRAMs


// Instruction Decode.
// There is only one instruction format so there is no real decoding to be
// done.
assign	f_src_a	= instr[31:30];				// MOVE0
assign	f_dst_a	= instr[29:27];
assign	f_src_b	= instr[26:25];				// MOVE1
assign	f_dst_b	= instr[24:22];
assign	f_src_c	= instr[21:20];				// MOVE2
assign	f_dst_c	= instr[19:18];
assign	f_com	= instr[17:15];				// MOVE3
`ifdef __swap_reg_fields
assign	f_reg1	= instr[14:11];				// Reg0 & reg1 share
assign	f_reg0	= {instr[14], instr[10:8]};		// the MSB
`else
assign	f_reg0	= instr[14:11];				// Reg0 & reg1 share
assign	f_reg1	= {instr[14], instr[10:8]};		// the MSB
`endif
assign	f_immed	= {{(WIDTH-7){instr[7]}}, instr[6:0]};	// Sign extended immediate
assign	f_limm	= {{(WIDTH-10){instr[10]}}, instr[9:0]};// Longer immed for stream0


//---------------------------------------------------------------------------
//  Stage II: Transport (T).
//	Due to PC trickiness, these two stages act like one.
//

`ifdef __use_async_transports
tta_stream4to8_async #(
`else
`ifdef __use_muxes_for_streams
tta_stream4to8_sync #(
`else
tta_stream4to8_highz_sync #(
`endif	// __use_muxes_for_streams
`endif	// __use_async_transports
	.WIDTH		(WIDTH),
	.ENCLR		(1)
) DPA (
`ifndef __use_async_transports
	.clock_i	(cpu_clk_i),
`endif	// __use_async_transports
	.enable_i	(t_stall_n),
	.src_i		(f_src_a),
	.dst_i		(f_dst_a),
	.data0_i	(t_com),
	.data1_i	(f_limm),
	.data2_i	(t_reg0),	// Adds 1-cycle of latency
	.data3_i	(x_mem),
	.data_o		(t_data_a),
	.dstsels_o	(t_sels_a),
	.dstpack_o	(t_pack_a)
);

`ifdef __use_async_transports
tta_stream4to8_async #(
`else
`ifdef __use_muxes_for_streams
tta_stream4to8_sync #(
`else
tta_stream4to8_highz_sync #(
`endif	// __use_muxes_for_streams
`endif	// __use_async_transports
	.WIDTH		(WIDTH),
	.ENCLR		(0)
) DPB (
`ifndef __use_async_transports
	.clock_i	(cpu_clk_i),
`endif	// __use_async_transports
	.enable_i	(t_stall_n),
	.src_i		(f_src_b),
	.dst_i		(f_dst_b),
	.data0_i	(t_com),
	.data1_i	(f_immed),
	.data2_i	(t_reg0),	// Adds 1-cycle of latency
	.data3_i	(x_mem),
	.data_o		(t_data_b),
	.dstsels_o	(t_sels_b),
	.dstpack_o	(t_pack_b)
);

`ifdef __use_async_transports
tta_stream4to4_async #(
`else
`ifdef __use_muxes_for_streams
tta_stream4to4_sync #(
`else
tta_stream4to4_highz_sync #(
`endif	// __use_muxes_for_streams
`endif	// __use_async_transports
	.WIDTH		(WIDTH),
	.ENCLR		(0)
) DPC (
`ifndef __use_async_transports
	.clock_i	(cpu_clk_i),
`endif	// __use_async_transports
	.enable_i	(t_stall_n),
	.src_i		(f_src_c),
	.dst_i		(f_dst_c),
	.data0_i	(t_com),
	.data1_i	(x_diff),
	.data2_i	(t_reg1),
	.data3_i	({pc_pad, pc_next}),
	.data_o		(t_data_c),
	.dstsels_o	(t_sels_c),
	.dstpack_o	(t_pack_c)
);

`ifdef __use_async_transports
tta_stream8to8_async #(
`else
`ifdef __use_muxes_for_streams
tta_stream8to8_sync #(
`else
tta_stream8to8_highz_sync #(
`endif	// __use_muxes_for_streams
`endif	// __use_async_transports
	.WIDTH		(WIDTH),
	.ENCLR		(1)
) COM (
`ifndef __use_async_transports
	.clock_i	(cpu_clk_i),
`endif	// __use_async_transports
	.enable_i	(t_stall_n),
	
	.src_i		(f_com),
	.dst_i		(0),
	
	.data0_i	(t_com),
	.data1_i	(f_immed),
	.data2_i	(t_reg1),
	.data3_i	(x_mem),
	.data4_i	(x_diff),
	.data5_i	(~x_bits_n),
	.data6_i	(x_plo),
	.data7_i	(x_phi),
	
	.srcsels_o	(),
	.dstsels_o	(),
	.data_o		(t_com)
);


//---------------------------------------------------------------------------
//  Stage II: Execute (EX).
//  These are the TTA's FUs (Functional Units).
//

wire	jmp;
reg	t_bra	= 0;
reg	t_bi0	= 0, t_bi1	= 0;

// TODO: This is probably quite slow. Does it need to be optimised?
assign	#3 jmp = (f_dst_a == `DA_BRA)          ||
		 (f_dst_a == `DA_JNB && !x_bf) ||
		 (f_dst_a == `DA_JB && x_bf)   ||
		 (f_dst_a == `DA_JNZ && !x_zf) ||
		 (f_dst_a == `DA_JZ && x_zf);

assign	#2 pc	= t_bra ? t_data_a[PSB:0] : pc_next;
assign	#2 bra_inhibit	= t_bra;

always @(posedge cpu_clk_i)
	if (cpu_rst_i)
		t_bra	<= #2 0;
	else if (!t_stall_n)
		t_bra	<= #2 t_bra;
	else if (bra_inhibit)
		t_bra	<= #2 0;
	else
		t_bra	<= #2 jmp;

always @(posedge cpu_clk_i)
	if (cpu_rst_i)		pc_prev	<= #2 PCINIT;
	else if (!t_stall_n)	pc_prev	<= #2 pc_prev;
	else			pc_prev	<= #2 pc;

// Choose base-2 or LFSR for PC.
`ifdef	__use_LFSR_for_synth
`ifdef	__use_two_instruction_pages
assign	pc_next[9]	= pc_prev[9];
mfsr9 PC_NEXT (
	.count_i	(pc_prev[8:0]),
	.count_o	(pc_next[8:0])
);
`else	// __use_two_instruction_pages
mfsr10 PC_NEXT (
	.count_i	(pc_prev),
	.count_o	(pc_next)
);
`endif	// __use_two_instruction_pages
`else
assign	#2 pc_next	= pc_prev + 1;
`endif


// Register File.
wire	#2 rf_wr	= (x_stall_n && t_sels_c[`DC_REG]);

`ifdef __use_low_latency_RF
always @(f_reg0, f_reg1) begin
	t_reg0	<= #2 rf[f_reg0];
	t_reg1	<= #2 rf[f_reg1];
end
`else
always @(posedge cpu_clk_i)
	if (t_stall_n) begin
		t_reg0	<= #2 rf[f_reg0];
		t_reg1	<= #2 rf[f_reg1];
	end
`endif	// !__use_low_latency_RF

always @(posedge cpu_clk_i)
	if (rf_wr)	rf[f_reg1]	<= #2 t_data_c;


// Subtract.
wire	[WIDTH:0]	sub	= {t_data_b, 1'b0};
wire	[WIDTH:0]	min	= {t_com, t_sels_b[`DB_SBB] & x_bf};	// Use borrow?
reg	unused;
wire	#2 sub_t	= x_stall_n && (t_sels_b[`DB_SUB] || t_sels_b[`DB_SBB]);
always @(posedge cpu_clk_i)
	if (sub_t)	{x_bf, x_diff, unused}	<= #2 min - sub;


// Multiply.
wire	#2 mult_t	= x_stall_n && t_sels_c[`DC_MUL];
`ifdef	__use_two_multiply_stages
// Two pipeline stages thanks to the bizarre implementation by Xilinx.
reg	[MSB+WIDTH:0]	prod;
reg	mult_r	= 0;

always @(posedge cpu_clk_i)
	if (mult_t)	prod	<= #2 t_data_c * t_com;

always @(posedge cpu_clk_i)
	mult_r	<= mult_t;

always @(posedge cpu_clk_i)
	if (mult_r)	{x_phi, x_plo}	<= #2 prod;
`else
always @(posedge cpu_clk_i)
	if (mult_t)	{x_phi, x_plo}	<= #2 t_data_c * t_com;
`endif


// Bitwise ops.
// NOTE: There is some nasty hackery here.
// The CMP (compare) operation performs both a subtract and an XOR operation.
// This means both the zero flag (`x_zf') and the borrow (`x_bf') flag get
// set.
wire	[MSB:0]	bits_n;
wire	zf;
wire	#2 bits_t	= x_stall_n && (t_sels_b[`DB_CMP] || t_pack_b[2]);
always @(posedge cpu_clk_i)
	if (bits_t) begin
		x_bits_n	<= #2 bits_n;
		x_zf		<= #2 zf;
	end

fastbits #(WIDTH) BITS (
	.a_i	(t_data_b),
	.b_i	(t_com),
	.m_i	(t_pack_b[1:0]),
	.b_no	(bits_n),
	.z_o	(zf)
);


// Machine Special Registers (MSR).
reg	[SSB:0]	rseg	= 0;	// Read segment
reg	[SSB:0]	wseg	= 0;	// Write segment

assign	#2 bram0_wr	= (x_stall_n && t_sels_c[`DC_MSR] && t_data_c[2:0] == 4);
assign	#2 bram1_wr	= (x_stall_n && t_sels_c[`DC_MSR] && t_data_c[2:0] == 5);

always @(posedge cpu_clk_i)
	if (cpu_rst_i)	{rseg, wseg}	<= #2 0;
	else if (t_sels_c[`DC_MSR]) case (t_data_c[2:0])
		0:	rseg	<= #2 t_com;
		1:	wseg	<= #2 t_com;
		2:	iadr	<= #2 t_com[PSB:0];
	endcase


// WB memory interface.
// TODO
reg	[ASB:0]	wb_adr;
reg	[WSB:0]	wb_dat;
wire	wb_rd, wb_wr;
assign	wb_adr_o	= wb_adr;
assign	wb_dat_o	= wb_dat;

assign	#2 wb_rd	= t_sels_a[`DA_RAD];// && !wb_cyc_o;// && x_stall_n;
assign	#2 wb_wr	= t_sels_a[`DA_WAD];// && !wb_cyc_o;// && x_stall_n;
always @(posedge cpu_clk_i)
	if (cpu_rst_i)
		{wb_we_o, wb_cyc_o, wb_stb_o}	<= #2 0;
	else if (wb_wr) begin
		wb_cyc_o	<= #2 1;
		wb_we_o		<= #2 1;
		wb_adr		<= #2 {wseg, t_data_a};
		wb_dat		<= #2 t_data_c;
		wb_stb_o	<= #2 wseg[SSB] ? 2'b10 : 2'b01 ;
	end else if (wb_rd) begin
		wb_cyc_o	<= #2 1;
		wb_we_o		<= #2 0;
		wb_adr		<= #2 {rseg, t_data_a};
		wb_stb_o	<= #2 rseg[SSB] ? 2'b10 : 2'b01 ;
	end else if (wb_ack_i || wb_rty_i)
		{wb_we_o, wb_cyc_o, wb_stb_o}	<= #2 0;


always @(posedge cpu_clk_i)
	if (wb_ack_i)	x_mem	<= #2 wb_dat_i;


`ifdef __icarus
`ifdef __use_disassembler

`define	RB0	1'b0
`define	RB1	1'b0
`define	R0	3'b000
`define	R1	3'b001
`define	R2	3'b010
`define	R3	3'b011
`define	R4	3'b100
`define	R5	3'b101
`define	R6	3'b110
`define	R7	3'b111

`ifndef __use_BRAMs
initial begin : Sim
	// Toggle LEDs.
	bram[2]	= {`SA_COM, `DA_NOP, `SB_COM, `DB_NOP, `SC_COM, `DC_NOP, `C_IMM, `RB0, `R0, `R0, 8'h01};
	bram[3]	= {`SA_COM, `DA_NOP, `SB_COM, `DB_NOP, `SC_COM, `DC_REG, `C_IMM, `RB0, `R0, `R0, 8'h02};
	bram[4]	= {`SA_COM, `DA_NOP, `SB_COM, `DB_NOP, `SC_COM, `DC_REG, `C_IMM, `RB0, `R1, `R0, 8'hxx};
	bram[5]	= {`SA_COM, `DA_NOP, `SB_COM, `DB_NOP, `SC_COM, `DC_NOP, `C_IMM, `RB0, `R2, `R0, 8'hxx};
	
	bram[6]	= {`SA_IMM, `DA_NOP, `SB_COM, `DB_NOP, `SC_COM, `DC_NOP, `C_NOP, `RB0, `R1, `R0, 8'hxx};
// loop:
	bram[7]	= {`SA_IMM, `DA_WAD, `SB_COM, `DB_NOP, `SC_REG, `DC_MEM, `C_NOP, `RB0, `R0, `R0, 8'h0a};
	bram[8]	= {`SA_IMM, `DA_BRA, `SB_COM, `DB_NOP, `SC_COM, `DC_NOP, `C_NOP, `RB0, `R2, `R0, 8'h06};
	bram[9]	= {`SA_IMM, `DA_WAD, `SB_COM, `DB_NOP, `SC_REG, `DC_MEM, `C_NOP, `RB0, `R1, `R0, 8'h00};
	
end	// Sim
`endif


// Disassembler
reg	[ISB:0]	i_m2, i_m1, i_m0;
reg	[PSB:0]	pc_m2, pc_m1, pc_m0;
always @(posedge cpu_clk_i)
	if (cpu_rst_i)	{i_m0, i_m1, i_m2, pc_m0, pc_m1, pc_m2}	<= #2 0;
	else if (f_stall_n) begin
		{i_m2, i_m1, i_m0}	<= #2 {i_m1, i_m0, instr};
		{pc_m2, pc_m1, pc_m0}	<= #2 {pc_m1, pc_m0, pc};
	end

wire	[MSB:0]	dr_bits	= ~x_bits_n;
reg	[MSB:0]	dr_r0, dr_r1, dr_com, dr_diff;
always @(posedge cpu_clk_i)
	if (cpu_rst_i)
		{dr_com, dr_r1, dr_r0}	<= #2 0;
	else if (f_stall_n)
		{dr_diff, dr_com, dr_r1, dr_r0}	<= #2 {x_diff, t_com, t_reg1, t_reg0};

wire	[1:0]	da_sa	= i_m0[31:30];
wire	[2:0]	da_da	= i_m0[29:27];
wire	[1:0]	da_sb	= i_m0[26:25];
wire	[2:0]	da_db	= i_m0[24:22];
wire	[1:0]	da_sc	= i_m0[21:20];
wire	[1:0]	da_dc	= i_m0[19:18];
wire	[2:0]	da_com	= i_m0[17:15];
wire	[3:0]	da_r0	= {i_m1[14], i_m1[10:8]};
wire	[3:0]	da_r1	= i_m1[14:11];
wire	[3:0]	da_rd	= instr[14:11];
wire	[15:0]	da_is	= {{(WIDTH-7){i_m0[7]}}, i_m0[6:0]};
wire	[15:0]	da_il	= {{(WIDTH-10){i_m0[10]}}, i_m0[9:0]};

always @(posedge cpu_clk_i)
	if (f_stall_n && !cpu_rst_i) begin
		$write("%03x, %08x: {", pc_m1, i_m0);
		
		if (da_da != `DA_NOP) begin
			case(da_sa)
			`SA_COM: $write("com(%4x)", dr_com);
			`SA_IMM: $write("#0%0x\t", da_il);
			`SA_REG: $write("$r%1d(%4x)", da_r0, dr_r0);
			`SA_MEM: $write("[%0x](%4x)", wb_adr_o[MSB:0], x_mem);
			endcase
			
			$write("\t->");
			
			case(da_da)
			`DA_BRA: $write("pc");
			`DA_RAD: $write("rad");
			`DA_WAD: $write("wad");
			`DA_JB:  $write("pc.b");
			`DA_JNB: $write("pc.nb");
			`DA_JZ:  $write("pc.z");
			`DA_JNZ: $write("pc.nz");
			endcase
		end else
			$write("\t\t");
		$write("\t,");
		
		if (da_db != `DB_NOP) begin
			case(da_sb)
			`SB_COM: $write("com(%4x)", dr_com);
			`SB_IMM: $write("#0%0x\t", da_is);
			`SB_REG: $write("$r%1d(%4x)", da_r0, dr_r0);
			`SB_MEM: $write("[%0x](%4x)", wb_adr_o[MSB:0], x_mem);
			endcase
			
			$write("\t->");
			
			case(da_db)
			`DB_SUB: $write("sub");
			`DB_SBB: $write("sbb");
			`DB_CMP: $write("cmp");
			`DB_NAND:$write("nand");
			`DB_AND: $write("and");
			`DB_OR:  $write("or");
			`DB_XOR: $write("xor");
			endcase
		end else
			$write("\t\t");
		$write("\t,");
		
		case(da_sc)
		`SC_COM: $write("com(%4x)", dr_com);
		`SC_DIFF:$write("diff(%4x)", dr_diff);
		`SB_REG: $write("$r%1d(%4x)", da_r1, dr_r1);
		`SC_PC:  $write("pc(%3x)", pc_prev);
		endcase
		
		$write("\t->");
		
		case(da_dc)
		`DC_MEM: $write("mem");
		`DC_REG: $write("$r%01d", da_rd);
		`DC_MUL: $write("mul");
		`DC_MSR: $write("msr");
		endcase
		$write("\t,");
		
		case(da_com)
		`C_COM: $write("\t");
		`C_IMM: $write("#0%0x\t", da_is);
		`C_REG: $write("$r%01d(%4x)", da_r1, dr_r1);
		`C_MEM: $write("[%0x](%4x)", wb_adr_o[MSB:0], x_mem);
		`C_DIFF:$write("diff(%4x)", dr_diff);
		`C_BITS:$write("bits(%4x)", dr_bits);
		`C_PLO: $write("plo(%4x)", x_plo);
		`C_PHI: $write("phi(%4x)", x_phi);
		endcase
		
		$display("\t}");
	end
`endif // __use_disassembler
`endif // __icarus


endmodule	// tta16
