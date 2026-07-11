        LIST      P=16F877A
        #INCLUDE <P16F877A.INC>

        __CONFIG  _XT_OSC & _WDT_OFF & _PWRTE_ON & _BODEN_ON & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF & _DEBUG_OFF

        #INCLUDE "../include/hardware_pins.inc"
        #INCLUDE "../include/ram_map.inc"
        #INCLUDE "../include/driver_macros.inc"
        #INCLUDE "game_defs.inc"

        ORG       0x0000
        GOTO      START

        ORG       0x0004
        MOVWF     W_TEMP
        SWAPF     STATUS, W
        MOVWF     STATUS_TEMP
        CLRF      STATUS
        MOVF      PCLATH, W
        MOVWF     PCLATH_TEMP
        PAGESEL   ISR_Dispatch
        GOTO      ISR_Dispatch

        ORG       0x0010
START
        PAGESEL   INIT
        CALL      INIT
        PAGESEL   LCD_Init
        CALL      LCD_Init
        PAGESEL   SEG_Init
        CALL      SEG_Init
        PAGESEL   BTN_Init
        CALL      BTN_Init
        PAGESEL   RNG_Init
        CALL      RNG_Init
        PAGESEL   GAME_Init
        CALL      GAME_Init
        PAGESEL   SCORE_Init
        CALL      SCORE_Init
        PAGESEL   TMR_Init
        CALL      TMR_Init

MAIN_LOOP
        PAGESEL   GAME_Poll
        CALL      GAME_Poll
        PAGESEL   SCORE_Poll
        CALL      SCORE_Poll
        PAGESEL   MAIN_LOOP
        GOTO      MAIN_LOOP

        #INCLUDE "init.asm"
        #INCLUDE "lcd_driver.asm"
        #INCLUDE "seven_seg_driver.asm"
        #INCLUDE "buttons.asm"
        #INCLUDE "rng.asm"
        #INCLUDE "game_fsm.asm"
        #INCLUDE "score_manager.asm"
        #INCLUDE "timer_isr.asm"

        END
