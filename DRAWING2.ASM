; ==============================================================================
; Example for buffered drawing in mode 13h.
; Example showing palette manipulation via port IO.
; Example for a very generic game-loop.
; ==============================================================================
.MODEL large	; multiple data segments and multiple code segments
.STACK 2048  	; stack

; --- INCLUDES -----------------------------------------------------------------

include VIDEO.INC
include RAND.INC
include KEYB.INC

; --- MACROS AND CONSTANTS -----------------------------------------------------

; Other constants	
SCREEN_X		equ 320
SCREEN_Y		equ 200

; --- DATA SEGMENT -------------------------------------------------------------
.DATA        ; data segment, variables
oldVideoMode	db ?

hardOffset	dw 0 ; test variable

; --- SCREEN BUFFER ------------------------------------------------------------
.FARDATA?	; segment that contains the screenBuffer for mode 13h drawing
palette			db 768 dup(0)
screenBuffer	db 64000 dup(?)	; the 64000 bytes for the screen

; --- CODE SEGMENT -------------------------------------------------------------
.CODE        ; code segment
initDrawing PROC NEAR
	push ax
	push ds
	
	mov	ax, @data	; get data segment address
	mov	ds, ax		; set DS to data segment
	
	; Install our own keyboard handler
	;call	installKeyboardHandler

	; fade to black
	call	fadeToBlack
	
	; clear video buffer
	call	clearScreenBuffer

	; draw the screen buffer
	call 	updateScreen
	
	; set mode 13h
	mov		ax, 13h
	push	ax
	call	setVideoMode
	mov		[oldVideoMode], al
	
	mov ah, 10
	mov al, 10
	call drawHead
	mov ah, 11
	mov al, 10
	call drawHead
	
	pop ds
	pop ax
	ret 0
initDrawing ENDP

; Fades the active colors to black
fadeToBlack PROC NEAR
	push	ax

	mov	ax, seg palette
	push	ax
	mov	ax, offset palette
	push	ax
	call	paletteInitFade
@@:
	waitVBlank
	call	paletteNextFade
	test	ax, ax
	jnz	@B

	pop	ax
	ret 0
fadeToBlack ENDP

; Clears the screen buffer to color 0
clearScreenBuffer PROC NEAR
	push	ax
	push	cx
	push	di
	push	es
	
	cld
	mov		ax, seg screenBuffer
	mov		es, ax
	mov		di, offset screenBuffer
	mov		cx, 64000 / 2
	xor		ax, ax
	rep		stosw
	
	pop	es
	pop	di
	pop	cx
	pop	ax
	ret	0
clearScreenBuffer ENDP

; Updates the screen (copies contents from screenBuffer to screen)
updateScreen PROC NEAR
	push	ax
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	
	; setup source and dest segments
	mov		ax, seg screenBuffer
	mov		ds, ax
	mov		si, offset screenBuffer
	mov		ax, 0a000h	; video memory
	mov		es, ax
	xor		di, di	; start at pixel 0
	
	cld
	mov		cx, 64000 / 2
	waitVBlank	; wait for a VB (modifies AX and DX)
	rep		movsw	; blit to screen	
	
	pop		es
	pop		ds
	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		ax
	ret		0
updateScreen ENDP

;get pixel offset for given board-coord
;AX the given coord
;@return AX the offset
offsetForCoord PROC NEAR
	push bx
	push dx

	;offset = y*SCREEN_X*(SCREEN_Y/BOARD_Y) + x*(SCREEN_X/BOARD_X)
	mov bx, ax
	mov ah, 0 ;AX = y
	mov dx, SCREEN_X
	mul dx ;AX = SCREEN_X*y
	mov dx, 10 ;(SCREEN_Y/BOARD_Y)
	mul dx ;AX = y*SCREEN_X*(SCREEN_Y/BOARD_Y)
	
	push ax ;save current offset
	
	mov al, bh
	mov ah, 0 ;AX = x
	mov dx, 10 ;(SCREEN_X/BOARD_X)
	mul dx ;AX = x*(SCREEN_X/BOARD_X)
	
	pop bx ;restore offset in bx
	add ax, bx ;AX = y*SCREEN_X*(SCREEN_Y/BOARD_Y) + x*(SCREEN_X/BOARD_X)
	
	pop dx
	pop bx
	ret 0
offsetForCoord ENDP

; ;draw a snake-head at given coord in AX
; AX : given coord (AH = x, AL = y)
drawHead PROC NEAR
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	es
	
	; set segment
	mov	bx, seg screenBuffer
	mov	es, bx
	
	;calculate offset from given coord in AX
	call offsetForCoord ;AX : offset
	add	ax, offset screenBuffer
	add	ax, [hardOffset]
	
	mov di, ax ;test will write on first pixel
	mov dl, 45 ;color from palette
	
	;temp : make a filled square
	mov bx, 0
@yLoop:
	mov si, 0
@xLoop:
	mov es:[di], dl ;set color at given offset
	inc di
	inc si
	cmp si, 10 ;(SCREEN_X/BOARD_X)
	jnz @xLoop
	
	mov ax, SCREEN_X
	sub ax, 10
	add di, ax
	inc bx
	cmp bx, 10 ;(SCREEN_Y/BOARD_Y)
	jnz @yLoop
	
	call updateScreen

	; We are done
	pop	es
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	; return
	ret	0
drawHead ENDP

; main:
	; call initDrawing
	; mov ah, 13
	; mov al, 10
	; call drawHead
	
	;Restore original video mode
	; mov		al, [oldVideoMode]
	; xor		ah, ah
	; push	ax
	; call	setVideoMode
	
	; mov	ax, 4c00h	; exit to DOS
	; int	21h

; _------------------------------- END OF CODE ---------------------------------
END
