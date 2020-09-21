; Just a demo RISC16 assembly file.
CRTC_SEG:	equ	0x40
SPROM_SEG:	equ	0x44
LEDS_SEG:	equ	0x48
DMA_SEG:	equ	0x50
FLUSH_SEG:	equ	0x58

		nop
		nop
		i12	cpu_init>>4
		brl	r15, cpu_init
		nop
		; Test memcpy
		i12	-100>>4
		subi	r0, r13, -100	; mov	r0, 100
		sw.s	[r14], r0	; push	r0
		subi	r14, r14, 1
		xor	r0, r0
		xor	r1, r1
		xor	r2, r2
		xor	r3, r3
		i12	memcpy_dma>>4
		brl	r15, memcpy_dma
		
		nop
		nop
		nop
		lw	r0, [r13-3]
;		nop
;		nop
;		nop
		sw	[r0], r1
		sw	[r13-1], r0
		sw	[r13-2], r0
		nop
		nop
		nop
		nop
__endless:	nop
		i12	__endless>>4
		br	r13, __endless
		nop
		nop


		nop
__reset_addr:	nop
		xor	r13, r13	; Set ZR
		xor	r12, r12	; SS
		msr.s	r13		; Set SS
		subi	r14, r13, 1	; SP := 65535
		subi	r15, r13, -1	; LR := 1 (__reset_addr)
		
		i12	set_leds>>4
		brl	r15, set_leds	; r15<-pc, pc<-immed
		nop
		
		i12	-end>>4		; These two lines are the same as:
		subi	r0, r13, -end	; lea	r0, end
		neg	r5		; sub	r5, #0, r5
		sw	[r2-0x4], r11
		i12	(CRTC_SEG>>4)
		orc	r1, CRTC_SEG
		jnz	__reset_addr
		nop
		nop
end:		ret


cpu_init:	xor	r13, r13	; Set ZR
		xor	r12, r12	; SS
		msr.s	r13		; Set SS
		subi	r14, r13, 1	; SP := 65535
		subi	r15, r13, -1	; LR := 1 (__reset_addr)

		subi	r0, r13, -1	; mov	r0, #1
		i12	set_leds>>4
		brl	r15, set_leds	; r15<-pc, pc<-immed
		nop
		ret


;----------------------------------------------------------------------------
; set_leds - The two LSBs of `r0' determines the LED outputs.
set_leds:	i12	-LEDS_SEG>>4
		subi	r1, r13, -LEDS_SEG
		msr.d	r1
		sw.d	[r13], r0
		ret


;----------------------------------------------------------------------------
; cache_flush - Flushes the CPU's data cache.
; Bits 8-5 of the memory address represent the cache tag indices. Each of
; these 16 indices need to invalidated to completely flush the cache.
; The MMIO address of the cache flush module is 25'h1C_xx_xx
; NOTE: The first writes to 0x0220 & 0x0200 is used for Wishbone bus timing
; reasons. Take a look at the GtkWave plot to see why. (To correct phasing
; between `cpu_adr' and `cache_rst_i'.)
; Pseudocode:
;	for (a=0x001c0200; a>=0x001c0000; a-=0x010)
;		*(void*)a	= 0;
;
; Inputs:	r15	- Return address
;		r14	- Stack pointer
;		r13	- Zero
;		r12	- Stack Seg
; Outputs:	none
;
cache_flush:	i12	-FLUSH_SEG>>4
		subi	r0, r13, -FLUSH_SEG
		i12	-0x220>>4
		subi	r1, r13, -0x220
		i12	-0x20>>4
		subi	r2, r13, -0x20
		msr.d	r0
cf_l0:		sw.d	[r1], r0	; Can write anything
		subc	r1, r2
		jnb	cf_l0
		ret


;----------------------------------------------------------------------------
; crtc_init - Set initial values for the CRTC, 640x480, 16-bit colour.
; inputs:	none
; outputs:	none
crtc_init:	ret


;----------------------------------------------------------------------------
; memcpy_dma - Optimised `memcpy' using the DMA to burst write data to the
;  SDRAM controller. There are five arguments, read seg+pointer, write seg+
; pointer, and number of words. The fifth value is TOS.
;	r0	- src_ptr*
;	r1	- src_seg
;	r2	- dst_ptr*
;	r3	- dst_seg
;	[TOS]	- n
; Return value:	none
DMA_start:	equ	0x0080
memcpy_dma:	; Setup the DMA controller.
		sw.s	[r14], r4		; PUSH r4, reg needed
		i12	-DMA_SEG>>4
		subi	r4, r13, -DMA_SEG
		nop				; No bypassing on
		nop				; MSR (the `dat' path)
		msr.d	r4			; Set output seg to DMA
		sw.d	[r13+1], r2		; Setup DMA, lo-word of addr
		sw.d	[r13+2], r3		; hi-word of addr
		sw.d	[r13+3], r13		; clear bit-masks
		lw.s	[r14-1], r2		; Get `n' from stack
		msr.s	r1			; Set src seg
mcpy_l0:	lw.s	[r0], r3
		decc	r2
		inc	r0			; Don't modify flags
		sw.d	[r13+0], r3		; Write to DMA
		jnz	mcpy_l0
		
		i12	-DMA_start>>4
		subi	r3, r13, -DMA_start
		msr.s	r12			; Restore SS and POP r4
		lw.s	[r14], r4		; While `r3' writes back
		sw.d	[r13+3], r3		; Start DMA xfer
		
		ret
