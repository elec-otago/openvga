		nop
		i12	start >> 4
		br	start

fb_seg:		equ	0x0000	; Absolute address is {seg, ptr}
fb_ptr:		equ	0x0000
tb_seg:		equ	0x0800
tb_ptr:		equ	0x0000
font_seg:	equ	0x0900
font_ptr:	equ	0x0000
pal_seg:	equ	0x0A00
pal_ptr:	equ	0x0000

stack_seg	equ	0x0FFF
stack_ptr	equ	0xFFFF

; uint32_t*	fb;	; RGBA, 8-bit/component
; uint16_t*	tb;	; 8-bit ASCII char + 8-bit attribute
; uint8_t*	font;	; 8x16 pixel font
; uint32_t*	pal;	; 16 entry colour palette

; Helper macros
; Conventions:
#define	ZERO		$r13
#define	SP		$r14
#define	LR		$r15
; Makes CPU more CISCy
#define	INC(a)		sub	a, a, #-1
#define	DEC(a)		sub	a, a, #1
#define	NEG(a)		sub.nf	a, #0
#define	TEST(a, b)	and.nc	a, b
#define	SHR(a, b)	i12	0x1000 >> (b) \\
			mul.h	a, (0x1000 >> (b)) & 0xf
#define	LEA(a, b)	i12	-(b) >> 4 \\
			sub	a, ZERO, -(b) & 0xf
#define	MOV(a, b)	sub	a, b, #0
#define	CALL(a)		i12	(a) >> 4 \\
			br	LR, (a) & 0xf
#define	RET		br	LR, ZERO


; Algorithms:
; Character at a time:
; - for each char in `tb' do:
;  - look up fg + bg colours from pal
;  - read a char from the `tb'
;  - for each row in char do:
;   - look up char row from font mem
;   - for each pixel in char row do:
;    - if pixel set, write fg colour to `fb'
;    - else write bg colour to `fb'

; FB-Row-At-A-Time:
; - for each row in FB do:
;  - calc offset into TB
;  - read char from TB
;  - look up fg + bg colours from pal
;...

; FB-Row-At-A-Time has the best SDRAM (+dcache) access behaviour?
#define	PCOLS	640
#define	PROWS	400
#define	CCOLS	80
#define	CROWS	25
#define	TCOLS	8
#define	TROWS	16


; Conventions:
; With RISC16, registers 0-3 are used as arguments and procedures can violate
; these at will. Register 14 is the SP, register 15 is the LR, these have to
; be sensible. Registers 4-13 must not be changed by a subroutine. If used
; within the subroutine, they must be saved first, then restored.
; Also, the `sf' flag means use the stack segment, without means the data
; segment. These have to be sensible, and do not change with restoring. There
; is no way to read these registers but the CPU keeps a copy of the values in
; segment zero.
; Register $r13 is zero. Mostly used for LEA.


; TODO: Optimisations:	Drawing two rows at a time halves the number of
;			accesses to the `font'.
;			Loop unrolling + sheep-run.
;			The same attribute byte is often used for an entire
;			screen, so check previous colour before palette index
;			calculation and colour retrieval?

