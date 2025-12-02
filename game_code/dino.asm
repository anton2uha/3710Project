; Chrome Dino style endless runner for the CS3710 CR16a-like core
; Compatible with assembler.py in this repo.
; ---------------------------------------------------------------
; Memory map (assumptions for external logic):
;   0x00E0 : KEY_ADDR     -> external PS/2 block writes 1 when SPACE is pressed, 0 otherwise
;   0x00F3 : SCORE_ADDR   -> low byte of score (written every frame for display/telemetry)
;   0x00F6 : CRASH_ADDR   -> crash flag set to 1 on collision
;   0x0100 : VRAM row 0 base (air row)
;   0x0110 : VRAM row 1 base (ground row), width = 16 tiles
; Tile codes rendered by VGA logic:
;   0 = empty, 1 = ground, 2 = dino, 3 = cactus/obstacle
;
; Register usage:
;   R0  software zero
;   R1  scratch / address work
;   R2  VRAM row 0 base address (0x0100)
;   R3  WORLD_WIDTH (16 tiles)
;   R4  dino x-position (fixed at column 2)
;   R5  dino y-state (0 = ground row, 1 = air row)
;   R6  obstacle x-position (counts left each frame)
;   R7  jump timer (counts down while dino is in the air)
;   R8  loop counters / temporary
;   R9  KEY_ADDR pointer
;   R10 score counter (low byte)
;   R11 VRAM row 1 base address (ground row = R2 + width)
;   R12 cactus tile code (3)
;   R13 jump duration constant
;   R14 ground tile code (1)
;   R15 dino tile code (2)

start:
    MOVI 0x00, R0          ; ensure R0 is a software zero for stores/compares

    ; R2 = 0x0100 (VRAM row 0 base)
    MOVI 0x00, R2
    ORI  0x01, R2
    LSHI 0x08, R2

    MOV  R2, R11           ; R11 = row 1 base = row0 + width (0x0110)
    MOVI 0x10, R3          ; width = 16 tiles
    ADDI 0x10, R11

    MOVI 0x02, R4          ; dino column
    MOVI 0x00, R5          ; dino starts on ground

    MOV  R3, R6            ; obstacle starts at right edge (width - 1)
    SUBI 0x01, R6

    MOVI 0x00, R7          ; jump timer = 0
    MOVI 0x00, R8          ; scratch init

    MOVI 0x00, R9          ; KEY_ADDR = 0x00E0
    ORI  0xE0, R9

    MOVI 0x00, R10         ; score = 0

    MOVI 0x06, R13         ; jump holds the dino up for 6 frames
    MOVI 0x01, R14         ; ground tile code
    MOVI 0x02, R15         ; dino tile code
    MOVI 0x03, R12         ; cactus tile code

    ; Boot-time VRAM clear and initial sprites
    MOV  R2, R1            ; clear air row
    MOVI 0x10, R8
clear_row0_boot:
    STOR R0, R1
    ADDI 0x01, R1
    SUBI 0x01, R8
    CMP  R8, R0
    BNE  clear_row0_boot

    MOV  R11, R1           ; paint ground row
    MOVI 0x10, R8
fill_ground_boot:
    STOR R14, R1
    ADDI 0x01, R1
    SUBI 0x01, R8
    CMP  R8, R0
    BNE  fill_ground_boot

    MOV  R11, R1           ; place initial obstacle at (row1, obstacle_x)
    ADD  R6, R1
    STOR R12, R1

    MOV  R11, R1           ; place dino at ground row
    ADD  R4, R1
    STOR R15, R1

; ------------------------------
; Main loop
; ------------------------------
main_loop:
    ; simple delay to slow game speed
    MOVI 0x20, R8
frame_delay:
    SUBI 0x01, R8
    CMP  R8, R0
    BNE  frame_delay

    ; poll spacebar latch and start jump if idle
    LOAD R1, R9            ; R1 = mem[KEY_ADDR]
    CMP  R1, R0
    BEQ  skip_jump
    CMP  R7, R0            ; if already mid-jump, ignore
    BNE  skip_jump
    MOV  R13, R7           ; seed jump timer
    MOVI 0x01, R5          ; dino now in air row
skip_jump:

    ; tick jump timer and fall back to ground when it expires
    CMP  R7, R0
    BEQ  end_jump_update
    SUBI 0x01, R7
    CMP  R7, R0
    BNE  end_jump_update
    MOVI 0x00, R5          ; landed
end_jump_update:

    ; move obstacle left; wrap and score when it passes the dino
    SUBI 0x01, R6
    CMP  R6, R0
    BGE  obstacle_ok
    MOV  R3, R6
    SUBI 0x01, R6          ; wrap to width - 1
    ADDI 0x01, R10         ; score++
obstacle_ok:

    ; collision detection: obstacle shares column with dino AND dino on ground
    CMP  R6, R4
    BNE  draw_scene
    CMP  R5, R0
    BNE  draw_scene
    MOVI 0x00, R1          ; crash flag address = 0x00F6
    ORI  0xF6, R1
    MOVI 0x01, R8
    STOR R8, R1
crash_loop:
    BUC  crash_loop        ; stop the world on collision

; redraw the two-row tile map
draw_scene:
    MOV  R2, R1            ; clear row 0 (air)
    MOVI 0x10, R8
draw_clear_row0:
    STOR R0, R1
    ADDI 0x01, R1
    SUBI 0x01, R8
    CMP  R8, R0
    BNE  draw_clear_row0

    MOV  R11, R1           ; reset row 1 to ground tiles
    MOVI 0x10, R8
draw_fill_ground:
    STOR R14, R1
    ADDI 0x01, R1
    SUBI 0x01, R8
    CMP  R8, R0
    BNE  draw_fill_ground

    MOV  R11, R1           ; draw obstacle on ground row
    ADD  R6, R1
    STOR R12, R1

    CMP  R5, R0            ; choose row for dino sprite
    BEQ  draw_dino_ground
    MOV  R2, R1            ; dino in air
    ADD  R4, R1
    STOR R15, R1
    BUC  store_score
draw_dino_ground:
    MOV  R11, R1           ; dino on ground
    ADD  R4, R1
    STOR R15, R1

store_score:
    MOVI 0x00, R1          ; SCORE_ADDR = 0x00F3
    ORI  0xF3, R1
    STOR R10, R1

    BUC  main_loop
