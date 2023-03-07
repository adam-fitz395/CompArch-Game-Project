*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program
* Trap CODES
TC_SCREEN   EQU         33          ; Screen size information trap code
TC_S_SIZE   EQU         00          ; Places 0 in D1.L to retrieve Screen width and height in D1.L
                                    ; First 16 bit Word is screen Width and Second 16 bits is screen Height
TC_KEYCODE  EQU         19          ; Check for pressed keys
TC_DBL_BUF  EQU         92          ; Double Buffer Screen Trap Code
TC_CURSR_P  EQU         11          ; Trap code cursor position
TC_EXIT     EQU         09          ; Exit Trapcode

* Key Inputs
UP_ARROW    EQU         $26         ;Up arrow ASCII keycode
ESCAPE      EQU         $1B         ; Escape ASCII Keycode
ENTER       EQU         $0D         ; Enter ASCII Keycode

* Player Setup
PLYR_W_INIT EQU         08          ; Players initial Width
PLYR_H_INIT EQU         08          ; Players initial Height

PLYR_DFLT_V EQU         00          ; Default Player Velocity
PLYR_JUMP_V EQU        -20          ; Player Jump Velocity
PLYR_DFLT_G EQU         01          ; Player Default Gravity

GND_TRUE    EQU         01          ; Player on Ground True
GND_FALSE   EQU         00          ; Player on Ground False

JMP_INDEX   EQU         01          ; Player Jump Sound Index  
OOPS_INDEX  EQU         02          ; Player Oops Sound Index
DEATH_INDEX EQU         10          ; Player death sound index

* Enemy Setup
ENMY_W_INIT EQU         08          ; Enemy initial Width
ENMY_H_INIT EQU         08          ; Enemy initial Height

*Get time at start of program
GET_START_TIME:
    MOVE.B #8, D0
    TRAP #15
    MOVE.L D1, START_TIME
    CLR D1
        
INITIALISE:
    ; Initialise Sounds
    BSR     JUMP_LOAD               ; Load Jump Sound into Memory
    BSR     OOPS_LOAD               ; Load Opps (Collision) Sound into Memory
    BSR     DEATH_LOAD

    ; Screen Size
    MOVE.B  #TC_SCREEN, D0          ; access screen information
    MOVE.L  #TC_S_SIZE, D1          ; placing 0 in D1 triggers loading screen size information
    TRAP    #15                     ; interpret D0 and D1 for screen size
    MOVE.W  D1,         SCREEN_H    ; place screen height in memory location
    SWAP    D1                      ; Swap top and bottom word to retrive screen size
    MOVE.W  D1,         SCREEN_W    ; place screen width in memory location

    ; Place the Player at the center of the screen
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.W  SCREEN_W,   D1          ; Place Screen width in D1
    DIVU    #02,        D1          ; divide by 2 for center on X Axis
    MOVE.L  D1,         PLAYER_X    ; Players X Position

    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.W  SCREEN_H,   D1          ; Place Screen width in D1
    DIVU    #02,        D1          ; divide by 2 for center on Y Axis
    MOVE.L  D1,         PLAYER_Y    ; Players Y Position

    ; Initialise Player HEALTH
    CLR.B   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.L  #100,        D1          ; Init Score
    MOVE.L  D1,         (PLAYER_HEALTH)

    ; Initialise Player Velocity
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.B  #PLYR_DFLT_V,D1         ; Init Player Velocity
    MOVE.L  D1,         PLYR_VELOCITY

    ; Initialise Player Gravity
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.L  #PLYR_DFLT_G,D1         ; Init Player Gravity
    MOVE.L  D1,         PLYR_GRAVITY

    ; Initialize Player on Ground
    MOVE.L  #GND_TRUE,  PLYR_ON_GND ; Init Player on Ground

    ; Initial Position for Enemy
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.W  SCREEN_W,   D1          ; Place Screen width in D1
    MOVE.L  D1,         ENEMY_X     ; Enemy X Position

    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.W  SCREEN_H,   D1          ; Place Screen width in D1
    DIVU    #02,        D1          ; divide by 2 for center on Y Axis
    MOVE.L  D1,         ENEMY_Y     ; Enemy Y Position

    ; Enable the screen back buffer(see easy 68k help)
	MOVE.B  #TC_DBL_BUF,D0          ; 92 Enables Double Buffer
    MOVE.B  #17,        D1          ; Combine Tasks
	TRAP	#15                     ; Trap (Perform action)

    ; Clear the screen (see easy 68k help)
    MOVE.B  #TC_CURSR_P,D0          ; Set Cursor Position
	MOVE.W  #$FF00,     D1          ; Fill Screen Clear
	TRAP	#15                     ; Trap (Perform action)

