; ==============================================================================
; Example for buffered drawing in mode 13h.
; Example showing palette manipulation via port IO.
; Example for a very generic game-loop.
; ==============================================================================
.MODEL large	; multiple data segments and multiple code segments
.STACK 2048  	; stack

; --- INCLUDES -----------------------------------------------------------------

include VIDEO.INC
include KEYB.INC
include RAND.INC
include GAME.INC
include DRAWING.INC
include INPUT.INC
include DRAWING.INC

; --- DATA SEGMENT -------------------------------------------------------------
.DATA        ; data segment, variables
oldVideoMode	db ?

; --- CODE SEGMENT -------------------------------------------------------------
.CODE        ; code segment

main PROC NEAR
	mov	ax, @data	; get data segment address
	mov	ds, ax		; set DS to data segment

	; Initialize random number generator
	call	randInit
	
	; Install our own keyboard handler
	call	installKeyboardHandler
	
	; set mode 13h
	mov		ax, 13h
	push	ax
	call	setVideoMode
	mov		[oldVideoMode], al
	
	;main menu
mainMenu:
	call renderMainMenu
	call handleMainMenuInput
	cmp al, 0 ;play
	jz mainMenu
	;game
	call startGame
	
	;game over
gameOver:
	call renderGameOver
	call handleGameOverInput
	cmp al, 0
	jnz quit
	jmp gameOver

quit:
	
	; Restore original keyboard handler
	call	uninstallKeyboardHandler

	; Restore original video mode
	mov		al, [oldVideoMode]
	xor		ah, ah
	push	ax
	call	setVideoMode
	
	; Exit to DOS
	mov		ax, 4c00h	; exit to DOS function, return code 00h
	int		21h			; call DOS
main ENDP

END main