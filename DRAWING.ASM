; ==============================================================================
; Example for buffered drawing in mode 13h.
; Example showing palette manipulation via port IO.
; Example for a very generic game-loop.
; ==============================================================================
.MODEL large	; multiple data segments and multiple code segments
.STACK 2048  	; stack

; --- INCLUDES -----------------------------------------------------------------

include VIDEO.INC
include DRAWING.INC
include GAME.INC
include INPUT.INC

; --- MACROS AND CONSTANTS -----------------------------------------------------

; Other constants	

; --- DATA SEGMENT -------------------------------------------------------------
.DATA        ; data segment, variables

WAIT_TIME dw 0

draw_snake_head_up byte 10,10
				byte a,a,g,a,r,r,a,g,a,a
				byte a,g,g,a,r,r,a,g,g,a
			   	byte g,g,l,g,r,r,g,l,g,g
				byte g,l,l,l,g,g,l,l,l,g
				byte g,b,b,l,l,l,l,b,b,g
				byte g,b,b,l,l,l,l,b,b,g
				byte a,g,l,l,l,l,l,l,g,a
				byte a,a,g,l,l,l,l,g,a,a
				byte a,g,l,l,l,l,l,l,g,a
				byte a,a,g,g,g,g,g,g,a,a
draw_snake_head_right byte 10,10
				byte a,a,a,a,g,g,g,g,a,a
				byte a,g,a,g,b,b,l,g,g,a
			   	byte g,l,g,l,b,b,l,l,g,g
				byte g,l,l,l,l,l,l,g,a,a
				byte g,l,l,l,l,l,g,r,r,r
				byte g,l,l,l,l,l,g,r,r,r
				byte g,l,l,l,l,l,l,g,a,a
				byte g,l,g,l,b,b,l,l,g,g
				byte a,g,a,g,b,b,l,g,g,a
				byte a,a,a,a,g,g,g,g,a,a
draw_snake_head_down byte 10,10
				byte a,a,g,g,g,g,g,g,a,a
				byte a,g,l,l,l,l,l,l,g,a
			   	byte a,a,g,l,l,l,l,g,a,a
				byte a,g,l,l,l,l,l,l,g,a
				byte g,b,b,l,l,l,l,b,b,g
				byte g,b,b,l,l,l,l,b,b,g
				byte g,l,l,l,g,g,l,l,l,g
				byte g,g,l,g,r,r,g,l,g,g
				byte a,g,g,a,r,r,a,g,g,a
				byte a,a,g,a,r,r,a,g,a,a
draw_snake_head_left byte 10,10
				byte a,a,g,g,g,g,a,a,a,a
				byte a,g,g,l,b,b,g,a,g,a
			   	byte g,g,l,l,b,b,l,g,l,g
				byte a,a,g,l,l,l,l,l,l,g
				byte r,r,r,g,l,l,l,l,l,g
				byte r,r,r,g,l,l,l,l,l,g
				byte a,a,g,l,l,l,l,l,l,g
				byte g,g,l,l,b,b,l,g,l,g
				byte a,g,g,l,b,b,g,a,g,a
				byte a,a,g,g,g,g,a,a,a,a
				
draw_snake_body byte 10,10
				byte a,a,g,g,g,g,g,g,a,a
				byte a,g,g,g,g,g,g,g,g,a
			   	byte g,g,g,l,l,l,l,g,g,g
				byte g,g,l,l,l,l,l,l,g,g
				byte g,g,l,l,l,l,l,l,g,g
				byte g,g,l,l,l,l,l,l,g,g
				byte g,g,l,l,l,l,l,l,g,g
				byte g,g,g,l,l,l,l,g,g,g
				byte a,g,g,g,g,g,g,g,g,a
				byte a,a,g,g,g,g,g,g,a,a
				
