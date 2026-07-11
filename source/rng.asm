
;==============================================================
; RNG.ASM
; Owning partner: Partner 3
;
; 8-bit Galois LFSR pseudo-random generator, reseeded from the
; free-running TMR0 value at the moment the master button press
; is validated - this is gameplay randomness, not cryptographic,
; so a simple LFSR plus a live hardware timer as entropy is
; sufficient and standard for this kind of round-based game.
; RAM variables are defined in include/ram_map.inc.
;==============================================================

RNG_TAPS   EQU  0xB4   ; feedback polynomial for an 8-bit maximal LFSR

;--------------------------------------------------------------
; RNG_Init : call once at startup. Seed can't be zero for an
; LFSR (it would get stuck), so force a non-zero starting value.
;--------------------------------------------------------------
RNG_Init
    MOVLW   0xA5
    MOVWF   RNG_Seed
    RETURN

;--------------------------------------------------------------
; RNG_Reseed : call right when the master press is validated.
; Mixes in the live TMR0 value so back-to-back rounds don't
; repeat the same sequence.
;--------------------------------------------------------------
RNG_Reseed
    BANKSEL TMR0
    MOVF    TMR0, W
    XORWF   RNG_Seed, F
    BTFSS   STATUS, Z
    RETURN
    MOVLW   0xA5
    MOVWF   RNG_Seed
    RETURN

;--------------------------------------------------------------
; RNG_GetNext : advances the LFSR by one step, then folds the
; result into range 0-60 by repeated subtraction (61 possible
; values, max input 255, so this loop runs at most 4 times).
; Returns judge time (0-60) in W and in RNG_Result.
;--------------------------------------------------------------
RNG_GetNext
    BCF     STATUS, C
    RRF     RNG_Seed, W
    BTFSS   STATUS, C
    GOTO    _RNG_NoXor
    XORLW   RNG_TAPS
_RNG_NoXor
    MOVWF   RNG_Seed
    MOVWF   RNG_Result
_RNG_Range
    MOVLW   D'61'
    SUBWF   RNG_Result, W
    BTFSS   STATUS, C           ; C=0 -> result < 61, we're done
    GOTO    _RNG_Done
    MOVWF   RNG_Result
    GOTO    _RNG_Range
_RNG_Done
    MOVF    RNG_Result, W
    RETURN
