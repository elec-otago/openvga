/***************************************************************************
 *                                                                         *
 *   wb_sdram_ctrl.v - This should be able to drive an SDRAM or DDR SDRAM  *
 *     or DDR2 SDRAM low-level controller.                                 *
 *                                                                         *
 *     All reads a bursts of 32-bit words and all writes are single 32-bit *
 *     words.                                                              *
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
module wb_sdram_ctrl #(
	parameter	HIGHZ		= 0,
	parameter	CL		= 2,
	parameter	ADDRESS		= 25,
	parameter	MODEREGVALUES	= CL == 2 ?	14'b0000_0_00_010_0_001 :
							14'b0000_0_00_011_0_001,
	parameter	ASB		= ADDRESS - 1,
	
	// parameter	RFC_PERIOD	= 1560;	// Every 15.625 us at about 100 MHz
	// parameter	RFC_PERIOD	= 780;	// Every 15.625 us at about 50 MHz
	// The following are timings for operation at 50 MHz.
	parameter	RFC_PERIOD	= 520,	// Every 15.625 us at about 33 MHz
	parameter	tRAS		= 3,	// Min. is 42 ns
	parameter	tRC		= 3,	// Min. row cycle time is 60 ns
	parameter	tRP		= 1,	// TODO: Unchecked ATM
	parameter	tRFC		= 3	// Min. refresh command time is 60 ns
) (
	input		sdr_clk_i,	// 100 MHz
	input		wb_clk_i,	// 50 MHz
	input		wb_clk_ni,	// For DDR transfers out of WB domain
	input		wb_rst_i,
	
	input		wb_cyc_i,
	input		wb_stb_i,
	input		wb_we_i,
	output		wb_ack_o,
	output		wb_rty_o,
	output		wb_err_o,
	input	[2:0]	wb_cti_i,
	input	[1:0]	wb_bte_i,
	input	[ASB:0]	wb_adr_i,
	
	input	[3:0]	wb_sel_i,
	input	[31:0]	wb_dat_i,
	output	[3:0]	wb_sel_o,
	output	[31:0]	wb_dat_o,
	
	// SDRAM pins.
	output		CLK,		// synthesis attribute iob of CLK is true ;
	output		CKE,		// synthesis attribute iob of CKE is true ;
	output		CS_n,		// synthesis attribute iob of CS_n is true ;
	output		RAS_n,		// synthesis attribute iob of RAS_n is true ;
	output		CAS_n,		// synthesis attribute iob of CAS_n is true ;
	output		WE_n,		// synthesis attribute iob of WE_n is true ;
	output		[1:0]	BA,	// synthesis attribute iob of BA is true ;
	output		[11:0]	A,	// synthesis attribute iob of A is true ;
	output	[1:0]	DM,		// synthesis attribute iob of DM is true ;
	inout	[15:0]	DQ		// synthesis attribute iob of DQ is true ;
);


reg	wb_ack	= 0;
reg	wb_rty	= 0;

// Initialisation signals.
reg	[19:0]	dramdelay	= 0;
reg	[2:0]	init_count	= 0;
reg	lmr_done	= 0;
reg	dram_stable	= 0;

wire	[19:0]	dramdelay_next;

// Refresh event generation signals.
wire	rfc_req;
wire	refreshing;

// Wait a little bit after a burst read to clear excess `ready's.
reg	read_inhibit	= 0;

reg	actv	= 0;
reg	wb_end	= 0;
reg	rd_one	= 1;
reg	[6:0]	col_adr;
reg	[13:0]	row_adr;
reg	[2:0]	rp_cnt	= 0;
reg	[2:0]	ras_cnt	= 0;

wire	x_boundary;
wire	wr_inhibit;
wire	cmd_rfc, cmd_pre, cmd_lmr, cmd_actv, cmd_rd, cmd_wr;
wire	burst, early;

// Datapath signals.
wire	ready;
wire	[31:0]	rd_dat;
reg	[31:0]	wb_dat;


`define	SDR_INIT	6'b00_0000
`define	SDR_IDLE	6'b00_0001
`define	SDR_ACTV	6'b00_0010
`define	SDR_RD		6'b00_0100
`define	SDR_WR		6'b00_1000
`define	SDR_PRE		6'b01_0000
`define	SDR_RFC		6'b10_0000
reg	[5:0]	state	= `SDR_INIT;

`define	INIT_PRE	3'b001
`define	INIT_RFC	3'b010
`define	INIT_LMR	3'b100

// TODO: Issue RTY when refreshing/initialising?
assign	#2 wb_ack_o	= HIGHZ ? (wb_stb_i ? wb_ack : 'bz) : wb_ack ;
assign	#2 wb_rty_o	= HIGHZ ? (wb_stb_i ? wb_rty : 'bz) : wb_rty ;
assign	#2 wb_err_o	= HIGHZ ? (wb_stb_i ? 0 : 'bz) : 0 ;
assign	#2 wb_sel_o	= HIGHZ ? (wb_stb_i ? 4'b1111 : 'bz) : 4'b1111 ;
assign	#2 wb_dat_o	= HIGHZ ? (wb_stb_i ? wb_dat : 'bz) : wb_dat ;

assign	#2 burst	= (wb_cti_i == 3'b010 && wb_bte_i == 2'b00 && wb_stb_i);
assign	#3 x_boundary	= row_adr != wb_adr_i [20:7];

//---------------------------------------------------------------------------
//  SDRAM Control Pin States.
//
// FIXME: There will be issues when two or more of these signals are asserted
// simultaneously.
assign	#2 cmd_rfc	= ((init_count == `INIT_RFC) || (state == `SDR_IDLE && rfc_req)) && !refreshing;
assign	#2 cmd_pre	= (init_count == `INIT_PRE) || (state == `SDR_PRE && ras_cnt == 0 && rp_cnt == 0);
assign	#2 cmd_rd	= (state == `SDR_RD) && rd_one;
assign	#2 cmd_wr	= (state == `SDR_WR) && rd_one;
assign	#2 cmd_actv	= (state == `SDR_IDLE && wb_stb_i);
assign	#2 cmd_lmr	= (init_count == `INIT_LMR) && !lmr_done && !refreshing;


//---------------------------------------------------------------------------
//  SDRAM State Machine.
//
always @(posedge wb_clk_i)
	if (wb_rst_i) begin
		state		<= #2 `SDR_INIT;
		init_count	<= #2 0;
	end else case (state)
	
	// SDRAM initialisation sequence:
	// 1) Wait for CLK to stabilise
	// 2) Issue PRECHARGE ALL
	// 3) Issue two AUTO REFRESHes
	// 4) LOAD MODE REGISTER
	`SDR_INIT: if (dram_stable) begin
		if (init_count == 0)
			init_count	<= #2 `INIT_PRE;
		else if (rfc_req)
			init_count	<= #2 `INIT_RFC;
		else if (!lmr_done)
			init_count	<= #2 `INIT_LMR;
		else if (!wb_stb_i) begin
			state	<= #2 `SDR_IDLE;
			init_count	<= #2 0;
		end
	end
	
	`SDR_IDLE:
		if (rfc_req)		state	<= #2 `SDR_RFC;
// 		else if (ready)		state	<= #2 state;
		else if (wb_stb_i)	state	<= #2 `SDR_ACTV;
	
	`SDR_ACTV:
		if (wb_end || !(wb_stb_i))
			state	<= #2 `SDR_PRE;
		else if (wb_we_i)
			state	<= #2 `SDR_WR;
		else if (rd_one)
			state	<= #2 `SDR_RD ;
	
	`SDR_RD:
		if (!burst || wb_end)
			state	<= #2 `SDR_ACTV;
	
	`SDR_WR:
		if (!burst || wb_end)
			state	<= #2 `SDR_ACTV;
	
	`SDR_PRE:
		if (cmd_pre)
			state	<= #2 `SDR_IDLE;
	
	`SDR_RFC:
		if (!refreshing)
			state	<= #2 `SDR_IDLE;
	
	endcase


always @(posedge wb_clk_i)
	if (wb_rst_i)
		actv	<= #2 0;
	else if (wb_stb_i && !(wb_ack && !burst) && !wb_rty)
		actv	<= #2 1;
	else
		actv	<= #2 0;

// Make sure just one read is issued when not bursting.
always @(posedge wb_clk_i)
	if (wb_rst_i)
		rd_one	<= #2 0;
	else if (state == `SDR_IDLE)
		rd_one	<= #2 1;
	else if (col_adr == 7'h7f && (cmd_rd || cmd_wr))
		rd_one	<= #2 0;
	else if (wb_ack && !burst)
		rd_one	<= #2 1;
	else if (cmd_rd && !burst)
		rd_one	<= #2 0;

always @(posedge wb_clk_i)
	if (wb_rst_i)
		wb_rty	<= #2 0;
	else if (wb_rty)
		wb_rty	<= #2 0;
	else if (x_boundary && state == `SDR_ACTV && wb_stb_i)
		wb_rty	<= #2 1;
	else
		wb_rty	<= #2 state == `SDR_INIT && wb_stb_i;


wire	#2 wb_ack_w	=  (state == `SDR_ACTV && wb_we_i)
			|| (state == `SDR_WR && burst)
			|| (!read_inhibit && early);
always @(posedge wb_clk_i)
	if (wb_rst_i)
		wb_ack	<= #2 0;
	else if (!wb_stb_i)
		wb_ack	<= #2 0;
	else if (x_boundary)
		wb_ack	<= #2 0;
	else if (wb_ack && !burst)
		wb_ack	<= #2 0;
	else
		wb_ack	<= #2 wb_ack_w;


always @(posedge wb_clk_i)
	if (wb_rst_i)
		wb_end	<= #2 0;
	else if (state == `SDR_IDLE)
		wb_end	<= #2 0;
	else if (!wb_stb_i || x_boundary)
		wb_end	<= #2 1;

// Loads the MODE REGISTER upon initialisation.
always @(posedge wb_clk_i)
	if (wb_rst_i)
		lmr_done	<= #2 0;
	else if (cmd_lmr)
		lmr_done	<= #2 1;


always @(posedge wb_clk_i)
	if (state == `SDR_IDLE && wb_stb_i)
		{row_adr, col_adr}	<= #2 wb_adr_i [20:0];
	else if ((cmd_wr || cmd_rd) && burst)
		col_adr	<= #2 col_adr + 1;
	else if (wb_stb_i && !wb_ack)
		col_adr	<= #2 wb_adr_i [6:0];


reg	[1:0]	ba;
reg	[11:0]	a;
always @(cmd_pre, cmd_lmr, cmd_actv, wb_adr_i, col_adr)
	if (cmd_pre)
		{ba, a}	<= #2 {2'b00, 4'b0100, col_adr, 1'b0};
	else if (cmd_lmr)
		{ba, a}	<= #2 MODEREGVALUES;
	else if (cmd_actv)
		{ba, a}	<= #2 wb_adr_i [20:7];
	else
		{ba, a}	<= #2 {2'b00, 4'b0, col_adr, 1'b0};


// One of Roy's ultra-fast Fibonacci counters is used to delay 100 us.
always @(posedge wb_clk_i)
	if (wb_rst_i)
		dramdelay	<= #2 0;
`ifdef __icarus
	else if (!dramdelay [6])
`else
	else if (!dramdelay [19])
`endif
		dramdelay	<= #2 dramdelay_next;


always @(posedge wb_clk_i)
	if (wb_rst_i)
		dram_stable	<= #2 0;
`ifndef __icarus
	else if (!dram_stable && dramdelay [19])
`else
	else if (!dram_stable && dramdelay [6])
`endif
		dram_stable	<= #2 1;


always @(posedge wb_clk_i)
	wb_dat	<= #2 rd_dat;


always @(posedge wb_clk_i)
	if (wb_rst_i)
		rp_cnt	<= #2 0;
	else if (cmd_pre)
		rp_cnt	<= #2 tRC - 2;
	else if (rp_cnt != 0)
		rp_cnt	<= #2 rp_cnt - 1;


always @(posedge wb_clk_i)
	if (wb_rst_i)
		ras_cnt	<= #2 0;
	else if (cmd_actv)
		ras_cnt	<= #2 tRAS - 1;
	else if (ras_cnt != 0)
		ras_cnt	<= #2 ras_cnt - 1;


always @(posedge wb_clk_i)
	if (wb_rst_i)
		read_inhibit	<= #2 0;
	else if (wb_cti_i == 3'b111)
		read_inhibit	<= #2 1;
	else if (!ready)
		read_inhibit	<= #2 0;


// Set the control pins driving the SDRAM IC.
`define	CMD_INHIBIT	4'b1111
`define	CMD_NOP		4'b0111
`define	CMD_ACTIVE	4'b0011
`define	CMD_READ	4'b0101
`define	CMD_WRITE	4'b0100
`define	CMD_TERMINATE	4'b0110
`define	CMD_PRECHARGE	4'b0010
`define	CMD_REFRESH	4'b0001
`define	CMD_LOADMODE	4'b0000

OFDDRTRSE CLK_OFDDR (
	.D0	(1'b0),
	.D1	(1'b1),
	.CE	(1'b1),
	.C0	(sdr_clk_i),
	.C1	(~sdr_clk_i),
	.O	(CLK),
	.T	(1'b0),
	.R	(wb_rst_i),
	.S	(1'b0)
);

`ifdef __icarus
wire	#2 cke	= dramdelay [5] | dramdelay [6];
`else
wire	#2 cke	= dramdelay [18] | dramdelay [19];
`endif
OFDDRTRSE CKE_OFDDR (
	.D0	(cke),
	.D1	(cke),
	.CE	(1'b1),
	.C0	(sdr_clk_i),	// Required due to PCB messup
	.C1	(~sdr_clk_i),
	.O	(CKE),
	.T	(1'b0),
	.R	(wb_rst_i),
	.S	(1'b0)
);

OFDDRTRSE CS_OFDDR (
	.D0	(1'b1),
	.D1	(1'b1),
	.CE	(1'b1),
	.C0	(wb_clk_i),
	.C1	(wb_clk_ni),
	.O	(CS_n),
	.T	(1'b0),
	.R	(cke),
	.S	(wb_rst_i)
);

wire	#2 ras_n	= !(cmd_actv || cmd_pre || cmd_rfc || cmd_lmr);
OFDDRTRSE RAS_OFDDR (
	.D0	(ras_n),
	.D1	(1'b1),
	.CE	(1'b1),
	.C0	(wb_clk_i),
	.C1	(wb_clk_ni),
	.O	(RAS_n),
	.T	(1'b0),
	.R	(1'b0),
	.S	(wb_rst_i)
);

wire	#2 cas_n	= !(cmd_rd || cmd_wr || cmd_rfc || cmd_lmr);
OFDDRTRSE CAS_OFDDR (
	.D0	(cas_n),
	.D1	(1'b1),
	.CE	(1'b1),
	.C0	(wb_clk_i),
	.C1	(wb_clk_ni),
	.O	(CAS_n),
	.T	(1'b0),
	.R	(1'b0),
	.S	(wb_rst_i)
);

wire	#2 we_n		= !(cmd_wr || cmd_pre || cmd_lmr);
OFDDRTRSE WE_OFDDR (
	.D0	(we_n),
	.D1	(1'b1),
	.CE	(1'b1),
	.C0	(wb_clk_i),
	.C1	(wb_clk_ni),
	.O	(WE_n),
	.T	(1'b0),
	.R	(1'b0),
	.S	(wb_rst_i)
);


wire	[13:0]	sdr_adr	= {ba, a};
OFDDRTRSE A_FDDR [13:0] (
	.D0	(sdr_adr),
	.D1	(sdr_adr),
	.CE	(1'b1),
	.C0	(wb_clk_i),
	.C1	(wb_clk_ni),
	.O	({BA, A}),
	.T	(1'b0),
	.R	(1'b0),
	.S	(1'b0)
);


ddr_datapath #(
	.WIDTH	(32),
	.CL	(CL)
) DP0 (
	.clk_i	(wb_clk_i),
	.clk_ni	(wb_clk_ni),
	.rst_i	(wb_rst_i),
	
	.read_i	(cmd_rd),
	.write_i(cmd_wr),
	.early_o(early),
	.ready_o(ready),
	.bes_i	(wb_sel_i),
	.data_i	(wb_dat_i),
	.data_o	(rd_dat),
	
	.DM_o	(DM),
	.DQ_io	(DQ)
);


rfc #(
	.INIT		(1),	// Causes two refreshes to be issued on reset
	.RFC_TIMER	(RFC_PERIOD),
	.TIMER_BITS	(10),
	.tRFC		(tRFC)
) RFC0 (
	.clk_i	(wb_clk_i),
	.rst_i	(wb_rst_i),
	.en_i	(1'b1),
	.req_o	(rfc_req),
	.gnt_i	(cmd_rfc),
	.rfc_o	(refreshing)
);


fib20 COUNT0 (
	.count_i	(dramdelay),
	.count_o	(dramdelay_next)
);


endmodule	// wb_sdram_ctrl
