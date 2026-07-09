;==============================================================
; DRIVER_MACROS.INC
;
; Shared macros used across driver modules. Add new shared
; macros here only - never duplicate a macro definition inside
; an individual .asm file (see coding standards, Section 3).
;==============================================================

_delay_cnt      EQU  0x40
_delay_ms_cnt   EQU  0x41

; DELAY_US n : busy-wait ~n microseconds (n = 1..255)
DELAY_US MACRO us
    MOVLW   us
    MOVWF   _delay_cnt
    DECFSZ  _delay_cnt, F
    GOTO    $-1
    ENDM

; DELAY_MS n : busy-wait ~n milliseconds (n = 1..255)
DELAY_MS MACRO ms
    LOCAL   _dms_outer
    MOVLW   ms
    MOVWF   _delay_ms_cnt
_dms_outer
    DELAY_US D'250'
    DELAY_US D'250'
    DELAY_US D'250'
    DELAY_US D'250'
    DECFSZ  _delay_ms_cnt, F
    GOTO    _dms_outer
    ENDM
