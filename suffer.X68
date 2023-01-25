*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

;Game boot dialogue start
        LEA within_WAV, A1 *Load first line into A1
        MOVE.B #0,D1
        MOVE.B #71, D0
        TRAP #15
        
        MOVE    #0,D1 *Play line 1
        MOVE    #72,D0
        TRAP    #15
        
        MOVE.L #$00FFFFFF, D1 *Set text colour
        MOVE.L #$06090000,D2 *Set font, size, etc
        MOVE.B #21, D0
        TRAP #15
        
        LEA fear,A1
        MOVE.W #60, D1
        MOVE.W #100, D2
        MOVE.B #95, D0
        TRAP #15
        
        
        move.l   #450,D1     ; delay in 1/100th of seconds
        moveq    #23,D0
        trap     #15
        
        LEA eldritch_WAV, A1 *Load line 2 into A1
        MOVE.B #1,D1
        MOVE.B #71, D0
        TRAP #15
        
        MOVE.B    #1,D1 *Play line 2
        MOVE.B    #72,D0
        TRAP    #15

        LEA eldritch,A1
        MOVE.W #60, D1
        MOVE.W #120, D2
        MOVE.B #95, D0
        TRAP #15
        
        move.l   #400,D1
        moveq    #23,D0
        trap     #15
        
        LEA reckon_WAV, A1 *Load line 3 into A1
        MOVE.B #1,D1
        MOVE.B #71, D0
        TRAP #15
        
        MOVE.B    #1,D1 *Play line 3
        MOVE.B    #72,D0
        TRAP    #15
        
        LEA how,A1
        MOVE.W #60, D1
        MOVE.W #140, D2
        MOVE.B #95, D0
        TRAP #15
        
        move.l   #400,D1
        moveq    #23,D0
        trap     #15
        
        LEA find_WAV, A1 *Load line 4 into A1
        MOVE.B #2,D1
        MOVE.B #71, D0
        TRAP #15
        
        MOVE.B    #2,D1 *Play line 4
        MOVE.B    #72,D0
        TRAP    #15
        
        MOVE.L #$00080888, D1
        MOVE.L #$06090000,D2
        MOVE.B #21, D0
        TRAP #15
        
        LEA let,A1
        MOVE.W #60, D1
        MOVE.W #250, D2
        MOVE.B #95, D0
        TRAP #15
        
        move.l   #200,D1
        moveq    #23,D0
        trap     #15
        
        MOVE.W #$FF00, D1
        MOVE.B #11, D0
        TRAP #15
;end of game boot dialogue
        
        

    

    SIMHALT             ; halt simulator

* Put variables and constants here
fear dc.b 'We fear not the darkness itself, but what lies within.',0
eldritch dc.b 'Eldritch horrors beyond human comprehension.',0
how dc.b 'How long do you reckon you can outrun them?',0
let dc.b 'Let us find out......',0
menu_WAV dc.b 'menu.wav', 0
within_WAV dc.b 'within.wav', 0
eldritch_WAV dc.b 'eldritch.wav',0
reckon_WAV dc.b 'reckon.wav',0
find_WAV dc.b 'find.wav',0

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
