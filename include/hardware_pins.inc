
; ---- LCD, 4-bit mode, all 6 lines on PORTA -------------------
; (init.asm: TRISA = 0x00, all output)
LCD_RS      EQU  5     ; RA5 - register select
LCD_EN      EQU  4     ; RA4 - enable strobe
LCD_D4      EQU  0     ; RA0 - data nibble bit0
LCD_D5      EQU  1     ; RA1 - data nibble bit1
LCD_D6      EQU  2     ; RA2 - data nibble bit2
LCD_D7      EQU  3     ; RA3 - data nibble bit3

; ---- 7-segment digit-select, PORTC, active-LOW ---------------
; (init.asm sets PORTC=0xFF at reset -> confirms active-low enable)
; *** CONFIRM bit->digit order with Rawand before Stage 2 ***
SEG_SEL_A0  EQU  0     ; Display A (Player 1), digit 1 (tentative)
SEG_SEL_A1  EQU  1     ; Display A, digit 2
SEG_SEL_A2  EQU  2     ; Display A, digit 3
SEG_SEL_A3  EQU  3     ; Display A, digit 4
SEG_SEL_B0  EQU  4     ; Display B (Player 2), digit 1
SEG_SEL_B1  EQU  5     ; Display B, digit 2
SEG_SEL_B2  EQU  6     ; Display B, digit 3
SEG_SEL_B3  EQU  7     ; Display B, digit 4

; ---- 7-segment shared segment bus, PORTD ---------------------
SEG_A       EQU  0
SEG_B       EQU  1
SEG_C       EQU  2
SEG_D       EQU  3
SEG_E       EQU  4
SEG_F       EQU  5
SEG_G       EQU  6
SEG_DP      EQU  7

; ---- PORTB: buttons + LEDs ------------------------------------
; (init.asm: TRISB = B'00110001')
BTN_MASTER  EQU  0     ; RB0/INT  - external interrupt capable
LED_1       EQU  1     ; RB1 - blue LED  (D1, per schematic)
LED_2       EQU  2     ; RB2 - green LED (D2, per schematic)
BTN_P1      EQU  4     ; RB4 - interrupt-on-change
BTN_P2      EQU  5     ; RB5 - interrupt-on-change
