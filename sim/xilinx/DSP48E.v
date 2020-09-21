/***************************************************************************
 *                                                                         *
 *   DSP48E.v - Simulates the Xilinx (Virtex5) primitive of the same name  *
 *     for use with Icarus Verilog.                                        *
 *                                                                         *
 *   WILL NOT SYNTHESISE!                                                  *
 *                                                                         *
 *   Copyright (C) 2007 by Patrick Suggate                                 *
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

`define	GND	'b0
`define	NC	'bx

`timescale 1ns/100ps
module DSP48E (
	CLK,		// Clock input
	ALUMODE,	// 4-bit ALU control input
	OPMODE,		// 7-bit operation mode input
	A,		// 30-bit A data input
	B,		// 18-bit B data input
	C,		// 48-bit C data input
	P,		// 48-bit output
	CARRYIN,	// 1-bit carry input signal
	CARRYOUT,	// 4-bit carry output, only upper bit set in 48-bit mode
	CARRYINSEL,	// 3-bit carry select input
	CEA1,		// 1-bit active high clock enable input for 1st stage A registers
	CEB1,		// 1-bit active high clock enable input for 1st stage B registers
	CEA2,		// 1-bit active high clock enable input for 2nd stage A registers
	CEB2,		// 1-bit active high clock enable input for 2nd stage B registers
	CEC,		// 1-bit active high clock enable input for C registers
	CEM,		// 1-bit active high clock enable input for multiplier registers
	CEP,		// 1-bit active high clock enable input for P registers
	CEALUMODE,	// 1-bit active high clock enable input for ALUMODE registers
	CECARRYIN,	// 1-bit active high clock enable input for CARRYIN register
	CECTRL,		// 1-bit active high clock enable input for OPMODE and carry registers
	RSTA,		// 1-bit reset input for A pipeline registers
	RSTALLCARRYIN,	// 1-bit reset input for carry pipeline registers
	RSTALUMODE,	// 1-bit reset input for ALUMODE pipeline registers
	RSTB,		// 1-bit reset input for B pipeline registers
	RSTC,		// 1-bit reset input for C pipeline registers
	RSTCTRL,	// 1-bit reset input for OPMODE pipeline registers
	RSTM,		// 1-bit reset input for multiplier registers
	RSTP		// 1-bit reset input for P pipeline registers
	
	// TODO
	//.CEMULTCARRYIN(CEMULTCARRYIN), // 1-bit active high clock enable for multiplier carry in register
	//.MULTSIGNIN(MULTSIGNIN), // 1-bit multiplier sign input
	//.PCIN(PCIN),     // 48-bit P cascade input 
	//.ACOUT(ACOUT),  // 30-bit A port cascade output 
	//.BCOUT(BCOUT),  // 18-bit B port cascade output
	//.CARRYCASCOUT(CARRYCASCOUT), // 1-bit cascade carry output
	//.ACIN(ACIN),    // 30-bit A cascade data input
	//.MULTSIGNOUT(MULTSIGNOUT), // 1-bit multiplier sign cascade output
	//.PATTERNBDETECT(PATTERNBDETECT), // 1-bit active high pattern bar detect output
	//.PATTERNDETECT(PATTERNDETECT),   //  1-bit active high pattern detect output
	//.PCOUT(PCOUT),  // 48-bit cascade output
	//.BCIN(BCIN),    // 18-bit B cascade input
	//.CARRYCASCIN(CARRYCASCIN), // 1-bit cascade carry input
	//.OVERFLOW	(OVERFLOW),	// 1-bit overflow in add/acc output
	//.UNDERFLOW(UNDERFLOW) // 1-bit active high underflow in add/acc output
);

// Pipeline registers. Use one of each for max frequency.
// FIXME: Parameters are ignored ATM.
parameter	AREG		= 1;	// Number of pipeline registers on the A input, 0, 1 or 2
parameter	BREG		= 1;	// Number of pipeline registers on the B input, 0, 1 or 2
parameter	CREG		= 1;	// Number of pipeline registers on the C input, 0 or 1
parameter	MREG		= 1;	// Number of multiplier pipeline registers, 0 or 1
parameter	PREG		= 1;	// Number of pipeline registers on the P output, 0 or 1

parameter	ALUMODEREG	= 1;	// Number of pipeline registers on ALUMODE input, 0 or 1
parameter	OPMODEREG	= 1;	// Number of pipeline registers on OPMODE input, 0 or 1

parameter	ACASCREG	= 0;	// Number of pipeline registers between A/ACIN input and ACOUT output, 0, 1, or 2
parameter	BCASCREG	= 0;	// Number of pipeline registers between B/BCIN input and BCOUT output, 0, 1, or 2
parameter	CARRYINREG	= 1;	// Number of pipeline registers for the CARRYIN input, 0 or 1
parameter	CARRYINSELREG	= 1;	// Number of pipeline registers for the CARRYINSEL input, 0 or 1
parameter	MULTCARRYINREG	= 0;	// Number of pipeline registers for multiplier carry in bit, 0 or 1
parameter	MASK	= 48'h3fffffffffff;	// 48-bit Mask value for pattern detect
parameter	PATTERN	= 48'h000000000000;	// 48-bit Pattern match for pattern detect
parameter	AUTORESET_PATTERN_DETECT	= "FALSE";	// Auto-reset upon pattern detect, "TRUE" or "FALSE" 
parameter	AUTORESET_PATTERN_DETECT_OPTINV	= "MATCH";	// Reset if "MATCH" or "NOMATCH" 
parameter	A_INPUT				= "DIRECT";	// Selects A input used, "DIRECT" 	= A port) or "CASCADE" 	= ACIN port)
parameter	B_INPUT				= "DIRECT";	// Selects B input used, "DIRECT" 	= B port) or "CASCADE" 	= BCIN port)
parameter	SEL_MASK			= "MASK";	// Select mask value between the "MASK" value or the value on the "C" port
parameter	SEL_PATTERN			= "PATTERN";	// Select pattern value between the "PATTERN" value or the value on the "C" port
parameter	SEL_ROUNDING_MASK		= "SEL_MASK";	// "SEL_MASK", "MODE1", "MODE2" 
parameter	USE_MULT			= "MULT_S";	// Select multiplier usage, "MULT" 	= MREG => 0; "MULT_S" 	= MREG => 1; "NONE" 	= no multiplier)
parameter	USE_PATTERN_DETECT		= "NO_PATDET";	// Enable pattern detect, "PATDET", "NO_PATDET" 
parameter	USE_SIMD			= "ONE48";	// SIMD selection, "ONE48", "TWO24", "FOUR12" 


input	CLK;
input	[3:0]	ALUMODE;
input	[6:0]	OPMODE;
input signed	[29:0]	A;
input signed	[17:0]	B;
input signed	[47:0]	C;
output signed	[47:0]	P;
input	CARRYIN;
output	[3:0]	CARRYOUT;
input	CARRYINSEL;
input	CEA1;
input	CEB1;
input	CEA2;
input	CEB2;
input	CEC;
input	CEM;
input	CEP;
input	CEALUMODE;
input	CECARRYIN;
input	CECTRL;
input	RSTA;
input	RSTALLCARRYIN;
input	RSTALUMODE;
input	RSTB;
input	RSTC;
input	RSTCTRL;
input	RSTM;
input	RSTP;


reg signed	[29:0]	A0_r;
reg signed	[17:0]	B0_r;
reg signed	[47:0]	C_r;
reg signed	[42:0]	M_r;	// TODO: Should be two registers
reg signed	[47:0]	P_r;

reg	[3:0]	ALU_r;
reg	[6:0]	OP_r;

wire signed	[42:0]	M;
wire signed	[47:0]	C_w;
wire signed	[47:0]	P_w;

wire signed	[47:0]	X;
wire signed	[47:0]	Y;
wire signed	[47:0]	Z;
wire	addsub;

wire signed [24:0] A0_25 = A0_r [24:0];

assign	M	= A0_25 * B0_r;
assign	C_w	= C_r;	// TODO: Should be a 2-1 MUX

// The three MUXs that feed the ALU stage.
assign	X	= M_r;
assign	Y	= 0;

assign	addsub	= (ALU_r == 4'b0011) ? 0 : 1;
assign	P_w	= addsub ? Z + (X + Y) : Z - (X + Y);
assign	P	= P_r;


always @(posedge CLK)
begin
	if (RSTA)
		A0_r	<= 0;
	else if (CEA2)
		A0_r	<= A;
	else
		A0_r	<= A0_r;
end


always @(posedge CLK)
begin
	if (RSTB)
		B0_r	<= 0;
	else if (CEB2)
		B0_r	<= B;
	else
		B0_r	<= B0_r;
end


always @(posedge CLK)
begin
	if (RSTC)
		C_r	<= 0;
	else if (CEC)
		C_r	<= C;
	else
		C_r	<= C_r;
end


always @(posedge CLK)
begin
	if (RSTM)
		M_r	<= 0;
	else if (CEM)
		M_r	<= M;
	else
		M_r	<= M_r;
end


always @(posedge CLK)
begin
	if (RSTP)
		P_r	<= 0;
	else if (CEP)
		P_r	<= P_w;
	else
		P_r	<= P_r;
end


always @(posedge CLK)
begin
	if (RSTALUMODE)
		ALU_r	<= 0;
	else if (CEALUMODE)
		ALU_r	<= ALUMODE;
	else
		ALU_r	<= ALU_r;
end


always @(posedge CLK)
begin
	if (RSTCTRL)
		OP_r	<= 0;
	else if (CECTRL)
		OP_r	<= OPMODE;
	else
		OP_r	<= OP_r;
end


mux8to1 #(
	.WIDTH		(48)
)
ZMUX (
	.sel_i		(OP_r [6:4]),
	
	.data0_i	(0),
	.data1_i	(`NC),
	.data2_i	(P),
	.data3_i	(`NC),
	.data4_i	(C_w),
	.data5_i	(`NC),
	.data6_i	(`NC),
	.data7_i	(`NC),
	
	.data_o		(Z)
);


endmodule	// DSP48E
