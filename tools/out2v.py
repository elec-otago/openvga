#!/usr/bin/env python
#
#  out2v.py - Reads an output file of Roys assembler and converts it to the
#    parameter format needed for including within a Xilinx RAMB16 parameter
#    field of a module instantiation.
#    
#    Options:
#    	-n <num>	- Number of columns
#    	-s <idx>	- Select the column to output [1->(n-1)]
#    	-v		- Verbose.
#    
#    Example:
#    	out2v.py -n 2 -s 0 test.out tta_asm0.v
#    	out2v.py -n 2 -s 1 test.out tta_asm1.v
#
# TODO: Parity info.
#
import sys

cols	= 4
sel	= -1	# All
mode	= 'normal'

if sys.argv[1] == '-n':
	cols	= int(sys.argv[2])
	del sys.argv[1:3]

if sys.argv[1] == '-s':
	sel	= int(sys.argv[2])
	del sys.argv[1:3]

if sys.argv[1] == '-v':
	mode	= 'verbose'
	del sys.argv[1]

if len (sys.argv) < 3 :
	sys.stderr.write ("USAGE: out2v [options] <file.out> <file.v>\n")
	sys.exit (1)

fi	= open (sys.argv [1], "r")
fo	= open (sys.argv [2], "w")

# Read in data
tline	= fi.readline ()
hdata	= []
while tline != '' :
	tline	= tline.split (":")[1].strip()
	hline	= []
	mult	= len (tline) / cols
	
	# Little endian
	for i in range ((cols-1)*mult, -1, -mult) :
		hline.append (tline [i:i+mult])
	
	hdata.append (hline)
	tline = fi.readline ()

fi.close ()

# Perform 2D array transpose
ndata	= []
for i in range (0, len (hdata [0])) :
	ndata.append ([])
	for j in range (0, len (hdata)) :
		ndata[i].append (hdata[j][i])

if mode=='verbose':
	print	ndata

def vdump(fh, dat):
	ln	= 0
	while len(dat) > 0:
		so	= "\t.INIT_" + hex(ln)[2:].rjust(2,'0').upper() + "\t(256'h"
		grab	= len(dat)
		lim	= 64/len(dat[0])-1
		if grab > lim:
			grab	= lim
		
		for a in range(grab, -1, -1):
			so	+= dat.pop(a)
		if len(dat) > 0:
			so	+= "),\n"
		else:
			so	+= ")\n"
		fh.write(so)
		ln	+= 1

if sel==-1:	# Dump-all
	for a in range(cols):
		vdump(fo, ndata[a])
else:
	vdump(fo, ndata[sel])

## Concat all the sub-strings into single strings, max length of 256-bit.
#maxlen	= len (ndata [0])
#if maxlen > (64 / len (ndata [0][0])) :
	#maxlen	= 64 / len (ndata [0][0])
#for i in range (len (ndata)-1, -1, -1) :
	#fo.write ("parameter\tINIT_LINE0"+chr(64+cols-i)+"\t= 256'h")
	#for j in range (maxlen-1, -1, -1) :
		#fo.write (ndata [i][j])
		##ndata [i][j].pop()
	#fo.write (";\n")

fo.close ()
print	"Done"
