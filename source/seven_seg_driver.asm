;==============================================================
; SEVENSEG_DRIVER.ASM
; Drives two 4-digit 7-segment displays (Player 1 / Player 2)
; sharing one segment bus (PORTD) via time-multiplexing across
; all 8 digit-select lines (PORTC).
; RAM variables  : defined in include/ram_map.inc
; Depends on     : hardware_pins.inc, driver_macros.inc
;==============================================================

; SEG_Init : clears digit buffers, deselects all digits
SEG_Init
    CLRF    P1_Digit0
    CLRF    P1_Digit1
    CLRF    P1_Digit2
    CLRF    P1_Digit3
    CLRF    P2_Digit0
    CLRF    P2_Digit1
    CLRF    P2_Digit2
    CLRF    P2_Digit3
    CLRF    SEG_Index
    MOVLW   0xFF
    MOVWF   PORTC        ; all digit-selects OFF (active-low)
    RETURN
_SEG_BinToBCD
    MOVWF   SEG_Temp
    CLRF    SEG_Tens
    BSF     STATUS, C
    MOVLW   D'10'
_SEG_BCD_Loop
    SUBWF   SEG_Temp, F
    INCF    SEG_Tens, F
    BTFSC   STATUS, C
    GOTO    _SEG_BCD_Loop
    ADDWF   SEG_Temp, F
    DECF    SEG_Tens, F
    RETURN

_SEG_DigitToPattern
    MOVWF   SEG_Tens
    MOVF    SEG_Tens, W
    XORLW   D'0'
    BTFSC   STATUS, Z
    GOTO    _SEG_Pattern0
    MOVF    SEG_Tens, W
    XORLW   D'1'
    BTFSC   STATUS, Z
    GOTO    _SEG_Pattern1
    MOVF    SEG_Tens, W
    XORLW   D'2'
    BTFSC   STATUS, Z
    GOTO    _SEG_Pattern2
    MOVF    SEG_Tens, W
    XORLW   D'3'
    BTFSC   STATUS, Z
    GOTO    _SEG_Pattern3
    MOVF    SEG_Tens, W
    XORLW   D'4'
    BTFSC   STATUS, Z
    GOTO    _SEG_Pattern4
    MOVF    SEG_Tens, W
    XORLW   D'5'
    BTFSC   STATUS, Z
    GOTO    _SEG_Pattern5
    MOVF    SEG_Tens, W
    XORLW   D'6'
    BTFSC   STATUS, Z
    GOTO    _SEG_Pattern6
    MOVF    SEG_Tens, W
    XORLW   D'7'
    BTFSC   STATUS, Z
    GOTO    _SEG_Pattern7
    MOVF    SEG_Tens, W
    XORLW   D'8'
    BTFSC   STATUS, Z
    GOTO    _SEG_Pattern8
    GOTO    _SEG_Pattern9

_SEG_Pattern0
    RETLW   0x3F
_SEG_Pattern1
    RETLW   0x06
_SEG_Pattern2
    RETLW   0x5B
_SEG_Pattern3
    RETLW   0x4F
_SEG_Pattern4
    RETLW   0x66
_SEG_Pattern5
    RETLW   0x6D
_SEG_Pattern6
    RETLW   0x7D
_SEG_Pattern7
    RETLW   0x07
_SEG_Pattern8
    RETLW   0x7F
_SEG_Pattern9
    RETLW   0x6F


;----------------------------------------------------------------
SEG_SetPlayer1
    MOVF    PARAM_SEC, W
    CALL    _SEG_BinToBCD
    MOVF    SEG_Tens, W
    CALL    _SEG_DigitToPattern
    MOVWF   P1_Digit0
    MOVF    SEG_Temp, W
    CALL    _SEG_DigitToPattern
    IORLW   B'10000000'      ; force decimal point on (SS.HH boundary)
    MOVWF   P1_Digit1

    MOVF    PARAM_HUN, W
    CALL    _SEG_BinToBCD
    MOVF    SEG_Tens, W
    CALL    _SEG_DigitToPattern
    MOVWF   P1_Digit2
    MOVF    SEG_Temp, W
    CALL    _SEG_DigitToPattern
    MOVWF   P1_Digit3
    RETURN