*-----------------------------------------------------------
* Subroutine    : Game
* Description   : Game including main GameLoop. GameLoop is like
* a while loop in that it runs forever until interupted
* (Input, Update, Draw). The Enemies Run at Player Jump to Avoid
*-----------------------------------------------------------
GAME:
GAMELOOP:
    ; Main Gameloop
    MOVEQ        #8,d0                * get time in 1/100 ths seconds
    TRAP        #15
    MOVE.L  D1,TIME_ELAPSED
    
    

    MOVE.l    D1,-(sp)            * push time on the stack
    BSR TIME
    BSR     INPUT                   ; Check Keyboard Input
    BSR     UPDATE                  ; Update positions and health
    BSR     IS_PLAYER_ON_GND        ; Check if player is on ground
    BSR     CHECK_COLLISIONS        ; Check for Collisions
    BSR     DRAW                    ; Draw the Scene
    MOVE.l    (sp)+,d7
wait:
    MOVEQ        #8,d0                * get time in 1/100 ths seconds
    TRAP        #15

    SUB.l        d7,D1                * subtract previous time from current time
    CMP.b        #2,D1                * compare with 2/100ths
    BMI.s        wait                * loop if time not up yet

    BRA        GAMELOOP                * loop forever

*-----------------------------------------------------------
* Subroutine    : Input
* Description   : Process Keyboard Input
*-----------------------------------------------------------
INPUT:
    ; Process Input
    CLR.L   D1                      ; Clear Data Register
    MOVE.B  #TC_KEYCODE,D0          ; Listen for Keys
    TRAP    #15                     ; Trap (Perform action)
    MOVE.B  D1,         D2          ; Move last key D1 to D2
    CMP.B   #00,        D2          ; Key is pressed
    BEQ     PROCESS_INPUT           ; Process Key
    TRAP    #15                     ; Trap for Last Key
    ; Check if key still pressed
    CMP.B   #$FF,       D1          ; Is it still pressed
    BEQ     PROCESS_INPUT           ; Process Last Key
    RTS                             ; Return to subroutine

*-----------------------------------------------------------
* Subroutine    : Process Input
* Description   : Branch based on keys pressed
*-----------------------------------------------------------
PROCESS_INPUT:
    MOVE.L  D2,         CURRENT_KEY ; Put Current Key in Memory
    CMP.L   #ESCAPE,    CURRENT_KEY ; Is Current Key Escape
    BEQ     EXIT                    ; Exit if Escape
    CMP.L   #UP_ARROW,  CURRENT_KEY ; Is Current Key Spacebar
    BEQ     JUMP                    ; Jump
    CMP.L   #ENTER, CURRENT_KEY     ; Is current key ENTER
    BEQ     START                   ; Return to START
    RTS                             ; Return to subroutine

*-----------------------------------------------------------
* Subroutine    : Update
* Description   : Main update loop update Player and Enemies
*-----------------------------------------------------------
UPDATE:

    
    ; Update the Players Positon based on Velocity and Gravity
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.L  PLYR_VELOCITY, D1       ; Fetch Player Velocity
    MOVE.L  PLYR_GRAVITY, D2        ; Fetch Player Gravity
    ADD.L   D2,         D1          ; Add Gravity to Velocity
    MOVE.L  D1,         PLYR_VELOCITY ; Update Player Velocity
    ADD.L   PLAYER_Y,   D1          ; Add Velocity to Player
    MOVE.L  D1,         PLAYER_Y    ; Update Players Y Position 

    ; Move the Enemy
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    CLR.L   D1                      ; Clear the contents of D0
    MOVE.L  ENEMY_X,    D1          ; Move the Enemy X Position to D0
    CMP.L   #00,        D1
    BLE     RESET_ENEMY_POSITION    ; Reset Enemy if off Screen
    BRA     MOVE_ENEMY              ; Move the Enemy
    
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    CLR.L   D1                      ; Clear the contents of D0
    MOVE.L  ENEMY_X,    D1          ; Move the Enemy X Position to D0
    CMP.L   #00,        D1
    BLE     RESET_ENEMY_POSITION    ; Reset Enemy if off Screen
    BRA     MOVE_ENEMY              ; Move the Enemy
    
    RTS                             ; Return to subroutine

