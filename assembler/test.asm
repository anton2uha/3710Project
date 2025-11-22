; Example assembly program for 16-bit chip


; various assembly instructions to compare to init_memory
MOVI 0x11, R1
LSHI 0x08, R4
LSHI 0x08, R5
; instr rsrc, rdest
ADD R2, R1      ; 0152
SUB R2, R1      ; 0192
ADD R2, R1      ; 0152
AND R2, R1      ; 0112
OR R3, R2       ; 0223
XOR R4, R2      ; 0234
NOT R0, R4      ; 0480
ADD R5, R4      ; 0455
ADDC R4, R2     ; 0274
ADDC R4, R2     ; 0274
ADD R5, R6      ; 0655
SUBC R0, R5     ; 05A0
LSH R7, R5      ; 05F7
; instr rdest, rsrc (LOAD)
LOAD R9, R8     ; 4908
ADD R0, R9      ; 0950
STOR R10, R0    ; 4A40
LOAD R2, R0     ; 4200
ADD R0, R2      ; 0250
CMP R10, R2     ; 02BA
JEQ R11         ; 40CB
ADD R7, R2      ; 0257
ADD R0, R2      ; 0250
CMP R2, R0      ; 00B2
BHI -21         ; C4EB
; testing other instructions
BNE 8           ; C108
JLO R15         ; 4ACF
ADDI 0x55, R15  ; 5F55
SUBCI 0x22, R14 ; AE22
ASHUI 8, R13    ; ED28
ASHUI -1, R13   ; ED3F sign bit set
target_label:
    ADD R0, R2          ; 0250
    ADD R0, R2          ; 0250
    ADD R0, R2          ; 0250
    BUC target_label    ; CEFC FC = -4 (2's complement)