draw_food_normal byte 10,10
				byte a,z,a,a,a,a,a,a,z,a
				byte a,z,a,a,a,a,a,a,z,a
			   	byte a,a,z,a,a,a,a,z,a,a
				byte z,z,a,z,z,z,z,a,z,z
				byte a,a,z,r,z,z,r,z,a,a
				byte z,z,z,z,z,z,z,z,z,z
				byte a,a,a,z,z,z,z,a,a,a
				byte a,a,z,a,a,a,a,z,a,a
				byte a,z,a,a,a,a,a,a,z,a
				byte a,z,a,a,a,a,a,a,z,a
draw_food_speed byte 10,10
				byte a,a,a,a,a,a,a,a,a,a
				byte a,a,a,a,a,a,a,a,a,a
			   	byte a,a,a,a,a,a,w,a,a,a
				byte a,a,o,o,a,w,w,a,w,a
				byte a,a,o,y,o,w,a,w,w,a
				byte a,a,o,o,y,o,w,w,a,a
				byte a,a,a,o,o,y,o,a,a,a
				byte a,a,a,a,o,o,o,a,a,a
				byte a,a,a,a,a,a,a,z,a,a
				byte a,a,a,a,a,a,a,a,a,a
draw_food_slow byte 10,10
				byte a,a,a,a,a,a,a,a,a,a
			   	byte a,a,a,a,a,o,o,o,a,a
				byte h,h,a,a,o,y,y,o,o,a
				byte a,h,h,o,y,o,y,o,y,o
				byte a,h,h,o,y,o,o,o,y,o
				byte a,h,h,o,o,y,y,y,o,o
				byte a,a,h,h,o,o,o,o,o,a
				byte a,a,a,h,h,h,h,h,h,a
				byte a,a,a,a,h,h,h,h,h,h
				byte a,a,a,a,a,a,a,a,a,a
draw_food_inc byte 10,10
				byte a,a,a,a,a,a,a,a,a,a
				byte m,a,m,m,m,m,m,a,m,a
				byte m,m,p,p,p,p,p,m,m,a
				byte m,m,z,z,p,z,z,m,m,a
				byte a,m,p,m,m,m,p,m,a,a
				byte a,m,m,r,m,r,m,m,a,a
				byte a,m,p,m,m,m,p,m,a,a
				byte a,a,m,p,p,p,m,a,a,a
				byte a,a,a,m,m,m,a,a,a,a
				byte a,a,a,a,a,a,a,a,a,a
draw_food_dec byte 10,10
				byte a,a,a,a,a,a,a,a,a,a
				byte a,b,a,a,a,a,a,a,b,a
				byte b,w,b,a,a,a,a,b,w,b
				byte b,p,w,b,a,a,b,w,p,b
				byte b,w,p,b,o,o,b,p,w,b
				byte a,b,b,w,b,b,w,b,b,a
				byte a,a,b,w,b,b,w,b,a,a
				byte a,b,p,b,a,a,b,p,b,a
				byte a,b,b,a,a,a,a,b,b,a
				byte a,a,a,a,a,a,a,a,a,a
				
draw_game_over byte 5, 35
				byte a,w,w,a,a,w,a,a,w,a,w,a,a,w,w,a,a,a,a,a,a,w,a,a,w,a,w,a,a,w,w,a,w,w,a
				byte w,a,a,a,w,a,w,a,w,w,w,a,w,a,a,a,a,a,a,a,w,a,w,a,w,a,w,a,w,a,a,a,w,a,w
				byte w,a,w,a,w,w,w,a,w,a,w,a,w,w,w,a,a,a,a,a,w,a,w,a,w,a,w,a,w,w,w,a,w,w,a
				byte w,a,w,a,w,a,w,a,w,a,w,a,w,a,a,a,a,a,a,a,w,a,w,a,w,a,w,a,w,a,a,a,w,a,w
				byte a,w,w,a,w,a,w,a,w,a,w,a,a,w,w,a,a,a,a,a,a,w,a,a,a,w,a,a,a,w,w,a,w,a,w

