/***************************************************************************
 *                                                                         *
 *   wb_pci_top.v - A module that connects a block of memory to the PCI    *
 *     Local Bus. The memory can work at different frequencies due to the  *
 *     use of asynchronous FIFOs.                                          *
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
module wb_pci_top #(
`ifdef __icarus
	parameter	ADDRESS	= 10,	// 4kB
`else
	parameter	ADDRESS	= 21,	// 8MB
`endif
	parameter	HIGHZ	= 0,
	parameter	ASB	= ADDRESS - 1
) (
	input		pci_clk_i,
	input		pci_rst_ni,
	input		pci_frame_ni,
	output		pci_devsel_no,
	input		pci_irdy_ni,
	output		pci_trdy_no,
	input		pci_idsel_i,
	input	[3:0]	pci_cbe_ni,
	inout	[31:0]	pci_ad_io,
	output		pci_stop_no,
	inout		pci_par_io,
	output		pci_inta_no,
	output		pci_req_no,
	input		pci_gnt_ni,
	
	input		enable_i,
	output		pci_disable_o,
	output		enabled_o,
	
	input		wb_clk_i,	// Wishbone Master
	input		wb_rst_i,
	
	input		wb_cyc_i,
	output		wb_cyc_o,
	output		wb_stb_o,
	output		wb_we_o,
	input		wb_ack_i,
	input		wb_rty_i,
	input		wb_err_i,
	output	[2:0]	wb_cti_o,
	output	[1:0]	wb_bte_o,
	output	[ASB:0]	wb_adr_o,
	
	input	[3:0]	wb_sel_i,
	input	[31:0]	wb_dat_i,
	output	[3:0]	wb_sel_o,
	output	[31:0]	wb_dat_o
);


// CFG space wires.
wire	cfg_devsel_n, cfg_trdy_n;
wire	cfg_act, cfg_sel;
wire	[31:0]	cfg_data;

wire	[(32-ADDRESS-3):0]	mm_ad;
wire	mm_en;

// Mem to PCI signals.
wire	mem_devsel_n, mem_trdy_n, mem_stop_n;
wire	mem_act, mem_sel;
wire	[31:0]	mem_data;

wire	[31:0]	data_out;

wire	burst;


assign	enabled_o	= mm_en;
assign	pci_disable_o	= ~enable_i;

// TODO: This MUXing causes quite long combinational delays.
assign	#2 data_out	= cfg_act ? cfg_data : mem_data;
assign	#2 pci_ad_io	= (cfg_act || mem_act) ? data_out : 'bz;
assign	#2 pci_devsel_no	= (cfg_sel || mem_sel) ? (cfg_devsel_n & mem_devsel_n) : 'bz;
assign	#2 pci_trdy_no	= (cfg_sel || mem_sel) ? (cfg_trdy_n & mem_trdy_n) : 'bz;
assign	#2 pci_stop_no	= mem_sel ? mem_stop_n : 'bz;

// These are unused ATM.
// assign	pci_stop_no	= 1'b1;
assign	pci_req_no	= 1'b1;
assign	pci_inta_no	= 1'b1;
assign	pci_par_io	= 1'bz;


// Allocates the memory-mapped regions on system boot-up.
cfgspace #(
	.ADDRESS	(ADDRESS+2)
) CFG0 (
	.pci_clk_i	(pci_clk_i),
	.pci_rst_ni	(pci_rst_ni),
	
	.pci_frame_ni	(pci_frame_ni),
	.pci_devsel_no	(cfg_devsel_n),
	.pci_irdy_ni	(pci_irdy_ni),
	.pci_trdy_no	(cfg_trdy_n),
	
	.pci_cbe_ni	(pci_cbe_ni),
	.pci_ad_i	(pci_ad_io),
	.pci_ad_o	(cfg_data),
	
	.pci_idsel_i	(pci_idsel_i),
	
	.active_o	(cfg_act),
	.selected_o	(cfg_sel),
	.memen_o	(mm_en),
	.addr_o		(mm_ad)
);


// wb_pci_snoop #(
wb_new_pci_mem #(
	.ADDRESS	(ADDRESS),
	.HIGHZ		(HIGHZ)
) PCIMEM0 (
	.pci_clk_i	(pci_clk_i),
	.pci_rst_ni	(pci_rst_ni),
	
	.pci_frame_ni	(pci_frame_ni),
	.pci_devsel_no	(mem_devsel_n),
	.pci_irdy_ni	(pci_irdy_ni),
	.pci_trdy_no	(mem_trdy_n),
	.pci_stop_no	(mem_stop_n),
	.pci_cbe_ni	(pci_cbe_ni),
	.pci_ad_i	(pci_ad_io),
	.pci_ad_o	(mem_data),
	
	.active_o	(mem_act),
	.selected_o	(mem_sel),
	
	.mm_enable_i	(mm_en),
	.mm_addr_i	(mm_ad),	// 4kB aligned
	
	.bursting_o	(burst),
	
	.wb_clk_i	(wb_clk_i),
	.wb_rst_i	(wb_rst_i),
	.wb_cyc_o	(wb_cyc_o),
	.wb_stb_o	(wb_stb_o),
	.wb_we_o	(wb_we_o),
	.wb_ack_i	(wb_ack_i),
	.wb_rty_i	(wb_rty_i),
	.wb_err_i	(wb_err_i),
	.wb_cti_o	(wb_cti_o),
	.wb_bte_o	(wb_bte_o),
	.wb_adr_o	(wb_adr_o),
	.wb_sel_i	(wb_sel_i),
	.wb_dat_i	(wb_dat_i),
	.wb_sel_o	(wb_sel_o),
	.wb_dat_o	(wb_dat_o)
);


endmodule	// wb_pci_top