*-----------------------------------------------------------
* Subroutine    : Move Enemy
* Description   : Move Enemy Right to Left
*-----------------------------------------------------------
MOVE_ENEMY:
    SUB.L   #5,        ENEMY_X     ; Move enemy by X Value
    RTS
    

*-----------------------------------------------------------
* Subroutine    : Reset Enemy
* Description   : Reset Enemy if to passes 0 to Right of Screen
*-----------------------------------------------------------
RESET_ENEMY_POSITION:
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.W  SCREEN_W,   D1          ; Place Screen width in D1
    MOVE.L  D1,         ENEMY_X     ; Enemy X Position
    RTS

*-----------------------------------------------------------
* Subroutine    : Draw
* Description   : Draw Screen
*-----------------------------------------------------------
DRAW: 
    ; Enable back buffer
    MOVE.B  #94,        D0
    TRAP    #15

    ; Clear the screen
    MOVE.B	#TC_CURSR_P,D0          ; Set Cursor Position
	MOVE.W	#$FF00,     D1          ; Clear contents
	TRAP    #15                     ; Trap (Perform action)

    BSR     DRAW_PLYR_DATA          ; Draw Draw Score, HUD, Player X and Y
    BSR     DRAW_PLAYER             ; Draw Player
    BSR     DRAW_ENEMY              ; Draw Enemy
    RTS                             ; Return to subroutine

*-----------------------------------------------------------
* Subroutine    : Draw Player Data
* Description   : Draw Player X, Y, Velocity, Gravity and OnGround
*-----------------------------------------------------------
DRAW_PLYR_DATA:
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)

    ; Player heatlh Message
    MOVE.B  #TC_CURSR_P,D0          ; Set Cursor Position
    MOVE.W  #$0201,     D1          ; Col 02, Row 01
    TRAP    #15                     ; Trap (Perform action)
    LEA     HEALTH_MSG,  A1          ; Score Message
    MOVE    #14,        D0          ; No Line feed
    TRAP    #15                     ; Trap (Perform action)

    ; Player heatlh Value
    MOVE.B  #03,        D0          ; Display number at D1.L
    MOVE.L  PLAYER_HEALTH,D1         ; Move Score to D1.L
    TRAP    #15                     ; Trap (Perform action)
    
    ; Time Message
    MOVE.B #TC_CURSR_P, D0
    MOVE.W #$0202, D1
    TRAP #15
    LEA TIME_MSG, A1
    MOVE #14, D0
    TRAP #15
    
    ; SHOW TIME
    MOVE.W TIME_IN_MIN, D1
    MOVE.B #3, D0
    TRAP #15
    
    LEA TIME_BREAK, A1
    MOVE.B #14,D0
    TRAP #15
    
    MOVE.W TIME_IN_SEC, D1
    MOVE.B #3,D0
    TRAP #15
    

    RTS

*-----------------------------------------------------------
* Subroutine    : Time
* Description   : Keeps Track of the current time
*-----------------------------------------------------------
TIME:    
    MOVE.L TIME_ELAPSED, D1
    SUB.L  START_TIME, D1
    
    DIVU    #100, D1
    AND.L   #$FFFF, D1
    
   
    
    DIVU    #60,D1
    MOVE.W  D1,TIME_IN_MIN
    
    SWAP    D1
    MOVE.W  D1,TIME_IN_SEC
RTS
    
  
    
*-----------------------------------------------------------
* Subroutine    : Player is on Ground
* Description   : Check if the Player is on or off Ground
*-----------------------------------------------------------

IS_PLAYER_ON_GND:
    ; Check if Player is on Ground
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    CLR.L   D2                      ; Clear contents of D2 (XOR is faster)
    MOVE.W  SCREEN_H,   D1          ; Place Screen width in D1
    DIVU    #02,        D1          ; divide by 2 for center on Y Axis
    MOVE.L  PLAYER_Y,   D2          ; Player Y Position
    CMP     D1,         D2          ; Compare middle of Screen with Players Y Position 
    BGE     SET_ON_GROUND           ; The Player is on the Ground Plane
    BLT     SET_OFF_GROUND          ; The Player is off the Ground
    RTS                             ; Return to subroutine


