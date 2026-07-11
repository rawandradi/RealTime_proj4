;==============================================================
;
; Owns the PIC16F877A's single interrupt vector. Two jobs:
;   1. TMR0 overflow (~every 1ms) -> auto-refresh both 7-seg
;      displays by calling SEG_Refresh. No more manual polling
;      loop needed once this is running.
;   2. RB0/INT (master button) and RB port-change (P1/P2
;      buttons) -> raise a RAW edge flag. Partner 2 does NOT
;      debounce or decide what a press means - that is Partner
;      3's job in buttons.asm, built on top of these flags.
; Depends on : hardware_pins.inc, driver_macros.inc, ram_map.inc,
;              sevenseg_driver.asm (calls SEG_Refresh)
;==============================================================

TMR_Init
    BANKSEL OPTION_REG
    MOVLW   B'10000001'   
    MOVWF   OPTION_REG   
                        

    BANKSEL INTCON
    BCF     INTCON, T0IF
    BCF     INTCON, INTF
    BCF     INTCON, RBIF
    CLRF    BTN_FLAGS
    CLRF    GAME_Tick1ms
    MOVF    PORTB, W      
                          ; mismatch condition before enabling RBIE
    MOVLW   B'10111000'   
    MOVWF   INTCON
    RETURN

ISR_Dispatch
    BTFSS   INTCON, T0IF
    GOTO    _ISR_CheckMaster
    PAGESEL SEG_Refresh
    CALL    SEG_Refresh
    PAGESEL _ISR_AfterRefresh
_ISR_AfterRefresh
    MOVF    GAME_Tick1ms, W
    XORLW   0xFF
    BTFSC   STATUS, Z
    GOTO    _ISR_TickSaturated
    INCF    GAME_Tick1ms, F
_ISR_TickSaturated
    BCF     INTCON, T0IF

_ISR_CheckMaster
    BTFSS   INTCON, INTF
    GOTO    _ISR_CheckPlayers
    BSF     BTN_FLAGS, 0   ; raw master-button edge
    BCF     INTCON, INTF

_ISR_CheckPlayers
    BTFSS   INTCON, RBIF
    GOTO    _ISR_Done
    MOVF    PORTB, W       ; read first to clear the port-change mismatch
    BCF     INTCON, RBIF
    BTFSS   PORTB, BTN_P1  ; active-low: 0 = pressed
    BSF     BTN_FLAGS, 1
    BTFSS   PORTB, BTN_P2
    BSF     BTN_FLAGS, 2

_ISR_Done
    MOVF    PCLATH_TEMP, W
    MOVWF   PCLATH
    SWAPF   STATUS_TEMP, W
    MOVWF   STATUS
    SWAPF   W_TEMP, F
    SWAPF   W_TEMP, W
    RETFIE
