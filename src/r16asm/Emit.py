############################################################################
#    Copyright (C) 2005 by Patrick Suggate                                 #
#    patrick@physics.otago.ac.nz                                           #
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

class Emit:
	def __init__(self, debug=False):
		self.debug	= debug
		self.op_dict = {'subi':0x4, 'subic':0x5,
				'incc':0x5, 'decc':0x5, 'inc':0x4, 'dec':0x4,
				'lw':0x8, 'lw.d':0x8, 'lw.s':0x9,
				'sw':0xa, 'sw.d':0xa, 'sw.s':0xb
				}
		self.rri1	= ['dec', 'inc', 'decc', 'incc']
		
		# TODO: I doubt all these conditions work correctly.
		self.jx_dict = {"jnz":0, "jz":1, "jl":2, "jg":3,
				"jb":4, "jbe":5, "ja":6, "jae":7,
				"jne":0, "je":1, "jnb":7
				}
		
		self.rr	= 0x0000
		self.ri	= 0x2000
		self.jx	= 0xC000
		self.i12= 0xE000
		
		# Nemonics.
		# A full 16-bit instruction.
		self.nm_dict	= {'ret':0x0f0a, 'nop':0x0000}
		
		# Bits:
		#	0	- CR
		#	1-3	- FN
		#	4	- SF
		self.fn_dict = {'sub':0x01, 'subc':0x11, 'cmp':0x10,
				'neg':0x01, 'negc':0x11,
				'sbb':0x03, 'sbbc':0x13, 'cmpb':0x12,
				'mull':0x05, 'mulh':0x15,
				'msr.d':0x06, 'msr.s':0x16,
				'and':0x09, 'andc':0x19, 'test':0x18,
				'br':0x0a, 'brl':0x0b,
				'or':0x0d, 'orc':0x1d,
				'xor':0x0f, 'xorc':0x1f, 'not':0x0f, 'notc':0x1f
				}
		self.ri1	= ['neg', 'negc', 'br', 'not', 'notc']	# TODO
		self.rr1	= ['br']
	#enddef
	
	
	def aluOp(self, fn, t):
		if len(t[3]) == 2 and type(t[3][1]) == int and t[3][0][0] == 'R':
			# RI
			r	= int(t[3][0][1:])
			i	= t[3][1]
			#         OP      | SF             | RD     | FN          | IMM4
			instr	= self.ri | ((fn&0x10)<<8) | (r<<8) | ((fn&0xf)<<4) | (i&0xf)
		elif len(t[3]) == 2 and t[3][1][0] == 'R' and t[3][0][0] == 'R':
			# RR
			rd	= int(t[3][0][1:])
			rs	= int(t[3][1][1:])
			#         OP      | SF             | RD      | RS      | FN
			instr	= self.rr | ((fn&0x10)<<8) | (rd<<8) | (rs<<4) | (fn&0xf)
		elif len(t[3]) == 1:
			# RI (br)
			r	= int(t[3][0][1:])
			#         OP      | SF             | RD     | FN
			instr	= self.ri | ((fn&0x10)<<8) | (r<<8) | ((fn&0xf)<<4)
		else:
			print	t
			ln	= str(t[0])+": "
			raise	Exception("ERROR: "+ln+"Unrecognised instruction.")
		
		return	instr
	
	
	def braOp(self, t):
		if t[2] in self.jx_dict:
			instr	= self.jx | (self.jx_dict[t[2]]<<10) | (t[3][0]&0x03ff)
			return	instr
		ln	= str(t[0])+": "
		raise	Exception("ERROR: "+ln+"Unrecognised instruction.")
	
	
	def rriOp(self, op, t):
		if len(t[3]) == 1 and t[2] in self.rri1:
			rd	= int(t[3][0][1:])
			rs	= int(t[3][0][1:])
			if t[2] == 'dec' or t[2] == 'decc':
				i	= 1
			elif t[2] == 'inc' or t[2] == 'incc':
				i	= -1
			else:
				raise	Exception("ERROR: "+ln+"Not an `inc' or `dec'.")
		elif len(t[3]) == 3 and not (t[2] in self.rri1):
			# RRI
			rd	= int(t[3][0][1:])
			rs	= int(t[3][1][1:])
			i	= t[3][2]
		else:
			print	t
			ln	= str(t[0])+": "
			raise	Exception("ERROR: "+ln+"Unrecognised instruction.")
		#         OP       | RD      | RS      | IMM4
		instr	= (op<<12) | (rd<<8) | (rs<<4) | (i&0xf)
		return	instr
	
	
	def emitLine(self, t, fo):
		if t[2] == 'i12':
			instr	= self.i12 | (t[3][0]&0x0fff)
		elif t[2] in self.op_dict:
			instr	= self.rriOp(self.op_dict[t[2]], t)
		elif t[2] in self.fn_dict:
			instr	= self.aluOp(self.fn_dict[t[2]], t)
		elif t[2] in self.nm_dict:
			instr	= self.nm_dict[t[2]]
		else:
			instr	= self.braOp(t)
		
		fo.write('%03X:%04X\n' % (t[1], instr))
		if self.debug:
			st	= '%03X:%04X\t%s' % (t[1], instr, t[2])
			print	st
	
	
	def emit(self, ts, fo):
		for t in ts:
			self.emitLine(t, fo)
	#end emit

#endclass Emit
