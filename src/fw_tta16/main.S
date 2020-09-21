include(prepro.m4)
arch(tta16)

;mov3r(r0, r1, r2, 0x00, 0x01, 0x02)
;ledflash:	{		,		,		,	}
;		{\r0	->wad	,		,\r1	->mem	,	}
;		{ledflash->bra	,		,		,\r0	}
;		{com	->wad	,		,\r2	->mem	,	}
;
;mov3r(r0, r1, r2, 0x10, 0x00, 0x10)

; Initialise stack pointer (SP), zero register (ZR), and stack segment (SS).
mov3r(r12, r13, r14, 0x00, 0x00, -1)

mov(r0, 0x00)	; Turn off LEDs
call(set_leds)

call(cache_flush)
call(crtc_init)

; Copy 16 words from 0x00_0000 to 0x01_0000
mov4r(r0, r1, r2, r3, 0, 0, 0, 1)
pushi(0x10)
call(memcpy_dma)

mov(r0, 0x02)	; Turn on a LED
call(set_leds)

forever:
branch(forever)
;branch(ledflash)
NOP


;----------------------------------------------------------------------------
; set_leds - The two LSBs of `r0' determines the LED outputs.
set_leds:	{		,		,		,1	}
		; Set segment to the memory-mapped LEDs.
		{		,		,com	->msr	,0x48	}
		{\r0	->wad	,		,\r0	->mem	,1	}
		 ; Restore SS and return.
		{\r15	->bra	,		,com	->msr	,\r12	}
		{		,		,		,	}


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
cache_flush:	{		,		,		,17	}
		{		,		,com	->mul	,32	} ; Calc 0x0200
		{		,		,		,1	} ; Set WSEG
		{		,		,com	->msr	,0x58	} ; 0xffc0
		{		,		,		,plo	}
		{		,		,com	->r0\	,	}
		{		,		,		,	}
cf_l0:		{		,		,		,	}
		{\r0	->wad	,32	->sub	,pc	->mem	,\r0	} ; Any val will do
		{		,		,		,	}
		{cf_l0	->jnb	,		,diff	->r0\	,	}
		{		,		,		,	} ; BDS
		{		,		,		,1	} ; Restore SS
		{		,		,com	->msr	,\r12	}
		{\r15	->bra	,		,		,	}
		{		,		,		,	} ; BDS


;----------------------------------------------------------------------------
; crtc_init - Set initial values for the CRTC, 640x480, 16-bit colour.
; inputs:	none
; outputs:	none
define(`CRTC', `0x40')dnl
crtc_init:	{		,		,		,1	}
		{		,		,com	->msr	,CRTC	}
		{		,		,		,1	}
		{4	->wad	,		,com	->mem	,4	} ; Set VSYNC
		{		,		,com	->mul	,64	} ; Calc 512
		{		,		,		,11	}
		{\r13	->wad	,		,com	->mem	,17	}
		{1	->wad	,		,com	->mem	,plo	}
		{		,		,com	->r0\	,97	}
		{2	->wad	,		,com	->mem	,	}
		{		,		,		,99	}
		{3	->wad	,		,com	->mem	,	}
		{		,-2	->sub	,		,\r0	} ; Calc 512+2
		{		,-14	->sub	,		,\r0	} ; Calc 512+14
		{6	->wad	,		,diff	->mem	,	} ; 514
		{7	->wad	,		,diff	->mem	,	} ; 524
		{		,		,		,34	}
		{5	->wad	,		,com	->mem	,	}
		{		,		,		,1	}
		{\r15	->bra	,		,com	->msr	,\r12	} ; Restore SS, RET
		{		,		,		,	} ; BDS


;----------------------------------------------------------------------------
; memcpy_dma - Optimised `memcpy' using the DMA to burst write data to the
;  SDRAM controller. There are five arguments, read seg+pointer, write seg+
; pointer, and number of words. The fifth value is TOS.
; This procedure does not check `n' until after the DMA is setup, or whether
; the DMA is currently in use (since this CPU has no interupts), i.e. it
; assumes that the programmer is not a moron.
;	r0	- src_ptr*
;	r1	- src_seg
;	r2	- dst_ptr*
;	r3	- dst_seg
;	[TOS]	- n
; Return value:	none
memcpy_dma:	; Setup the DMA controller.
		{		,		,		,1	}
		{		,		,com	->msr	,0x50	} ; DMA addy
		{		,-1	->sub	,		,\r14	} ; Start POP
		{3	->wad	,		,\r13	->mem	,	}
		{2	->wad	,		,\r3	->mem	,diff	}
		{com	->rad	,		,diff	->r14\	,	} ; Fetch for POP
		{1	->wad	,1	->sub	,\r2	->mem	,mem	} ; Clear masks
		{		,		,		,	}
		{		,		,diff	->r2\	,0	} ; Set read seg
		{		,		,com	->msr	,\r1	}
		{		,		,		,	}
		; Setup complete, now spam data at the DMA.
mcpy_l0:	{\r0	->rad	,-1	->sub	,		,\r0	} ; read+inc src*
		{		,1	->sub	,		,\r2	}
		{		,		,diff	->r0\	,mem	}
		{\r13	->wad	,		,com	->mem	,	}
		{mcpy_l0->jnb	,		,diff	->r2\	,	}
		{		,		,		,-128	}
		{3	->wad	,		,com	->mem	,	} ; start DMA write
		{		,		,		,	}
		{\r15	->bra	,		,		,	}
		{		,		,		,	} ; BDS
		
;----------------------------------------------------------------------------
; memcpy - Not a very useful subroutine since mem-writes through the cache
;  are blocking, and very slow, and will hammer the system's memory Wishbone
;  bus, blocking the redraw logic. The best way is to do it via the DMA.
; Inputs:	r0	- src*
;		r1	- dst*
;		r2	- n
; Outputs:	r0	- points to src EOB
; TODO: This doesn't support segments properly.
memcpy:		{		,		,		,	} ; n > 0
		{		,0	->or	,		,\r2	} ; if (z) ret
		{		,1	->sub	,		,	} ; Pipeline `n--'
		{\r15	->jz	,		,		,	}
		{		,		,diff	->r2\	,\r0	}
		{		,-1	->sub	,com	->r0\	,\r1	}
loop:		{\r1	->rad	,2	->sub	,		,\r2	} ; r2 timesharing
		{		,		,diff	->r1\	,mem	}
		{\r0	->wad	,-1	->sub	,com	->mem	,\r0	}
		{loop	->jnb	,		,diff	->r2\	,	}
		{		,-1	->sub	,diff	->r0\	,\r1	}
		{\r1	->nil	,		,		,\r2	} ; r1 needed for loop start
		{		,		,		,	}
		{\r15	->bra	,		,		,	}
		{		,		,		,	}