SEG_SetPlayer2
    MOVF    PARAM_SEC, W
    CALL    _SEG_BinToBCD
    MOVF    SEG_Tens, W
    CALL    _SEG_DigitToPattern
    MOVWF   P2_Digit0
    MOVF    SEG_Temp, W
    CALL    _SEG_DigitToPattern
    IORLW   B'10000000'      ; force decimal point on (SS.HH boundary)
    MOVWF   P2_Digit1

    MOVF    PARAM_HUN, W
    CALL    _SEG_BinToBCD
    MOVF    SEG_Tens, W
    CALL    _SEG_DigitToPattern
    MOVWF   P2_Digit2
    MOVF    SEG_Temp, W
    CALL    _SEG_DigitToPattern
    MOVWF   P2_Digit3
    RETURN

SEG_Refresh
    MOVLW   0xFF
    MOVWF   PORTC          ; blank all digits first 

    MOVF    SEG_Index, W
    XORLW   D'0'
    BTFSC   STATUS, Z
    GOTO    _SEG_Show0
    MOVF    SEG_Index, W
    XORLW   D'1'
    BTFSC   STATUS, Z
    GOTO    _SEG_Show1
    MOVF    SEG_Index, W
    XORLW   D'2'
    BTFSC   STATUS, Z
    GOTO    _SEG_Show2
    MOVF    SEG_Index, W
    XORLW   D'3'
    BTFSC   STATUS, Z
    GOTO    _SEG_Show3
    MOVF    SEG_Index, W
    XORLW   D'4'
    BTFSC   STATUS, Z
    GOTO    _SEG_Show4
    MOVF    SEG_Index, W
    XORLW   D'5'
    BTFSC   STATUS, Z
    GOTO    _SEG_Show5
    MOVF    SEG_Index, W
    XORLW   D'6'
    BTFSC   STATUS, Z
    GOTO    _SEG_Show6
    GOTO    _SEG_Show7

_SEG_Show0
    MOVF    P1_Digit0, W
    MOVWF   PORTD
    BCF     PORTC, SEG_SEL_A0
    GOTO    _SEG_Next
_SEG_Show1
    MOVF    P1_Digit1, W
    MOVWF   PORTD
    BCF     PORTC, SEG_SEL_A1
    GOTO    _SEG_Next
_SEG_Show2
    MOVF    P1_Digit2, W
    MOVWF   PORTD
    BCF     PORTC, SEG_SEL_A2
    GOTO    _SEG_Next
_SEG_Show3
    MOVF    P1_Digit3, W
    MOVWF   PORTD
    BCF     PORTC, SEG_SEL_A3
    GOTO    _SEG_Next
_SEG_Show4
    MOVF    P2_Digit0, W
    MOVWF   PORTD
    BCF     PORTC, SEG_SEL_B0
    GOTO    _SEG_Next
_SEG_Show5
    MOVF    P2_Digit1, W
    MOVWF   PORTD
    BCF     PORTC, SEG_SEL_B1
    GOTO    _SEG_Next
_SEG_Show6
    MOVF    P2_Digit2, W
    MOVWF   PORTD
    BCF     PORTC, SEG_SEL_B2
    GOTO    _SEG_Next
_SEG_Show7
    MOVF    P2_Digit3, W
    MOVWF   PORTD
    BCF     PORTC, SEG_SEL_B3

_SEG_Next
    INCF    SEG_Index, F
    MOVLW   D'8'
    SUBWF   SEG_Index, W
    BTFSC   STATUS, Z
    CLRF    SEG_Index
    RETURN
