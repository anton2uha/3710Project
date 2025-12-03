; Minimal loop: keep player Y and obstacle X in RAM for VGA.
; Writes:
;   0x0100 -> player_y (top-left of 32x32 sprite)
;   0x0101 -> obstacle_x (top-left of 32x32 sprite)
; Inputs:
;   R13 is driven externally with space press (1=pressed, 0=idle).
;   vblank flag is memory-mapped at 0xFFFE: bit0 = vblank_start pulse/flag.

; Register use
; R1  = player_y
; R2  = obstacle_x
; R3  = wrap_x (reset position when obstacle leaves screen)
; R4  = 0 (constant zero)
; R6  = jump_active flag (0 = on ground, 1 = in air)
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

    ; Load R4 with 0
    MOVI 0, R4

    ; jump_active = 0 (player starts on ground)
    MOVI 0, R6

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

    ; Reset vblank to 0
    STOR R4, R0

    ;----------------------------------------------------------
    ; 1) Jump logic
    ;    TODOs implemented:
    ;    - Only jump if player is "on the ground" (jump_active == 0).
    ;    - Bring the player back to the ground after a jump.
    ;
    ;  We treat "on ground" as "not currently in a jump":
    ;    R6 == 0 -> on ground
    ;    R6 == 1 -> jump in progress
    ;----------------------------------------------------------

    ; --- Jump start: only if space is pressed AND not already jumping ---
    CMPI 1, R13          ; is space pressed?
    BNE NO_JUMP_START    ; if not pressed, skip

    CMPI 0, R6           ; are we on the ground? (jump_active == 0)
    BNE NO_JUMP_START    ; if already jumping, skip

    ; Start jump: move up 10 px and mark jump as active
    SUBI 10, R1          ; go up
    MOVI 1, R6           ; jump_active = 1
    BUC AFTER_JUMP_LOGIC

NO_JUMP_START:
    ; --- Return to ground: if jump_active == 1 and space released ---
    CMPI 1, R6           ; are we in a jump?
    BNE AFTER_JUMP_LOGIC ; if not jumping, nothing to do

    CMPI 0, R13          ; has space been released?
    BNE AFTER_JUMP_LOGIC ; if still holding space, stay in air

    ; bring player back down to ground level
    ADDI 10, R1          ; go back down same amount
    MOVI 0, R6           ; jump_active = 0 (back on ground)

AFTER_JUMP_LOGIC:

    ;----------------------------------------------------------
    ; 2) Move obstacle left by 3 px; wrap when it leaves screen
    ;----------------------------------------------------------
    SUBI 3, R2
    CMPI 0, R2
    BGE OBSTACLE_OK
    MOV R3, R2           ; wrap to right edge minus sprite width
OBSTACLE_OK:

    ;----------------------------------------------------------
    ; 3) Store player_y to 0x0100
    ;----------------------------------------------------------
    MOVI 0x01, R12
    LSHI 0x08, R12       ; R12 = 0x0100
    STOR R1, R12

    ; Store obstacle_x to 0x0101
    ADDI 0x01, R12       ; R12 = 0x0101
    STOR R2, R12

    BUC GAME_LOOP
