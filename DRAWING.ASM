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
SCREEN_X equ 320
SCREEN_Y equ 200
BOARD_X equ 32
BOARD_Y equ 19
BOARD_SIZE equ BOARD_X * BOARD_Y

DIR_UP equ 0
DIR_RIGHT equ 1
DIR_DOWN equ 2
DIR_LEFT equ 3

FOOD_MAX equ 5

a equ 3 ;background color
z equ 0 ;black
b equ 1 ;blue
g equ 2 ;green
q equ 3 ;cyan
r equ 4 ;red
m equ 5 ;magenta
o equ 6 ;brown
w equ 7 ;white
y equ 14 ;yellow
l equ 10 ;light green

; --- DATA SEGMENT -------------------------------------------------------------
.DATA        ; data segment, variables
oldVideoMode	db ?

hardOffset	dw 0 ; test variable
snake_mem dw BOARD_SIZE dup(?)

snake_size dw 0 ;size of snake
snake_direction db DIR_UP ;direction (0=UP, 1=RIGHT, 2=DOWN, 3=LEFT)
snake_head dw 0 ;offset to head starting from snake_mem
snake_speed db 16 ;snake-speed (0 slowest to 18 fastest)

food_nb db 0 ;current nb of food-objects
food_mem db 3*FOOD_MAX dup(?) ;array with food-objects

score dw 0 ;the game-score

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
				byte o,o,o,o,o,o,o,o,o,o
				byte o,o,o,o,o,o,o,o,o,o
			   	byte o,o,o,o,o,o,o,o,o,o
				byte o,o,o,o,o,o,o,o,o,o
				byte o,o,o,o,o,o,o,o,o,o
				byte o,o,o,o,o,o,o,o,o,o
				byte o,o,o,o,o,o,o,o,o,o
				byte o,o,o,o,o,o,o,o,o,o
				byte o,o,o,o,o,o,o,o,o,o
				byte o,o,o,o,o,o,o,o,o,o
				
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
main PROC NEAR
	mov	ax, @data	; get data segment address
	mov	ds, ax		; set DS to data segment

	; Initialize random number generator
	call	randInit
	
	; Install our own keyboard handler
	call	installKeyboardHandler

	; fade to black
	call	fadeToBlack
	
	; clear video buffer
	call	clearScreenBuffer

	; draw the screen buffer
	call 	updateScreen
	
	;init game variables
	call initGame
	
	; set mode 13h
	mov		ax, 13h
	push	ax
	call	setVideoMode
	mov		[oldVideoMode], al
	
	;first food
	call newFood
	call newFood
	call newFood
	
@main_loop:	
	call	updateWorld	; this would contain the game code (like AI)

	call	renderWorld	; draws the world
	
	call	handleGameInput	; handle user input
	cmp		al, 0
	jz		@main_loop
	
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

renderWorld PROC NEAR
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

updateWorld PROC NEAR
	push bp
	mov bp, sp
	
	call move
	call eatFood
	mov ax, @data
	mov ds, ax
	mov ax, offset snake_mem
	add ax, [snake_head]
	mov si, ax
	lodsw
	push ax ;coord
	mov ax, 3 ;skip first 3 parts
	push ax
	call collide
	cmp ax, 0
	jz continue
	
	; Exit to DOS
	mov		ax, 4c00h	; exit to DOS function, return code 00h
	int		21h			; call DOS
	
continue:
	
	mov sp, bp
	pop bp
	ret 0
updateWorld ENDP

; Reads keyboard buffer and acts (returns non-zero if loop should end, 0 otherwise)
handleGameInput PROC NEAR
	push	es

	mov	ax, seg __keysActive
	mov	es, ax

	xor	ah, ah
	mov	al, es:[__keysActive]
	cmp	al, 0
	jz	@done		; no key pressed

	; handle keys
	mov	al, es:[__keyboardState][SCANCODE_UP]	; test UP key
	cmp	al, 0
	jz @F	; jump next
	cmp [snake_direction], DIR_DOWN
	jz @F	; jump next
	; call some function to handle this key
	mov	al, DIR_UP
	mov [snake_direction], al
