; ============================================================
; Project Title : Assembly Snake Game
; Author        : CSE132 Student - Spring 2026
; Description   : A snake game using INT 16h for keyboard
;                 input (arrow keys) and INT 10h for video.
;                 The snake moves automatically across the
;                 80x25 text screen. Eat food (*) to grow.
;                 Game over on wall or self collision.
;                 Press ESC to quit.
;
; Controls      : Arrow keys = change direction
;                 ESC        = quit
;
; Registers     : AX, BX, CX, DX used for I/O and logic
;                 SI, DI used for array indexing
; ============================================================

.MODEL SMALL
.STACK 100h

; ------------------------------------------------------------
; DATA SEGMENT
; ------------------------------------------------------------
.DATA
    ; Screen boundaries (play area inside border)
    MIN_X       EQU  1
    MAX_X       EQU  78
    MIN_Y       EQU  1
    MAX_Y       EQU  23
    MAX_LEN     EQU  100

    ; Snake body arrays
    snakeX      DB  MAX_LEN DUP(0)
    snakeY      DB  MAX_LEN DUP(0)
    sLen        DB  3             ; current snake length

    ; Direction: 0=right, 1=down, 2=left, 3=up
    dir         DB  0

    ; Food position
    foodX       DB  20
    foodY       DB  10

    ; Game state
    score       DW  0
    alive       DB  1
    speed       DB  1             ; ticks between moves (lower=faster)

    ; Tick tracking
    lastTick    DW  0

    ; Messages
    msg_score   DB  "SCORE: $"
    msg_over    DB  "GAME OVER! $"
    msg_esc     DB  "Press any key...$"
    msg_title   DB  "SNAKE GAME - Arrows=Move, ESC=Quit$"

; ------------------------------------------------------------
; CODE SEGMENT
; ------------------------------------------------------------
.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    ; Set video mode 03h (80x25 text, clears screen)
    MOV AX, 0003h
    INT 10h

    ; Hide cursor
    MOV AH, 01h
    MOV CX, 2607h
    INT 10h

    ; Init snake at center going right
    MOV snakeX[0], 40         ; head
    MOV snakeY[0], 12
    MOV snakeX[1], 39         ; body
    MOV snakeY[1], 12
    MOV snakeX[2], 38         ; tail
    MOV snakeY[2], 12

    ; Get initial tick
    MOV AH, 00h
    INT 1Ah
    MOV lastTick, DX

    ; Draw border and initial food
    CALL DRAW_BORDER
    CALL SPAWN_FOOD
    CALL DRAW_FOOD
    CALL DRAW_SNAKE
    CALL DRAW_SCORE

; ============================================================
; MAIN GAME LOOP
; ============================================================
GAME_LOOP:
    CMP alive, 0
    JE  GAME_OVER

    ; --- Read keyboard (non-blocking) ---
    CALL READ_INPUT

    ; --- Wait for tick delay ---
    CALL WAIT_TICK
    CMP AL, 0                ; 0 = not time yet
    JE  GAME_LOOP

    ; --- Erase old tail before moving ---
    CALL ERASE_TAIL

    ; --- Move snake ---
    CALL MOVE_SNAKE

    ; --- Check collisions ---
    CMP alive, 0
    JE  GAME_OVER

    ; --- Check if food eaten ---
    CALL CHECK_FOOD

    ; --- Draw snake ---
    CALL DRAW_SNAKE

    ; --- Draw score ---
    CALL DRAW_SCORE

    JMP GAME_LOOP

; ---- Game Over ----------------------------------------------
GAME_OVER:
    ; Show game over message at center
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 12
    MOV DL, 30
    INT 10h

    ; Print "GAME OVER!" in red
    LEA SI, msg_over
PRINT_OVER:
    LODSB
    CMP AL, '$'
    JE  SHOW_FINAL_SCORE
    MOV AH, 0Eh
    MOV BL, 0Ch              ; red color
    INT 10h
    JMP PRINT_OVER

SHOW_FINAL_SCORE:
    ; Move cursor below
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 14
    MOV DL, 30
    INT 10h

    LEA DX, msg_esc
    MOV AH, 09h
    INT 21h

    ; Wait for any key
    MOV AH, 00h
    INT 16h

    ; Restore cursor and exit
    MOV AH, 01h
    MOV CX, 0607h
    INT 10h

    MOV AH, 4Ch
    INT 21h
