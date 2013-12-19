; ==============================================================================
; Drawing functionality.
; ==============================================================================


; --- EXPORTS ------------------------------------------------------------------

externdef renderWorld:FAR
externdef renderMainMenu:FAR
externdef renderGameOver:FAR

; --- MACROS AND CONSTANTS -----------------------------------------------------

;sizes
SCREEN_X equ 320
SCREEN_Y equ 200
BOARD_X equ 32
BOARD_Y equ 19
BOARD_SIZE equ BOARD_X * BOARD_Y

;colors
a equ 3 ;background color
z equ 0 ;black
b equ 1 ;blue
g equ 2 ;green
q equ 3 ;cyan
r equ 4 ;red
m equ 5 ;magenta
o equ 6 ;brown
w equ 15 ;white
h equ 8 ;gray
p equ 13 ;light magenta
y equ 14 ;yellow
l equ 10 ;light green