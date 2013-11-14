; ==============================================================================
; Entry point of program
; ==============================================================================
.MODEL large ; one data and one code segment, stack and data segment are grouped
.STACK 1024  ; stack, 1024 bytes

; --- INCLUDES -----------------------------------------------------------------

include VIDEO.INC
include RAND.INC
include KEYB.INC

include DRAWING.INC
include GAME.INC

; --- DATA SEGMENT -------------------------------------------------------------
.DATA


; --- CODE SEGMENT -------------------------------------------------------------
.CODE
main:
	
	;call initialize

	mov	ax, 4c00h	; exit to DOS
	int	21h

; _------------------------------- END OF CODE ---------------------------------
END main