MAIN ENDP

; ============================================================
; PROCEDURE: READ_INPUT
; Purpose  : Non-blocking keyboard read. Arrow keys change
;            direction. ESC quits. Prevents 180-degree turns.
; ============================================================
READ_INPUT PROC
    PUSH AX
    PUSH BX

    MOV AH, 01h              ; check keyboard buffer
    INT 16h
    JZ  INPUT_DONE            ; no key waiting

    MOV AH, 00h              ; read the key
    INT 16h                   ; AH = scan code

    ; ESC = quit
    CMP AL, 27
    JE  ESC_QUIT

    ; Check arrow keys by scan code
    CMP AH, 48h              ; Up
    JNE NOT_UP
    CMP dir, 1               ; cant reverse from Down
    JE  INPUT_DONE
    MOV dir, 3
    JMP INPUT_DONE

NOT_UP:
    CMP AH, 50h              ; Down
    JNE NOT_DOWN
    CMP dir, 3               ; cant reverse from Up
    JE  INPUT_DONE
    MOV dir, 1
    JMP INPUT_DONE

NOT_DOWN:
    CMP AH, 4Bh              ; Left
    JNE NOT_LEFT
    CMP dir, 0               ; cant reverse from Right
    JE  INPUT_DONE
    MOV dir, 2
    JMP INPUT_DONE

NOT_LEFT:
    CMP AH, 4Dh              ; Right
    JNE INPUT_DONE
    CMP dir, 2               ; cant reverse from Left
    JE  INPUT_DONE
    MOV dir, 0
    JMP INPUT_DONE

ESC_QUIT:
    MOV alive, 0

INPUT_DONE:
    POP BX
    POP AX
    RET
READ_INPUT ENDP

; ============================================================
; PROCEDURE: WAIT_TICK
; Purpose  : Returns AL=1 when enough ticks have passed
;            (speed control). AL=0 if not time yet.
; ============================================================
WAIT_TICK PROC
    PUSH CX
    PUSH DX

    MOV AH, 00h
    INT 1Ah                   ; DX = low word of tick count

    MOV AX, DX
    SUB AX, lastTick          ; elapsed ticks

    MOV BL, speed
    MOV BH, 0
    CMP AX, BX
    JB  NOT_YET

    MOV lastTick, DX          ; update last tick
    MOV AL, 1                 ; time to move
    JMP TICK_DONE

NOT_YET:
    MOV AL, 0

TICK_DONE:
    POP DX
    POP CX
    RET
WAIT_TICK ENDP

; ============================================================
; PROCEDURE: MOVE_SNAKE
; Purpose  : Shifts body segments forward, moves head in
;            current direction. Checks wall and self collision.
; ============================================================
MOVE_SNAKE PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI

    ; Shift body: from tail to index 1
    MOV CL, sLen
    MOV CH, 0
    DEC CX                    ; start from last index

SHIFT_BODY:
    CMP CX, 0
    JE  SHIFT_DONE
    MOV SI, CX

    ; snakeX[SI] = snakeX[SI-1]
    MOV AL, snakeX[SI-1]
    MOV snakeX[SI], AL
    MOV AL, snakeY[SI-1]
    MOV snakeY[SI], AL

    DEC CX
    JMP SHIFT_BODY

SHIFT_DONE:
    ; Move head based on direction
    MOV AL, snakeX[0]
    MOV BL, snakeY[0]

    CMP dir, 0               ; right
    JNE CHK_D1
    INC AL
    JMP SET_HEAD
CHK_D1:
    CMP dir, 1               ; down
    JNE CHK_D2
    INC BL
    JMP SET_HEAD
CHK_D2:
    CMP dir, 2               ; left
    JNE CHK_D3
    DEC AL
    JMP SET_HEAD
CHK_D3:                       ; up
    DEC BL

SET_HEAD:
    MOV snakeX[0], AL
    MOV snakeY[0], BL

    ; --- Wall collision ---
    CMP AL, MIN_X
    JB  SNAKE_DEAD
    CMP AL, MAX_X
    JA  SNAKE_DEAD
    CMP BL, MIN_Y
    JB  SNAKE_DEAD
    CMP BL, MAX_Y
    JA  SNAKE_DEAD

    ; --- Self collision (check head vs body) ---
    MOV CL, sLen
    MOV CH, 0
    MOV SI, 1                ; start from segment 1

