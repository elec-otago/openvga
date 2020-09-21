/***************************************************************************
 *                                                                         *
 *   RAMB36.v - Emulates the Xilinx primitive of the same name for use     *
 *     with simulation using Icarus Verilog.                               *
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

`timescale 1ns/100ps
module RAMB36 (
	// Port A
	CLKA,
	SSRA,
	
	ENA,
	WEA,
	ADDRA,
	REGCEA,
	
	DIA,
	DIPA,
	DOA,
	DOPA,
	
	// Port B
	CLKB,
	SSRB,
	
	ENB,
	WEB,
	ADDRB,
	REGCEB,
	
	DIB,
	DIPB,
	DOB,
	DOPB,
	
	// Useless crap
	CASCADEOUTLATA,
	CASCADEOUTLATB,
	CASCADEOUTREGA,
	CASCADEOUTREGB,
	
	CASCADEINLATA,
	CASCADEINLATB,
	CASCADEINREGA,
	CASCADEINREGB
);

// The following INIT_xx declarations specify the initial contents of the RAM
parameter	INIT_00	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_01	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_02	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_03	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_04	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_05	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_06	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_07	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_08	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_09	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_0A	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_0B	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_0C	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_0D	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_0E	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_0F	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_10	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_11	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_12	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_13	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_14	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_15	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_16	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_17	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_18	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_19	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_1A	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_1B	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_1C	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_1D	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_1E	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_1F	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_20	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_21	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_22	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_23	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_24	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_25	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_26	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_27	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_28	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_29	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_2A	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_2B	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_2C	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_2D	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_2E	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_2F	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_30	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_31	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_32	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_33	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_34	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_35	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_36	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_37	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_38	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_39	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_3A	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_3B	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_3C	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_3D	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_3E	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_3F	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_40	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_41	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_42	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_43	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_44	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_45	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_46	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_47	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_48	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_49	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_4A	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_4B	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_4C	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_4D	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_4E	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_4F	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_50	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_51	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_52	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_53	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_54	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_55	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_56	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_57	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_58	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_59	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_5A	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_5B	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_5C	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_5D	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_5E	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_5F	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_60	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_61	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_62	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_63	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_64	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_65	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_66	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_67	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_68	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_69	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_6A	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_6B	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_6C	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_6D	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_6E	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_6F	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_70	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_71	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_72	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_73	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_74	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_75	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_76	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_77	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_78	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_79	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_7A	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_7B	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_7C	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_7D	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_7E	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INIT_7F	= 256'h0000000000000000000000000000000000000000000000000000000000000000;

// The next set of INITP_xx are for the parity bits
parameter	INITP_00	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INITP_01	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INITP_02	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INITP_03	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INITP_04	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INITP_05	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INITP_06	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INITP_07	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INITP_08	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INITP_09	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INITP_0A	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INITP_0B	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INITP_0C	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INITP_0D	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INITP_0E	= 256'h0000000000000000000000000000000000000000000000000000000000000000;
parameter	INITP_0F	= 256'h0000000000000000000000000000000000000000000000000000000000000000;

parameter	DOA_REG		= 0;
parameter	DOB_REG		= 0;
parameter	INIT_A		= 36'h0_0000_0000;
parameter	INIT_B		= 36'h0_0000_0000;
parameter	RAM_EXTENSION_A	= "NONE";
parameter	RAM_EXTENSION_B	= "NONE";
parameter	READ_WIDTH_A	= 0;
parameter	READ_WIDTH_B	= 0;
parameter	SIM_COLLISION_CHECK	= "ALL";
parameter	SRVAL_A		= 36'h000000000;
parameter	SRVAL_B		= 36'h000000000;
parameter	WRITE_MODE_A	= "WRITE_FIRST";
parameter	WRITE_MODE_B	= "WRITE_FIRST";
parameter	WRITE_WIDTH_A	= 0;
parameter	WRITE_WIDTH_B	= 0;


// Port A.
input		CLKA;
input		SSRA;

input		ENA;
input	[3:0]	WEA;
input	[15:0]	ADDRA;
input		REGCEA;

input	[31:0]	DIA;
input	[3:0]	DIPA;
output	[31:0]	DOA;
output	[3:0]	DOPA;

// Port B.
input		CLKB;
input		SSRB;

input		ENB;
input	[3:0]	WEB;
input	[15:0]	ADDRB;
input		REGCEB;

input	[31:0]	DIB;
input	[3:0]	DIPB;
output	[31:0]	DOB;
output	[3:0]	DOPB;

// Useless crap.
output	CASCADEOUTLATA;
output	CASCADEOUTLATB;
output	CASCADEOUTREGA;
output	CASCADEOUTREGB;

input	CASCADEINLATA;
input	CASCADEINLATB;
input	CASCADEINREGA;
input	CASCADEINREGB;


// Probably easy to parameterise using single bits.
reg	ram_bits [0:32767];
reg	par_bits [0:4095];


reg	[31:0]	doa	= INIT_A [31:0];
reg	[31:0]	doa_p	= INIT_A [31:0];
reg	[3:0]	dopa	= INIT_A [35:32];
reg	[3:0]	dopa_p	= INIT_A [35:32];

reg	[31:0]	dob	= INIT_B [31:0];
reg	[31:0]	dob_p	= INIT_B [31:0];
reg	[3:0]	dopb	= INIT_B [35:32];
reg	[3:0]	dopb_p	= INIT_B [35:32];


// FIXME: This is broken, but I am not using ATM.
assign	CASCADEOUTLATA	= CASCADEINLATA;
assign	CASCADEOUTLATB	= CASCADEINLATB;
assign	CASCADEOUTREGA	= CASCADEINREGA;
assign	CASCADEOUTREGB	= CASCADEINREGB;


// Are the pipeline registers enabled?
//assign	DOA	= DOA_REG ? doa_p  : doa;
assign	DOA	= doa;
assign	DOPA	= dopa;

assign	DOB	= dob;
assign	DOPB	= dopb;



//---------------------------------------------------------------------------
// Port A logic.
//

// Generate the actual array indices based upon the current mode.
reg	[14:0]	rd_idx_a, wr_idx_a;

wire	[5:0]	width_a = READ_WIDTH_A > 32 ? 32 : READ_WIDTH_A;
wire	[2:0]	par_a	= READ_WIDTH_A >> 3;

wire	[6:0]	wr_width_a	= (WRITE_WIDTH_A > 32) ? 32 : WRITE_WIDTH_A;
wire	[4:0]	wr_par_a	= (WRITE_WIDTH_A >> 3);


always @(ADDRA)
case (READ_WIDTH_A)
	'd1:	rd_idx_a	<=  ADDRA [14:0];
	'd2:	rd_idx_a	<= {ADDRA [14:1], 1'b0};
	'd4:	rd_idx_a	<= {ADDRA [14:2], 2'b0};
	'd9:	rd_idx_a	<= {ADDRA [14:3], 3'b0};
	'd18:	rd_idx_a	<= {ADDRA [14:4], 4'b0};
	'd36:	rd_idx_a	<= {ADDRA [14:5], 5'b0};
	default:	rd_idx_a	<= 'bx;
endcase


always @(ADDRA)
case (WRITE_WIDTH_A)
	'd1:	wr_idx_a	<=  ADDRA [14:0];
	'd2:	wr_idx_a	<= {ADDRA [14:1], 1'b0};
	'd4:	wr_idx_a	<= {ADDRA [14:2], 2'b0};
	'd9:	wr_idx_a	<= {ADDRA [14:3], 3'b0};
	'd18:	wr_idx_a	<= {ADDRA [14:4], 4'b0};
	'd36:	wr_idx_a	<= {ADDRA [14:5], 5'b0};
	default:	wr_idx_a	<= 'bx;
endcase


// TODO: Support for when reading from, and writing to, the same address.
integer	ar;
always @(posedge CLKA)
begin
	if (SSRA)
	begin
		doa	<= SRVAL_A [31:0];
		doa_p	<= SRVAL_A [31:0];
		dopa	<= SRVAL_A [35:32];
		dopa_p	<= SRVAL_A [35:32];
	end
	else if (ENA)
	begin
		if (REGCEA)	// Use the pipeline regs?
		begin
			doa	<= doa_p;
			dopa	<= dopa_p;
		end
		
		for (ar=0; ar<width_a; ar=ar+1)
		begin
			if (REGCEA)
				doa_p [ar]	= ram_bits [rd_idx_a + ar];
			else
				doa [ar]	= ram_bits [rd_idx_a + ar];
			
		end
		
		for (ar=0; ar<par_a; ar=ar+1)
		begin
			if (REGCEA)
				dopa_p [ar]	= par_bits [rd_idx_a [14:3] + ar];
			else
				dopa [ar]	= par_bits [rd_idx_a [14:3] + ar];
		end
	end
end


integer	aw, amax;
always @(posedge CLKA)
begin
	if (WEA > 0 && !SSRA && ENA)
	begin
		if (WEA [0])
		begin
			if (WRITE_WIDTH_A > 8)
				amax	= 8;
			else
				amax	= WRITE_WIDTH_A;
			
			for (aw=0; aw<amax; aw=aw+1)
				ram_bits [wr_idx_a + aw]	= DIA [aw];
			
			if (wr_par_a > 0)
				par_bits [wr_idx_a [14:3] + 0]	= DIPA [0];
		end
		
		if (WEA [1])
		begin
			if (WRITE_WIDTH_A > 16)
				amax	= 16;
			else
				amax	= WRITE_WIDTH_A;
			
			for (aw=8; aw<amax; aw=aw+1)
				ram_bits [wr_idx_a + aw]	= DIA [aw];
			
			if (wr_par_a > 1)
				par_bits [wr_idx_a [14:3] + 1]	= DIPA [1];
		end
		
		if (WEA [2])
		begin
			if (WRITE_WIDTH_A > 24)
				amax	= 24;
			else
				amax	= WRITE_WIDTH_A;
			
			for (aw=16; aw<amax; aw=aw+1)
				ram_bits [wr_idx_a + aw]	= DIA [aw];
			
			if (wr_par_a > 2)
				par_bits [wr_idx_a [14:3] + 2]	= DIPA [2];
		end
		
		if (WEA [3])
		begin
			if (WRITE_WIDTH_A > 32)
				amax	= 32;
			else
				amax	= WRITE_WIDTH_A;
			
			for (aw=24; aw<amax; aw=aw+1)
				ram_bits [wr_idx_a + aw]	= DIA [aw];
			
			if (wr_par_a > 3)
				par_bits [wr_idx_a [14:3] + 3]	= DIPA [3];
		end
	end
end



//---------------------------------------------------------------------------
// Port B logic.
//

// Generate the actual array indices based upon the current mode.
reg	[14:0]	rd_idx_b, wr_idx_b;

wire	[5:0]	width_b	= READ_WIDTH_B > 32 ? 32 : READ_WIDTH_B;
wire	[2:0]	par_b	= READ_WIDTH_B >> 3;

wire	[5:0]	wr_width_b	= WRITE_WIDTH_B > 32 ? 32 : WRITE_WIDTH_B;
wire	[2:0]	wr_par_b	= WRITE_WIDTH_B >> 3;


always @(ADDRB)
case (READ_WIDTH_B)
	'd1:	rd_idx_b	<=  ADDRB [14:0];
	'd2:	rd_idx_b	<= {ADDRB [14:1], 1'b0};
	'd4:	rd_idx_b	<= {ADDRB [14:2], 2'b0};
	'd9:	rd_idx_b	<= {ADDRB [14:3], 3'b0};
	'd18:	rd_idx_b	<= {ADDRB [14:4], 4'b0};
	'd36:	rd_idx_b	<= {ADDRB [14:5], 5'b0};
	default:	rd_idx_a	<= 'bx;
endcase


always @(ADDRB)
case (WRITE_WIDTH_B)
	'd1:	wr_idx_b	<=  ADDRB [14:0];
	'd2:	wr_idx_b	<= {ADDRB [14:1], 1'b0};
	'd4:	wr_idx_b	<= {ADDRB [14:2], 2'b0};
	'd9:	wr_idx_b	<= {ADDRB [14:3], 3'b0};
	'd18:	wr_idx_b	<= {ADDRB [14:4], 4'b0};
	'd36:	wr_idx_b	<= {ADDRB [14:5], 5'b0};
	default:	wr_idx_b	<= 'bx;
endcase


// TODO: Support for when reading from, and writing to, the same address.
integer	br;
always @(posedge CLKB)
begin
	if (SSRB)
	begin
		dob	<= SRVAL_B [31:0];
		dob_p	<= SRVAL_B [31:0];
		dopb	<= SRVAL_B [35:32];
		dopb_p	<= SRVAL_B [35:32];
	end
	else if (ENB)
	begin
		if (REGCEB)	// Use the pipeline regs?
		begin
			dob	<= dob_p;
			dopb	<= dopb_p;
		end
		
		for (br=0; br<width_b; br=br+1)
		begin
			if (REGCEB)
				dob_p [br]	= ram_bits [rd_idx_b + br];
			else
				dob [br]	= ram_bits [rd_idx_b + br];
			
		end
		
		for (br=0; br<par_b; br=br+1)
		begin
			if (REGCEB)
				dopb_p [br]	= par_bits [rd_idx_b [14:3] + br];
			else
				dopb [br]	= par_bits [rd_idx_b [14:3] + br];
		end
	end
end


integer	bw, bmax;
always @(posedge CLKB)
begin
	if (WEB > 0 && !SSRB && ENB)
	begin
		if (WEB [0])
		begin
			if (WRITE_WIDTH_B > 8)
				bmax	= 8;
			else
				bmax	= WRITE_WIDTH_B;
			
			for (bw=0; bw<bmax; bw=bw+1)
				ram_bits [wr_idx_b + bw]	= DIB [bw];
			
			if (wr_par_b > 0)
				par_bits [wr_idx_b [14:3] + 0]	= DIPB [0];
		end
		
		if (WEB [1])
		begin
			if (WRITE_WIDTH_B > 16)
				bmax	= 16;
			else
				bmax	= WRITE_WIDTH_B;
			
			for (bw=8; bw<bmax; bw=bw+1)
				ram_bits [wr_idx_b + bw]	= DIB [bw];
			
			if (wr_par_b > 1)
				par_bits [wr_idx_b [14:3] + 1]	= DIPB [1];
		end
		
		if (WEB [2])
		begin
			if (WRITE_WIDTH_B > 24)
				bmax	= 24;
			else
				bmax	= WRITE_WIDTH_B;
			
			for (bw=16; bw<bmax; bw=bw+1)
				ram_bits [wr_idx_b + bw]	= DIB [bw];
			
			if (wr_par_b > 2)
				par_bits [wr_idx_b [14:3] + 2]	= DIPB [2];
		end
		
		if (WEB [3])
		begin
			if (WRITE_WIDTH_B > 32)
				bmax	= 32;
			else
				bmax	= WRITE_WIDTH_B;
			
			for (bw=24; bw<bmax; bw=bw+1)
				ram_bits [wr_idx_b + bw]	= DIB [bw];
			
			if (wr_par_b > 3)
				par_bits [wr_idx_b [14:3] + 3]	= DIPB [3];
		end
	end
end



//---------------------------------------------------------------------------
// Initialisation stuff.
//

integer	ii;
initial begin : Init
	for (ii=0; ii<256; ii=ii+1)
	begin
		#0.1
		ram_bits ['h00_00+ii]	= INIT_00 [ii];
		ram_bits ['h01_00+ii]	= INIT_01 [ii];
		ram_bits ['h02_00+ii]	= INIT_02 [ii];
		ram_bits ['h03_00+ii]	= INIT_03 [ii];
		ram_bits ['h04_00+ii]	= INIT_04 [ii];
		ram_bits ['h05_00+ii]	= INIT_05 [ii];
		ram_bits ['h06_00+ii]	= INIT_06 [ii];
		ram_bits ['h07_00+ii]	= INIT_07 [ii];
		ram_bits ['h08_00+ii]	= INIT_08 [ii];
		ram_bits ['h09_00+ii]	= INIT_09 [ii];
		ram_bits ['h0A_00+ii]	= INIT_0A [ii];
		ram_bits ['h0B_00+ii]	= INIT_0B [ii];
		ram_bits ['h0C_00+ii]	= INIT_0C [ii];
		ram_bits ['h0D_00+ii]	= INIT_0D [ii];
		ram_bits ['h0E_00+ii]	= INIT_0E [ii];
		ram_bits ['h0F_00+ii]	= INIT_0F [ii];
		
		ram_bits ['h10_00+ii]	= INIT_10 [ii];
		ram_bits ['h11_00+ii]	= INIT_11 [ii];
		ram_bits ['h12_00+ii]	= INIT_12 [ii];
		ram_bits ['h13_00+ii]	= INIT_13 [ii];
		ram_bits ['h14_00+ii]	= INIT_14 [ii];
		ram_bits ['h15_00+ii]	= INIT_15 [ii];
		ram_bits ['h16_00+ii]	= INIT_16 [ii];
		ram_bits ['h17_00+ii]	= INIT_17 [ii];
		ram_bits ['h18_00+ii]	= INIT_18 [ii];
		ram_bits ['h19_00+ii]	= INIT_19 [ii];
		ram_bits ['h1A_00+ii]	= INIT_1A [ii];
		ram_bits ['h1B_00+ii]	= INIT_1B [ii];
		ram_bits ['h1C_00+ii]	= INIT_1C [ii];
		ram_bits ['h1D_00+ii]	= INIT_1D [ii];
		ram_bits ['h1E_00+ii]	= INIT_1E [ii];
		ram_bits ['h1F_00+ii]	= INIT_1F [ii];
		
		ram_bits ['h20_00+ii]	= INIT_20 [ii];
		ram_bits ['h21_00+ii]	= INIT_21 [ii];
		ram_bits ['h22_00+ii]	= INIT_22 [ii];
		ram_bits ['h23_00+ii]	= INIT_23 [ii];
		ram_bits ['h24_00+ii]	= INIT_24 [ii];
		ram_bits ['h25_00+ii]	= INIT_25 [ii];
		ram_bits ['h26_00+ii]	= INIT_26 [ii];
		ram_bits ['h27_00+ii]	= INIT_27 [ii];
		ram_bits ['h28_00+ii]	= INIT_28 [ii];
		ram_bits ['h29_00+ii]	= INIT_29 [ii];
		ram_bits ['h2A_00+ii]	= INIT_2A [ii];
		ram_bits ['h2B_00+ii]	= INIT_2B [ii];
		ram_bits ['h2C_00+ii]	= INIT_2C [ii];
		ram_bits ['h2D_00+ii]	= INIT_2D [ii];
		ram_bits ['h2E_00+ii]	= INIT_2E [ii];
		ram_bits ['h2F_00+ii]	= INIT_2F [ii];
		
		ram_bits ['h30_00+ii]	= INIT_30 [ii];
		ram_bits ['h31_00+ii]	= INIT_31 [ii];
		ram_bits ['h32_00+ii]	= INIT_32 [ii];
		ram_bits ['h33_00+ii]	= INIT_33 [ii];
		ram_bits ['h34_00+ii]	= INIT_34 [ii];
		ram_bits ['h35_00+ii]	= INIT_35 [ii];
		ram_bits ['h36_00+ii]	= INIT_36 [ii];
		ram_bits ['h37_00+ii]	= INIT_37 [ii];
		ram_bits ['h38_00+ii]	= INIT_38 [ii];
		ram_bits ['h39_00+ii]	= INIT_39 [ii];
		ram_bits ['h3A_00+ii]	= INIT_3A [ii];
		ram_bits ['h3B_00+ii]	= INIT_3B [ii];
		ram_bits ['h3C_00+ii]	= INIT_3C [ii];
		ram_bits ['h3D_00+ii]	= INIT_3D [ii];
		ram_bits ['h3E_00+ii]	= INIT_3E [ii];
		ram_bits ['h3F_00+ii]	= INIT_3F [ii];
		
		ram_bits ['h40_00+ii]	= INIT_40 [ii];
		ram_bits ['h41_00+ii]	= INIT_41 [ii];
		ram_bits ['h42_00+ii]	= INIT_42 [ii];
		ram_bits ['h43_00+ii]	= INIT_43 [ii];
		ram_bits ['h44_00+ii]	= INIT_44 [ii];
		ram_bits ['h45_00+ii]	= INIT_45 [ii];
		ram_bits ['h46_00+ii]	= INIT_46 [ii];
		ram_bits ['h47_00+ii]	= INIT_47 [ii];
		ram_bits ['h48_00+ii]	= INIT_48 [ii];
		ram_bits ['h49_00+ii]	= INIT_49 [ii];
		ram_bits ['h4A_00+ii]	= INIT_4A [ii];
		ram_bits ['h4B_00+ii]	= INIT_4B [ii];
		ram_bits ['h4C_00+ii]	= INIT_4C [ii];
		ram_bits ['h4D_00+ii]	= INIT_4D [ii];
		ram_bits ['h4E_00+ii]	= INIT_4E [ii];
		ram_bits ['h4F_00+ii]	= INIT_4F [ii];
		
		ram_bits ['h50_00+ii]	= INIT_50 [ii];
		ram_bits ['h51_00+ii]	= INIT_51 [ii];
		ram_bits ['h52_00+ii]	= INIT_52 [ii];
		ram_bits ['h53_00+ii]	= INIT_53 [ii];
		ram_bits ['h54_00+ii]	= INIT_54 [ii];
		ram_bits ['h55_00+ii]	= INIT_55 [ii];
		ram_bits ['h56_00+ii]	= INIT_56 [ii];
		ram_bits ['h57_00+ii]	= INIT_57 [ii];
		ram_bits ['h58_00+ii]	= INIT_58 [ii];
		ram_bits ['h59_00+ii]	= INIT_59 [ii];
		ram_bits ['h5A_00+ii]	= INIT_5A [ii];
		ram_bits ['h5B_00+ii]	= INIT_5B [ii];
		ram_bits ['h5C_00+ii]	= INIT_5C [ii];
		ram_bits ['h5D_00+ii]	= INIT_5D [ii];
		ram_bits ['h5E_00+ii]	= INIT_5E [ii];
		ram_bits ['h5F_00+ii]	= INIT_5F [ii];
		
		ram_bits ['h60_00+ii]	= INIT_60 [ii];
		ram_bits ['h61_00+ii]	= INIT_61 [ii];
		ram_bits ['h62_00+ii]	= INIT_62 [ii];
		ram_bits ['h63_00+ii]	= INIT_63 [ii];
		ram_bits ['h64_00+ii]	= INIT_64 [ii];
		ram_bits ['h65_00+ii]	= INIT_65 [ii];
		ram_bits ['h66_00+ii]	= INIT_66 [ii];
		ram_bits ['h67_00+ii]	= INIT_67 [ii];
		ram_bits ['h68_00+ii]	= INIT_68 [ii];
		ram_bits ['h69_00+ii]	= INIT_69 [ii];
		ram_bits ['h6A_00+ii]	= INIT_6A [ii];
		ram_bits ['h6B_00+ii]	= INIT_6B [ii];
		ram_bits ['h6C_00+ii]	= INIT_6C [ii];
		ram_bits ['h6D_00+ii]	= INIT_6D [ii];
		ram_bits ['h6E_00+ii]	= INIT_6E [ii];
		ram_bits ['h6F_00+ii]	= INIT_6F [ii];
		
		ram_bits ['h70_00+ii]	= INIT_70 [ii];
		ram_bits ['h71_00+ii]	= INIT_71 [ii];
		ram_bits ['h72_00+ii]	= INIT_72 [ii];
		ram_bits ['h73_00+ii]	= INIT_73 [ii];
		ram_bits ['h74_00+ii]	= INIT_74 [ii];
		ram_bits ['h75_00+ii]	= INIT_75 [ii];
		ram_bits ['h76_00+ii]	= INIT_76 [ii];
		ram_bits ['h77_00+ii]	= INIT_77 [ii];
		ram_bits ['h78_00+ii]	= INIT_78 [ii];
		ram_bits ['h79_00+ii]	= INIT_79 [ii];
		ram_bits ['h7A_00+ii]	= INIT_7A [ii];
		ram_bits ['h7B_00+ii]	= INIT_7B [ii];
		ram_bits ['h7C_00+ii]	= INIT_7C [ii];
		ram_bits ['h7D_00+ii]	= INIT_7D [ii];
		ram_bits ['h7E_00+ii]	= INIT_7E [ii];
		ram_bits ['h7F_00+ii]	= INIT_7F [ii];
		
		// Parity Bits.
		par_bits ['h00_00+ii]	= INITP_00 [ii];
		par_bits ['h01_00+ii]	= INITP_01 [ii];
		par_bits ['h02_00+ii]	= INITP_02 [ii];
		par_bits ['h03_00+ii]	= INITP_03 [ii];
		par_bits ['h04_00+ii]	= INITP_04 [ii];
		par_bits ['h05_00+ii]	= INITP_05 [ii];
		par_bits ['h06_00+ii]	= INITP_06 [ii];
		par_bits ['h07_00+ii]	= INITP_07 [ii];
		par_bits ['h08_00+ii]	= INITP_08 [ii];
		par_bits ['h09_00+ii]	= INITP_09 [ii];
		par_bits ['h0A_00+ii]	= INITP_0A [ii];
		par_bits ['h0B_00+ii]	= INITP_0B [ii];
		par_bits ['h0C_00+ii]	= INITP_0C [ii];
		par_bits ['h0D_00+ii]	= INITP_0D [ii];
		par_bits ['h0E_00+ii]	= INITP_0E [ii];
		par_bits ['h0F_00+ii]	= INITP_0F [ii];
	end
end	// Init


endmodule	// RAMB36
