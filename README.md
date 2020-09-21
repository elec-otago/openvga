=	The OpenVGA Open Graphics Adapter =

OpenVGA was an M.Sc project in the Elec Research Group at the University of Otago by Patrick Suggate under the supervision of Tim Molteno.

Copyright 2009 Patrick Suggate



== What is OpenVGA? ==

OpenVGA is an open-source hardware graphics adapter project. The project has a PCB design, the Verilog describing the logic within the FPGA (including processors, a memory controller, a PCI to Wishbone bridge, and a fast data-cache), a simple Linux kernel module, and some miscellaneous tools. The tools include a TTA assembler, the RISC16 assembler, a CRT simulator, and some scripts for data conversion tasks.

Currently OpenVGA will display data written to it, via the PCI bus, on an attached VGA monitor. Some more work is needed to allow it to function as a PC's primary display adapter. This is mostly firmware plus a tweak to the PCI bridge so that it will request to be a VGA device on system startup.

Also included in this package are components developed by others:
 - A VGA BIOS release, with the current version available from http://www.nongnu.org/vgabios/
 - TTA assembler, written in the Mercury programming language, developed by Roy Ward who was a Ph.D student in the Elec Research Group



== Verilog Source Simulation and Synthesis Instructions ==

=== Software Requirements:

 - Icarus Verilog for simulation.
 - GtkWave for displaying created waveforms.
 - Xilinx synthesis toolchain, currently expected to be installed to `/opt/Xilinx'
   The following line within rtl/makefile needs to modified if the location is different:
	export XILINX=/opt/Xilinx
 - A working Mercury compiler install if the TTA assembler needs to be (re)built, a working binary is contained within the `bin' folder though.
 - A working Python setup is needed to run the Python scripts within the `tools' folder. wxPython is needed to run a couple of these scripts too.
 - The `m4' macro processor is needed for assembling also.

=== Building

 - Synthesising:
	make

 - To simulate:
	make	icarus

 - Assembling:
	make	assemble
