; ============================================================
; DINO RUNNER GAME - 16-bit Assembly
; ============================================================

; ============================================================
; REGISTER ALLOCATION
; ============================================================
; R0  - vblank address (0xFFFE)
; R1  - Player Y position (top-left)
; R2  - Player Y velocity
; R3  - Obstacle X position (top-left)
; R4  - Score / Zero register
; R5  - Game state (0 = running, 1 = game over)
; R6  - Temp / calculations
; R7  - Temp / calculations
; R8  - Ground level constant (200) / obstacle Y
; R9  - Gravity constant
; R10 - Jump velocity constant
; R11 - Wrap X constant (608) / vblank value
; R12 - Memory address pointer
; R13 - Input value (driven externally)
; R14 - Player X constant (0)
; R15 - Sprite size (96)

; ============================================================
; PROGRAM START
; ============================================================

INIT:
    ; --- Load constants into registers ---
    ; Ground level = 200 (0xC8)
    MOVI 0x64, R8         ; 100
    ADDI 0x64, R8         ; +100 = 200
    
    MOVI 2, R9            ; R9 = Gravity 
    MOVI -40, R10         ; R10 = Jump velocity (negative = upward)
    
    ; Screen wrap X = 608 (0x0260)
    MOVI 0x02, R11
    LSHI 0x08, R11
    ADDI 0x60, R11        ; R11 = 608
    
    ; Player X = 0 (left edge)
    MOVI 0, R14

    ; Sprite size = 96
    MOVI 96, R15          ; 96x96 hitbox

    MOVI 0, R4            ; R4 = 0 (for resets / score)
    
    ; vblank address = 0xFFFE
    MOVI 0xFE, R0         ; R0 = 0xFFFE (sign-extended)
    
    ; --- Initialize game state ---
    MOV R8, R1            ; R1 = Player Y starts at ground (200)
    MOVI 0, R2            ; R2 = Player velocity = 0
    MOV R11, R3           ; R3 = Obstacle X starts at 608 (right edge)
    MOVI 0, R5            ; R5 = Game state = 0 (running)

; ============================================================
; MAIN GAME LOOP
; ============================================================

GAME_LOOP:
    ; --- 0. WAIT FOR VBLANK ---
WAIT_FOR_VBLANK:
    LOAD R6, R0
    CMPI 1, R6
    BNE WAIT_FOR_VBLANK
    MOVI 0, R6
    STOR R6, R0

    ; Reset R15 back to 96
    MOVI 96, R15          ; R15 = Sprite size (96)

    ; Check if game is over
    CMPI 0, R5
    BNE GAME_OVER_STATE   ; If game state != 0, go to game over
    
    ; --- 1. HANDLE JUMP INPUT ---
    ; R13 is driven externally (1 = pressed, 0 = idle)
    ; Only allow jump if player is on ground
    CMP R8, R1            ; Compare ground with player_y
    BNE SKIP_JUMP         ; If not on ground, skip jump
    
    CMPI 1, R13           ; Check if jump button pressed
    BNE SKIP_JUMP         ; If button not pressed, skip
    
    ; Start jump - set upward velocity
    MOV R10, R2           ; velocity = JUMP_VELOCITY (negative = up)

SKIP_JUMP:

    ; --- 2. UPDATE PLAYER PHYSICS ---
    ; Apply gravity to velocity
    ADD R9, R2            ; velocity += gravity
    
    ; Apply velocity to position
    ADD R2, R1            ; player_y += velocity
    
    ; --- 3. GROUND COLLISION ---
    ; Check if player is below ground
    CMP R8, R1            ; Compare ground with player_y
    BLT PLAYER_NOT_BELOW  ; If ground < player_y then below ground
    
    ; Player hit ground - clamp position and stop
    MOV R8, R1            ; player_y = ground
    MOVI 0, R2            ; velocity = 0

PLAYER_NOT_BELOW:

    ; --- 4. UPDATE OBSTACLE ---
    ; Move obstacle left by 6 pixels
    SUBI 6, R3            ; obstacle_x -= 6
    
    ; Check if obstacle went off left edge
    CMPI 0, R3
    BGE OBSTACLE_ON_SCREEN ; If obstacle_x >= 0, still on screen
    
    ; Reset obstacle to right side (608)
    MOV R11, R3           ; obstacle_x = 608
    
    ; Increment score (player survived one obstacle)
    ADDI 1, R4            ; score++