@@:
	mov	al, es:[__keyboardState][SCANCODE_DOWN]	; test DOWN key
	cmp	al, 0
	jz @F	; jump next
	cmp [snake_direction], DIR_UP
	jz @F	; jump next
	; call some function to handle this key
	mov	al, DIR_DOWN
	mov [snake_direction], al
@@:
	mov	al, es:[__keyboardState][SCANCODE_LEFT]	; test LEFT key
	cmp	al, 0
	jz @F	; jump next
	cmp [snake_direction], DIR_RIGHT
	jz @F	; jump next
	; call some function to handle this key
	mov	al, DIR_LEFT
	mov [snake_direction], al
@@:
	mov	al, es:[__keyboardState][SCANCODE_RIGHT]	; test RIGHT key
	cmp	al, 0
	jz @F	; jump next
	cmp [snake_direction], DIR_LEFT
	jz @F	; jump next
	; call some function to handle this key
	mov	al, DIR_RIGHT
	mov [snake_direction], al
@@:
	
	; finally, let's put the ESC key status as return value in AX
	mov	al, es:[__keyboardState][SCANCODE_ESC]	; test ESC

@done:
	pop	es
	ret 0
handleGameInput ENDP

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

;draw a food-object at given coord on stack
drawFood PROC NEAR
	push bp
	mov	bp, sp
	
	push ax
	
	mov ax, offset draw_food_normal
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
	
	push ax
	call drawFood
	inc si ;skip type byte
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

;========================
;-------SNAKE GAME-------
;========================
initGame PROC NEAR
	push bp
	mov	bp, sp
	
	push ax
	push cx
	push di ;used with stosw
	push es
	
	;initialize size
	mov WORD PTR [snake_size], 3 ;initial size = 3
	;initialize direction
	mov BYTE PTR [snake_direction], DIR_UP ;initial direction = LEFT
	;initialize head
	mov WORD PTR [snake_head], 10 ;head is at beginning of snake_mem
	
	mov ax, seg snake_mem
	mov es, ax
	mov ax, offset snake_mem
	add ax, [snake_head]
	mov di, ax
	
	;initialize snake
	;inverse x and y because when writing word with stosw,
	;al will be written first
	mov ah, 16 ;snake-head.x
	mov al, 1 ;snake-head.y
	
	mov cx, 3 ; size counter
snakeInitLoop:
	stosw ;store ax in snake_mem : mov es:[di], ax
	inc al ;update x-coord
	dec cx
	jnz snakeInitLoop
	
	pop es
	pop di
	pop cx
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
initGame ENDP

;returns new coord of head according to current direction
;AX : new coord
nextHead PROC NEAR
	push bp
	mov	bp, sp

	push bx
	push dx
	push di
	push es
	
	;set segment
	mov ax, seg snake_mem
	mov es, ax
	;set offset
	mov ax, offset snake_mem
	add ax, [snake_head]
	mov di, ax
	
	;coord
	mov al, [di] ;snake-head.y
	mov ah, [di+1] ;snake-head.x
	
	mov bx, ax ;save snake-head coord
	
	cmp [snake_direction], DIR_UP ;moving to top ?
	jz top
	cmp [snake_direction], DIR_RIGHT ;moving to right ?
	jz right
	cmp [snake_direction], DIR_DOWN ; moving to bottom ?
	jz bottom
	cmp [snake_direction], DIR_LEFT ; moving to left ?
	jz left

top:
	mov ah, 0
	dec ax
	jns positive
	add al, BOARD_Y
positive:
	mov ah, bh ;saved x-coord
	jmp return
	
right:
	inc ah ;x+1 because moving to right
	
	mov al, ah ;prepare div
	mov ah, 0
	mov dl, BOARD_X
	idiv dl ;AH : rest = modulo
	mov al, bl ;saved y-coord
	jmp return

bottom:
	inc al ;y+1 because moving to bottom
	
	mov ah, 0 ;prepare div
	mov dl, BOARD_Y
	idiv dl ;AH : rest
	mov al, ah ;modified y-coord
	mov ah, bh ;saved x-coord
	jmp return

left:
	dec ah ;x-1 because moving to left
	
	mov al, ah ;prepare div
	mov ah, 0
	mov dl, BOARD_X
	idiv dl
	mov al, bl ; saved y-coord
	
return:
	;ax contains new snake-head coord
	pop es
	pop di
	pop dx
	pop bx
	
	mov sp, bp
	pop bp
	ret 0
