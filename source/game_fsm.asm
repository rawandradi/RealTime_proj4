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
; Depends on : hardware_pins.inc, game_defs.inc,
;              buttons.asm (BTN_x_Event/Held),
;              rng.asm (RNG_GetNext/Reseed),
;              sevenseg_driver.asm (SEG_SetPlayer1/2, PARAM_SEC/HUN),
;              timer_isr.asm (GAME_Tick1ms - see coordination note)
;==============================================================

    CBLOCK 0x7A
    GAME_State
    GAME_RunSec           ; shared running clock, seconds (0-99)
    GAME_RunHun           ; shared running clock, hundredths (0-99)
    GAME_TickAccum         ; counts 1ms ticks up to 10 -> 1 hundredth
    GAME_CountdownCnt      ; ms counter for the 1-second LED countdown
    GAME_TimeoutSec         ; counts elapsed seconds during RUNNING
    GAME_Temp
    ENDC

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
    BTFSS   GAME_Tick1ms, 0
    RETURN                     ; no new tick yet, nothing to do
    BCF     GAME_Tick1ms, 0
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
    CLRF    BTN_P1_Event
    CLRF    BTN_P2_Event

    MOVLW   D'0'
    MOVWF   GAME_CountdownCnt
    BANKSEL PORTB
    BSF     PORTB, LED_1          ; both LEDs on = "get ready"
    BSF     PORTB, LED_2

    MOVLW   STATE_COUNTDOWN
    MOVWF   GAME_State
    RETURN

;--------------------------------------------------------------
_GAME_DoCountdown
    INCF    GAME_CountdownCnt, F
    MOVLW   LOW COUNTDOWN_TICKS
    SUBWF   GAME_CountdownCnt, W
    BTFSS   STATUS, C
    RETURN                          ; not yet 1 second, keep waiting

    BANKSEL PORTB
    BCF     PORTB, LED_1            ; LEDs off, running clock starts now
    BCF     PORTB, LED_2
    MOVLW   STATE_RUNNING
    MOVWF   GAME_State
    RETURN

;--------------------------------------------------------------
_GAME_DoRunning
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
    GOTO    _GAME_ForceStop           ; timed out, nobody pressed - EDGE CASE per spec

_GAME_CapturePresses
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
    MOVF    GAME_RunSec, W
    MOVWF   PARAM_SEC
    MOVF    GAME_RunHun, W
    MOVWF   PARAM_HUN
    CALL    SEG_SetPlayer1           ; still live-updating for whichever
    CALL    SEG_SetPlayer2           ; player hasn't pressed yet
    RETURN

_GAME_BothPressed
    MOVLW   STATE_STOPPED
    MOVWF   GAME_State
    CALL    GAME_Resolve
    RETURN

_GAME_ForceStop
    ; EDGE CASE: timeout reached. Whichever player never pressed
    ; is assigned a maximally-far time so they cannot win.
    BTFSS   GAME_Temp, 0
    GOTO    _GAME_ForceP1Far
    BTFSS   GAME_Temp, 1
    GOTO    _GAME_ForceP2Far
    GOTO    _GAME_DoForceResolve
_GAME_ForceP1Far
    MOVLW   D'99'
    MOVWF   RR_P1Sec
    MOVWF   RR_P1Hun
_GAME_ForceP2Far
    BTFSC   GAME_Temp, 1
    GOTO    _GAME_DoForceResolve
    MOVLW   D'99'
    MOVWF   RR_P2Sec
    MOVWF   RR_P2Hun
_GAME_DoForceResolve
    MOVLW   STATE_STOPPED
    MOVWF   GAME_State
    CALL    GAME_Resolve
    RETURN

;--------------------------------------------------------------
; GAME_Resolve : compute |P1 - Judge| vs |P2 - Judge| in whole
; seconds (hundredths ignored for the compare - close enough for
; gameplay purposes, and keeps this readable). Smaller wins; a
; tie is a replay (no winner, no score) per spec.
;--------------------------------------------------------------
GAME_Resolve
    ; delta1 = |RR_P1Sec - RR_JudgeTime|
    MOVF    RR_JudgeTime, W
    SUBWF   RR_P1Sec, W
    BTFSC   STATUS, C
    GOTO    _GR_D1Pos
    MOVF    RR_P1Sec, W
    SUBWF   RR_JudgeTime, W
_GR_D1Pos
    MOVWF   GAME_Temp                ; delta1 stored temporarily

    ; delta2 = |RR_P2Sec - RR_JudgeTime|
    MOVF    RR_JudgeTime, W
    SUBWF   RR_P2Sec, W
    BTFSC   STATUS, C
    GOTO    _GR_D2Pos
    MOVF    RR_P2Sec, W
    SUBWF   RR_JudgeTime, W
_GR_D2Pos
    ; W = delta2, GAME_Temp = delta1
    SUBWF   GAME_Temp, W             ; W = delta1 - delta2
    BTFSC   STATUS, Z
    GOTO    _GR_Tie
    BTFSC   STATUS, C
    GOTO    _GR_P2Wins               ; delta1 >= delta2 (and not equal) -> P2 closer
    MOVLW   0x01
    MOVWF   RR_Winner                ; P1 closer
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

;--------------------------------------------------------------
; GAME_ReturnToIdle : Partner 4 calls this after consuming
; RR_Ready/RR_Winner/etc, once it's safe to start a new round.
;--------------------------------------------------------------
GAME_ReturnToIdle
    CLRF    RR_Ready
    MOVLW   STATE_IDLE
    MOVWF   GAME_State
    CLRF    GAME_Temp
    RETURN
