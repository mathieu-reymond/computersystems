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

; --- DATA SEGMENT -------------------------------------------------------------
.DATA        ; data segment, variables
oldVideoMode	db ?

hardOffset	dw 0 ; test variable

snake_mem dw BOARD_SIZE dup(?) ;snake memory

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

;=================================
;--------SNAKE GAME---------------
;=================================

;returns new coord of head according to current direction (stored in dh)
;AX : new coord
nextHead PROC NEAR
	push bp
	mov bp, sp
	
	push bx
	push dx
	
	mov di, es
	mov ah, [di] ;snake-head.x
	mov al, [di+1] ;snake-head.y
	
	mov bx, ax ;save snake-head coord
	
	cmp dh, 0 ;moving to top ?
	jz top
	cmp dh, 1 ;moving to right ?
	jz right
	cmp dh, 2 ; moving to bottom ?
	jz bottom
	cmp dh, 3 ; moving to left ?
	jz left

top:
	mov ah, al ;snake-head.y -1 could be negative, need to be in AH to avoid overflow
	dec ah ;y-1 because moving to top
	
	mov al, ah ;prepare div
	mov ah, 0
	mov dl, BOARD_Y
	idiv dl ;AH : rest = modulo
	mov al, ah ;modified y-coord
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
	pop dx
	pop bx
	
	mov sp, bp
	pop bp
	ret 0
nextHead ENDP
	

;snake moves from one position depending on DH (direction)
;new snake-head.coord are placed 2 bytes left of old snake-head.coord in the memory segment
move PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	push bx
	push dx
	
	call nextHead ;AX : new-snake-head.coord
	push ax ;save new coord on stack
	;new-snake-head = [(old-snake-head - mem-segm - 2) % BOARD_SIZE] + mem-segm
	mov ax, es
	mov bx, ds
	sub ax, bx
	sub ax, 2 ;snake-head moved 2 bytes to the left in memory segment
	
	mov dx, 0 ;prepare div
	mov bx, BOARD_SIZE
	idiv bx ;DX : rest = modulo
	
	mov bx, ds
	add bx, dx ;new position of snake head
	pop ax ;get new-snake-head.coord
	mov [bx], ah ;write new-snake-head.x in new position
	mov [bx+1], al ;write new-snake-head.y in new position
	
	mov es, bx ;update pointer to snake-head
	
	pop dx
	pop bx
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
move ENDP

;snake-size = snake-size + 1
;need to be moved before doing collision
grow PROC NEAR
	push bp
	mov bp, sp
	
	inc cx ;snake-length + 1 : tail doesn't move
	
	mov sp, bp
	pop bp
	ret 0
grow ENDP

;see if current snake-head collides with it's body
;AX = 1 if collision, AX = 0 if not
;TODO other possibilty of return ?
collide PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	push bx
	push dx
	push si
	
	mov si, cx ;counter to loop over whole body
	
	mov ax, si
	mov dx, 0
	mov bx, 2
	mul bx
	mov si, ax ;counter*2 because 2 bytes per coord
	
	mov di, es
	mov ah, [di] ;get snake-head.x
	mov al, [di+1] ;get snake-head.y
	
	add di, si
bodyLoop: ;loop from tail to head
	dec si
	dec di
	mov bl, [di] ;get body-part.y
	dec si
	dec di
	mov bh, [di] ;get body-part.x
	cmp ax, bx ;head.x == current-body-part.x && head.y == current-body-part.y ?
	jz collided
	cmp si, 6 ;no need to check first 3 snake-parts, they will never collide
	jz notCollided
	jmp bodyLoop

collided:
	mov ax, 1 ;collided, AX = 1 (true)
	jmp return
notCollided:
	mov ax, 0 ;not collided, AX = 0 (false)
	jmp return
	
return:
	
	pop si
	pop dx
	pop bx
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
collide ENDP

makeFood PROC NEAR
	push bp
	mov bp, sp
	
	;food generated from random number
	;call rand ;AX: random number
	mov ax, 10
	
	mov bx, ax
	mov ah, 0 ;x%BOARD_X
	mov dl, BOARD_X
	div dl
	
	mov al, bh
	mov bh, ah ;new x-coord saved
	mov ah, 0 ;y%BOARD_Y
	mov dl, BOARD_Y
	div dl
	mov bl, ah ;new y-coord saved
	
	;TODO new coord collided with snake-part
	
	mov sp, bp
	pop bp
	ret 0
makeFood ENDP

initGame PROC FAR
	push bp
	mov bp, sp
	
	mov ax, @data
	mov ax, offset snake_mem ;start of snake memory
	mov ds, ax
	mov es, ax ;head of snake (first in begin of snake memory)
	
	;initialize random number generator
	;call randInit
	
	;initialize snake
	mov ah, 16 ; snake-head.x
	mov al, 10 ; snake-head.y
	mov cx, 0 ; size
	
	mov si, 0
snakeInitLoop:
	mov es:[si], ah ;set x in mem
	inc si ;counter++
	mov es:[si], al ;set y in mem
	inc ah ;x-coord++ (for next body-part of snake)
	inc si
	inc cx ;size++
	cmp cx, 3 ;init-size reached ?
	jnz snakeInitLoop
	
	mov sp, bp
	pop bp
	ret 0
initGame ENDP

drawSnake PROC FAR
	push ax
	push bx
	push dx
	push di
	push si

	mov di, es
	mov ah, [di]
	inc di
	mov al, [di]
	inc di
	call drawHead
	
	mov si, 1 ;head already drawn
@bodyLoop:
	mov ax, di
	mov dx, ds
	sub ax, dx
	
	mov dx, 0 ;prepare dx
	mov bx, BOARD_SIZE
	idiv bx ;DX = rest = modulo
	
	mov di, ds
	add di, dx
	
	mov ah, [di]
	inc di
	mov al, [di]
	inc di
	call drawHead ;should be drawBody
	inc si
	cmp si, cx ;if counter == snake-size, finished looping
	jnz @bodyLoop
	
	pop si
	pop di
	pop dx
	pop bx
	pop ax
	ret 0
drawSnake ENDP

main:
	;call initGame
	call initDrawing
	
	;Restore original video mode
	mov		al, [oldVideoMode]
	xor		ah, ah
	push	ax
	call	setVideoMode
	
	mov	ax, 4c00h	; exit to DOS
	int	21h

; _------------------------------- END OF CODE ---------------------------------
END main
