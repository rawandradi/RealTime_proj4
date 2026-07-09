;==============================================================
; SEVENSEG_DRIVER.ASM
; Drives two 4-digit 7-segment displays (Player 1 / Player 2)
; sharing one segment bus (PORTD) via time-multiplexing across
; all 8 digit-select lines (PORTC).
; Registers used : 0x46-0x52 (Partner 2 RAM range: 0x40-0x5F)
; Depends on     : hardware_pins.inc, driver_macros.inc
;==============================================================

P1_Digit0    EQU  0x46   ; Player 1 tens-of-seconds    (segment pattern, ready to output)
P1_Digit1    EQU  0x47   ; Player 1 units-of-seconds   (dp forced on)
P1_Digit2    EQU  0x48   ; Player 1 tens-of-hundredths
P1_Digit3    EQU  0x49   ; Player 1 units-of-hundredths

P2_Digit0    EQU  0x4A   ; Player 2 tens-of-seconds
P2_Digit1    EQU  0x4B   ; Player 2 units-of-seconds
P2_Digit2    EQU  0x4C   ; Player 2 tens-of-hundredths
P2_Digit3    EQU  0x4D   ; Player 2 units-of-hundredths

SEG_Index    EQU  0x4E   ; which of the 8 digits is lit right now (0-7)
SEG_Temp     EQU  0x4F   ; scratch / units digit result from _SEG_BinToBCD
SEG_Tens     EQU  0x52   ; tens digit result from _SEG_BinToBCD
PARAM_SEC    EQU  0x50   ; input: 0-99, set by caller before SEG_SetPlayerX
PARAM_HUN    EQU  0x51   ; input: 0-99, set by caller before SEG_SetPlayerX

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
    ADDWF   PCL, F
    RETLW   0x3F    ; 0
    RETLW   0x06    ; 1
    RETLW   0x5B    ; 2
    RETLW   0x4F    ; 3
    RETLW   0x66    ; 4
    RETLW   0x6D    ; 5
    RETLW   0x7D    ; 6
    RETLW   0x07    ; 7
    RETLW   0x7F    ; 8
    RETLW   0x6F    ; 9


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
    ADDWF   PCL, F
    GOTO    _SEG_Show0
    GOTO    _SEG_Show1
    GOTO    _SEG_Show2
    GOTO    _SEG_Show3
    GOTO    _SEG_Show4
    GOTO    _SEG_Show5
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
