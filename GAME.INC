; ==============================================================================
; Game functionality.
; ==============================================================================


; --- EXPORTS ------------------------------------------------------------------

externdef startGame:FAR
externdef snake_mem:WORD, snake_size:WORD, snake_direction:BYTE, snake_head:WORD, snake_speed:BYTE
externdef food_nb:BYTE, food_mem:BYTE
externdef score:WORD

; --- MACROS AND CONSTANTS -----------------------------------------------------

FOOD_MAX equ 5
FOOD_NORMAL equ 0
FOOD_SPEED equ 1
FOOD_SLOW equ 2
FOOD_INC equ 3
FOOD_DEC equ 4