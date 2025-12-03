; Minimal loop: keep player Y and obstacle X in RAM for VGA.
; Writes:
;   0x0100 -> player_y (top-left of 32x32 sprite)
;   0x0101 -> obstacle_x (top-left of 32x32 sprite)
; Inputs:
;   R13 is driven externally with space press (1=pressed, 0=idle).

; Register use
; R1 = player_y
; R2 = obstacle_x
; R3 = wrap_x (reset position when obstacle leaves screen)
; R12 = address pointer

; Constants
; Ground/start Y: 200
; Obstacle wrap X: 608 (640 - 32 sprite width)

INIT:
    ; Move 0xC8 (200) into R1 for player_y start. Have to do 2 adds because MOVI is sign extended
    MOVI 0x64, R1        ; 100
    ADDI 0x64, R1        ; +100 = 200 = 0xC8
    MOVI 0x02, R3        ; build 0x0260 = 608
    LSHI 0x08, R3
    ADDI 0x60, R3
    MOV R3, R2           ; obstacle starts at right side

GAME_LOOP:
    ; If space pressed, nudge player up by 10 px
    CMPI 1, R13
    BNE NO_JUMP
    SUBI 10, R1
    CMPI 0, R1           ; clamp so it never wraps negative
    BGE NO_JUMP
    MOVI 0, R1
NO_JUMP:

    ; Move obstacle left by 3 px; wrap when it leaves screen
    SUBI 3, R2
    CMPI 0, R2
    BGE OBSTACLE_OK
    MOV R3, R2           ; wrap to right edge minus sprite width
OBSTACLE_OK:

    ; Store player_y to 0x0100
    MOVI 0x01, R12
    LSHI 0x08, R12       ; R12 = 0x0100
    STOR R1, R12

    ; Store obstacle_x to 0x0101
    ADDI 0x01, R12       ; R12 = 0x0101
    STOR R2, R12

    ; Simple delay to slow movement a bit
    MOVI 0xFF, R0
DELAY_LOOP:
    SUBI 1, R0
    CMPI 0, R0
    BNE DELAY_LOOP

    BUC GAME_LOOP
