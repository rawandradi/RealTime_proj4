
;==============================================================
; BUTTONS.ASM
; Owning partner: Partner 3
;
; Converts Partner 2's raw, non-debounced edge flags (BTN_FLAGS,
; set in timer_isr.asm's ISR) into clean, single-shot logical
; press events. Partner 2 only tells us "the pin was low when
; the interrupt fired" - it does not guarantee that's a real,
; settled press. This file owns the settling/debounce decision.
;
; Depends on : hardware_pins.inc, timer_isr.asm (BTN_FLAGS,
;              GAME_Tick1ms)
;==============================================================

    CBLOCK 0x60
    BTN_M_Count       ; master button debounce counter
    BTN_M_Held         ; 1 = currently considered pressed & settled
    BTN_M_Event         ; 1 = fresh logical press this poll (consumed by game_fsm)

    BTN_P1_Count
    BTN_P1_Held
    BTN_P1_Event

    BTN_P2_Count
    BTN_P2_Held
    BTN_P2_Event
    ENDC

DEBOUNCE_MS   EQU  D'20'     ; ms of continuous "pressed" reads before we trust it

;--------------------------------------------------------------
; BTN_Init : clear all debounce state. Call once from game_fsm's
; startup, after INIT and before the main loop begins.
;--------------------------------------------------------------
BTN_Init
    CLRF    BTN_M_Count
    CLRF    BTN_M_Held
    CLRF    BTN_M_Event
    CLRF    BTN_P1_Count
    CLRF    BTN_P1_Held
    CLRF    BTN_P1_Event
    CLRF    BTN_P2_Count
    CLRF    BTN_P2_Held
    CLRF    BTN_P2_Event
    RETURN

;--------------------------------------------------------------
; BTN_Poll : call once per 1ms tick (game_fsm checks GAME_Tick1ms
; and calls this, then clears the tick flag). Reads the live pin
; state directly - the raw ISR flags are only used as a wake hint,
; not as the source of truth, since interrupt-on-change can fire
; on release too.
; Sets BTN_x_Event = 1 exactly once per real press (not per poll).
; Caller must read and clear each Event flag after acting on it.
;--------------------------------------------------------------
BTN_Poll
    BANKSEL PORTB

    ; ---- Master button (RB0, active-low) ----
    BTFSS   PORTB, BTN_MASTER
    GOTO    _BTN_M_Pressed
    CLRF    BTN_M_Count
    CLRF    BTN_M_Held
    GOTO    _BTN_P1_Check
_BTN_M_Pressed
    MOVF    BTN_M_Held, F
    BTFSS   STATUS, Z
    GOTO    _BTN_P1_Check       ; already latched pressed, nothing new to do
    INCF    BTN_M_Count, F
    MOVLW   DEBOUNCE_MS
    SUBWF   BTN_M_Count, W
    BTFSS   STATUS, C
    GOTO    _BTN_P1_Check         ; not settled yet
    MOVLW   0x01
    MOVWF   BTN_M_Held
    MOVWF   BTN_M_Event            ; fresh logical press

_BTN_P1_Check
    BTFSS   PORTB, BTN_P1
    GOTO    _BTN_P1_Pressed
    CLRF    BTN_P1_Count
    CLRF    BTN_P1_Held
    GOTO    _BTN_P2_Check
_BTN_P1_Pressed
    MOVF    BTN_P1_Held, F
    BTFSS   STATUS, Z
    GOTO    _BTN_P2_Check
    INCF    BTN_P1_Count, F
    MOVLW   DEBOUNCE_MS
    SUBWF   BTN_P1_Count, W
    BTFSS   STATUS, C
    GOTO    _BTN_P2_Check
    MOVLW   0x01
    MOVWF   BTN_P1_Held
    MOVWF   BTN_P1_Event

_BTN_P2_Check
    BTFSS   PORTB, BTN_P2
    GOTO    _BTN_P2_Pressed
    CLRF    BTN_P2_Count
    CLRF    BTN_P2_Held
    RETURN
_BTN_P2_Pressed
    MOVF    BTN_P2_Held, F
    BTFSS   STATUS, Z
    RETURN
    INCF    BTN_P2_Count, F
    MOVLW   DEBOUNCE_MS
    SUBWF   BTN_P2_Count, W
    BTFSS   STATUS, C
    RETURN
    MOVLW   0x01
    MOVWF   BTN_P2_Held
    MOVWF   BTN_P2_Event
    RETURN