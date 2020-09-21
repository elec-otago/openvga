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
	
	if len(argv) == 4 :
		if argv[2] == '-v' :
			in_file = open(argv[1], 'r')
			out_file = open(argv[3], 'w')
			mode = 'verilog'
		
	elif len(argv) < 3 :
		print "USAGE:"
		print "    bmp2font font_file.raw font_file.txt"
		sys.exit(1)
	
	else :
		in_file = open(argv[1], 'r')
		out_file = open(argv[2], 'w')
		mode = 'hexdump'
	
	font = []
	
	if mode == 'hexdump' :
		# only outputting half of the data in a dump because the font block is split in two
		count = 0
		word = in_file.read(4)
		while len(word) == 4  and count < 512:
			hex_word = hex( (long(ord(word[0])) << 24) |
				(long(ord(word[1])) << 16) | (long(ord(word[2])) << 8) | long(ord(word[3])))
			hex_word = hex_word.lstrip('0x')
			hex_word = hex_word.rstrip('L')
			hex_word = hex_word.rjust(8)
			hex_word = hex_word.replace(' ', '0')
			hex_word += ' '
			
			out_file.write(hex_word)
			word = in_file.read(4)
			
			count += 1
		# endwhile
		
	elif mode == 'verilog' :
		count = 0
		word = in_file.read(32)
		while len(word) == 32:
			
			hex_string = ''
			
			for ii in range(32) :
				hex_word = hex(ord(word[ii]))
				hex_word = hex_word.lstrip('0x')
				hex_word = hex_word.rjust(2)
				hex_word = hex_word.replace(' ', '0')
				hex_string += hex_word
			# endfor
			
			#### NEW ####
# 			hex_string = hex_string[32:64] + hex_string[0:32]
			
			new_string1 = ''
			new_string2 = ''
			for a in range(32) :
				new_string1 += hex_string[31 - a]
				new_string2 += hex_string[63 - a]
			# endfor
			
			hex_string = new_string2 + new_string1
			
			# Possible chars: 012345678abcdef
			# Chars that do need flipping:
			#   1234578abce
			new_string = ''
			for char in hex_string :
				if char == '1' :
					new_string += '8'
				elif char == '2' :
					new_string += '4'
				elif char == '3' :
					new_string += 'c'
				elif char == '4' :
					new_string += '2'
				elif char == '5' :
					new_string += 'a'
				elif char == '7' :
					new_string += 'e'
				elif char == '8' :
					new_string += '1'
				elif char == 'a' :
					new_string += '5'
				elif char == 'b' :
					new_string += 'd'
				elif char == 'c' :
					new_string += '3'
				elif char == 'd' :
					new_string += 'b'
				elif char == 'e' :
					new_string += '7'
				else :
					new_string += char
			# endfor
			
			hex_string = new_string
			
			#### END NEW ####
			
			init_num_string = '.INIT_' + hex(count & 0x03F).lstrip('0x').rjust(2).replace(' ', '0').upper()
			out_string = chr(9) + 'defparam font_cache' + str(count >> 6) + init_num_string + " = 256'h" + hex_string + ";\n"
			out_file.write(out_string)
			
			word = in_file.read(32)
			count += 1
			
		# endwhile
		
	else :
		print "INTERNAL ERROR: Shouldn't be able to see this"
		
	# endif
	
	in_file.close()
	out_file.close()
	
# end main


if __name__ == "__main__" :
	main(sys.argv)
