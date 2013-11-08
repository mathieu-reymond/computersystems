;==================
; Game drawings
;==================
.MODEL large

;----INCLUDES------



;-----MACRO'S and CONSTANTS------

SCREEN_X equ 320
SCREEN_Y equ 200

;-----SCREEN BUFFER-------
.FARDATA?

palette db 0,0,0,63,63,63
screenBuffer db SCREEN_X * SCREEN_Y dup(?) ;pixels of screen

;--------CODE SEGMENT-------

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
	