SELF_CHECK:
    CMP SI, CX
    JAE  MOVE_OK
    MOV AL, snakeX[SI]
    CMP AL, snakeX[0]
    JNE  SELF_NEXT
    MOV AL, snakeY[SI]
    CMP AL, snakeY[0]
    JE   SNAKE_DEAD

SELF_NEXT:
    INC SI
    JMP SELF_CHECK

SNAKE_DEAD:
    MOV alive, 0

MOVE_OK:
    POP SI
    POP CX
    POP BX
    POP AX
    RET
MOVE_SNAKE ENDP

; ============================================================
; PROCEDURE: CHECK_FOOD
; Purpose  : If head is on food, grow snake and spawn new food.
; ============================================================
CHECK_FOOD PROC
    PUSH AX
    PUSH BX

    MOV AL, snakeX[0]
    CMP AL, foodX
    JNE  NO_FOOD
    MOV AL, snakeY[0]
    CMP AL, foodY
    JNE  NO_FOOD

    ; Eat food: grow snake
    MOV AL, sLen
    CMP AL, MAX_LEN
    JAE  SKIP_GROW
    INC sLen
SKIP_GROW:
    INC score

    ; Spawn new food
    CALL SPAWN_FOOD
    CALL DRAW_FOOD

NO_FOOD:
    POP BX
    POP AX
    RET
CHECK_FOOD ENDP

; ============================================================
; PROCEDURE: SPAWN_FOOD
; Purpose  : Places food at a random position using BIOS ticks.
;            Avoids placing on the snake body.
; ============================================================
SPAWN_FOOD PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

SPAWN_TRY:
    ; Get tick count for pseudo-random
    MOV AH, 00h
    INT 1Ah                   ; CX:DX = tick count

    ; foodX = (DL mod play_width) + MIN_X
    MOV AL, DL
    MOV AH, 0
    MOV BL, MAX_X - MIN_X
    DIV BL                    ; AH = remainder
    ADD AH, MIN_X
    MOV foodX, AH

    ; foodY = (DH mod play_height) + MIN_Y
    MOV AL, DH
    MOV AH, 0
    MOV BL, MAX_Y - MIN_Y
    DIV BL
    ADD AH, MIN_Y
    MOV foodY, AH

    ; Check food is not on snake
    MOV CL, sLen
    MOV CH, 0
    MOV SI, 0

SPAWN_CHK:
    CMP SI, CX
    JAE  SPAWN_OK
    MOV AL, snakeX[SI]
    CMP AL, foodX
    JNE  SPAWN_NXT
    MOV AL, snakeY[SI]
    CMP AL, foodY
    JE   SPAWN_TRY            ; on snake, try again

SPAWN_NXT:
    INC SI
    JMP SPAWN_CHK

SPAWN_OK:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SPAWN_FOOD ENDP

; ============================================================
; PROCEDURE: DRAW_BORDER
; Purpose  : Draws a # border around the play area.
; ============================================================
DRAW_BORDER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; Top border (row 0, col 0..79)
    MOV DH, 0
    MOV DL, 0
DRAW_TOP:
    CMP DL, 79
    JA  DRAW_BOTTOM
    MOV AH, 02h
    MOV BH, 0
    INT 10h
    MOV AH, 09h
    MOV AL, '#'
    MOV BH, 0
    MOV BL, 07h
    MOV CX, 1
    INT 10h
    INC DL
    JMP DRAW_TOP

    ; Bottom border (row 24, col 0..79)
DRAW_BOTTOM:
    MOV DH, 24
    MOV DL, 0
DRAW_BOT_L:
    CMP DL, 79
    JA  DRAW_SIDES
    MOV AH, 02h
    MOV BH, 0
    INT 10h
    MOV AH, 09h
    MOV AL, '#'
    MOV BH, 0
    MOV BL, 07h
    MOV CX, 1
    INT 10h
    INC DL
    JMP DRAW_BOT_L

    ; Left and right borders
DRAW_SIDES:
    MOV DH, 1
