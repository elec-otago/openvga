ASM_FILE=main
OUT2V=../../tools/out2v.py
ASSEM=../r16asm/r16asm.py

all: assemble
	cp *.v ../../rtl/cpu/risc16/

%.s: %.S
	m4 $< > $*.s

assemble: $(ASM_FILE).s
	${ASSEM} $(ASM_FILE).s
	${OUT2V} -n 1 -s 0 $(ASM_FILE).out risc_asm.v

clean:
	rm -f $(ASM_FILE).out $(ASM_FILE).s risc_asm.v