*-----------------------------------------------------------
* Subroutine    : On Ground
* Description   : Set the Player On Ground
*-----------------------------------------------------------
SET_ON_GROUND:
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.W  SCREEN_H,   D1          ; Place Screen width in D1
    DIVU    #02,        D1          ; divide by 2 for center on Y Axis
    MOVE.L  D1,         PLAYER_Y    ; Reset the Player Y Position
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.L  #00,        D1          ; Player Velocity
    MOVE.L  D1,         PLYR_VELOCITY ; Set Player Velocity
    MOVE.L  #GND_TRUE,  PLYR_ON_GND ; Player is on Ground
    RTS

*-----------------------------------------------------------
* Subroutine    : Off Ground
* Description   : Set the Player Off Ground
*-----------------------------------------------------------
SET_OFF_GROUND:
    MOVE.L  #GND_FALSE, PLYR_ON_GND ; Player if off Ground
    RTS                             ; Return to subroutine
*-----------------------------------------------------------
* Subroutine    : Jump
* Description   : Perform a Jump
*-----------------------------------------------------------
JUMP:
    CMP.L   #GND_TRUE,PLYR_ON_GND   ; Player is on the Ground ?
    BEQ     PERFORM_JUMP            ; Do Jump
    BRA     JUMP_DONE               ;
PERFORM_JUMP:
    BSR     PLAY_JUMP               ; Play jump sound
    MOVE.L  #PLYR_JUMP_V,PLYR_VELOCITY ; Set the players velocity to true
    RTS                             ; Return to subroutine
JUMP_DONE:
    RTS                             ; Return to subroutine

*-----------------------------------------------------------
* Subroutines   : Sound Load and Play
* Description   : Initialise game sounds into memory 
* Current Sounds are RUN, JUMP and Opps for Collision
*-----------------------------------------------------------
JUMP_LOAD:
    LEA     JUMP_WAV,   A1          ; Load Wav File into A1
    MOVE    #JMP_INDEX, D1          ; Assign it INDEX
    MOVE    #71,        D0          ; Load into memory
    TRAP    #15                     ; Trap (Perform action)
    RTS                             ; Return to subroutine

PLAY_JUMP:
    MOVE    #JMP_INDEX, D1          ; Load Sound INDEX
    MOVE    #72,        D0          ; Play Sound
    TRAP    #15                     ; Trap (Perform action)
    RTS                             ; Return to subroutine

OOPS_LOAD:
    LEA     OOPS_WAV,   A1          ; Load Wav File into A1
    MOVE    #OOPS_INDEX,D1          ; Assign it INDEX
    MOVE    #71,        D0          ; Load into memory
    TRAP    #15                     ; Trap (Perform action)
    RTS                             ; Return to subroutine

PLAY_OOPS:
    MOVE    #OOPS_INDEX,D1          ; Load Sound INDEX
    MOVE    #72,        D0          ; Play Sound
    TRAP    #15                     ; Trap (Perform action)
    RTS                             ; Return to subroutine
    
DEATH_LOAD:
    LEA DEATH_WAV,A1
    MOVE DEATH_INDEX,D1
    MOVE #71, D0
    TRAP #15
    RTS

DEATH_PLAY:
    MOVE DEATH_INDEX,D1
    MOVE #72, D0
    TRAP #15
    RTS
    

*-----------------------------------------------------------
* Subroutine    : Draw Player
* Description   : Draw Player Square
*-----------------------------------------------------------
DRAW_PLAYER:
    ; Set Pixel Colors
    MOVE.L  #WHITE,     D1          ; Set Background color
    MOVE.B  #80,        D0          ; Task for Background Color
    TRAP    #15                     ; Trap (Perform action)

    ; Set X, Y, Width and Height
    MOVE.L  PLAYER_X,   D1          ; X
    MOVE.L  PLAYER_Y,   D2          ; Y
    MOVE.L  PLAYER_X,   D3
    ADD.L   #PLYR_W_INIT,   D3      ; Width
    MOVE.L  PLAYER_Y,   D4 
    ADD.L   #PLYR_H_INIT,   D4      ; Height
    
    ; Draw Player
    MOVE.B  #87,        D0          ; Draw Player
    TRAP    #15                     ; Trap (Perform action)
    RTS                             ; Return to subroutine

