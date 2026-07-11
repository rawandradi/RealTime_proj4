;==============================================================
; GAME_DEFS.INC
; Public constants and the round-result structure consumed by
; Partner 4's score_manager.asm. No other module should read
; or write these fields directly except through game_fsm.asm's
; documented entry points.
;==============================================================

; ---- Game states ----
STATE_IDLE        EQU  0x00
STATE_READY        EQU  0x01
STATE_COUNTDOWN    EQU  0x02
STATE_RUNNING      EQU  0x03
STATE_STOPPED      EQU  0x04
STATE_WINNER       EQU  0x05

; ---- Round timing limits ----
COUNTDOWN_TICKS    EQU  D'1000'   ; 1000 x 1ms = 1 second LED-on countdown
ROUND_TIMEOUT_SEC  EQU  D'60'     ; auto-stop at 60.00 (judge max is 60)

; Round-result RAM variables are defined in include/ram_map.inc.
; Winner encoding: 0 = no winner (timeout or tie -> replay), 1 = P1, 2 = P2