; RISC16 assembly:
; Inputs:	r0  - x
;		r1  - y
;		r2  - LSW of colour
;		r3  - MSW of colour
;		r13 - zero
;		r14 - stack pointer
;		r15 - link register
;
; Outputs:	none
;
; Note:		DSEG is assumed to be pointing somewhere sensible,
;		this routine will change it temporarily.
;
; Algorithm:	1/ Calculate 32-bit address. Colour size is 32-bit so
;		   multiply by 1280, not 640.
;		2/ Add the MSW to the base FB segment address.
;		3/ Save old seg and set FB seg.
;		4/ Set the 32-bit colour.
;		5/ Restore seg.
;
;
; Other:	 1 load
; 		 3 stores
;		18 instructions
;
.proc		set_pixel
set_pixel:	sw.sf	[$r14-#1], $r4	; push

		MOV	($r4, $r1)
		NEG	($r0)		; negate x
		i12	#0x050
		mul.l	$r1, #0x0	; calc:	y*1280 + x
		i12	#0x050
		mul.h	$r4, #0x0	; ptr = {$r4, $r1}
		sub	$r1, $r0
		jnb	#set_pixel_nb
		INC	($r4)		; increment upon overflow
set_pixel_nb:	NEG	($r4)
		i12	#fb_seg
		msr	#fb_seg, $r4
		sw	[$r4-#0], $r2	; write 32-bit colour
		sw	[$r4-#-1], $r3
		msr	#0, $r13	; restore system data seg

		lw.sf	$r4, [$r14-#1]	; pop $r4
		RET
.endproc


; RISC16 assembly:
; Inputs:	r0  - character
;		r1  - row
;		r14 - stack pointer (unused)
;		r15 - link register
;
; Outputs:	r0  - 8-bit pixel data
;
; Note:		DSEG is assumed to be pointing somewhere sensible.
;		Data is 16-bit aligned, but we need only 8-bits.
;		Font address is a global constant since it needs to
;		negated.
;
;
; Other:	 1 load
; 		 0 stores
;		12 instructions
;
.proc		get_font_row
get_font_row:	MOV	($r2, $r0)	; actually: sub $r2, $r0, #0
		i12	0x000		; prevent sign-extend
		mul.l	$r0, #0x8	; 8x16-bit words per char
		NEG	($r1)		; Negate row
		and	$r2, #1		; Odd or even byte?
		sub.nf	$r0, $r1	; Calc offset with font
		i12	#-font_ptr	; set 1st 12-bits of imm
		lw	$r0, [$r0 - #-font_ptr]
		jz	#gfr_done
		i12	#0x010		; set long immediate to 256
		mul.h	$r0, #0		; shift right 8 places
gfr_done:	RET
.endproc


; RISC16 assembly:
; Inputs:	r0  - column
;		r1  - row
;		r2  - char
;		r3  - attr
;		r14 - stack pointer
;		r15 - link register
;
; Outputs:	none
;
; Note:		DSEG is assumed to be pointing somewhere sensible.
;		Data is 16-bit aligned, but we need only 8-bits.
;		Font address is a global constant since it needs to
;		negated.
;
;
; Other:	14 loads
; 		10 stores
;		63 instructions
;
.proc		draw_char_row
draw_char_row:	sw.sf	[$r14], $r15	; Push LR
		sw.sf	[$r14-#1], $r4	; These regs are clobbered
		sw.sf	[$r14-#2], $r5
		sw.sf	[$r14-#3], $r6
		sw.sf	[$r14-#4], $r7
		sw.sf	[$r14-#5], $r8
		sw.sf	[$r14-#6], $r9
		sw.sf	[$r14-#7], $r10
		sub	$r14, #7
		sw.sf	[$r14], $r11
		sw.sf	[$r14-#1], $r12
		sub	$r14, #2	; so set_pixel can use it

		mov	$r4, $r0
		mov	$r5, $r1
		mov	$r6, $r2	; {$r7, %r6} := FG colour
		mov	$r8, $r2	; {$r9, %r8} := BG colour
		mov	$r10, $r3	; char

		mov	$r0, $r2
		i12	#0x000
		and	$r0, #0xf	; i12 to prevent sign-extend
		i12	#get_font_row
		br	$r15, #get_font_row
		mov	$r11, $r0	; row pixel data

		; Calculate FG + BG colours.
		i12	#0x000
		and	$r6, #0xf
		i12	#0x100
		mul.h	$r8, #0x0	; $r8 >>= 4

		i12	#font		; lea $r7, #-font
		sub	$r7, $r13, #font
		sub	$r6, $r7	; FG ptr
		sub	$r8, $r7	; BG ptr

		lw	$r7, [$r6-#-1]	; font[r6+1]	// FG
		lw	$r6, [$r6]	; font[r6+0]
		lw	$r9, [$r8-#-1]	; font[r8+1]	// BG
		lw	$r8, [$r8]	; font[r8+0]

		i12	#0x008
		sub	$r12, $r13, #0	; mov $r12, #0x0080

drc_loop:	mov	$r3, $r9	; BG more probable?
		mov	$r4, $r10
		TEST	($r11, $r12)	; and.nc $r11, $r12
		jnz	#drc_disp_pix
		mov	$r3, $r7	; pix not set, use FG
		mov	$r4, $r8
drc_disp_pix:	mov	$r0, $r4
		mov	$r1, $r5
		CALL	(#set_pixel)
;		i12	#set_pixel
;		br	$r15, #set_pixel
		INC	($r4)		; x++
		mul.l	$r11,#2		; r <<= 1
		TEST	($r4, #0x7)
		jnz	#drc_loop

		lw.sf	$r12,[$r14-#-1]; Restore clobbered regs
		lw.sf	$r11,[$r14]
		sub	$r14, #-7
		lw.sf	$r10,[$r14-#7]
		lw.sf	$r9, [$r14-#6]
		lw.sf	$r8, [$r14-#5]
		lw.sf	$r7, [$r14-#4]
		lw.sf	$r6, [$r14-#3]
		lw.sf	$r5, [$r14-#2]
		lw.sf	$r4, [$r14-#1]
		lw.sf	$r15, [$r14]	; Pop LR

		RET		; Ret
.endproc


; This assumes width of 8 pixels/char and height of 16 pixels/char and 80
; chars per row.
; RISC16 assembly:
; Inputs:	r0  - row
;		r14 - stack pointer
;		r15 - link register
;
; Outputs:	none
;
;
; Other:	84 loads
; 		 4 stores
;		33 instructions
;
.proc		draw_row
draw_row:	sw.sf	[$r14], $r15	; Push LR
		sw.sf	[$r14-#1], $r4	; These regs are clobbered
		sw.sf	[$r14-#2], $r5
		sw.sf	[$r14-#3], $r6
		sub	$r14, $r14, #4

		mov	$r5, $r0
		i12	#0xfff
		and	$r5, $r5, #0
		mov	$r4, $r0	; Save `row'
		mul.l	$r5, $r5, #5	; TB ptr
		i12	#-tb_ptr
		sub	$r5, $r5, #-tb_ptr

		i12	#0x027
		mov	$r6, #0xf	; start at col 639

draw_row_loop:	lw	$r2, [$r5]
		sub	$r5, $r5, #-1	; p := tb[idx++]

		mov	$r3, $r2
		i12	#0x00f
		and	$r2, $r2, #0xf	; keep low 8-bit for char
		i12	#0x010
		mul.h	$r3, $r3, #0x0	; >>8 to get attr

		mov	$r0, $r6	; column
		mov	$r1, $r4	; row
		i12	#draw_char_row
		br	$r15, #draw_char_row

		sub	$r6, $r6, #1
		jnb	#draw_row_loop

		lw.sf	$r6, [$r14-#-1]	; Restore clobbered regs
		lw.sf	$r5, [$r14-#-2]
		lw.sf	$r4, [$r14-#-3]
		lw.sf	$r15, [$r14-#-4]; Pop LR
		sub	$r14, $r14, #-4	; Restore SP

		br	$r15		; Ret
.endproc


; RISC16 assembly:
; Inputs:	r14 - stack pointer
;		r15 - link register
;
; Outputs:	none
;
; Other:	2  loads
;		2  stores
;		14 instructions
;
.proc		update_fb
update_fb:	sw.sf	[$r14], $r15	; Push LR
		sw.sf	[$r14], $r4	; Push $r4
		sub	$r14, $r14, #2

		i12	#0x01e
		mov	$r4, #0xf	; Start at 479 and dec

update_fb_loop:	mov	$r0, $r4
		i12	#draw_row
		br	$r15, #draw_row	; Call draw_row

		sub	$r4, $r4, #1
		jnb	#update_fb_loop

		lw.sf	$r4, [$r14-#-1]	; Pop $r4
		lw.sf	$r15, [$r14-#-2]; Pop LR
		sub	$r14, $r14, #-2

		br	$r15		; Ret
.endproc
