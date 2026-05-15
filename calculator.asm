; ============================================================
; Project Title : Multi-functional Calculator
; Author        : CSE132 Student — Spring 2026
; Description   : A menu-driven calculator that performs
;                 Addition, Subtraction, Multiplication,
;                 and Division on two user-entered numbers.
;                 Uses INT 21h for all I/O operations.
;                 Registers AX, BX, CX, DX are used for
;                 arithmetic. Results are printed digit-by-digit.
; ============================================================

.MODEL SMALL
.STACK 100h

; ------------------------------------------------------------
; DATA SEGMENT — all strings and variables declared here
; ------------------------------------------------------------
.DATA
    msg_menu    DB 13,10,"===== CALCULATOR MENU =====",13,10
                DB " 1. Addition       (+)",13,10
                DB " 2. Subtraction    (-)",13,10
                DB " 3. Multiplication (*)",13,10
                DB " 4. Division       (/)",13,10
                DB " 5. Exit",13,10
                DB "Select (1-5): $"

    msg_num1    DB 13,10,"Enter first number  (0-99): $"
    msg_num2    DB 13,10,"Enter second number (0-99): $"
    msg_result  DB 13,10,"Result = $"
    msg_divzero DB 13,10,"ERROR: Division by zero!$"
    msg_invalid DB 13,10,"Invalid choice. Try again.$"
    msg_bye     DB 13,10,"Goodbye!",13,10,"$"
    msg_nl      DB 13,10,"$"

    num1        DW 0      ; first operand
    num2        DW 0      ; second operand
    choice      DB 0      ; menu selection

; ------------------------------------------------------------
; CODE SEGMENT
; ------------------------------------------------------------
.CODE
MAIN PROC
    ; --- Initialise Data Segment ---
    MOV AX, @DATA         ; Load data segment address into AX
    MOV DS, AX            ; Point DS to our data segment

MENU_LOOP:
    ; --- Print menu ---
    CALL CLEAR_SCREEN
    LEA DX, msg_menu      ; Load address of menu string
    MOV AH, 09h           ; INT 21h / AH=09h — print string
    INT 21h

    ; --- Read single character choice ---
    MOV AH, 01h           ; INT 21h / AH=01h — read char with echo
    INT 21h
    MOV choice, AL        ; Save the character entered

    ; --- Branch on choice ---
    CMP AL, '1'
    JE  DO_ADD
    CMP AL, '2'
    JE  DO_SUB
    CMP AL, '3'
    JE  DO_MUL
    CMP AL, '4'
    JE  DO_DIV
    CMP AL, '5'
    JE  EXIT_PROG

    ; --- Invalid input ---
    LEA DX, msg_invalid
    MOV AH, 09h
    INT 21h
    CALL WAIT_KEY
    JMP MENU_LOOP

; ---- Addition -----------------------------------------------
DO_ADD:
    CALL GET_TWO_NUMS     ; reads num1 and num2 from user
    MOV AX, num1          ; AX = first operand
    ADD AX, num2          ; AX = num1 + num2
    PUSH AX               ; save result before INT 21h destroys AX
    LEA DX, msg_result
    MOV AH, 09h
    INT 21h
    POP AX                ; restore result into AX
    CALL PRINT_NUMBER     ; print AX as decimal
    CALL WAIT_KEY
    JMP MENU_LOOP

; ---- Subtraction --------------------------------------------
DO_SUB:
    CALL GET_TWO_NUMS
    MOV AX, num1          ; AX = first operand
    SUB AX, num2          ; AX = num1 - num2
    PUSH AX               ; save result before INT 21h destroys AX
    LEA DX, msg_result
    MOV AH, 09h
    INT 21h
    POP AX                ; restore result into AX
    CALL PRINT_NUMBER
    CALL WAIT_KEY
    JMP MENU_LOOP

; ---- Multiplication -----------------------------------------
DO_MUL:
    CALL GET_TWO_NUMS
    MOV AX, num1          ; AX = multiplicand
    MOV BX, num2          ; BX = multiplier
    MUL BX                ; DX:AX = AX * BX (unsigned)
    PUSH AX               ; save result before INT 21h destroys AX
    LEA DX, msg_result
    MOV AH, 09h
    INT 21h
    POP AX                ; restore result into AX
    CALL PRINT_NUMBER     ; result in AX (fits for 0-99*99=9801)
    CALL WAIT_KEY
    JMP MENU_LOOP

; ---- Division -----------------------------------------------
DO_DIV:
    CALL GET_TWO_NUMS
    MOV BX, num2          ; BX = divisor
    CMP BX, 0             ; Check for division by zero
    JE  DIV_ZERO_ERR
    MOV AX, num1          ; AX = dividend
    MOV DX, 0             ; Clear DX before 16-bit division
    DIV BX                ; AX = quotient, DX = remainder
    PUSH AX               ; save quotient before INT 21h destroys AX
    LEA DX, msg_result
    MOV AH, 09h
    INT 21h
    POP AX                ; restore quotient into AX
    CALL PRINT_NUMBER     ; print quotient in AX
    CALL WAIT_KEY
    JMP MENU_LOOP

DIV_ZERO_ERR:
    LEA DX, msg_divzero
    MOV AH, 09h
    INT 21h
    CALL WAIT_KEY
    JMP MENU_LOOP

; ---- Exit ---------------------------------------------------
EXIT_PROG:
    LEA DX, msg_bye
    MOV AH, 09h
    INT 21h
    MOV AH, 4Ch           ; INT 21h / AH=4Ch — terminate program
    MOV AL, 0             ; Return code 0 (no error)
    INT 21h
