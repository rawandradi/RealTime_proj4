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
; Depends on : hardware_pins.inc, driver_macros.inc,
;              sevenseg_driver.asm (calls SEG_Refresh)
;==============================================================

BTN_FLAGS   EQU  0x53
W_TEMP      EQU  0x70   
STATUS_TEMP EQU  0x71  
GAME_Tick1ms   EQU  0x54     ; set to 1 every T0IF, cleared by game_fsm each pass


TMR_Init
    BANKSEL OPTION_REG
    MOVLW   B'10000001'   
    MOVWF   OPTION_REG   
                        

    BANKSEL INTCON
    BCF     INTCON, T0IF
    BCF     INTCON, INTF
    BCF     INTCON, RBIF
    CLRF    BTN_FLAGS
    MOVF    PORTB, W      
                          ; mismatch condition before enabling RBIE
    MOVLW   B'10111000'   
    MOVWF   INTCON
    RETURN

ISR
    MOVWF   W_TEMP
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP
    BCF     STATUS, RP0   ; force bank 0 for everything below -
    BCF     STATUS, RP1   ; original bank is restored at the end

    BTFSS   INTCON, T0IF
    GOTO    _ISR_CheckMaster
    CALL    SEG_Refresh
    BSF     GAME_Tick1ms, 0
    BCF     INTCON, T0IF

_ISR_CheckMaster
    BTFSS   INTCON, INTF
    GOTO    _ISR_CheckPlayers
    BSF     BTN_FLAGS, 0   ; raw master-button edge
    BCF     INTCON, INTF

_ISR_CheckPlayers
    BTFSS   INTCON, RBIF
    GOTO    _ISR_Done
    BTFSS   PORTB, BTN_P1  ; active-low: 0 = pressed
    BSF     BTN_FLAGS, 1
    BTFSS   PORTB, BTN_P2
    BSF     BTN_FLAGS, 2
    MOVF    PORTB, W       ; required read: clears the mismatch
    BCF     INTCON, RBIF   ; condition before re-enabling

_ISR_Done
    SWAPF   STATUS_TEMP, W
    MOVWF   STATUS
    SWAPF   W_TEMP, F
    SWAPF   W_TEMP, W
    RETFIE