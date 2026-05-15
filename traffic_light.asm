; ============================================================
; Project Title : Traffic Light Controller
; Author        : CSE132 Student - Spring 2026
; Description   : Controls the Emu8086 Virtual Traffic Light
;                 device using the OUT instruction on port 4.
;                 Realistic loop: Green(10s), Yellow(3s), Red(10s)
;                 Press ESC to exit.
;
; Port 4 Bit Map (Virtual Traffic Light):
;   Bit 0 = Red
;   Bit 1 = Yellow
;   Bit 2 = Green
; ============================================================

.MODEL SMALL
.STACK 100h

; ------------------------------------------------------------
; DATA SEGMENT
; ------------------------------------------------------------
.DATA
    ; Display messages
    msg_title   DB 13,10,"Traffic Light Controller",13,10
                DB "ESC to exit.",13,10,"$"

    msg_green   DB 13,10,"GREEN (10s)",13,10,"$"
    msg_yellow  DB 13,10,"YELLOW (3s)",13,10,"$"
    msg_red     DB 13,10,"RED (10s)",13,10,"$"

    msg_bye     DB 13,10,"Goodbye!",13,10,"$"

    esc_flag    DB 0              ; 1 if ESC was pressed

; ------------------------------------------------------------
; CODE SEGMENT
; ------------------------------------------------------------
.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    ; Print title
    LEA DX, msg_title
    MOV AH, 09h
    INT 21h

; ============================================================
; MAIN TRAFFIC LOOP: Green -> Yellow -> Red -> repeat
; ============================================================
TRAFFIC_LOOP:

    ; ---- GREEN (10s) ----------------------------------------
    MOV AL, 00000100b         ; Green ON (bit 2)
    OUT 4, AL

    LEA DX, msg_green
    MOV AH, 09h
    INT 21h

    MOV BL, 10
    CALL DELAY_SECONDS
    CMP esc_flag, 1
    JE  EXIT_PROG

    ; ---- YELLOW (3s) ----------------------------------------
    MOV AL, 00000010b         ; Yellow ON (bit 1)
    OUT 4, AL

    LEA DX, msg_yellow
    MOV AH, 09h
    INT 21h

    MOV BL, 3
    CALL DELAY_SECONDS
    CMP esc_flag, 1
    JE  EXIT_PROG

    ; ---- RED (10s) ------------------------------------------
    MOV AL, 00000001b         ; Red ON (bit 0)
    OUT 4, AL

    LEA DX, msg_red
    MOV AH, 09h
    INT 21h

    MOV BL, 10
    CALL DELAY_SECONDS
    CMP esc_flag, 1
    JE  EXIT_PROG

    JMP TRAFFIC_LOOP

; ---- Exit ---------------------------------------------------
EXIT_PROG:
    MOV AL, 0                 ; turn off all lights
    OUT 4, AL

    LEA DX, msg_bye
    MOV AH, 09h
    INT 21h

    MOV AH, 4Ch
    INT 21h
MAIN ENDP

; ============================================================
; PROCEDURE: DELAY_SECONDS
; Purpose  : Waits for BL seconds using INT 15h/AH=86h.
;            This is a BIOS microsecond delay that Emu8086
;            handles natively without freezing the emulator.
;            Checks for ESC key between each 1-second wait.
; Input    : BL = number of seconds to wait
; Output   : esc_flag = 1 if ESC was pressed
; ============================================================
DELAY_SECONDS PROC
    PUSH AX
    PUSH CX
    PUSH DX

    MOV esc_flag, 0           ; reset ESC flag

WAIT_ONE_SEC:
    CMP BL, 0
    JE  WAIT_DONE

    ; --- Check keyboard for ESC (non-blocking) ---
    MOV AH, 01h              ; INT 16h/AH=01h check buffer
    INT 16h
    JZ  NO_ESC               ; ZF=1 means no key

    MOV AH, 00h              ; read the key
    INT 16h
    CMP AL, 27               ; ESC?
    JNE NO_ESC

    MOV esc_flag, 1           ; ESC was pressed
    JMP WAIT_DONE

NO_ESC:
    ; --- Wait 1 second = 1,000,000 microseconds ---
    ; CX:DX = microseconds = 000Fh:4240h = 1,000,000
    MOV AH, 86h
    MOV CX, 000Fh
    MOV DX, 4240h
    INT 15h

    DEC BL
    JMP WAIT_ONE_SEC

WAIT_DONE:
    POP DX
    POP CX
    POP AX
    RET
DELAY_SECONDS ENDP

END MAIN
