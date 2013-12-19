; ==============================================================================
; Example for buffered drawing in mode 13h.
; Example showing palette manipulation via port IO.
; Example for a very generic game-loop.
; ==============================================================================
.MODEL large	; multiple data segments and multiple code segments
.STACK 2048  	; stack

; --- INCLUDES -----------------------------------------------------------------

include RAND.INC
include INPUT.INC
include DRAWING.INC
include GAME.INC

; --- MACROS AND CONSTANTS -----------------------------------------------------

; Other constants

; --- DATA SEGMENT -------------------------------------------------------------
.DATA        ; data segment, variables

snake_mem dw BOARD_SIZE dup(?)

snake_size dw 0 ;size of snake
snake_direction db DIR_UP ;direction (0=UP, 1=RIGHT, 2=DOWN, 3=LEFT)
snake_head dw 0 ;offset to head starting from snake_mem
snake_speed db 16 ;snake-speed (0 slowest to 18 fastest)

food_nb db 0 ;current nb of food-objects
food_mem db 3*FOOD_MAX dup(?) ;array with food-objects

score dw 0 ;the game-score

; --- CODE SEGMENT -------------------------------------------------------------
.CODE        ; code segment

startGame PROC FAR
	push bp
	mov bp, sp
	
	push ax
	
	;init game variables
	call initGame
	;first food
	call newFood
	
@gameLoop:	
	call	updateWorld	; this would contain the game code (like AI)
	cmp al, 0 ;collision ?
	jnz return

	call	renderWorld	; draws the world
	
	call	handleGameInput	; handle user input
	cmp		al, 0
	jnz		return
	jmp @gameLoop
	
return:

	pop ax
	
	mov sp, bp
	pop bp
	ret 0
startGame ENDP

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
	
	;return ax(0 = continue)
	
	mov sp, bp
	pop bp
	ret 0
updateWorld ENDP

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

	mov ax, FOOD_DEC ;decrease food

	cmp bx, 90
	jae @F
	mov ax, FOOD_INC ;increase food
@@:	
	cmp bx, 80
	jae @F
	mov ax, FOOD_SLOW ;slow food
@@:	
	cmp bx, 70
	jae @F
	mov ax, FOOD_SPEED ;speed food
@@:
	cmp bx, 60
	jae @F
	mov ax, FOOD_NORMAL ;normal food
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
	cmp bl, FOOD_NORMAL
	jz normal
	cmp bl, FOOD_SPEED
	jz speed
	cmp bl, FOOD_SLOW
	jz slow
	cmp bl, FOOD_INC
	jz increase
	cmp bl, FOOD_DEC
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

END