draw_main_menu byte 5, 19
				byte a,w,w,a,w,w,a,a,a,w,a,a,w,a,a,a,a,w,w
				byte w,a,a,a,w,a,w,a,w,a,w,a,w,a,w,a,w,a,a
				byte a,w,a,a,w,a,w,a,w,w,w,a,w,w,a,a,w,w,w
				byte a,a,w,a,w,a,w,a,w,a,w,a,w,a,w,a,w,a,a
				byte w,w,a,a,w,a,w,a,w,a,w,a,w,a,w,a,a,w,w
				
draw_score byte 5,22
				byte a,w,w,a,a,w,w,a,a,w,a,a,w,w,a,a,a,w,w,a,a,a
				byte w,a,a,a,w,a,a,a,w,a,w,a,w,a,w,a,w,a,a,a,w,a
				byte a,w,a,a,w,a,a,a,w,a,w,a,w,w,a,a,w,w,w,a,a,a
				byte a,a,w,a,w,a,a,a,w,a,w,a,w,a,w,a,w,a,a,a,w,a
				byte w,w,a,a,a,w,w,a,a,w,a,a,w,a,w,a,a,w,w,a,a,a
draw_nb_0 byte 5, 3
				byte a,w,a
				byte w,a,w
				byte w,a,w
				byte w,a,w
				byte a,w,a
draw_nb_1 byte 5, 3
				byte a,w,a
				byte w,w,a
				byte a,w,a
				byte a,w,a
				byte w,w,w
draw_nb_2 byte 5, 3
				byte w,w,a
				byte a,a,w
				byte a,w,a
				byte w,a,a
				byte w,w,w
draw_nb_3 byte 5, 3
				byte w,w,a
				byte a,a,w
				byte a,w,a
				byte a,a,w
				byte w,w,a
draw_nb_4 byte 5, 3
				byte w,a,a
				byte w,a,w
				byte w,w,w
				byte a,a,w
				byte a,a,w
draw_nb_5 byte 5, 3
				byte w,w,w
				byte w,a,a
				byte a,w,a
				byte a,a,w
				byte w,w,a
draw_nb_6 byte 5, 3
				byte a,w,w
				byte w,a,a
				byte w,w,a
				byte w,a,w
				byte a,w,a
draw_nb_7 byte 5, 3
				byte w,w,w
				byte a,a,w
				byte a,w,a
				byte a,w,a
				byte a,w,a
draw_nb_8 byte 5, 3
				byte a,w,a
				byte w,a,w
				byte a,w,a
				byte w,a,w
				byte a,w,a
draw_nb_9 byte 5, 3
				byte a,w,a
				byte w,a,w
				byte a,w,w
				byte a,a,w
				byte w,w,a

				

; --- SCREEN BUFFER ------------------------------------------------------------
.FARDATA?	; segment that contains the screenBuffer for mode 13h drawing
palette			db 768 dup(0)
screenBuffer	db 64000 dup(?)	; the 64000 bytes for the screen

; --- CODE SEGMENT -------------------------------------------------------------
.CODE        ; code segment

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
	;xor		ax, ax
	mov ah, a
	mov al, a
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

renderWorld PROC FAR
	push	ax
	push 	di
	call	clearScreenBuffer

	call drawSnake
	call drawAllFood
	
	call drawScore
	
	call delay
	
	; draw the screen buffer
	call 	updateScreen
	pop di
	pop	ax
	ret	0
renderWorld ENDP

renderMainMenu PROC FAR
	push	ax
	push 	di
	call	clearScreenBuffer

	call drawMainMenu
	
	; draw the screen buffer
	call 	updateScreen
	pop di
	pop	ax
	ret	0
renderMainMenu ENDP

renderGameOver PROC FAR
	push	ax
	push 	di
	call	clearScreenBuffer

	call drawGameOver
	
	; draw the screen buffer
	call 	updateScreen
	pop di
	pop	ax
	ret	0
renderGameOver ENDP

delay PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	push dx
	
