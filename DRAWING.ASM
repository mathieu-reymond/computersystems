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
BOARD_Y equ 20
BOARD_SIZE equ BOARD_X * BOARD_Y

DIR_UP equ 0
DIR_RIGHT equ 1
DIR_DOWN equ 2
DIR_LEFT equ 3

FOOD_MAX equ 5

; --- DATA SEGMENT -------------------------------------------------------------
.DATA        ; data segment, variables
oldVideoMode	db ?

hardOffset	dw 0 ; test variable
snake_mem dw BOARD_SIZE dup(?)

snake_size dw 0 ;size of snake
snake_direction db DIR_UP ;direction (0=UP, 1=RIGHT, 2=DOWN, 3=LEFT)
snake_head dw 0 ;offset to head starting from snake_mem

food_nb db 0 ;current nb of food-objects
food_mem db 3*FOOD_MAX dup(?) ;array with food-objects

WAIT_TIME dw 0

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
	
@main_loop:	
	;call	updateWorld	; this would contain the game code (like AI)

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

renderWorld PROC NEAR
	push	ax
	push 	di
	call	clearScreenBuffer

	; draw a random rectangle
	call	rand
	and		ax, 0ffh
	;push	ax
	call	rand
	and		ax, 07fh
	;push	ax
	
	;move test - OK
	call move
	;grow test - OK
	;call grow
	;collide test - OK
	;call nextHead
	;push ax ;coord to check
	;mov ax, 1
	;push ax ;check whole snake
	;call collide
	;cmp ax, 1 ;result true ?
	;jnz noCollide
	;mov al, [snake_direction]
	;inc ax
	;mov BYTE PTR [snake_direction], al
noCollide:
	;call 	drawRect
	call drawSnake
	;nextHead test - OK
	;call nextHead
	;push ax
	;call drawHead
	
	;eatFood test
	call eatFood
	
	;newFood test
	;call newFood
	;drawFood test - OK
	;mov ax, offset food_mem
	;mov di, ax
	;mov ah, [di]
	;mov al, [di+1]
	;push ax
	;call drawFood
	;drawAllFood test
	call drawAllFood
	
	call delay
	
	; draw the screen buffer
	call 	updateScreen
	pop di
	pop	ax
	ret	0
renderWorld ENDP

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
	; call some function to handle this key
	mov	al, DIR_UP
	mov [snake_direction], al
@@:
	mov	al, es:[__keyboardState][SCANCODE_DOWN]	; test DOWN key
	cmp	al, 0
	jz @F	; jump next
	; call some function to handle this key
	mov	al, DIR_DOWN
	mov [snake_direction], al
@@:
	mov	al, es:[__keyboardState][SCANCODE_LEFT]	; test LEFT key
	cmp	al, 0
	jz @F	; jump next
	; call some function to handle this key
	mov	al, DIR_LEFT
	mov [snake_direction], al
@@:
	mov	al, es:[__keyboardState][SCANCODE_RIGHT]	; test RIGHT key
	cmp	al, 0
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

; Reads keyboard buffer and acts (returns non-zero if loop should end, 0 otherwise)
handleInput PROC NEAR
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
	; call some function to handle this key
	mov	ax, SCREEN_X
	sub [hardOffset], ax
	sub [hardOffset], ax
@@:
	mov	al, es:[__keyboardState][SCANCODE_DOWN]	; test DOWN key
	cmp	al, 0
	jz @F	; jump next
	; call some function to handle this key
	mov	ax, SCREEN_X
	add [hardOffset], ax
	add [hardOffset], ax
@@:
	mov	al, es:[__keyboardState][SCANCODE_LEFT]	; test LEFT key
	cmp	al, 0
	jz @F	; jump next
	; call some function to handle this key
	dec [hardOffset]
	dec [hardOffset]
@@:
	mov	al, es:[__keyboardState][SCANCODE_RIGHT]	; test RIGHT key
	cmp	al, 0
	jz @F	; jump next
	; call some function to handle this key
	inc [hardOffset]
	inc [hardOffset]
@@:
	
	; finally, let's put the ESC key status as return value in AX
	mov	al, es:[__keyboardState][SCANCODE_ESC]	; test ESC

@done:
	pop	es
	ret 0
handleInput ENDP

