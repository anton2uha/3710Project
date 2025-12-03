; Minimal loop: keep player Y and obstacle X in RAM for VGA.
; Writes:
;   0x0100 -> player_y (top-left of 32x32 sprite)
;   0x0101 -> obstacle_x (top-left of 32x32 sprite)
; Inputs:
;   R13 is driven externally with space press (1=pressed, 0=idle).
<<<<<<< HEAD
;   vblank flag is memory-mapped at 0xFFFE: bit0 = vblank_start pulse/flag.
=======
>>>>>>> 0373fdabbc7556dbc43e96502adb75b79d5a8e6b

; Register use
; R1  = player_y
; R2  = obstacle_x
; R3  = wrap_x (reset position when obstacle leaves screen)
<<<<<<< HEAD
; R4  = jump_up_counter
; R5  = jump_down_counter
; R6  = vblank IO address (0xFFFE)
; R12 = address pointer
; R0  = scratch / vblank read

; Constants
; Ground/start Y: 200 (encoded as two 0x64 adds)
; Obstacle wrap X: 608 (640 - 32 sprite width)

INIT:
    ; player_y = 200 (0x00C8)
    MOVI 0x64, R1        ; 100
    ADDI 0x64, R1        ; +100 = 200 = 0x00C8

    ; wrap_x = 0x0260 = 608
    MOVI 0x02, R3
    LSHI 0x08, R3        ; R3 = 0x0200
    ADDI 0x60, R3        ; R3 = 0x0260 (608)

    MOV R3, R2           ; obstacle_x starts at right side

    ; no jump in progress initially
    MOVI 0x00, R4        ; jump_up_counter = 0
    MOVI 0x00, R5        ; jump_down_counter = 0

    ; vblank IO address = 0xFFFE (exploiting sign-extended MOVI)
    MOVI 0xFE, R6        ; R6 = 0xFFFE

GAME_LOOP:
    ;----------------------------------------------------------
    ; 0) Wait for vblank (one game update per frame)
    ;    Reads memory-mapped vblank flag at 0xFFFE.
    ;    Assumes mem[0xFFFE] = 0x0000 or 0x0001 (bit0 = vblank).
    ;----------------------------------------------------------
WAIT_FOR_VBLANK:
    LOAD R0, R6          ; R0 = mem[0xFFFE]
    CMPI 1, R0           ; vblank flag set?
    BNE WAIT_FOR_VBLANK  ; if not 1, keep waiting

    ;----------------------------------------------------------
    ; 1) Handle jump start when space is pressed
    ;----------------------------------------------------------
    CMPI 1, R13          ; space pressed?
    BNE NO_JUMP_START    ; if R13 != 1, skip

    ; only start a jump if not already in one
    CMPI 0, R4
    BNE NO_JUMP_START    ; if jump_up_counter != 0, already jumping
    CMPI 0, R5
    BNE NO_JUMP_START    ; if jump_down_counter != 0, already falling

    MOVI 10, R4          ; start jump: 10 frames upward
NO_JUMP_START:

    ;----------------------------------------------------------
    ; 2) Apply jump motion (up then down)
    ;    R4 > 0 => move up, then start falling (R5) when R4 hits 0
    ;    R5 > 0 => move down
    ;----------------------------------------------------------
    ; if (R4 != 0) go do upward motion
    CMPI 0, R4
    BNE DO_JUMP_UP

    ; else if (R5 != 0) go do downward motion
    CMPI 0, R5
    BNE DO_JUMP_DOWN

    BUC AFTER_JUMP_MOTION   ; no jump in progress

DO_JUMP_UP:
    SUBI 2, R1           ; move up 2 pixels
    SUBI 1, R4           ; decrement jump_up_counter

    ; if R4 just became 0, start falling
    CMPI 0, R4
    BNE AFTER_JUMP_MOTION
    MOVI 10, R5          ; 10 frames to fall back down
    BUC AFTER_JUMP_MOTION

DO_JUMP_DOWN:
    ADDI 2, R1           ; move down 2 pixels
    SUBI 1, R5           ; decrement jump_down_counter
    BUC AFTER_JUMP_MOTION

AFTER_JUMP_MOTION:

    ;----------------------------------------------------------
    ; 3) Move obstacle left by 3 px; wrap when it leaves screen
=======
; R12 = address pointer
; R0  = vblank address (0xFFFE)
; R11 = vblank value (scratch)

; Constants
; Ground/start Y: 200
; Obstacle wrap X: 608 (640 - 32 sprite width)

INIT:
    ; Move 0xC8 (200) into R1 for player_y start. Have to do 2 adds because MOVI is sign extended
    MOVI 0x64, R1        ; 100
    ADDI 0x64, R1        ; +100 = 200 = 0xC8

    ; build 0x0260 = 608
    MOVI 0x02, R3
    LSHI 0x08, R3
    ADDI 0x60, R3
    MOV R3, R2           ; obstacle starts at right side

    ; vblank IO address = 0xFFFE (MOVI is sign-extended)
    MOVI 0xFE, R0        ; R0 = 0xFFFE

GAME_LOOP:
    ;----------------------------------------------------------
    ; 0) Wait for vblank (uses mem-mapped vblank at 0xFFFE)
    ;    Assumes mem[0xFFFE] is 0 normally, 1 when it's time
    ;    to do one game update.
    ;----------------------------------------------------------
WAIT_FOR_VBLANK:
    LOAD R11, R0         ; R11 = mem[0xFFFE]
    CMPI 1, R11
    BNE WAIT_FOR_VBLANK  ; stay here until vblank flag == 1

    ;----------------------------------------------------------
    ; 1) If space pressed, nudge player up by 10 px
    ;----------------------------------------------------------
    CMPI 1, R13
    BNE NO_JUMP
    SUBI 10, R1
    CMPI 0, R1           ; clamp so it never wraps negative
    BGE NO_JUMP
    MOVI 0, R1
NO_JUMP:

    ;----------------------------------------------------------
    ; 2) Move obstacle left by 3 px; wrap when it leaves screen
>>>>>>> 0373fdabbc7556dbc43e96502adb75b79d5a8e6b
    ;----------------------------------------------------------
    SUBI 3, R2
    CMPI 0, R2
    BGE OBSTACLE_OK
    MOV R3, R2           ; wrap to right edge minus sprite width
OBSTACLE_OK:

    ;----------------------------------------------------------
<<<<<<< HEAD
    ; 4) Store player_y and obstacle_x to RAM
    ;    0x0100 -> player_y
    ;    0x0101 -> obstacle_x
    ;----------------------------------------------------------
    MOVI 0x01, R12
    LSHI 0x08, R12       ; R12 = 0x0100
    STOR R1, R12         ; mem[0x0100] = player_y

    ADDI 0x01, R12       ; R12 = 0x0101
    STOR R2, R12         ; mem[0x0101] = obstacle_x
=======
    ; 3) Store player_y to 0x0100
    ;----------------------------------------------------------
    MOVI 0x01, R12
    LSHI 0x08, R12       ; R12 = 0x0100
    STOR R1, R12

    ; Store obstacle_x to 0x0101
    ADDI 0x01, R12       ; R12 = 0x0101
    STOR R2, R12
>>>>>>> 0373fdabbc7556dbc43e96502adb75b79d5a8e6b

    BUC GAME_LOOP
