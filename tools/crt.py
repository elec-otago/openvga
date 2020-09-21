#!/usr/bin/env python
############################################################################
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
import os
from wxPython.wx import *
import numarray

TIMERID			= 20

# A frame where the timing diagrams are plotted
class CRTFrame(wxFrame) :
	
	def __init__(self, parent, id, title) :
		"""
		Re-inventing the wheel
		"""
		
		wxFrame.__init__(self, parent, id, title, style=wxDEFAULT_FRAME_STYLE)
		
		self.pageWidth = 640	# 640x400 text mode
		self.pageHeight = 400
		
		self._pauseInterval = 10	# 0.03s pause between updates
		
		self.screen = numarray.array(shape=[400, 640], type=numarray.Int)
		self._x = 0
		self._y = 0
		
		self.refreshCounter = 0
		
		self.pixels = []
		
		self.pen = wxPen(colour=wxBLACK)
		
		self.drawPanel = wxWindow(self, -1, style=wxSUNKEN_BORDER)
		self.drawPanel.SetBackgroundColour(wxGREEN)
		
		EVT_PAINT(self.drawPanel, self.onPaintEvent)
		
		# Setup a timer
		self._updateTimer = wxTimer(self, TIMERID)
		EVT_TIMER(self, TIMERID, self.onTimer)
		self._updateTimer.Start(self._pauseInterval, wxTIMER_CONTINUOUS)
		self._readingInput = False
		
		self.SetSizeHints(minW=646, minH=406, maxW=800, maxH=600)
		self.SetSize(wxSize(self.pageWidth, self.pageHeight))
		self.drawPanel.SetFocusFromKbd()
		
	# end __init__
	
	def onTimer(self, event) :
		if not self._readingInput :
			self._readingInput = True	# block timer event while reading
			
			# Start at top left corner when a VSYNC is detected
			pixelRow = sys.stdin.readline()
			while pixelRow.find('VSYNC') != -1 :
				self._x = 0
				self._y = 0
				self.drawPanel.Refresh(eraseBackground=True)	# Pixels to draw
				pixelRow = sys.stdin.readline()
			# endwhile
			
			self.pixels = map(int, pixelRow.split())
			
			try :
				while len(self.pixels) :
					self.screen[self._y][self._x] = self.pixels.pop(0)
					
					if self._x == 639 :
						self._x = 0
						if self._y == 399 :
							self._y = 0
						else :
							self._y += 1
						# endif
					else :
						self._x += 1
					# endif
					
				# endwhile
			except :
				print self._x, self._y
				
		self._readingInput = False
		
	# end onTimer
	
	def onPaintEvent(self, event) :
		"""
		Draws the display
		"""
		
		# Have stuff to draw
		dc = wxPaintDC(self.drawPanel)
		dc.BeginDrawing()
		
		for y in range(400) :
			for x in range(640) :
				if self.screen[y][x] == 1 :
					dc.DrawPoint(x, y)
			# endfor
		# endfor
		
		dc.EndDrawing()
		
	# end OnPaintEvent
	
# endclass CRTFrame


class CRTApp(wxApp) :
	""" The main 'timing' application object.
	"""
	
	def OnInit(self) :
		""" Initialise the application.
		"""
		wxInitAllImageHandlers()
	
		print '\nCRT Monitor Simulator'
		
		# needs a comand line argument
		if(len(sys.argv) > 1) :
			print 'USAGE:'
			print '    PROGGY | crt.py'
			sys.exit(1);
		#endif
		
		self.frame = CRTFrame(None, -1, "CRT Ouput Simulator")
		self.frame.Show(True)
		
		print
		return True
		
# endclass CRTApp


def main() :
	
	global _app
	
	# Create and start the pySketch application.
	
	_app = CRTApp(0)
	_app.MainLoop()
	
# end main


if __name__ == "__main__" :
	main()
