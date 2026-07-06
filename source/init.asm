
    LIST P=16F877A
    #INCLUDE <P16F877A.INC>

    __CONFIG _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF

    ORG     0x00
    GOTO    START

;------------------------------------------------------------------------------
; INIT
; Full hardware bring-up: port directions, analog/digital mode, and safe
; initial output states for every subsystem. Call this once, first, before
; anything else runs.
;------------------------------------------------------------------------------
INIT
    BANKSEL TRISA
    MOVLW   0x00
    MOVWF   TRISA        ; PORTA all outputs (LCD: RS, EN, D4-D7)

    MOVLW   B'00110001'  ; RB0(master btn)=1 in, RB4(P1 btn)=1 in,
    MOVWF   TRISB        ; RB5(P2 btn)=1 in, RB1/RB2(LEDs)=0 out, rest=0

    MOVLW   0x00
    MOVWF   TRISC        ; PORTC all outputs (digit-select, 8 lines)

    MOVLW   0x00
    MOVWF   TRISD        ; PORTD all outputs (segment bus, 8 lines)

    MOVLW   0x00
    MOVWF   TRISE        ; PORTE all outputs (free/margin, kept as output)

    MOVLW   0x06         ; force RA0-RA5 to DIGITAL mode -- see header note.
    MOVWF   ADCON1        ; without this, PORTA output writes silently fail.

    BANKSEL PORTA
    CLRF    PORTA         ; LCD control/data lines idle low

    MOVLW   B'00000000'
    MOVWF   PORTB         ; both LEDs off; button inputs unaffected by this write

    MOVLW   0xFF
    MOVWF   PORTC         ; all digit-select lines HIGH = all digits OFF
                          ; (active-low enable, per the verified CC display wiring)

    CLRF    PORTD         ; all segment lines off

    CLRF    PORTE         ; free pins, defined low

    ; NOTE: RB0 has no internal pull-up option -- external 10k required,
    ; already present in the schematic. RB4/RB5's internal weak pull-ups
    ; are intentionally NOT enabled here (OPTION_REG left at its reset
    ; default). Enabling them is Partner 2/3's responsibility as part of
    ; the button driver, per the Collaboration Points in the task plan --
    ; INIT only sets up directions and safe idle states, not per-feature
    ; button behavior.

    RETURN
    
START
    CALL    INIT
HOLD
    GOTO    HOLD

    END