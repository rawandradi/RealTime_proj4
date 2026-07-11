; Authoritative PIC16F877A RAM map. Include once from future main.asm.
; Partner 3 game result structure
RR_JudgeTime EQU 0x20
RR_P1Sec EQU 0x21
RR_P1Hun EQU 0x22
RR_P2Sec EQU 0x23
RR_P2Hun EQU 0x24
RR_Winner EQU 0x25
RR_Ready EQU 0x26
; Partner 3 game FSM
GAME_State EQU 0x27
GAME_RunSec EQU 0x28
GAME_RunHun EQU 0x29
GAME_TickAccum EQU 0x2A
GAME_CountdownCnt EQU 0x2B
GAME_TimeoutSec EQU 0x2C
GAME_Temp EQU 0x2D
GAME_Reserved1 EQU 0x2E
GAME_Reserved2 EQU 0x2F
; 0x30-0x3F reserved for Partner 4 score_manager/main variables.
; Score manager allocations:
SCORE_P1 EQU 0x30
SCORE_P2 EQU 0x31
SCORE_GameOver EQU 0x32
; Partner 2 delay/LCD/display/interrupt variables
_delay_cnt EQU 0x40
_delay_ms_cnt EQU 0x41
LCD_Nibble EQU 0x42
PARAM_ROW EQU 0x43
PARAM_COL EQU 0x44
LCD_Temp EQU 0x45
P1_Digit0 EQU 0x46
P1_Digit1 EQU 0x47
P1_Digit2 EQU 0x48
P1_Digit3 EQU 0x49
P2_Digit0 EQU 0x4A
P2_Digit1 EQU 0x4B
P2_Digit2 EQU 0x4C
P2_Digit3 EQU 0x4D
SEG_Index EQU 0x4E
SEG_Temp EQU 0x4F
PARAM_SEC EQU 0x50
PARAM_HUN EQU 0x51
SEG_Tens EQU 0x52
BTN_FLAGS EQU 0x53
GAME_Tick1ms EQU 0x54
; Partner 3 buttons
BTN_M_Count EQU 0x60
BTN_M_Held EQU 0x61
BTN_M_Event EQU 0x62
BTN_P1_Count EQU 0x63
BTN_P1_Held EQU 0x64
BTN_P1_Event EQU 0x65
BTN_P2_Count EQU 0x66
BTN_P2_Held EQU 0x67
BTN_P2_Event EQU 0x68
; Partner 3 RNG
RNG_Seed EQU 0x69
RNG_Result EQU 0x6A
; 0x6B-0x6F remain free.
; ISR context in common RAM
W_TEMP EQU 0x70
STATUS_TEMP EQU 0x71
PCLATH_TEMP EQU 0x72
