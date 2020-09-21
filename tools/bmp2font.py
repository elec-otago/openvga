#!/usr/bin/env python
############################################################################
#                                                                          #
#    bmp2font.py - Converts a greyscale windows 128x256 .bmp file into a   #
#      raw font file that can be loaded by a verilog simulation.           #
#                                                                          #
#    Copyright (C) 2005 by patrick                                         #
#    patrick@Slappy                                                        #
#                                                                          #
#    This program is free software; you can redistribute it and#or modify  #
#    it under the terms of the GNU General Public License as published by  #
#    the Free Software Foundation; either version 2 of the License, or     #
#    (at your option) any later version.                                   #
#                                                                          #
#    This program is distributed in the hope that it will be useful,       #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#    GNU General Public License for more details.                          #
#                                                                          #
#    You should have received a copy of the GNU General Public License     #
#    along with this program; if not, write to the                         #
#    Free Software Foundation, Inc.,                                       #
#    59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
############################################################################

import sys

#---------------------------------------------------------------------

def main(argv) :
	
	if len(argv) < 3 :
		print "USAGE:"
		print "    bmp2font font_file.bmp font_file.raw"
	
	in_file = open(argv[1], 'r')
	out_file = open(argv[2], 'w')
	
	header = in_file.read(1078)
	
	font = []
	
	# BMPs are in reverse row order. (0,0) at bottom left
	row = in_file.read(128)
	while len(row) == 128 :
		index = 0
		pixelRow = ''
		for ii in range(16) :
			pixels = 0
			for jj in range(8) :
				pixels <<= 1
				if ord(row[index]) > 127 :	# White
					pixels |= 1
				# endif
				index += 1
			# endfor
			pixelRow += chr(pixels)
		# endfor
		font.append(pixelRow)
		row = in_file.read(128)
	# endwhile
	
	for ii in range(15,-1,-1) :
		for jj in range(16) :
			for kk in range(15,-1,-1) :
				out_file.write(font[ii * 16 + kk][jj])
	
	# endfor
	
	in_file.close()
	out_file.close()
	
# end main


if __name__ == "__main__" :
	main(sys.argv)
