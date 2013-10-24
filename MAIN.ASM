; ==============================================================================
; Empty example assembly file.
; ==============================================================================
.MODEL small ; one data and one code segment, stack and data segment are grouped
.STACK 1024  ; stack, 1024 bytes
.DATA        ; data segment, static variables

.CODE        ; code segment

; ----------------------------- CODE STARTS HERE -------------------------------
main:

	mov	ax, 4c00h	; exit to DOS
	int	21h

; _------------------------------- END OF CODE ---------------------------------
END main