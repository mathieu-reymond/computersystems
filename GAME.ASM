;==========================
;Game functionality
;==========================
.MODEL large ; one data and one code segment, stack and data segment are grouped
.STACK 1024  ; stack, 1024 bytes

;INCLUDE Rand.inc
INCLUDE DRAWING.INC

.DATA        ; data segment, global variables

BOARD_X equ 32
BOARD_Y equ 20
BOARD_SIZE equ BOARD_X * BOARD_Y
snake_mem dw BOARD_SIZE dup(?)

.CODE        ; code segment

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

initialize PROC FAR
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
initialize ENDP

drawSnake PROC FAR
	push ax
	push bx
	push dx
	push di
	push si

	mov ax, 11
	mov ax, 11
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
	
	call initialize
	call initDrawing
	;call drawSnake
	mov ah, 10
	mov al, 10
	call drawHead
	
	;mov dh, 2
	;call move

	mov	ax, 4c00h	; exit to DOS
	int	21h
	
END main
; _------------------------------- END OF CODE ---------------------------------
;END
	