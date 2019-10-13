;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
		.data
Array: 	.byte 17, 18, 20, 0, 6, 10, 16, 19, 13, 16, 14, 18, 16, 14, 16
Mem1:	.space 1			;to store the maximum 0x240f
Mem2:	.space 21			;to store the histogram 0x2410-0x2424 (0-20)
Mem3:	.space 1			;to store the mode (value that occurs most)	0x2425
		;define the numbers
		.text
		mov.w #Array, R10	;R10 is the pointer to control the address to memory
		mov.w R10, R13		;store the start address
		mov.w #Mem1, R14
		dec.w R14			;store the end address
		mov.w R13, R7		;make a copy of R13(start address)
		call #Max			;run the max subroutine
		mov.b R15, Mem1
		call #histo			;run the histo subroutine

		;call Max again, now with some changes
		mov.w #Mem2, R10
		mov.w R10, R13		;store the start address
		mov.w #Mem3, R14
		dec.w R14			;store the end address
		call #Max			;call Max again
		sub.w #Mem2, R9		;get the difference of address(it equlas the value-1)
		mov.b R9, Mem3		;move it to memory
		inc.b Mem3			;plus 1, so now the value in memory equls the numbers
							;which appears most often

		jmp OVER			;the program is finished
Max:
		clr.w R15			;ready for storing
		mov.b @R10, R6		;initial R6 to get ready to store the larger value
		cmp.b R6, 1(R10)
							;two Max_ini to initial the larger number to R6/R15
		jge Max_ini1
		jl Max_ini2
Max_ini1:					;get the larger value(initialization)
		mov.b 1(R10), R6
		mov.b R6, R15
		jmp Max_main
Max_ini2:					;get the larger value(initialization)
		mov.b 0(R10), R6
		mov.b R6, R15
Max_main:
		cmp.w R10, R14		;whether the program is end or not
		jeq done1			;if the address is traverses over, jump to end
		mov.w R10, R4		;move the first value's address to R4
		inc.w R10			;R10 points to next couple
		mov.w R10, R5		;then the next address to R5
		cmp.b @R4, 0(R5)	;then compare the two value
		jl Max_define1		;if not, jump to move the larger value(R4 points to)
		jge Max_define2		;if yes, jump to move the larger value(R5 points to)
Max_define1:
		mov.b @R4, R6		;move R4 to R6
		cmp.b R6, R15		;compare which is larger
		jl Max_swap1
		jmp Max_main
Max_swap1:					;get the larger value
		mov.b R6, R15
		mov.w R4, R9
		jmp Max_main		;jump back
Max_define2:
		mov.b @R5, R6		;move R5 to R6
		cmp.b R6, R15		;compare which is larger
		jl Max_swap1
		jmp Max_main
Max_swap2:					;get the larger value
		mov.b R6, R15
		mov.w R5, R9
		jmp Max_main		;jump back
done1:
		mov.w R13, R10		;reset R10
		ret					;get back to where this Subroutine is called
; subroutine histo
; will find the number of occurrences of a value in a range
; of addresses. Assumes R14 > R13.
; input: R12 = value
; R13 = start address
; R14 = end address
;
; uses R11 for temporary storage
; R13 is changed in the subroutine
;
; output: R15 = number of occurrences of value in range
; R13-R14 inclusive
histo:
		mov.w #Mem2, R8		;use R8 as a pointer to memory to store
		mov.b #0, R12		;initialize the counter
histo_start:
		clr.w R15 			; number of occurences is zero
again: 	mov.b @R13,R11 		; move data to temporary R11
		cmp.b R11,R12 		; is R11 same as value?
		jne skip 			; if not same, then skip
		add.w #1,R15 		; found a score same as value!
skip: 	add.w #1,R13 		; next address
		cmp.w R13,R14 		; R14-R13: info to SR
		jl count
		jmp again
count:
		mov.w R7, R13		;reset R13, from the start address
		mov.b R15, 0(R8)	;store the times of number to memory
		inc.w R8			;ready for next address to store
		inc.b R12			;ready for comparing next value(0-20)
		cmp.b #21, R12		;compare if the number which is compared exceeds 20
							;(so need to plus 1)
		jge done2			;means the histo module is finished
		jl histo_start		;back to continue
done2: 	ret					;get back to where this Subroutine is called

OVER:
;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            
