; ============================================================
; DINO RUNNER GAME - 16-bit Assembly
; Simple jumping game similar to Chrome's T-Rex runner
; ============================================================

; ============================================================
; MEMORY MAP (adjust these based on your VGA controller)
; ============================================================
; 0x0000 - 0x00FF : Program variables (RAM)
; 0x0100+        : VGA display memory (memory-mapped)
;
; VGA Memory Layout (example - adjust to your design):
;   PLAYER_DISPLAY_ADDR = 0x0100   ; Where VGA reads player Y
;   OBSTACLE_DISPLAY_ADDR = 0x0101 ; Where VGA reads obstacle X
;   SCORE_DISPLAY_ADDR = 0x0102    ; Where VGA reads score
;   INPUT_ADDR = 0x0103            ; Where input button state is read

; ============================================================
; REGISTER ALLOCATION (Convention for this game)
; ============================================================
; R0  - Zero register / temp
; R1  - Player Y position
; R2  - Player Y velocity
; R3  - Obstacle X position  
; R4  - Score
; R5  - Game state (0 = running, 1 = game over)
; R6  - Temp / calculations
; R7  - Temp / calculations
; R8  - Ground level constant
; R9  - Gravity constant
; R10 - Jump velocity constant
; R11 - Screen width constant
; R12 - Memory address pointer
; R13 - Input value
; R14 - Collision box size
; R15 - Temp / loop counter

; ============================================================
; GAME CONSTANTS (load these at startup)
; ============================================================
; GROUND_Y       = 200    ; Y position of ground (bottom of screen area)
; GRAVITY        = 2      ; Downward acceleration per frame
; JUMP_VELOCITY  = -20    ; Initial upward velocity when jumping (negative = up)
; OBSTACLE_SPEED = 3      ; How fast obstacles move left
; SCREEN_WIDTH   = 320    ; Or whatever your display width is
; PLAYER_X       = 40     ; Player's fixed X position
; COLLISION_BOX  = 10     ; Size for collision detection

; ============================================================
; PROGRAM START
; ============================================================

INIT:
    ; --- Load constants into registers ---
    MOVI 200, R8          ; R8 = Ground level (Y=200)
    MOVI 2, R9            ; R9 = Gravity 
    MOVI -20, R10         ; R10 = Jump velocity (negative = upward)
    MOVI 0xFF, R11        ; R11 = Screen width (255 for 8-bit, adjust as needed)
    MOVI 10, R14          ; R14 = Collision box size
    
    ; --- Initialize game state ---
    MOV R8, R1            ; R1 = Player Y starts at ground
    MOVI 0, R2            ; R2 = Player velocity = 0 (not moving)
    MOV R11, R3           ; R3 = Obstacle X starts at right edge
    MOVI 0, R4            ; R4 = Score = 0
    MOVI 0, R5            ; R5 = Game state = 0 (running)

; ============================================================
; MAIN GAME LOOP
; ============================================================

GAME_LOOP:
    ; Check if game is over
    CMPI 0, R5
    BNE GAME_OVER_STATE   ; If game state != 0, go to game over
    
    ; --- 1. READ INPUT ---
    MOVI 0x01, R12        ; Load input address (0x0103) - adjust to your hardware
    LSH 0x08, R12
    ; If your address space allows: you might need to build address differently
    ; For now assuming low memory for simplicity
    LOAD R13, R12         ; R13 = input button state
    
    ; --- 2. HANDLE JUMP INPUT ---
    ; Only allow jump if player is on ground
    CMP R8, R1            ; Compare player Y with ground
    BNE SKIP_JUMP         ; If not on ground, skip jump
    
    ; Check if jump button pressed (assume bit 0 = jump)
    ANDI 0x01, R13        ; Mask to check bit 0
    CMPI 0, R13
    BEQ SKIP_JUMP         ; If button not pressed, skip
    
    ; Start jump - set upward velocity
    MOV R10, R2           ; velocity = JUMP_VELOCITY (negative = up)