nextHead ENDP

move PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	push bx
	push dx
	push di
	push es
	
	;get new-head coord
	call nextHead
	push ax ;store result
	;set segment
	mov ax, seg snake_mem
	mov es, ax
	;set new snake_head offset
	mov ax, [snake_head]
	sub ax, 2 ;next head is 1 word on the left in mem
	
	jns positive
	add ax, BOARD_SIZE
positive:
	mov [snake_head], ax ;update snake-head pos in mem
	
	;set offset
	mov ax, offset snake_mem
	add ax, [snake_head]
	mov di, ax
	;get new-head coord
	pop ax
	stosw ;write new-head in mem
	;mov es:[di], ah
	;mov es:[di+1], al
	
	pop es
	pop di
	pop dx
	pop bx
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
move ENDP

grow PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	push di
	push es
	
	mov ax, seg snake_size
	mov es, ax
	mov ax, offset snake_size
	mov di, ax
	mov ax, [snake_size]
	inc ax
	stosw ;snake_size++
	
	pop es
	pop di
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
grow ENDP

;see if given coord is contained in body of snake
;stack : top = nb of bodyparts to be skipped from head
;              (0=check all including head, 1=check all except head...)
;        next = coord to check
;AX : result (0=false, 1=true)
collide PROC NEAR
	push bp
	mov bp, sp
	
	push bx
	push cx
	push dx
	push di
	push es
	
	;set segment
	mov ax, seg snake_size
	mov es, ax
	;snake_mem offset
	mov ax, offset snake_mem
	mov di, ax
	;set offset
	mov ax, 2
	mov cx, [snake_size]
	inc cx ;+1 to check tail because in bodyloop, decrease before compare
	mul cx 
	add ax, [snake_head] ;AX contains offset to tail
	;modulo offset
	mov dx, 0
	mov bx, BOARD_SIZE
	idiv bx ;DX : rest = modulo
	
	mov ax, [bp+4][2] ;coord to check
	
bodyLoop:
	cmp cx, [bp+4][0] ;reached bodyparts to skip ?
	jz notCollided
	dec dx
	jns positive
	add dx, BOARD_SIZE
positive:
	add di, dx
	;mov bl, [di] ;y-coord
	;mov bh, [di-1] ;x-coord
	mov bh, [di] ;x-coord
	mov bl, [di-1] ;y-coord
	sub di, dx
	dec dx
	cmp ax, bx ;see if coord are equal
	jz collided
	dec cx ;counter--
	jmp bodyLoop
	
collided:
	mov ax, 1 ;true
	jmp return
notCollided:
	mov ax, 0 ;false
	
return:
	pop es
	pop di
	pop dx
	pop cx
	pop bx

	mov sp, bp
	pop bp
	ret 4
collide ENDP

;========================
;----------FOOD----------
;========================

newFood PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	push bx
	push di
	push es
	
	;set segment
	mov ax, seg food_mem
	mov es, ax
	;set new-food offset
	mov ax, 3
	mov bl, [food_nb]
	mul bl
	add ax, offset food_mem
	mov di, ax
	;generate random coord
	mov ax, BOARD_X
	push ax
	call randLimited
	mov bh, al ;save x-coord
	mov ax, BOARD_Y
	push ax
	call randLimited
	mov bl, al ;save y-coord
	
collisionLoop:
	push bx ;collision check
	mov ax, 0 ;check whole body
	push ax 
	call collide
	cmp ax, 0
	jz notCollided
	dec bh
	jns collisionLoop ;x-coord valid, loop again
	add bh, BOARD_X ;set x-coord
	dec bl
	jns collisionLoop ;y-coord valid, loop again
	add bl, BOARD_Y ;set y-coord
	jmp collisionLoop
	
notCollided: ;bx : new-food coord
	mov [di+1], bh ;x-coord
	mov [di], bl ;y-coord
	;mov al, 0 ;food type
	call newFoodType ;food type
	mov [di+2], al
	
	;update food count
	mov al, [food_nb]
	inc al
	mov [food_nb], al
	
	pop es
	pop di
	pop bx
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
newFood ENDP

newFoodType PROC NEAR
	push bp
	mov bp, sp
	
	push bx
	
	mov ax, 100
	push ax
	call randLimited
	mov bx, ax

	mov ax, 4 ;decrease food

	cmp bx, 90
	jae @F
	mov ax, 3 ;increase food