OBSTACLE_ON_SCREEN:

    ; --- 5. COLLISION DETECTION (AABB, 96x96) ---
    ; Player:
    ;   P_left   = R14          (0)
    ;   P_right  = R14 + 96
    ;   P_top    = R1
    ;   P_bottom = R1  + 96
    ; Obstacle:
    ;   O_left   = R3
    ;   O_right  = R3 + 96
    ;   O_top    = R8           (200)
    ;   O_bottom = R8  + 96
    ;
    ; Non-overlap conditions (any true -> NO_COLLISION):
    ; 1) P_left   >= O_right
    ; 2) P_right  <= O_left
    ; 3) P_top    >= O_bottom
    ; 4) P_bottom <= O_top

    ; player1.x < player2.x + player2.width
    ; 1) If P_left >= O_right → NO_COLLISION
    MOV R3, R6            ; R6 = O_left
    ADD R15, R6           ; R6 = O_right = R3 + SPRITE_SIZE
    CMP R14, R6           ; compare P_left vs O_right (dest=P_left, src=O_right)
    BLT NO_COLLISION      ; if P_left < O_right: no overlap

    ; player1.x + player1.width > player2.x 
    ; 2) If P_right <= O_left → NO_COLLISION
    MOV R14, R7           ; R7 = P_left
    ADD R15, R7           ; R7 = P_right = P_left + SPRITE_SIZE
    CMP R7, R3            ; compare O_left vs P_right (dest=O_left, src=P_right)
    BGT NO_COLLISION      ; if O_left < P_right: no overlap

    ; player1.y < player2.y + player2.height
    ; 3) If P_top >= O_bottom → NO_COLLISION
    MOV R8, R6            ; R6 = O_top
    ADD R15, R6           ; R6 = O_bottom = O_top + SPRITE_SIZE
    CMP R1, R6            ; compare P_top vs O_bottom (dest=P_top, src=O_bottom)
    BLT NO_COLLISION      ; if P_top < O_bottom: no overlap

    ; player1.y + player1.height > player2.y
    ; 4) If P_bottom <= O_top → NO_COLLISION
    MOV R1, R7            ; R7 = P_top
    ADD R15, R7           ; R7 = P_bottom = P_top + SPRITE_SIZE
    CMP R8, R7            ; compare O_top vs P_bottom (dest=O_top, src=P_bottom)
    BLT NO_COLLISION      ; if O_top < P_bottom: no overlap

    ; If we reach here, all four separating conditions are false:
    ; => boxes overlap → collision
    MOVI 1, R5            ; Collision detected, game over

NO_COLLISION:

    ; --- 6. UPDATE VGA MEMORY ---
    ; Write player Y position to 0x0100
    MOVI 0x01, R12 
    LSHI 0x08, R12        ; R12 = 0x0100
    STOR R1, R12          ; Store player Y
    
    ; Write obstacle X to 0x0101
    ADDI 0x01, R12        ; R12 = 0x0101
    STOR R3, R12          ; Store obstacle X
    
    ; Write score to 0x0102 (if VGA supports it)
    ADDI 0x01, R12        ; R12 = 0x0102
    MOV R4, R6            ; Get score from R4
    STOR R6, R12          ; Store score

    ; --- 7. LOOP BACK ---
    BUC GAME_LOOP

; ============================================================
; GAME OVER STATE
; ============================================================

GAME_OVER_STATE:
    ; Wait for vblank even in game over
WAIT_VBLANK_GAMEOVER:
    LOAD R6, R0
    CMPI 1, R6
    BNE WAIT_VBLANK_GAMEOVER
    MOVI 0, R6
    STOR R6, R0
    
    ; Check if restart button pressed (bit 1 of R13)
    ANDI 0x02, R13
    CMPI 0, R13
    BEQ GAME_OVER_WAIT    ; If not pressed, keep waiting
    
    ; Restart game
    BUC INIT

GAME_OVER_WAIT:
    ; Keep displaying game over state
    BUC GAME_OVER_STATE

; ============================================================
; END OF PROGRAM
; ============================================================