; Draw a rectangle at the center of the screen buffer.
; W, H passed on stack.
drawRect PROC NEAR
	push	bp
	mov	bp, sp
	
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	es
	
	; set segment
	mov	ax, seg screenBuffer
	mov	es, ax
	
	; Calculate posX
	mov	ax, [bp + 4][2]
	neg	ax
	add	ax, SCREEN_X
	shr	ax, 1
	mov	bx, ax		; posX is in BX now
	
	; Calculate posY
	mov	ax, [bp + 4][0]
	neg	ax
	add	ax, SCREEN_Y
	shr	ax, 1		; and posY is in AX
	
	; Calculate offset of top-left corner
	mov	dx, SCREEN_X
	mul	dx		; AX = posY * SCREEN_X
	add	ax, bx		; AX now contains start offset of rectangle
	add	ax, offset screenBuffer
	add	ax, [hardOffset]
	
	; Draw upper horizontal line
	mov	di, ax
	mov	cx, [bp + 4][2]	; rect W
	mov	al, 15	; color
	cld
	rep	stosb	; draw	
	
	; Draw right vertical line	
	mov		cx, [bp + 4][0]	; rect H
	dec	di
@@:
	mov	es:[di], al	; set pixel
	add	di, SCREEN_X	; jump to next pixel (on next line)
	loop	@B
	
	; Draw bottom horizontal line
	mov	cx, [bp+4][2]	; rect W
	std	; count backwards
	rep	stosb	; draw
	
	; Draw left vertical line
	mov	cx, [bp + 4][0]	; rect H
	inc di
@@:
	mov	es:[di], al	; set pixel
	sub	di, SCREEN_X	; jump to next pixel (on next line)
	loop	@B

	; We are done
	pop	es
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	; return
	pop	bp
	ret	4
drawRect ENDP

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
	add dx, 3 ;1-18, where smaller is faster and 18 is close to 1 second
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

;draw a snake-head at given coord on stack
drawHead PROC NEAR
	push bp
	mov	bp, sp
	
	push ax
	push bx
	push cx
	push di
	push es
	
	; set segment
	mov	ax, seg screenBuffer
	mov	es, ax
	
	mov bx, [bp+4][0]
	push bx
	call offsetForCoord
	add	ax, offset screenBuffer
	
	mov di, ax
	mov al, 1 ;color from palette
	
	;temp : make a filled square
	mov bx, 10 ;(SCREEN_Y/BOARD_Y)
@yLoop:
	mov cx, 10 ;(SCREEN_X/BOARD_X)
	rep stosb ;loop cx times the instruction mov es:[di], al
	mov cx, SCREEN_X
	sub cx, 10
	add di, cx
	dec bx
	jnz @yLoop
	
	pop es
	pop di
	pop cx
	pop bx
	pop ax
	
	mov sp, bp
	pop bp
	ret 2
drawHead ENDP

drawSnake PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	push bx
	push cx
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
	;size counter
	mov cx, [snake_size]
	
bodyLoop:
	;get current body-part
	mov ah, es:[di]
	inc di
	mov al, es:[di]
	inc di
	;draw current body-part
	push ax
	call drawHead
	;modulo current offset
	mov ax, di
	sub ax, offset snake_mem
	mov bx, BOARD_SIZE
	mov dx, 0
	div bx ;DX : rest = modulo
	add dx, offset snake_mem
	mov di, dx
	;next step
	dec cx
	jnz bodyLoop
	
	pop es
	pop di
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
	push bx
	push cx
	push di
	push es
	
	; set segment
	mov	ax, seg screenBuffer
	mov	es, ax
	
	mov bx, [bp+4][0]
	push bx
	call offsetForCoord
	add	ax, offset screenBuffer
	
	mov di, ax
	mov al, 5 ;color from palette
	
	;temp : make a filled square
	mov bx, 10 ;(SCREEN_Y/BOARD_Y)
@yLoop:
	mov cx, 10 ;(SCREEN_X/BOARD_X)
	rep stosb ;loop cx times the instruction mov es:[di], al
	mov cx, SCREEN_X
	sub cx, 10
	add di, cx
	dec bx
	jnz @yLoop
	
	pop es
	pop di
	pop cx
	pop bx
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
	lodsw ;ah : y-coord, al : x-coord !
	mov bh, al
	mov bl, ah
	
	push bx
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
	mov ah, 1 ; snake-head.y
	mov al, 16 ; snake-head.x
	
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
	mov ah, [di] ;snake-head.x
	mov al, [di+1] ;snake-head.y
	
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
	;stosw ;write new-head in mem
	mov es:[di], ah
	mov es:[di+1], al
	
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

;see if given coord is contained id body of snake
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
	mov bl, [di] ;y-coord
	mov bh, [di-1] ;x-coord
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
	mov [di], bh ;x-coord
	mov [di+1], bl ;y-coord
	mov al, 0 ;food type
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
	;TEMP
	call newFood
	call grow
	
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

; _------------------------------- END OF CODE ---------------------------------
END main
