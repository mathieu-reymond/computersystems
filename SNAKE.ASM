

;returns new coord of head according to current direction (stored in dh)
;AX : new coord
nextHead PROC NEAR
	push bp
	mov bp, sp
	
	push bx
	push dx
	
	mov ah, [es] ;snake-head.x
	mov al, [es+1] ;snake-head.y
	
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
	


move PROC NEAR
	push bp
	mov bp, sp
	
	push ax
	push bx
	push dx
	
	;new-snake-head = [(old-snake-head - mem-segm - 2) % BOARD_SIZE] + mem-segm
	mov ax, es
	sub ax, ds
	sub ax, 2 ;snake-head moved 2 bytes to the left in memory segment
	
	mov dx, 0 ;prepare div
	mov bx, BOARD_SIZE
	idiv bx ;DX : rest = modulo
	
	call nextHead ;AX : new-snake-head.coord
	mov es, ds
	add es, dx ;new position of snake head
	mov [es], ah ;write new-snake-head.x in new position
	mov [es+1], al ;write new-snake-head.y in new position
	
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
	
	call move ;move one position
	inc cx ;snake-length + 1 : tail doesn't move
	
	mov sp, bp
	pop bp
	ret 0
grow ENDP
	
	
	
	