timer:
	mov ah, 00h
	int 1ah
	cmp dx, wait_time
	jb timer
	mov al, 18
	mov ah, [snake_speed]
	sub al, ah
	mov ah, 0
	add dx, ax ;0-18, where smaller is faster and 18 is close to 1 second
	mov wait_time, dx
	
	pop dx
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
delay ENDP

;get pixel offset for given board-coord
;stack: the given coord
;@return AX the offset
offsetForCoord PROC NEAR
	push bp
	mov	bp, sp
	
	push bx
	push dx

	mov ax, [bp+4][0] ;get coord from stack
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
	
	mov sp, bp
	pop bp
	ret 2
offsetForCoord ENDP

;draw array
;stack : top - offset where array will be drawn
;		 next - offset of array
drawArray PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	push bx
	push cx
	push si
	push ds
	push di
	push es
	
	cld
	;screenbuffer
	mov ax, seg screenBuffer
	mov es, ax
	mov ax, [bp+4][0]
	add ax, offset screenBuffer ;offset where array will be drawn
	mov di, ax
	;array
	mov ax, @data
	mov ds, ax
	mov ax, [bp+4][2]
	mov si, ax
	;array-width and array-height
	lodsw
	mov cx, 0
	mov bh, ah ;width
	mov bl, al ;height
	
arrayLoop:
	mov cl, bh
	rep movsb ;copy row
	mov ax, SCREEN_X
	mov cl, bh
	sub ax, cx
	add di, ax ;next row
	dec bl
	jnz arrayLoop
	
	pop es
	pop di
	pop ds
	pop si
	pop cx
	pop bx
	pop ax
	
	mov sp, bp
	pop bp
	ret 4
drawArray ENDP

drawMainMenu PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	
	;clear screen
	call clearScreenBuffer
	;draw main menu
	mov ax, offset draw_main_menu
	push ax
	mov ah, 5
	mov al, 10
	push ax
	call offsetForCoord
	push ax
	call drawArray
	
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
drawMainMenu ENDP

drawGameOver PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	
	;draw "game over"
	mov ax, offset draw_game_over
	push ax
	mov ah, 5
	mov al, 10
	push ax
	call offsetForCoord
	push ax
	call drawArray
	;draw score
	call drawScore
	
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
drawGameOver ENDP

drawScore PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	
	mov ax, offset draw_score
	push ax
	mov ah, 0
	mov al, 19
	push ax
	call offsetForCoord
	push ax
	call drawArray
	
	add ax, 22 ;score-width
	push ax
	mov ax, [score] ;integer to draw
	push ax
	call drawInteger

	pop ax
	
	mov sp, bp
	pop bp
	ret 0
drawScore ENDP

;on stack : TOP integer to draw
;           NEXT offset in buffer
drawInteger PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	push bx
	push cx
	push dx
	
	mov cx, 0
	mov bx, 10 ;div by 10
	mov ax, [bp+4][0] ;integer
	
moduloLoop:
	mov dx, 0
	div bx
	push dx
	inc cx ;nb-length++
	cmp ax, 0
	jnz moduloLoop
	
	mov dx, [bp+4][2] ;buffer offset
	
drawNbLoop:
	pop ax
	cmp ax, 0
	jnz @F
	mov bx, offset draw_nb_0
@@:
	cmp ax, 1
	jnz @F
	mov bx, offset draw_nb_1
@@:
	cmp ax, 2
	jnz @F
	mov bx, offset draw_nb_2
@@:
	cmp ax, 3
	jnz @F
	mov bx, offset draw_nb_3
@@:
	cmp ax, 4
	jnz @F
	mov bx, offset draw_nb_4
@@:
	cmp ax, 5
	jnz @F
	mov bx, offset draw_nb_5
@@:
	cmp ax, 6
	jnz @F
	mov bx, offset draw_nb_6
@@:
	cmp ax, 7
	jnz @F
	mov bx, offset draw_nb_7
@@:
	cmp ax, 8
	jnz @F
	mov bx, offset draw_nb_8
@@:
	cmp ax, 9
	jnz @F
	mov bx, offset draw_nb_9
