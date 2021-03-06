/***************************************************************************
 *                                                                         *
 *   MFSR10.v - One of Roy Ward's ultra tricky Multiple Feed-back Shift    *
 *     Registers (MFSR). This one is 10-bits wide.                         *
 *                                                                         *
 *   Copyright (C) 2006 by Patrick Suggate and Roy Ward                    *
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
module	mfsr10 (
		count_i,
		count_o
	);
	
	input	[9:0]	count_i;
	output	[9:0]	count_o;
	
	assign	#1 count_o	= {count_i[8:1], count_i[0]^count_i[3], count_i[9]};
	
endmodule	//	mfsr10
