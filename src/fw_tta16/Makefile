ASM_FILE=main
OUT2V=../../tools/out2v.py
ASSEM=../../bin/assemble

all: assemble
	cp *.v ../../rtl/cpu/tta16/

%.s: %.S
	m4 $< > $*.s

assemble: $(ASM_FILE).s
	$(ASSEM) $(ASM_FILE).s
	$(OUT2V) -n 2 -s 0 $(ASM_FILE).out tta_asm0.v
	$(OUT2V) -n 2 -s 1 $(ASM_FILE).out tta_asm1.v

clean:
	rm -f $(ASM_FILE).out $(ASM_FILE).s tta_asm0.v tta_asm1.v
