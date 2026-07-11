;==============================================================
; GAME_FSM.ASM
; Owning partner: Partner 3
;
; Round state machine: IDLE -> READY -> COUNTDOWN -> RUNNING ->
; STOPPED -> WINNER -> (back to IDLE).
; Drives both 7-seg displays live during RUNNING via
; SEG_SetPlayer1/SEG_SetPlayer2 (Partner 2's driver), drives the
; two status LEDs during COUNTDOWN, and hands off a completed
; round-result structure to Partner 4 via RR_* fields + RR_Ready.
;
; Depends on : hardware_pins.inc, ram_map.inc, game_defs.inc,
;              buttons.asm (BTN_x_Event/Held),
;              rng.asm (RNG_GetNext/Reseed),
;              sevenseg_driver.asm (SEG_SetPlayer1/2, PARAM_SEC/HUN),
;              timer_isr.asm (GAME_Tick1ms - see coordination note)
;==============================================================

;--------------------------------------------------------------
; GAME_Init : call once at startup, after INIT / BTN_Init /
; RNG_Init have all run.
;--------------------------------------------------------------
GAME_Init
    MOVLW   STATE_IDLE
    MOVWF   GAME_State
    CLRF    RR_Ready
    RETURN

;--------------------------------------------------------------
; GAME_Poll : call once per main-loop pass. Internally waits on
; GAME_Tick1ms so all timing is tied to the 1ms tick, not to
; loop speed.
;--------------------------------------------------------------
GAME_Poll
    BANKSEL GAME_Tick1ms
    MOVF    GAME_Tick1ms, F
    BTFSC   STATUS, Z
    RETURN                     ; no new tick yet, nothing to do
    DECF    GAME_Tick1ms, F
    CALL    BTN_Poll

    MOVF    GAME_State, W
    XORLW   STATE_IDLE
    BTFSC   STATUS, Z
    GOTO    _GAME_DoIdle
    MOVF    GAME_State, W
    XORLW   STATE_COUNTDOWN
    BTFSC   STATUS, Z
    GOTO    _GAME_DoCountdown
    MOVF    GAME_State, W
    XORLW   STATE_RUNNING
    BTFSC   STATUS, Z
    GOTO    _GAME_DoRunning
    CLRF    BTN_M_Event
    RETURN                       ; STOPPED/WINNER handled synchronously below, not per-tick

;--------------------------------------------------------------
_GAME_DoIdle
    MOVF    BTN_M_Event, W
    BTFSS   STATUS, Z
    GOTO    _GAME_StartRound
    RETURN
_GAME_StartRound
    CLRF    BTN_M_Event          ; consume the event
    CALL    RNG_Reseed
    CALL    RNG_GetNext          ; result in W and RNG_Result
    MOVWF   RR_JudgeTime          ; store the secret target for this round

    CLRF    GAME_RunSec
    CLRF    GAME_RunHun
    CLRF    GAME_TickAccum
    CLRF    GAME_TimeoutSec
    CLRF    GAME_Temp
    CLRF    BTN_P1_Event
    CLRF    BTN_P2_Event

    MOVLW   D'0'
    MOVWF   GAME_CountdownCnt
    CLRF    GAME_Reserved1
    BANKSEL PORTB
    BSF     PORTB, LED_1          ; both LEDs on = "get ready"
    BSF     PORTB, LED_2

    MOVLW   STATE_COUNTDOWN
    MOVWF   GAME_State
    RETURN

;--------------------------------------------------------------
_GAME_DoCountdown
    CLRF    BTN_M_Event
    CLRF    BTN_P1_Event
    CLRF    BTN_P2_Event
    INCF    GAME_CountdownCnt, F
    BTFSC   STATUS, Z
    INCF    GAME_Reserved1, F

    MOVLW   HIGH COUNTDOWN_TICKS
    SUBWF   GAME_Reserved1, W
    BTFSS   STATUS, C
    RETURN                          ; not yet 1 second, keep waiting
    BTFSS   STATUS, Z
    GOTO    _GAME_CountdownDone

    MOVLW   LOW COUNTDOWN_TICKS
    SUBWF   GAME_CountdownCnt, W
    BTFSS   STATUS, C
    RETURN

_GAME_CountdownDone
    BANKSEL PORTB
    BCF     PORTB, LED_1            ; LEDs off, running clock starts now
    BCF     PORTB, LED_2
    CLRF    BTN_P1_Event
    CLRF    BTN_P2_Event
    MOVLW   STATE_RUNNING
    MOVWF   GAME_State
    RETURN

;--------------------------------------------------------------
_GAME_DoRunning
    CLRF    BTN_M_Event
    ; advance the shared running clock by one 1ms tick
    INCF    GAME_TickAccum, F
    MOVLW   D'10'
    SUBWF   GAME_TickAccum, W
    BTFSS   STATUS, C
    GOTO    _GAME_UpdateDisplays     ; not yet a full hundredth, just redisplay

    CLRF    GAME_TickAccum
    INCF    GAME_RunHun, F
    MOVLW   D'100'
    SUBWF   GAME_RunHun, W
    BTFSS   STATUS, C
    GOTO    _GAME_CheckTimeout

    CLRF    GAME_RunHun
    INCF    GAME_RunSec, F

_GAME_CheckTimeout
    MOVLW   D'100'                    ; 100 ticks-of-hundredths = 1 second boundary marker
    ; (timeout is tracked by GAME_RunSec directly, no extra counter needed)
    MOVF    GAME_RunSec, W
    MOVLW   ROUND_TIMEOUT_SEC
    SUBWF   GAME_RunSec, W
    BTFSS   STATUS, C
    GOTO    _GAME_CapturePresses
    GOTO    _GAME_ShowTimeout          ; elapsed time is exactly 60.00 here

_GAME_CapturePresses
    BTFSC   GAME_Temp, 0
    GOTO    _GAME_CheckP2
    MOVF    BTN_P1_Event, W
    BTFSS   STATUS, Z
    GOTO    _GAME_CaptureP1
    GOTO    _GAME_CheckP2
_GAME_CaptureP1
    CLRF    BTN_P1_Event
    MOVF    GAME_RunSec, W
    MOVWF   RR_P1Sec
    MOVF    GAME_RunHun, W
    MOVWF   RR_P1Hun
    BSF     GAME_Temp, 0              ; mark P1 captured (bit0 of a local flags byte)
_GAME_CheckP2
    BTFSC   GAME_Temp, 1
    GOTO    _GAME_CheckBothDone
    MOVF    BTN_P2_Event, W
    BTFSS   STATUS, Z
    GOTO    _GAME_CaptureP2
    GOTO    _GAME_CheckBothDone
_GAME_CaptureP2
    CLRF    BTN_P2_Event
    MOVF    GAME_RunSec, W
    MOVWF   RR_P2Sec
    MOVF    GAME_RunHun, W
    MOVWF   RR_P2Hun
    BSF     GAME_Temp, 1

_GAME_CheckBothDone
    MOVF    GAME_Temp, W
    ANDLW   B'00000011'
    XORLW   B'00000011'
    BTFSC   STATUS, Z
    GOTO    _GAME_BothPressed
    ; NOTE: EDGE CASE - "player never presses" is resolved by
    ; _GAME_ForceStop above (timeout path), not here. This branch
    ; only fires once BOTH have pressed within the timeout window.

_GAME_UpdateDisplays
    BTFSC   GAME_Temp, 0
    GOTO    _GAME_DisplayP1Captured
    MOVF    GAME_RunSec, W
    MOVWF   PARAM_SEC
    MOVF    GAME_RunHun, W
    MOVWF   PARAM_HUN
    CALL    SEG_SetPlayer1
    GOTO    _GAME_UpdateP2Display

_GAME_DisplayP1Captured
    MOVF    RR_P1Sec, W
    MOVWF   PARAM_SEC
    MOVF    RR_P1Hun, W
    MOVWF   PARAM_HUN
    CALL    SEG_SetPlayer1

_GAME_UpdateP2Display
    BTFSC   GAME_Temp, 1
    GOTO    _GAME_DisplayP2Captured
    MOVF    GAME_RunSec, W
    MOVWF   PARAM_SEC
    MOVF    GAME_RunHun, W
    MOVWF   PARAM_HUN
    CALL    SEG_SetPlayer2
    RETURN

_GAME_DisplayP2Captured
    MOVF    RR_P2Sec, W
    MOVWF   PARAM_SEC
    MOVF    RR_P2Hun, W
    MOVWF   PARAM_HUN
    CALL    SEG_SetPlayer2
    RETURN

_GAME_BothPressed
    MOVLW   STATE_STOPPED
    MOVWF   GAME_State
    CALL    GAME_Resolve
    RETURN

_GAME_ShowTimeout
    BTFSC   GAME_Temp, 0
    GOTO    _GAME_ShowTimeoutP2
    MOVLW   ROUND_TIMEOUT_SEC
    MOVWF   PARAM_SEC
    CLRF    PARAM_HUN
    CALL    SEG_SetPlayer1

_GAME_ShowTimeoutP2
    BTFSC   GAME_Temp, 1
    GOTO    _GAME_ForceStop
    MOVLW   ROUND_TIMEOUT_SEC
    MOVWF   PARAM_SEC
    CLRF    PARAM_HUN
    CALL    SEG_SetPlayer2

_GAME_ForceStop
    MOVF    GAME_Temp, W
    ANDLW   B'00000011'
    XORLW   B'00000011'
    BTFSC   STATUS, Z
    GOTO    _GAME_BothPressed

    BTFSC   GAME_Temp, 0
    GOTO    _GAME_TimeoutP1Wins
    BTFSC   GAME_Temp, 1
    GOTO    _GAME_TimeoutP2Wins
    CLRF    RR_Winner
    GOTO    _GAME_TimeoutDone

_GAME_TimeoutP1Wins
    MOVLW   0x01
    MOVWF   RR_Winner
    GOTO    _GAME_TimeoutDone

_GAME_TimeoutP2Wins
    MOVLW   0x02
    MOVWF   RR_Winner

_GAME_TimeoutDone
    MOVLW   0x01
    MOVWF   RR_Ready
    MOVLW   STATE_WINNER
    MOVWF   GAME_State
    RETURN

;--------------------------------------------------------------
; GAME_Resolve : compare absolute differences in hundredths.
; Judge time is RR_JudgeTime * 100. Smaller wins; a tie is a
; replay (no winner, no score) per spec.
;--------------------------------------------------------------
GAME_Resolve
    ; Build P1 delta in GAME_Reserved2:GAME_TimeoutSec.
    MOVF    RR_JudgeTime, W
    SUBWF   RR_P1Sec, W
    BTFSC   STATUS, C
    GOTO    _GR_P1AtOrAfterJudge
    MOVF    RR_P1Sec, W
    SUBWF   RR_JudgeTime, W
    CALL    _GR_Mul100
    MOVF    RR_P1Hun, W
    SUBWF   GAME_Reserved2, F
    BTFSS   STATUS, C
    DECF    GAME_TimeoutSec, F
    GOTO    _GR_SaveP1Delta

_GR_P1AtOrAfterJudge
    CALL    _GR_Mul100
    MOVF    RR_P1Hun, W
    ADDWF   GAME_Reserved2, F
    BTFSC   STATUS, C
    INCF    GAME_TimeoutSec, F

_GR_SaveP1Delta
    MOVF    GAME_Reserved2, W
    MOVWF   GAME_Temp
    MOVF    GAME_TimeoutSec, W
    MOVWF   GAME_Reserved1

    ; Build P2 delta in GAME_Reserved2:GAME_TimeoutSec.
    MOVF    RR_JudgeTime, W
    SUBWF   RR_P2Sec, W
    BTFSC   STATUS, C
    GOTO    _GR_P2AtOrAfterJudge
    MOVF    RR_P2Sec, W
    SUBWF   RR_JudgeTime, W
    CALL    _GR_Mul100
    MOVF    RR_P2Hun, W
    SUBWF   GAME_Reserved2, F
    BTFSS   STATUS, C
    DECF    GAME_TimeoutSec, F
    GOTO    _GR_Compare

_GR_P2AtOrAfterJudge
    CALL    _GR_Mul100
    MOVF    RR_P2Hun, W
    ADDWF   GAME_Reserved2, F
    BTFSC   STATUS, C
    INCF    GAME_TimeoutSec, F

_GR_Compare
    MOVF    GAME_TimeoutSec, W
    SUBWF   GAME_Reserved1, W
    BTFSS   STATUS, Z
    GOTO    _GR_DifferentHigh
    MOVF    GAME_Reserved2, W
    SUBWF   GAME_Temp, W
    BTFSC   STATUS, Z
    GOTO    _GR_Tie
    BTFSC   STATUS, C
    GOTO    _GR_P2Wins
    GOTO    _GR_P1Wins

_GR_DifferentHigh
    BTFSC   STATUS, C
    GOTO    _GR_P2Wins

_GR_P1Wins
    MOVLW   0x01
    MOVWF   RR_Winner
    GOTO    _GR_Done
_GR_P2Wins
    MOVLW   0x02
    MOVWF   RR_Winner
    GOTO    _GR_Done
_GR_Tie
    CLRF    RR_Winner                ; 0 = no winner, replay per spec
_GR_Done
    MOVLW   0x01
    MOVWF   RR_Ready                  ; hand off to Partner 4
    MOVLW   STATE_WINNER
    MOVWF   GAME_State
    RETURN

; W input: seconds difference. Output:
; GAME_TimeoutSec:GAME_Reserved2 = W * 100.
_GR_Mul100
    MOVWF   GAME_CountdownCnt
    CLRF    GAME_Reserved2
    CLRF    GAME_TimeoutSec
    MOVF    GAME_CountdownCnt, F
    BTFSC   STATUS, Z
    RETURN
_GR_Mul100Loop
    MOVLW   D'100'
    ADDWF   GAME_Reserved2, F
    BTFSC   STATUS, C
    INCF    GAME_TimeoutSec, F
    DECFSZ  GAME_CountdownCnt, F
    GOTO    _GR_Mul100Loop
    RETURN

;--------------------------------------------------------------
; GAME_ReturnToIdle : Partner 4 calls this after consuming
; RR_Ready/RR_Winner/etc, once it's safe to start a new round.
;--------------------------------------------------------------
GAME_ReturnToIdle
    CLRF    RR_Ready
    CLRF    BTN_M_Event
    MOVLW   STATE_IDLE
    MOVWF   GAME_State
    CLRF    GAME_Temp
    RETURN