@@:
	push bx ;nb offset
	mov ax, dx ;buffer offset
	push ax
	call drawArray
	add dx, 4 ;nb-width + 1 space
	dec cx ;nb-length--
	jnz drawNbLoop
	
	pop dx
	pop cx
	pop bx
	pop ax
	
	mov sp, bp
	pop bp
	ret 4
drawInteger ENDP

;draw a snake-head at given coord on stack
drawHead PROC NEAR
	push bp
	mov	bp, sp
	
	push ax
	cmp [snake_direction], DIR_UP
	mov ax, offset draw_snake_head_up
	jz draw
	cmp [snake_direction], DIR_RIGHT
	mov ax, offset draw_snake_head_right
	jz draw
	cmp [snake_direction], DIR_DOWN
	mov ax, offset draw_snake_head_down
	jz draw
	mov ax, offset draw_snake_head_left
draw:
	push ax
	mov ax, [bp+4][0]
	push ax
	call offsetForCoord
	push ax
	call drawArray

	pop ax
	
	mov sp, bp
	pop bp
	ret 2
drawHead ENDP

;draw a snake-body-part at given coord on stack
drawBody PROC NEAR
	push bp
	mov	bp, sp
	
	push ax
	
	mov ax, offset draw_snake_body
	push ax
	mov ax, [bp+4][0]
	push ax
	call offsetForCoord
	push ax
	call drawArray

	pop ax
	
	mov sp, bp
	pop bp
	ret 2
drawBody ENDP

drawSnake PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	push bx
	push cx
	push dx
	push si
	push ds
	
	;set segment
	mov ax, @data
	mov ds, ax
	;set offset
	mov ax, offset snake_mem
	add ax, [snake_head]
	mov si, ax
	;size counter
	mov cx, [snake_size]
	
	;get head
	lodsw
	;draw head
	push ax
	call drawHead
	
bodyLoop:
	;next step
	dec cx
	jz return
	;modulo current offset
	mov ax, si
	sub ax, offset snake_mem
	mov bx, BOARD_SIZE
	mov dx, 0
	div bx ;DX : rest = modulo
	add dx, offset snake_mem
	mov si, dx
	;get current body-part
	lodsw
	;draw current body-part
	push ax
	call drawBody
	jmp bodyLoop
	
return:
	
	pop ds
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
drawSnake ENDP

;draw a food-object
;stack : TOP food type
;	     NEXT given coord
drawFood PROC NEAR
	push bp
	mov	bp, sp
	
	push ax
	
	mov bx, [bp+4][0] ;bl : food type
	
	cmp bl, FOOD_NORMAL
	jnz @F
	mov ax, offset draw_food_normal
@@:
	cmp bl, FOOD_SPEED
	jnz @F
	mov ax, offset draw_food_speed
@@:
	cmp bl, FOOD_SLOW
	jnz @F
	mov ax, offset draw_food_slow
@@:
	cmp bl, FOOD_INC
	jnz @F
	mov ax, offset draw_food_inc
@@:
	cmp bl, FOOD_DEC
	jnz @F
	mov ax, offset draw_food_dec
@@:
	push ax
	mov ax, [bp+4][2] ;coord
	push ax
	call offsetForCoord
	push ax
	call drawArray

	pop ax
	
	mov sp, bp
	pop bp
	ret 4
drawFood ENDP

drawAllFood PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	push cx
	push si
	push ds
	
	cld
	;segment
	mov ax, @data
	mov ds, ax
	;offset
	mov ax, offset food_mem
	mov si, ax
	;counter
	mov cx, 0
	mov cl, [food_nb]

foodLoop:
	lodsw
	
	push ax ;coord
	lodsb 
	push ax ;type byte (al)
	call drawFood
	;inc si ;skip type byte
	dec cx
	jnz foodLoop
	
	pop ds
	pop si
	pop cx
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
drawAllFood ENDP

; _------------------------------- END OF CODE ---------------------------------
END