DRAW_SIDE_L:
    CMP DH, 24
    JAE  BORDER_DONE

    ; Left wall (col 0)
    MOV DL, 0
    MOV AH, 02h
    MOV BH, 0
    INT 10h
    MOV AH, 09h
    MOV AL, '#'
    MOV BH, 0
    MOV BL, 07h
    MOV CX, 1
    INT 10h

    ; Right wall (col 79)
    MOV DL, 79
    MOV AH, 02h
    MOV BH, 0
    INT 10h
    MOV AH, 09h
    MOV AL, '#'
    MOV BH, 0
    MOV BL, 07h
    MOV CX, 1
    INT 10h

    INC DH
    JMP DRAW_SIDE_L

BORDER_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_BORDER ENDP

; ============================================================
; PROCEDURE: DRAW_SNAKE
; Purpose  : Draws the snake. @ = head, o = body (green).
; ============================================================
DRAW_SNAKE PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV CL, sLen
    MOV CH, 0
    MOV SI, 0

DRAW_SEG:
    CMP SI, CX
    JAE  DRAW_S_DONE

    ; Set cursor to snakeX[SI], snakeY[SI]
    MOV DL, snakeX[SI]
    MOV DH, snakeY[SI]
    MOV AH, 02h
    MOV BH, 0
    INT 10h

    ; Head = @, body = o
    CMP SI, 0
    JNE  IS_BODY
    MOV AL, '@'
    MOV BL, 0Ah              ; bright green
    JMP  WRITE_SEG
IS_BODY:
    MOV AL, 'o'
    MOV BL, 02h              ; dark green

WRITE_SEG:
    MOV AH, 09h
    MOV BH, 0
    MOV CX, 1
    INT 10h

    ; Restore CX for loop counter
    MOV CL, sLen
    MOV CH, 0

    INC SI
    JMP DRAW_SEG

DRAW_S_DONE:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_SNAKE ENDP

; ============================================================
; PROCEDURE: ERASE_TAIL
; Purpose  : Erases the last segment of the snake (before move).
; ============================================================
ERASE_TAIL PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; Tail is at index sLen-1
    MOV AL, sLen
    MOV AH, 0
    DEC AX
    MOV SI, AX

    MOV DL, snakeX[SI]
    MOV DH, snakeY[SI]
    MOV AH, 02h
    MOV BH, 0
    INT 10h

    MOV AH, 09h
    MOV AL, ' '
    MOV BH, 0
    MOV BL, 07h
    MOV CX, 1
    INT 10h

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ERASE_TAIL ENDP

; ============================================================
; PROCEDURE: DRAW_FOOD
; Purpose  : Draws the food (*) in yellow on screen.
; ============================================================
DRAW_FOOD PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV DL, foodX
    MOV DH, foodY
    MOV AH, 02h
    MOV BH, 0
    INT 10h

    MOV AH, 09h
    MOV AL, '*'
    MOV BH, 0
    MOV BL, 0Eh              ; yellow
    MOV CX, 1
    INT 10h

    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_FOOD ENDP

; ============================================================
; PROCEDURE: DRAW_SCORE
; Purpose  : Displays "SCORE: X" on the bottom border row.
; ============================================================
DRAW_SCORE PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; Position cursor at bottom-left inside border
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 24
    MOV DL, 2
    INT 10h

    ; Print "SCORE: " using teletype
    LEA SI, msg_score
PRINT_SC:
    LODSB
    CMP AL, '$'
    JE  PRINT_NUM
    MOV AH, 0Eh
    MOV BL, 0Fh              ; white
    INT 10h
    JMP PRINT_SC

    ; Print score number
PRINT_NUM:
    MOV AX, score
    CALL PRINT_NUMBER

    ; Print title on top border
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 0
    MOV DL, 2
    INT 10h

    LEA SI, msg_title
PRINT_TT:
    LODSB
    CMP AL, '$'
    JE  SC_DONE
    MOV AH, 0Eh
    MOV BL, 0Fh
    INT 10h
    JMP PRINT_TT

SC_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_SCORE ENDP

; ============================================================
; PROCEDURE: PRINT_NUMBER
; Purpose  : Prints unsigned 16-bit integer in AX as decimal.
; ============================================================
PRINT_NUMBER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV BX, 10
    MOV CX, 0

EXTRACT_D:
    MOV DX, 0
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE EXTRACT_D

PRINT_D:
    POP DX
    ADD DL, '0'
    MOV AH, 0Eh
    MOV BL, 0Fh
    INT 10h
    LOOP PRINT_D

    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUMBER ENDP

END MAIN
