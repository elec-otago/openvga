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

class AsmParse:
	def __init__(self, toks, adInc, addrBits):
		# A final object-code block has all address locations set,
		# but the number of address bits is needed.
		self.abits	= addrBits
		
		self.ts	= toks
		self.incFn	= adInc
	
	def parse(self):
		(cs, self.ts)	= self.buildConsts(self.ts)
		(ls, self.ts)	= self.buildLabels(self.ts)
		self.ts	= self.evalConsts(self.ts, cs)
		self.ts	= self.evalLabels(self.ts, ls)
		self.ts	= self.evalAllArgs(self.ts)
		return	self.ts

	# Performs a sanity check on the incoming string, removing the register
	# portion, discarding the rest.
	def getReg(self, s):
		n	= 0
		if s[0] != 'R':
			raise	Exception("ERROR: Expecting a register.")
		if s[1].isdigit():
			n	= int(s[1])
		if len(s) > 2 and s[2].isdigit():
			n	= n*10 + int(s[2])
		return	'R'+str(n)


	# Evaluate constants, including hexidecimals and mathematical expressions.
	# The Python funtion `eval' can do most the work, but wont work on registers,
	# labels, and memory addresses.
	def evalArgs(self, args, ln):
		outArgs	= []
		prevMem	= False
		mem	= []
		ln	= "Line "+str(ln)+": "
		for a in args:
			a	= a.upper()
			if a[0] == 'R':		# Register
				outArgs.append(self.getReg(a))
				if (prevMem):
					outArgs.append(mem[0])
					outArgs.append(mem[1])
					prevMem	= False;
			elif a[0] == '[':	# Memory address
				if prevMem:
					raise	Exception("ERROR: "+ln+"Multiple memory arguments.")
				# Strip `[]' and evaluate.
				m	= a.strip("[]")
				r	= self.getReg(m)
				c	= m.replace(r, '', 1)
				if len(c) > 0:
					try:
						c	= -eval(c)
					except:
						raise	Exception("ERROR: "+ln+"Invalid constant.")
				else:
					c	= 0
				# Is memory address after the reg arg?
				if len(outArgs) == 1:
					outArgs.append(r)
					outArgs.append(c)
				else:
					prevMem	= True;
					mem	= [r, c]
			else:			# Constants
				try:
					outArgs.append(eval(a))
				except:
						raise	Exception("ERROR: "+ln+"Invalid constant.")
				if prevMem:
					raise	Exception("ERROR: "+ln+"Memory+constant is invalid.")
		return	outArgs


	# Constants have to be removed before labels so that they don't effect
	# address generation.
	# Token format:
	#	[line#, label, op, args]
	# Constant format (in assembly file):
	#	label:	equ	val
	def buildConsts(self, ts):
		ctable	= []
		outTs	= []
		for t in ts:
			if t[2] == 'equ':
				a	= self.evalArgs(t[3], t[0])
				if len(t[1]) > 0 and len(t[3]) == 1:
					ctable.append([t[1], t[3][0]])
				else:
					ln	= "Line "+str(t[0])+": "
					raise	Exception("ERROR: "+ln+"Invalid constant")
			else:
				outTs.append(t)
		return	(ctable, outTs)


	# Scan the arguments replacing constant labels with constant values.
	# Input token format:
	#	[line#, addr#, 'op', ['args'...]]
	# TODO: Add support for bit-selects.
	def evalConsts(self, ts, ctable):
		outTs	= []
		for t in ts:
			if len(t[3]) > 0:
				na	= self.evalConstArgs(t[3], ctable)
				nt	= [t[0], t[1], t[2], na]
				outTs.append(nt)
			else:
				outTs.append(t)
		return	outTs


	def evalConstArgs(self, args, ctable):
		nArgs	= []
		for a in args:
			for c in ctable:
				if self.matchConst(a, c[0]):
					a	= a.replace(c[0], str(c[1]))
			nArgs.append(a)
		return	nArgs


	# Look for a substring `c' within string `a'. If it is found, make sure it is
	# an exact match, ie. `c' is not part of a larger label.
	def matchConst(self, a, c):
		p	= a.find(c)
		if p != -1:
			# Is it an exact match?
			if p > 0:
				if a[p-1].isalpha() or a[p-1].isdigit() or a[p-1] == '_':
					return	False
			if (len(a)-p) > len(c):
				nc	= a[p+len(c)]
				if nc.isalpha() or nc.isdigit() or nc == '_':
					return	False
			return	True
		return	False


	# Build the table of labels and addresses from the tokens.
	def buildLabels(self, ts):
		ltable	= []
		outTs	= []
		ad	= 0
		for t in ts :
			if len(t[1]) > 0 :
				ltable.append([t[1], ad])
			if t[2] != '':
				outTs.append([t[0], ad, t[2], t[3]])
				ad	= self.incFn(ad)
				#ad	+= 1
		return	(ltable, outTs)


	# Replace all instances of labels with the actual address.
	def evalLabels(self, ts, ltable):
		outTs	= []
		for t in ts:
			if len(t[3]) > 0:
				na	= self.evalLabelArgs(t[3], ltable)
				nt	= [t[0], t[1], t[2], na]
				outTs.append(nt)
			else:
				outTs.append(t)
		return	outTs


	def evalLabelArgs(self, args, ctable):
		nArgs	= []
		for a in args:
			for c in ctable:
				if self.matchConst(a, c[0]):
					a	= a.replace(c[0], str(c[1]))
					a	= str(eval(a))
			nArgs.append(a)
		return	nArgs


	def evalAllArgs(self, ts):
		outTs	= []
		for t in ts:
			a	= self.evalArgs(t[3], t[0])
			outTs.append([t[0], t[1], t[2], a])
		return	outTs
	
	
	# Fill all unsued instructions within a block with `nop's.
	def sortAndPad(self, ts):
		outTs	= []
		for i in range(2**self.abits):
			outTs.append([-1, i, 'nop', []])
		
		for t in ts:
			outTs[t[1]]	= t
		
		return	outTs
	
	
#endclass AsmParse