MAIN ENDP

; ============================================================
; PROCEDURE: GET_TWO_NUMS
; Purpose  : Prompts the user to enter num1 then num2 (0-99).
;            Reads two digits, converts ASCII → binary, stores
;            in variables num1 and num2.
; Registers: AX, BX, CX, DX (all restored via stack)
; ============================================================
GET_TWO_NUMS PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; -- Read num1 --
    LEA DX, msg_num1
    MOV AH, 09h
    INT 21h
    CALL READ_BYTE        ; returns value in BL
    MOV num1, BX         ; store as word

    ; -- Read num2 --
    LEA DX, msg_num2
    MOV AH, 09h
    INT 21h
    CALL READ_BYTE        ; returns value in BL
    MOV num2, BX         ; store as word

    POP DX
    POP CX
    POP BX
    POP AX
    RET
GET_TWO_NUMS ENDP

; ============================================================
; PROCEDURE: READ_BYTE
; Purpose  : Reads up to 2 digit characters from keyboard,
;            converts them to a binary number in BX (0-99).
; Algorithm: digit1*10 + digit2
; Returns  : BX = numeric value entered
; FIX NOTE : Use 8-bit MUL (MUL BL) so result stays in AX only.
;            16-bit MUL DX writes high word into DX, corrupting it.
; ============================================================
READ_BYTE PROC
    PUSH AX
    PUSH CX

    MOV BX, 0            ; BX will accumulate the number
    MOV CX, 2            ; max 2 digits

READ_DIGIT_LOOP:
    MOV AH, 01h          ; INT 21h / AH=01h — read char with echo into AL
    INT 21h
    CMP AL, 13           ; 13 = Enter (CR) — stop reading
    JE  READ_DONE
    CMP AL, '0'          ; reject anything below '0'
    JB  READ_DONE
    CMP AL, '9'          ; reject anything above '9'
    JA  READ_DONE
    SUB AL, '0'          ; convert ASCII → binary digit (0-9) in AL

    ; Shift accumulator left one decimal place: BX = BX * 10
    ; Use 8-bit multiply: AL = BL * 10, result in AX (AH:AL)
    ; This does NOT touch DX — safe!
    PUSH AX              ; save the new digit (AL)
    MOV  AL, BL          ; AL = low byte of accumulator
    MOV  BL, 10          ; BL = multiplier 10
    MUL  BL              ; AX = AL * BL  (8-bit: result in AX only, DX untouched)
    MOV  BX, AX          ; BX = accumulator * 10
    POP  AX              ; restore new digit into AL
    MOV  AH, 0           ; clear AH so ADD works on full word
    ADD  BX, AX          ; BX = BX*10 + new digit
    LOOP READ_DIGIT_LOOP

READ_DONE:
    POP CX
    POP AX
    RET
READ_BYTE ENDP

; ============================================================
; PROCEDURE: PRINT_NUMBER
; Purpose  : Prints the 16-bit unsigned integer in AX to screen.
; Algorithm: Repeatedly divide AX by 10; push remainders onto
;            stack; then pop and print each digit.
; Registers: AX, BX, CX, DX used internally
; ============================================================
PRINT_NUMBER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV BX, 10           ; divisor = 10
    MOV CX, 0            ; digit counter

EXTRACT_DIGITS:
    MOV DX, 0            ; clear DX before division
    DIV BX               ; AX = quotient, DX = remainder (one digit)
    PUSH DX              ; push digit onto stack
    INC CX               ; increment digit count
    CMP AX, 0            ; if quotient is 0, no more digits
    JNE EXTRACT_DIGITS

PRINT_DIGITS:
    POP DX               ; pop digit (in reverse = correct order)
    ADD DL, '0'          ; convert binary digit → ASCII character
    MOV AH, 02h          ; INT 21h / AH=02h — print single character
    INT 21h
    LOOP PRINT_DIGITS

    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUMBER ENDP

; ============================================================
; PROCEDURE: CLEAR_SCREEN
; Purpose  : Clears the 80x25 text screen using INT 10h.
;            Sets scroll window (AH=06h), blanks full screen,
;            then repositions cursor to top-left (AH=02h).
; ============================================================
CLEAR_SCREEN PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AH, 06h          ; INT 10h / AH=06h — scroll window up
    MOV AL, 0            ; AL=0 clears the entire window
    MOV BH, 07h          ; BH = attribute (light grey on black)
    MOV CH, 0            ; CH = top row
    MOV CL, 0            ; CL = left column
    MOV DH, 24           ; DH = bottom row (24 = last row of 80x25)
    MOV DL, 79           ; DL = right column
    INT 10h

    ; Reposition cursor to row 0, col 0
    MOV AH, 02h          ; INT 10h / AH=02h — set cursor position
    MOV BH, 0            ; BH = page number 0
    MOV DH, 0            ; DH = row 0
    MOV DL, 0            ; DL = column 0
    INT 10h

    POP DX
    POP CX
    POP BX
    POP AX
    RET
CLEAR_SCREEN ENDP

; ============================================================
; PROCEDURE: WAIT_KEY
; Purpose  : Prints a prompt and waits for any key press.
; ============================================================
WAIT_KEY PROC
    PUSH AX
    PUSH DX
    LEA DX, msg_nl
    MOV AH, 09h
    INT 21h
    MOV AH, 01h          ; Wait for any key
    INT 21h
    POP DX
    POP AX
    RET
WAIT_KEY ENDP

END MAIN