*-----------------------------------------------------------
* Subroutine    : Draw Enemy
* Description   : Draw Enemy Square
*-----------------------------------------------------------
DRAW_ENEMY:
    ; Set Pixel Colors
    MOVE.L  #RED,       D1          ; Set Background color
    MOVE.B  #80,        D0          ; Task for Background Color
    TRAP    #15                     ; Trap (Perform action)

    ; Set X, Y, Width and Height
    MOVE.L  ENEMY_X,    D1          ; X
    MOVE.L  ENEMY_Y,    D2          ; Y
    MOVE.L  ENEMY_X,    D3
    ADD.L   #ENMY_W_INIT,   D3      ; Width
    MOVE.L  ENEMY_Y,    D4 
    ADD.L   #ENMY_H_INIT,   D4      ; Height
    
    ; Draw Enemy    
    MOVE.B  #87,        D0          ; Draw Enemy
    TRAP    #15                     ; Trap (Perform action)
    RTS                             ; Return to subroutine


*-----------------------------------------------------------
* Subroutine    : Collision Check
* Description   : Axis-Aligned Bounding Box Collision Detection
* Algorithm checks for overlap on the 4 sides of the Player and 
* Enemy rectangles
* PLAYER_X <= ENEMY_X + ENEMY_W &&
* PLAYER_X + PLAYER_W >= ENEMY_X &&
* PLAYER_Y <= ENEMY_Y + ENEMY_H &&
* PLAYER_H + PLAYER_Y >= ENEMY_Y
*-----------------------------------------------------------
CHECK_COLLISIONS:
    CLR.L   D1                      ; Clear D1
    CLR.L   D2                      ; Clear D2
PLAYER_X_LTE_TO_ENEMY_X_PLUS_W:
    MOVE.L  PLAYER_X,   D1          ; Move Player X to D1
    MOVE.L  ENEMY_X,    D2          ; Move Enemy X to D2
    ADD.L   ENMY_W_INIT,D2          ; Set Enemy width X + Width
    CMP.L   D1,         D2          ; Do the Overlap ?
    BLE     PLAYER_X_PLUS_W_LTE_TO_ENEMY_X  ; Less than or Equal ?
    BRA     COLLISION_CHECK_DONE    ; If not no collision
PLAYER_X_PLUS_W_LTE_TO_ENEMY_X:     ; Check player is not  
    ADD.L   PLYR_W_INIT,D1          ; Move Player Width to D1
    MOVE.L  ENEMY_X,    D2          ; Move Enemy X to D2
    CMP.L   D1,         D2          ; Do they OverLap ?
    BGE     PLAYER_Y_LTE_TO_ENEMY_Y_PLUS_H  ; Less than or Equal
    BRA     COLLISION_CHECK_DONE    ; If not no collision   
PLAYER_Y_LTE_TO_ENEMY_Y_PLUS_H:     
    MOVE.L  PLAYER_Y,   D1          ; Move Player Y to D1
    MOVE.L  ENEMY_Y,    D2          ; Move Enemy Y to D2
    ADD.L   ENMY_H_INIT,D2          ; Set Enemy Height to D2
    CMP.L   D1,         D2          ; Do they Overlap ?
    BLE     PLAYER_Y_PLUS_H_LTE_TO_ENEMY_Y  ; Less than or Equal
    BRA     COLLISION_CHECK_DONE    ; If not no collision 
PLAYER_Y_PLUS_H_LTE_TO_ENEMY_Y:     ; Less than or Equal ?
    ADD.L   PLYR_H_INIT,D1          ; Add Player Height to D1
    MOVE.L  ENEMY_Y,    D2          ; Move Enemy Height to D2  
    CMP.L   D1,         D2          ; Do they OverLap ?
    BGE     COLLISION               ; Collision !
    BRA     COLLISION_CHECK_DONE    ; If not no collision
COLLISION_CHECK_DONE:               ; No Collision Update heatlh
    RTS
    
