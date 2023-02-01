*-----------------------------------------------------------
* Title      : Jump
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000

START:                  ; first instruction of program

PLAYER_YPOS EQU $100
UP_ARROW EQU $26
    ;MOVE.B #1,PLAYER_YPOS
    ;MOVE.B #5, D0
    ;TRAP #15

    ;IF.B D1 <EQ> #$20 THEN
    ;    ADD.B   #1,PLAYER_YPOS
    ;ENDI
    
    ;MOVE.B PLAYER_YPOS,D3
    WHILE $100 <NE> #$10 DO
        MOVE.B  #19,D0
        MOVE.L  #$26000000,D1
        TRAP    #15
    
        BTST.L  #24,D1
        IF <NE> THEN
            ADD.B   #1,PLAYER_YPOS
        ENDI
     ENDW

    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
