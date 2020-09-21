#!/usr/bin/env python
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


import	sys
from	CodeCleaner	import CodeCleaner
from	AsmParse	import AsmParse
from	Emit		import Emit


def tokenise(lineList):
	# Format:
	#	[label:]	op	[args]
	# Output:
	#	[[line#, 'label', 'op', [args]]]
	tokens	= []
	for l in lineList:
		(label, sep, tail)	= l[1].partition(":")
		if sep == '':
			tail	= label
			label	= ''
		tail	= tail.split()
		if len(tail) > 0 :
			op	= tail.pop(0)
			if len(tail) > 0 :
				args	= ''.join(tail).split(",")
			else:
				args	= []
		else:
			op	= ''
			args	= []
		tokens.append([l[0], label, op, args])
	return	tokens


#def mfsr10(prev):
	#return	prev+3;


# TODO: Using `numarray's or similar, and Roy's matrix method could be a good
# optimisation.
def mfsr10(prev):
	if prev == 0:
		return	1
	u8	= (prev&0x1fe)<<1;
	b1	= ((prev^(prev>>3))&1)<<1
	b0	= (prev>>9)&1
	return	u8 | b1 | b0


# Operation: Pull out arguments until just the filename of the input file is
# left, if no output file ws specified, guess it from the input file.
# Arguments:
# input_file
# -o output_file
# --debug
def getFnames(args):
	if len(args) < 2 :
		raise	Exception("You are a moron")
	args.pop(0)
	for i in range(len(args)-1):
		if args[i] == '-o':
			outfile	= args[i+1]
			args.pop(i)
			args.pop(i)
			break
	else:
		outfile	= None
	
	for i in range(len(args)):
		if args[i] == '--debug':
			debug	= True
			args.pop(i)
			break
	else:
		debug	= False
	
	if outfile == None:
		outfile	= args[0].split('.')[0] + '.out'
	
	return	[args[0], outfile, debug]


def main(args):
	print	"r16asm.py - RISC16 Assembler, copyright 2009 Patrick Suggate\n"
	try:
		fnames	= getFnames(args)
		fi	= open(fnames[0], "r")
		fo	= open(fnames[1], "w")
	except:
		print	"\tUSAGE:\tr16asm.py [--debug] file.in [-o file.out]\n"
		print
		return	-1
	
	asm	= CodeCleaner().clean(fi)
	ts	= tokenise(asm)
	asmParser	= AsmParse(ts, mfsr10, 10)
	ts	= asmParser.parse()
	if fnames[2]:
		for	t in ts:	print	t
	nts	= asmParser.sortAndPad(ts)
	
	asmEmitter	= Emit()
	#asmEmitter	= Emit(fnames[2])
	txt	= asmEmitter.emit(nts, fo)
	
	return	0

if __name__ == "__main__" :
	sys.exit(main(sys.argv))