@@:	
	cmp bx, 80
	jae @F
	mov ax, 2 ;slow food
@@:	
	cmp bx, 70
	jae @F
	mov ax, 1 ;speed food
@@:
	cmp bx, 60
	jae @F
	mov ax, 0 ;normal food
@@:
	pop bx
	
	mov sp, bp
	pop bp
	ret 0
newFoodType ENDP

eatFood PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	push bx
	push cx
	push di
	push si
	push ds
	push es
	
	cld
	;set segment
	mov ax, @data
	mov ds, ax
	mov es, ax
	;get snake-head coord
	mov ax, offset snake_mem
	add ax, [snake_head]
	mov si, ax
	lodsw ;mov ax, ds:[si]
	mov bx, ax ;snake-coord
	;set offset
	mov ax, offset food_mem
	mov si, ax
	;counter
	mov cx, 0
	mov cl, [food_nb]
	
foodLoop:
	lodsw
	cmp ax, bx ;head-coord == food-coord ?
	jz sameCoord
	inc si ;skip type byte
	dec cx ;update counter
	jnz foodLoop
	
	;no food at snake-head.coord
	jmp return
	
sameCoord:
	lodsb ;AL : food type
	mov bl, al
	
	;update food count
	mov ax, 0
	mov al, [food_nb]
	dec al
	mov [food_nb], al
	;swapping
	sub si, 3
	mov cl, 3
	mul cl ;AX : offset to last food
	mov di, si ;offset to used food
	mov si, offset food_mem
	add si, ax ;offset to last food
	rep movsb ;copy 3 bytes
	
	;TODO call proc depending on food type
	cmp bl, 0
	jz normal
	cmp bl, 1
	jz speed
	cmp bl, 2
	jz slow
	cmp bl, 3
	jz increase
	cmp bl, 4
	jz decrease
	
normal:
	call normalFood
	jmp return
speed:
	call speedFood
	jmp return
slow:
	call slowFood
	jmp return
increase:
	call incFood
	jmp return
decrease:
	call decFood
	jmp return
	
return:
	pop es
	pop ds
	pop si
	pop di
	pop cx
	pop bx
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
eatFood ENDP

normalFood PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	push bx
	
	call newFood
	call grow
	;update score
	mov ax, 0
	mov al, [snake_speed]
	mov bl, 10
	mul bl
	add ax, [score]
	mov [score], ax
	
	pop bx
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
normalFood ENDP

speedFood PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	push bx
	
	call newFood
	call grow
	;update score
	mov ax, 0
	mov al, [snake_speed]
	mov bl, 10
	mul bl
	add ax, [score]
	mov [score], ax
	;update speed
	mov ax, 0
	mov al, [snake_speed]
	cmp ax, 18
	jz return
	inc al
	mov [snake_speed], al
	
return:

	pop bx
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
speedFood ENDP

slowFood PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	push bx
	
	call newFood
	call grow
	;update score
	mov ax, 0
	mov al, [snake_speed]
	mov bl, 10
	mul bl
	add ax, [score]
	mov [score], ax
	;update speed
	mov ax, 0
	mov al, [snake_speed]
	cmp ax, 0
	jz return
	dec al
	mov [snake_speed], al
	
return:

	pop bx
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
slowFood ENDP

incFood PROC
	push bp
	mov bp, sp
	
	push ax
	push bx
	
	call newFood
	mov al, [food_nb]
	cmp al, FOOD_MAX
	jz @F
	call newFood
@@:
	call grow
	;update score
	mov ax, 0
	mov al, [snake_speed]
	mov bl, 10
	mul bl
	add ax, [score]
	mov [score], ax
	
	pop bx
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
incFood ENDP

decFood PROC
	push bp
	mov bp, sp
	
	push ax
	push bx
	
	mov al, [food_nb]
	cmp al, 1
	jnz @F
	call newFood
@@:
	call grow
	;update score
	mov ax, 0
	mov al, [snake_speed]
	mov bl, 10
	mul bl
	add ax, [score]
	mov [score], ax
	
	pop bx
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
decFood ENDP

; _------------------------------- END OF CODE ---------------------------------
END main
