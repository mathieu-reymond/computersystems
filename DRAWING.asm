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
.CODE

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

;draw a snake-head at given coord in AX
drawHead PROC FAR
	push bx
	push dx
	push di
	push si
	push es
	
	mov ax, seg screenBuffer ;temp mov to ax
	add ax, offset screenBuffer
	mov es, ax ;screenBuffer in es (es points to first pixel of screen)
	
	call offsetForCoord ;AX = pixel offset
	mov di, ax
	mov dx, 1 ;color from palette
	
	;temp : make a filled square
	mov bx, 0
@yLoop:
	mov si, 0
@xLoop:
	mov es:[di], dx ;set color at given offset
	inc di
	inc si
	cmp si, 10 ;;(SCREEN_X/BOARD_X)
	jnz @xLoop
	
	mov ax, SCREEN_X
	add di, ax
	inc bx
	cmp bx, 10 ;(SCREEN_Y/BOARD_Y)
	jnz @yLoop
	
	pop es
	pop si
	pop di
	pop dx
	pop bx
	ret 0
drawHead ENDP
END