COLLISION:
    BSR     PLAY_OOPS               ; Play Opps Wav
    SUB.L  #20, PLAYER_HEALTH       ; Take 10 from score
    IF.L (PLAYER_HEALTH) <EQ> #0 THEN
    BSR DEATH_PLAY
    MOVE.B	#TC_CURSR_P,D0          ; Set Cursor Position
	MOVE.W	#$FF00,     D1          ; Clear contents
	TRAP    #15                     ; Trap (Perform action)

    BSR     DRAW_PLYR_DATA          ; Draw Draw Score, HUD, Player X and Y
    BSR     DRAW_PLAYER             ; Draw Player
    BSR     DRAW_ENEMY              ; Draw Enemy
    
    
    MOVE.B  #94,        D0
    TRAP    #15
    
    MOVE.B	#TC_CURSR_P,D0          ; Set Cursor Position
	MOVE.W	#$FF00,     D1          ; Clear contents
	TRAP    #15
	
    JMP    RESTART
        
    ENDI
    RTS                             ; Return to subroutine
    

*-----------------------------------------------------------
* Subroutine    : RESTART
* Description   : Resets the game
*-----------------------------------------------------------
RESTART:
    MOVE.B #TC_CURSR_P, D0
    MOVE.W #$0203, D1
    TRAP #15
    
    LEA RESTART_MSG, A1
    MOVE #14, D0
    TRAP #15
    
    BSR DRAW
    
    MOVE.B #19,D0
    MOVE.L #ENTER, D1
    TRAP #15
    CMP.L  #$FF, D1
    BEQ START
    BRA RESTART
    
    

*-----------------------------------------------------------
* Subroutine    : EXIT
* Description   : Exit message and End Game
*-----------------------------------------------------------
EXIT:
    MOVE.B  #TC_EXIT,   D0          ; Exit Code
    TRAP    #15                     ; Trap (Perform action)
    SIMHALT

* Put variables and constants here

*-----------------------------------------------------------
* Section       : Messages
* Description   : Messages to be displayed to the screen
*-----------------------------------------------------------

HEALTH_MSG      DC.B    'HEALTH: ', 0       ; Score Message
TIME_MSG        DC.B    'TIME: ', 0          ; Time Message
TIME_BREAK      DC.B    ':',0
EXIT_MSG        DC.B    'Exiting....', 0    ; Exit Message
RESTART_MSG     DC.B    'Press ENTER to restart...',0   ;Restart Message

*-----------------------------------------------------------
* Section       : Graphic Colors
* Description   : Screen Pixel Color
*-----------------------------------------------------------
WHITE           EQU     $00FFFFFF
RED             EQU     $00080888

*-----------------------------------------------------------
* Section       : Screen Size
* Description   : Screen Width and Height
*-----------------------------------------------------------
SCREEN_W        DS.W    01  ; Reserve Space for Screen Width
SCREEN_H        DS.W    01  ; Reserve Space for Screen Height

*-----------------------------------------------------------
* Section       : Keyboard Input
* Description   : Used for storing Keypresses
*-----------------------------------------------------------
CURRENT_KEY     DS.L    01  ; Reserve Space for Current Key Pressed

*-----------------------------------------------------------
* Section       : Character Positions
* Description   : Player and Enemy Position Memory Locations
*-----------------------------------------------------------
PLAYER_X        DS.L    01  ; Reserve Space for Player X Position
PLAYER_Y        DS.L    01  ; Reserve Space for Player Y Position
PLAYER_HEALTH   DS.L    01  ; Reserve Space for Player Health

PLYR_VELOCITY   DS.L    01  ; Reserve Space for Player Velocity
PLYR_GRAVITY    DS.L    01  ; Reserve Space for Player Gravity
PLYR_ON_GND     DS.L    01  ; Reserve Space for Player on Ground

ENEMY_X         DS.L    01  ; Reserve Space for Enemy X Position
ENEMY_Y         DS.L    01  ; Reserve Space for Enemy Y Position

START_TIME      DS.L    01  ; Time game is started at
TIME_ELAPSED    DS.L    01  ; Time passed since game start
TIME_IN_SEC     DS.L    01  ; Time stored in seconds
TIME_IN_MIN     DS.L    01  ; Time stored in minutes

*-----------------------------------------------------------
* Section       : Sounds
* Description   : Player sounds
*-----------------------------------------------------------

JUMP_WAV        DC.B    'sounds/jump.wav',0        ; Jump Sound
OOPS_WAV        DC.B    'sounds/oops.wav',0        ; Collision Opps
DEATH_WAV       DC.b    'sounds/death.wav',0       ; Death sound


    END    START        ; last line of source
























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
