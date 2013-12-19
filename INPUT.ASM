; ==============================================================================
; Example for buffered drawing in mode 13h.
; Example showing palette manipulation via port IO.
; Example for a very generic game-loop.
; ==============================================================================
.MODEL large	; multiple data segments and multiple code segments
.STACK 2048  	; stack

; --- INCLUDES -----------------------------------------------------------------

include KEYB.INC
include INPUT.INC
include GAME.INC

;  --- CODE SEGMENT -------------------------------------------------------------
.CODE        ; code segment

; Reads keyboard buffer and acts (returns non-zero if loop should end, 0 otherwise)
handleMainMenuInput PROC FAR
	push	es

	mov	ax, seg __keysActive
	mov	es, ax

	xor	ah, ah
	mov	al, es:[__keysActive]
	cmp	al, 0
	jz	@done		; no key pressed
	
	; finally, let's put the ESC key status as return value in AX
	mov	al, es:[__keyboardState][SCANCODE_ENTER]	; test ESC

@done:
	pop	es
	ret 0
handleMainMenuInput ENDP

; Reads keyboard buffer and acts (returns non-zero if loop should end, 0 otherwise)
handleGameOverInput PROC FAR
	push	es

	mov	ax, seg __keysActive
	mov	es, ax

	xor	ah, ah
	mov	al, es:[__keysActive]
	cmp	al, 0
	jz	@done		; no key pressed
	
	; finally, let's put the ESC key status as return value in AX
	mov	al, es:[__keyboardState][SCANCODE_ENTER]	; test ESC

@done:
	pop	es
	ret 0
handleGameOverInput ENDP

; Reads keyboard buffer and acts (returns non-zero if loop should end, 0 otherwise)
handleGameInput PROC FAR
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

END