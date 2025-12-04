; ============================================================
; DINO RUNNER GAME - 16-bit Assembly
; ============================================================

; ============================================================
; REGISTER ALLOCATION
; ============================================================
; R0  - vblank address (0xFFFE)
; R1  - Player Y position
; R2  - Player Y velocity
; R3  - Obstacle X position  
; R4  - Score / Zero register
; R5  - Game state (0 = running, 1 = game over)
; R6  - Temp / calculations
; R7  - Temp / calculations
; R8  - Ground level constant (200)
; R9  - Gravity constant
; R10 - Jump velocity constant
; R11 - Wrap X constant (608) / vblank value
; R12 - Memory address pointer
; R13 - Input value (driven externally)
; R14 - Collision box size
; R15 - Temp / loop counter

; ============================================================
; PROGRAM START
; ============================================================

INIT:
    ; --- Load constants into registers ---
    ; Ground level = 200 (0xC8)
    MOVI 0x64, R8         ; 100
    ADDI 0x64, R8         ; +100 = 200
    
    MOVI 2, R9            ; R9 = Gravity 
    MOVI -25, R10         ; R10 = Jump velocity (negative = upward)
    
    ; Screen wrap X = 608 (0x0260) - matches working code
    MOVI 0x02, R11
    LSHI 0x08, R11
    ADDI 0x60, R11        ; R11 = 608
    
    MOVI 10, R14          ; R14 = Collision box size
    MOVI 0, R4            ; R4 = 0 (for resets)
    
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
    LOAD R15, R0          ; R15 = mem[0xFFFE]
    CMPI 1, R15
    BNE WAIT_FOR_VBLANK   ; Wait until vblank flag == 1
    
    STOR R4, R0           ; Reset vblank flag to 0

    ; Check if game is over
    CMPI 0, R5
    BNE GAME_OVER_STATE   ; If game state != 0, go to game over
    
    ; --- 1. HANDLE JUMP INPUT ---
    ; R13 is driven externally (1 = pressed, 0 = idle)
    ; Only allow jump if player is on ground
    CMP R8, R1            ; Compare player Y with ground
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
    BLT PLAYER_NOT_BELOW  ; If ground >= player_y, player is above ground
    
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

    ; --- 5. COLLISION DETECTION ---
    ; Player sprite: 96x96 at X=252, Y=player_y
    ; Obstacle sprite: 96x96 at X=obstacle_x, Y=200 (ground)
    
    ; X collision: Check if obstacle_x is in range (156, 348)
    
    ; Build 156 (0x9C) in R6
    MOVI 0x4E, R6         ; 78
    ADDI 0x4E, R6         ; +78 = 156
    CMP R3, R6            ; Compare obstacle_x with 156
    BGE NO_COLLISION      ; FLIPPED: was BLT
    
    ; Build 348 (0x15C) in R6
    MOVI 0xAE, R6         ; 174
    ADDI 0xAE, R6         ; +174 = 348
    CMP R3, R6            ; Compare obstacle_x with 348
    BLT NO_COLLISION      ; FLIPPED: was BGE
    
    ; X overlaps - now check Y
    
    ; Build 104 (0x68) in R6
    MOVI 0x34, R6         ; 52
    ADDI 0x34, R6         ; +52 = 104
    CMP R1, R6            ; Compare player_y with 104
    BGE NO_COLLISION      ; FLIPPED: was BLT
    
    ; COLLISION DETECTED - Game Over
    MOVI 1, R5            ; Set game state to game over

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
    LOAD R15, R0
    CMPI 1, R15
    BNE WAIT_VBLANK_GAMEOVER
    STOR R4, R0
    
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
