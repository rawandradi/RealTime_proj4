;==============================================================
; SCORE_MANAGER.ASM
; Partner 4 score tracking and LCD presentation.
; Depends on: ram_map.inc, game_defs.inc, lcd_driver.asm,
;             game_fsm.asm (GAME_ReturnToIdle).
;==============================================================

SCORE_Init
    CLRF    SCORE_P1
    CLRF    SCORE_P2
    CLRF    SCORE_GameOver
    CALL    _SCORE_ShowScores
    RETURN

; Call once per main-loop pass after GAME_Poll.
SCORE_Poll
    MOVF    SCORE_GameOver, F
    BTFSC   STATUS, Z
    GOTO    _SCORE_CheckResult

    ; Keep the win message while IDLE. The first master-started
    ; round moves the FSM out of IDLE and resets the match.
    MOVF    GAME_State, W
    XORLW   STATE_IDLE
    BTFSC   STATUS, Z
    RETURN
    CALL    SCORE_Init
    RETURN

_SCORE_CheckResult
    MOVF    RR_Ready, F
    BTFSC   STATUS, Z
    RETURN
    CLRF    RR_Ready

    MOVF    RR_Winner, W
    XORLW   0x01
    BTFSC   STATUS, Z
    GOTO    _SCORE_P1WonRound

    MOVF    RR_Winner, W
    XORLW   0x02
    BTFSC   STATUS, Z
    GOTO    _SCORE_P2WonRound
    GOTO    _SCORE_ShowRoundScore

_SCORE_P1WonRound
    INCF    SCORE_P1, F
    MOVLW   D'5'
    SUBWF   SCORE_P1, W
    BTFSC   STATUS, Z
    GOTO    _SCORE_P1WonGame
    GOTO    _SCORE_ShowRoundScore

_SCORE_P2WonRound
    INCF    SCORE_P2, F
    MOVLW   D'5'
    SUBWF   SCORE_P2, W
    BTFSC   STATUS, Z
    GOTO    _SCORE_P2WonGame

_SCORE_ShowRoundScore
    CALL    _SCORE_ShowScores
    GOTO    _SCORE_RoundComplete

_SCORE_P1WonGame
    MOVLW   0x01
    MOVWF   SCORE_GameOver
    CALL    _SCORE_ShowP1Wins
    GOTO    _SCORE_RoundComplete

_SCORE_P2WonGame
    MOVLW   0x01
    MOVWF   SCORE_GameOver
    CALL    _SCORE_ShowP2Wins

_SCORE_RoundComplete
    CALL    GAME_ReturnToIdle
    RETURN

_SCORE_Home
    CLRF    PARAM_ROW
    CLRF    PARAM_COL
    CALL    LCD_SetCursor
    RETURN

_SCORE_ShowScores
    CALL    LCD_Clear
    CALL    _SCORE_Home
    MOVLW   'P'
    CALL    LCD_Char
    MOVLW   '1'
    CALL    LCD_Char
    MOVLW   ':'
    CALL    LCD_Char
    MOVF    SCORE_P1, W
    ADDLW   '0'
    CALL    LCD_Char
    MOVLW   ' '
    CALL    LCD_Char
    MOVLW   'P'
    CALL    LCD_Char
    MOVLW   '2'
    CALL    LCD_Char
    MOVLW   ':'
    CALL    LCD_Char
    MOVF    SCORE_P2, W
    ADDLW   '0'
    CALL    LCD_Char
    RETURN

_SCORE_ShowP1Wins
    CALL    LCD_Clear
    CALL    _SCORE_Home
    MOVLW   'P'
    CALL    LCD_Char
    MOVLW   '1'
    CALL    LCD_Char
    GOTO    _SCORE_ShowWins

_SCORE_ShowP2Wins
    CALL    LCD_Clear
    CALL    _SCORE_Home
    MOVLW   'P'
    CALL    LCD_Char
    MOVLW   '2'
    CALL    LCD_Char

_SCORE_ShowWins
    MOVLW   ' '
    CALL    LCD_Char
    MOVLW   'W'
    CALL    LCD_Char
    MOVLW   'I'
    CALL    LCD_Char
    MOVLW   'N'
    CALL    LCD_Char
    MOVLW   'S'
    CALL    LCD_Char
    RETURN
