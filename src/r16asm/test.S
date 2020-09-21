; Just a demo RISC16 assembly file.
CRTC_SEG:	equ	0x40
SPROM_SEG:	equ	0x44
LEDS_SEG:	equ	0x48
DMA_SEG:	equ	0x50
FLUSH_SEG:	equ	0x58

	nop
__reset_addr:	xor	r13, r13	; Set ZR
		xor	r12, r12	; SS
		msr.s	r13		; Set SS
		subi	r14, r13, 1	; SP := 65535
		subi	r15, r13, -1	; LR := 1 (__reset_addr)
		
		i12	set_leds>>4
		brl	r15, set_leds	; r15<-pc, pc<-immed
		
		i12	-end>>4		; These two lines are the same as:
		subi	r0, r13, -end	; lea	r0, end
		sw	[r2-0x4], r11
		i12	(CRTC_SEG>>4)
		orc	r1, CRTC_SEG
		jz	__reset_addr
end:		ret


;----------------------------------------------------------------------------
; set_leds - The two LSBs of `r0' determines the LED outputs.
set_leds:	i12	-LEDS_SEG>>4
		subi	r1, r13, -LEDS_SEG
		msr.d	r1
		sw.d	[r13], r0
		ret
