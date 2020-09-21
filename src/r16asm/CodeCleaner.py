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

# Removes comments
class CodeCleaner:
	def clean(self, fi):
		lines	= fi.readlines()
		lines	= self.addLineNumbers(lines)
		#if self.cleanMultiLineComments:
			#lines	= self.removeMultiLineComments(lines)
		if self.cleanSingleLineComments:
			lines	= self.removeSingleLineComments(lines)
		if self.cleanWhitespaces:
			lines	= self.removeWhitespaces(lines)
		return	lines
	
	def addLineNumbers(self, lines):
		oLines	= []
		n	= 1
		for line in lines:
			oLines.append([n, line])
			n	+= 1
		return	oLines
	
	def removeSingleLineComments(self, lineList):
		outLines	= []
		for line in lineList:
			pos	= line[1].find(self.singleLineComment)
			if pos != -1:
				outLines.append([line[0], line[1][0:pos]])
			else:
				outLines.append(line)
		return	outLines
	
	def removeWhitespaces(self, lineList):
		lines	= map(lambda l: [l[0], l[1].strip()], lineList)
		return filter(lambda l: len(l[1]) > 0, lines)
	
	singleLineComment	= ";"
	multiLineCommentStart	= "/*"
	multiLineCommentEnd	= "*/"
	cleanSingleLineComments	= True;
	cleanMultiLineComments	= False;	# TODO
	cleanWhitespaces	= True;
# endclass CodeCleaner
