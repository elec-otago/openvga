/***************************************************************************
 *                                                                         *
 *   data_path_ddr.v - Transports data to/from a DDR SDRAM.                *
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
module ddr_datapath #(
	parameter	CL	= 2,	// TODO
	parameter	WIDTH	= 32,
	parameter	ENABLES	= WIDTH / 8,
	parameter	MSB	= WIDTH - 1,
	parameter	ESB	= ENABLES - 1,
	parameter	DSB	= ENABLES / 2 - 1,
	parameter	QSB	= WIDTH / 2 - 1
) (
	input		clk_i,
	input		clk_ni,
	input		rst_i,		// System clock domain
	
	input		read_i,
	input		write_i,
	output		early_o,
	output	reg	ready_o	= 0,
	input	[ESB:0]	bes_i,
	input	[MSB:0]	data_i,
	output	reg	[MSB:0]	data_o,
	
	output	[DSB:0]	DM_o,
	inout	[QSB:0]	DQ_io
);


reg	read	= 0;
reg	read0	= 0;
reg	read1	= 0;
reg	read2	= 0;
reg	wr_n	= 1;
reg	wr_n0	= 1;
reg	[MSB:0]	data_r;

// wire	[DSB:0]	dm_en	= {write_i | read_i, write_i | read_i};
wire	[QSB:0]	oe_n	= {(WIDTH/2){wr_n}};
// wire	[QSB:0]	rd_en	= {(WIDTH/2){read0}};
// wire	[QSB:0]	rd_en	= {(WIDTH/2){read2}};
wire	[QSB:0]	rd_en	= CL == 3 ? {(WIDTH/2){read2}} : {(WIDTH/2){read0}} ;
wire	[MSB:0]	rd_dat;

reg	[ESB:0]	bes_n	= 4'b1111;
reg	[DSB:0]	dm_rst	= 2'b11;
reg	[DSB:0]	dm_set	= 2'b00;


assign	early_o	= read1;


always @(posedge clk_ni) begin
	dm_rst	<= #2 ~{write_i, write_i};
	dm_set	<= #2 0;
/*	dm_rst	<= #2 {read_i, read_i};
	dm_set	<= #2 ~{write_i | read_i, write_i | read_i};*/
end

always @(posedge clk_ni)
	read2	<= #2 read0;

always @(posedge clk_i)
	bes_n	<= #2 ~bes_i;

always @(posedge clk_i)
	if (rst_i)	wr_n0	<= #2 1;
	else		wr_n0	<= ~write_i;

always @(posedge clk_i)
	if (rst_i)	wr_n	<= #2 1;
	else		wr_n	<= #2 !write_i && wr_n0;

always @(posedge clk_i)
	data_r	<= #2 data_i;

always @(posedge clk_i)
	if (rst_i)	read	<= #2 0;
	else		read	<= #2 read_i;

always @(posedge clk_i)
	{read1, read0}	<= #2 {read0, read};

always @(posedge clk_i)
	if (rst_i)	ready_o	<= #2 0;
	else		ready_o	<= #2 read1;


always @(posedge clk_ni)
	data_o	<= #2 rd_dat;


OFDDRTRSE DM_OFDDR [DSB:0] (
	.C0	(clk_i),
	.C1	(clk_ni),
	.CE	(1'b1),
	.D0	(bes_n [DSB:0]),
	.D1	(bes_n [ESB:ENABLES/2]),
	.O	(DM_o),
	.R	(dm_rst),
	.S	(dm_set),
	.T	(1'b0)
);


OFDDRTRSE DQ_OFDDR [QSB:0] (
	.C0	(clk_i),
	.C1	(clk_ni),
	.CE	(1'b1),
	.D0	(data_i [QSB:0]),
	.D1	(data_r [MSB:WIDTH/2]),
	.O	(DQ_io),
	.R	(1'b0),
	.S	(1'b0),
	.T	(oe_n)
);

IFDDRRSE IFDDR [QSB:0] (
	.C0	(CL == 3 ? clk_i  : clk_ni),
	.C1	(CL == 3 ? clk_ni : clk_i ),
/*	.C0	(clk_ni),
	.C1	(clk_i),*/
	.CE	(rd_en),
	.D	(DQ_io),
	.Q0	(rd_dat [QSB:0]),
	.Q1	(rd_dat [MSB:WIDTH/2]),
	.R	(1'b0),
	.S	(1'b0)
);


endmodule	// ddr_datapath
