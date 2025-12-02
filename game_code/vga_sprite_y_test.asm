; ============================================================
; VGA SPRITE Y-POSITION BOUNCE TEST
; ------------------------------------------------------------
; Purpose:
;   - Demonstrates how the CPU can keep a sprite's Y position in RAM
;     for the VGA side to read over the second RAM port.
;   - Stores the current Y value at SPRITE_Y_ADDR (0x0100).
;   - Moves the sprite up and down between MIN_Y and MAX_Y so you can
;     watch the VGA sprite follow the memory value.
;
; How to use:
;   1) Hook VGA logic to read mem[0x0100] as the sprite Y coordinate.
;      (Optional) This example also writes mem[0x0101] with a fixed X.
;   2) Assemble: from repo root
;        cd assembler
;        python assembler.py ../game_code/vga_sprite_y_test.asm ../game_code/vga_sprite_y_test.hex
;   3) Point $readmemh to the generated hex when loading RAM.
;
; Register usage:
;   R0  software zero
;   R1  sprite_y (current value)
;   R2  y_delta (+1 when moving down, -1 when moving up)
;   R3  MIN_Y
;   R4  MAX_Y
;   R5  SPRITE_Y_ADDR pointer (0x0100)
;   R6  temp for address math
;   R7  delay counter
;   R8  fixed X value (optional store to 0x0101)
;
; Notes:
;   - Immediates are 8-bit; 0x0100 is built by ORI + LSHI.
;   - Tune MIN_Y/MAX_Y/DELAY to change the motion speed and bounds.
; ============================================================

start:
    MOVI 0x00, R0          ; R0 = 0 (software zero)

    ; Build 0x0100 into R5 for SPRITE_Y_ADDR
    MOVI 0x00, R5
    ORI  0x01, R5
    LSHI 0x08, R5          ; R5 = 0x0100

    ; Constants and initial state
    MOVI 0x10, R3          ; MIN_Y  = 16
    MOVI 0x70, R4          ; MAX_Y  = 112
    MOVI 0x30, R1          ; sprite_y starts near the middle
    MOVI 0x01, R2          ; y_delta = +1 (moving down)

    ; Optional: write a fixed X to 0x0101 so VGA has both coords
    MOV  R5, R6            ; R6 = 0x0100
    ADDI 0x01, R6          ; R6 = 0x0101 (SPRITE_X_ADDR)
    MOVI 0x20, R8          ; X = 32
    STOR R8, R6

main_loop:
    ; Push current Y to shared RAM for VGA each frame
    STOR R1, R5

    ; Update Y: sprite_y += y_delta
    ADD R2, R1

    ; Bounce off bottom edge: if sprite_y >= MAX_Y -> clamp and go up
    CMP R1, R4
    BGE bounce_up

    ; Bounce off top edge: if sprite_y < MIN_Y -> clamp and go down
    CMP R1, R3
    BLT bounce_down

    BUC frame_delay        ; No edge hit, continue to delay

bounce_up:
    MOV  R4, R1            ; Clamp to MAX_Y
    MOVI -1, R2            ; Move upward next frame
    BUC frame_delay

bounce_down:
    MOV  R3, R1            ; Clamp to MIN_Y
    MOVI 0x01, R2          ; Move downward next frame

frame_delay:
    ; Simple delay so motion is visible on VGA
    MOVI 0xFF, R7
delay_loop:
    SUBI 0x01, R7
    CMP  R7, R0
    BNE  delay_loop

    BUC  main_loop

; ============================================================
; END
; ============================================================
