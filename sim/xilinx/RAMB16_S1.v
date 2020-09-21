/***************************************************************************
 *                                                                         *
 *   RAMB16_S1.v - Simulates the Xilinx primitive of the same name for use *
 *     with Icarus Verilog.                                                *
 *                                                                         *
 *   Copyright (C) 2005 by Patrick Suggate                                 *
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

module RAMB16_S1(
		DI, ADDR, EN, WE, SSR, CLK, DO
	);
	
	input	DI;
	input	[13:0]	ADDR;
	input	EN;
	input	WE;
	input	SSR;
	input	CLK;
	output	reg	DO;
	
	reg		[31:0]	ram_block_16k[511:0];
	
	
	//	These parameters allow the block RAM to have values upon initialisation
	parameter	INIT_00 	= 256'h0;
	parameter	INIT_01 	= 256'h0;
	parameter	INIT_02 	= 256'h0;
	parameter	INIT_03 	= 256'h0;
	parameter	INIT_04 	= 256'h0;
	parameter	INIT_05 	= 256'h0;
	parameter	INIT_06 	= 256'h0;
	parameter	INIT_07 	= 256'h0;
	parameter	INIT_08 	= 256'h0;
	parameter	INIT_09 	= 256'h0;
	parameter	INIT_0A 	= 256'h0;
	parameter	INIT_0B 	= 256'h0;
	parameter	INIT_0C 	= 256'h0;
	parameter	INIT_0D 	= 256'h0;
	parameter	INIT_0E 	= 256'h0;
	parameter	INIT_0F 	= 256'h0;
	parameter	INIT_10 	= 256'h0;
	parameter	INIT_11 	= 256'h0;
	parameter	INIT_12 	= 256'h0;
	parameter	INIT_13 	= 256'h0;
	parameter	INIT_14 	= 256'h0;
	parameter	INIT_15 	= 256'h0;
	parameter	INIT_16 	= 256'h0;
	parameter	INIT_17 	= 256'h0;
	parameter	INIT_18 	= 256'h0;
	parameter	INIT_19 	= 256'h0;
	parameter	INIT_1A 	= 256'h0;
	parameter	INIT_1B 	= 256'h0;
	parameter	INIT_1C 	= 256'h0;
	parameter	INIT_1D 	= 256'h0;
	parameter	INIT_1E 	= 256'h0;
	parameter	INIT_1F 	= 256'h0;
	parameter	INIT_20 	= 256'h0;
	parameter	INIT_21 	= 256'h0;
	parameter	INIT_22 	= 256'h0;
	parameter	INIT_23 	= 256'h0;
	parameter	INIT_24 	= 256'h0;
	parameter	INIT_25 	= 256'h0;
	parameter	INIT_26 	= 256'h0;
	parameter	INIT_27 	= 256'h0;
	parameter	INIT_28 	= 256'h0;
	parameter	INIT_29 	= 256'h0;
	parameter	INIT_2A 	= 256'h0;
	parameter	INIT_2B 	= 256'h0;
	parameter	INIT_2C 	= 256'h0;
	parameter	INIT_2D 	= 256'h0;
	parameter	INIT_2E 	= 256'h0;
	parameter	INIT_2F 	= 256'h0;
	parameter	INIT_30 	= 256'h0;
	parameter	INIT_31 	= 256'h0;
	parameter	INIT_32 	= 256'h0;
	parameter	INIT_33 	= 256'h0;
	parameter	INIT_34 	= 256'h0;
	parameter	INIT_35 	= 256'h0;
	parameter	INIT_36 	= 256'h0;
	parameter	INIT_37 	= 256'h0;
	parameter	INIT_38 	= 256'h0;
	parameter	INIT_39 	= 256'h0;
	parameter	INIT_3A 	= 256'h0;
	parameter	INIT_3B 	= 256'h0;
	parameter	INIT_3C		= 256'h0;
	parameter	INIT_3D 	= 256'h0;
	parameter	INIT_3E 	= 256'h0;
	parameter	INIT_3F 	= 256'h0;
	
	
	//	States for the state machine
	parameter	ST_IDLE		= 3'b0xx;
	parameter	ST_READ		= 3'b100;
	parameter	ST_WRITE	= 3'b110;
	parameter	ST_RESET	= 3'b1x1;
	
	
	always @(posedge CLK)
	begin
		case ({EN, WE, SSR})
		ST_READ:
			DO <= #8 get_bit(ram_block_16k[ADDR[13:5]], ADDR[4:0]);
			
		ST_WRITE:
			ram_block_16k[ADDR[13:5]] <= #8 set_bit(ram_block_16k[ADDR[13:5]], ADDR[4:0], DI);
			
		ST_RESET:;
			
		default:;
		endcase
	end
	
	
	//	Outputs the bit at position 'bit_num' from 'word'
	function get_bit;
		input	[31:0]	word;
		input	[4:0]	bit_num;
		
		begin
			get_bit = word[31 - bit_num];
		end
		
	endfunction	//	get_bit
	
	
	function [31:0]	set_bit;
		input	[31:0]	word;
		input	[4:0]	bit_num;
		input	bit;
		
		integer	mask;
		begin
			mask = 32'b1 << (31 - bit_num);
			if (bit)
				set_bit = word | mask;
			else
				set_bit = word & ~mask;
		end
	endfunction
	
	
//--------------------------------------------------------------
//	Simulation stuff below
//
	integer	ii, jj;
	
	initial begin : Init
		//	Assign a random 'font'
		fill_ram_block_16k(3);
		
/*		#11000
		$display;
		for (ii = 0; ii < 512; ii = ii + 1)
			$display("%b", ram_block_16k[ii]);
			
		$display;
		for (ii = 0; ii < 16; ii = ii + 1)
		begin
			for (jj = 0; jj < 8; jj = jj + 1)
				$write("%1b", get_bit(ram_block_16k[{9'd364 + ii[11:2]}], {ii[1:0], jj[2:0]}));
			$display;
		end
		
		#10
		$finish;*/
		
	end	//	Init
	
	
	//	Used to initialise the 'ram_block_16k' for a test bench
	task fill_ram_block_16k;
		input	mode;
		integer	n, mode;
	
	begin : Fill_Ram_Block_16k
		
		for (n = 0; n < 512; n = n+1)
		begin
			case (mode)
				0:	ram_block_16k[n] = 32'h0000_0000;
				1:	ram_block_16k[n] = $random;
				2:	ram_block_16k[n] = 32'h3030_3030;
				3:;
			endcase
		end
		
		if (mode == 3)
			$readmemh("/home/patrick/cvs/spartacus/data/font.txt", ram_block_16k, 0, 511);
			
	end	//	Fill_Ram_Block_16k
	endtask	//	fill_ram_block_16k
	
	
endmodule	//	RAMB16_S1
