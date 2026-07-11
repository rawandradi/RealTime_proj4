
; RAM variables are defined in include/ram_map.inc.

_LCD_Out4
    MOVWF   LCD_Nibble      ; nibble already aligned to RA0-RA3, no shift needed
    MOVF    PORTA, W
    ANDLW   B'11110000'     ; preserve upper PORTA latch bits; replace RA0-RA3
    IORWF   LCD_Nibble, W
    MOVWF   PORTA

    BSF     PORTE, LCD_EN
    DELAY_US D'1'
    BCF     PORTE, LCD_EN
    DELAY_US D'1'
    RETURN

LCD_Cmd
    MOVWF   LCD_Temp
    BCF     PORTE, LCD_RS
    SWAPF   LCD_Temp, W
    ANDLW   0x0F
    CALL    _LCD_Out4
    MOVF    LCD_Temp, W
    ANDLW   0x0F
    CALL    _LCD_Out4
    DELAY_US D'60'
    RETURN

LCD_Char
    MOVWF   LCD_Temp
    BSF     PORTE, LCD_RS
    SWAPF   LCD_Temp, W
    ANDLW   0x0F
    CALL    _LCD_Out4
    MOVF    LCD_Temp, W
    ANDLW   0x0F
    CALL    _LCD_Out4
    DELAY_US D'60'
    RETURN

LCD_Clear
    MOVLW   0x01
    CALL    LCD_Cmd
    DELAY_MS D'2'
    RETURN

LCD_SetCursor
    MOVLW   0x80
    MOVWF   LCD_Temp
    MOVF    PARAM_ROW, F
    BTFSC   STATUS, Z
    GOTO    _LCD_SC_Row0
    MOVLW   0xC0
    MOVWF   LCD_Temp
_LCD_SC_Row0
    MOVF    PARAM_COL, W
    ADDWF   LCD_Temp, F
    MOVF    LCD_Temp, W
    CALL    LCD_Cmd
    RETURN

LCD_Init
    DELAY_MS D'20'

    BCF     PORTE, LCD_RS
    MOVLW   0x03
    CALL    _LCD_Out4
    DELAY_MS D'5'
    MOVLW   0x03
    CALL    _LCD_Out4
    DELAY_US D'150'
    MOVLW   0x03
    CALL    _LCD_Out4
    DELAY_US D'150'
    MOVLW   0x02
    CALL    _LCD_Out4
    DELAY_US D'50'

    MOVLW   0x28
    CALL    LCD_Cmd
    MOVLW   0x08
    CALL    LCD_Cmd
    CALL    LCD_Clear
    MOVLW   0x06
    CALL    LCD_Cmd
    MOVLW   0x0C
    CALL    LCD_Cmd
    RETURN