SKIP_JUMP:

    ; --- 3. UPDATE PLAYER PHYSICS ---
    ; Apply gravity to velocity
    ADD R9, R2            ; velocity += gravity
    
    ; Apply velocity to position
    ADD R2, R1            ; player_y += velocity
    
    ; ------ This might be unecessary? ------
    ; --- 4. GROUND COLLISION ---
    ; Check if player is below ground
    CMP R8, R1            ; Compare ground with player_y
    BGE PLAYER_NOT_BELOW  ; If ground >= player_y, player is above/at ground
    
    ; Player hit ground - clamp position and stop
    MOV R8, R1            ; player_y = ground
    MOVI 0, R2            ; velocity = 0

PLAYER_NOT_BELOW:

    ; --- 5. UPDATE OBSTACLE ---
    ; Move obstacle left
    MOVI 3, R6            ; R6 = obstacle speed
    SUB R6, R3            ; obstacle_x -= speed
    
    ; Check if obstacle went off left edge
    CMPI 0, R3
    BGE OBSTACLE_ON_SCREEN ; If obstacle_x >= 0, still on screen
    
    ; Reset obstacle to right side
    MOV R11, R3           ; obstacle_x = screen_width
    
    ; Increment score (player survived one obstacle)
    ADDI 1, R4            ; score++

OBSTACLE_ON_SCREEN:

    ; --- 6. COLLISION DETECTION ---
    ; Simple box collision between player and obstacle
    ; Player is at fixed X (around 40), obstacle moves
    ; Check if obstacle X is near player X AND player Y is low (near ground)
    
    ; Check X overlap: is obstacle near player's X position?
    MOVI 40, R6           ; R6 = Player fixed X position
    MOV R3, R7            ; R7 = obstacle X
    SUB R6, R7            ; R7 = obstacle_x - player_x
    
    ; Check if difference is small (within collision range)
    ; Need absolute value - check both positive and negative
    CMPI 0, R7
    BGE CHECK_POSITIVE_X
    
    ; R7 is negative, negate it
    MOVI 0, R6
    SUB R7, R6            ; R6 = 0 - R7 = -R7 (absolute value)
    MOV R6, R7

CHECK_POSITIVE_X:
    ; R7 now has absolute X distance
    CMP R14, R7           ; Compare collision_box with distance
    BLT NO_COLLISION      ; If collision_box < distance, no collision
    
    ; X overlaps - now check Y
    ; Obstacle is on ground (Y = ground level)
    ; Check if player is close to ground
    MOV R8, R6            ; R6 = ground level
    SUB R1, R6            ; R6 = ground - player_y (how high player is)
    
    CMP R14, R6           ; Compare collision_box with height
    BLT NO_COLLISION      ; If collision_box < height, player jumped over
    
    ; COLLISION DETECTED - Game Over
    MOVI 1, R5            ; Set game state to game over
    ; branch to the end? (skip no collision routine?)

NO_COLLISION:

    ; --- 7. UPDATE VGA MEMORY ---
    ; Write player Y position to display memory
    MOVI 0x00, R12        ; Display address for player (0x0100)
    ; NOTE: You may need to construct larger addresses differently
    ; depending on your memory architecture
    STOR R1, R12          ; Store player Y to VGA memory
    
    MOVI 0x01, R12        ; Display address for obstacle (0x0101)
    STOR R3, R12          ; Store obstacle X to VGA memory
    
    MOVI 0x02, R12        ; Display address for score (0x0102)
    STOR R4, R12          ; Store score to VGA memory

    ; --- 8. FRAME DELAY ---
    ; Simple delay loop to control game speed
    MOVI 0xFF, R15        ; Outer loop counter
DELAY_OUTER:
    MOVI 0xFF, R6         ; Inner loop counter  
DELAY_INNER:
    SUBI 1, R6
    BNE DELAY_INNER
    SUBI 1, R15
    BNE DELAY_OUTER

    ; --- 9. LOOP BACK ---
    BUC GAME_LOOP

; ============================================================
; GAME OVER STATE
; ============================================================

GAME_OVER_STATE:
    ; Read input to check for restart
    MOVI 0x03, R12
    LOAD R13, R12
    
    ; Check if restart button pressed (assume bit 1 = restart)
    ANDI 0x02, R13
    CMPI 0, R13
    BEQ GAME_OVER_WAIT    ; If not pressed, keep waiting
    
    ; Restart game - jump back to init
    BUC INIT

GAME_OVER_WAIT:
    ; Could flash display or show game over indicator
    ; For now, just loop back and wait for restart
    BUC GAME_OVER_STATE

; ============================================================
; END OF PROGRAM
; ============================================================
