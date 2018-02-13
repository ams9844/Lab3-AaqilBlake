;****************** main.s ***************
; Program written by: ***Your Names**update this***
; Date Created: 2/4/2017
; Last Modified: 1/15/2018
; Brief description of the program
;   The LED toggles at 8 Hz and a varying duty-cycle
; Hardware connections (External: One button and one LED)
;  PE1 is Button input  (1 means pressed, 0 means not pressed)
;  PE0 is LED output (1 activates external LED on protoboard)
;  PF4 is builtin button SW1 on Launchpad (Internal) 
;        Negative Logic (0 means pressed, 1 means not pressed)
; Overall functionality of this system is to operate like this
;   1) Make PE0 an output and make PE1 and PF4 inputs.
;   2) The system starts with the the LED toggling at 8Hz,
;      which is 8 times per second with a duty-cycle of 20%.
;      Therefore, the LED is ON for (0.2*1/8)th of a second
;      and OFF for (0.8*1/8)th of a second.
;   3) When the button on (PE1) is pressed-and-released increase
;      the duty cycle by 20% (modulo 100%). Therefore for each
;      press-and-release the duty cycle changes from 20% to 40% to 60%
;      to 80% to 100%(ON) to 0%(Off) to 20% to 40% so on
;   4) Implement a "breathing LED" when SW1 (PF4) on the Launchpad is pressed:
;      a) Be creative and play around with what "breathing" means.
;         An example of "breathing" is most computers power LED in sleep mode
;         (e.g., https://www.youtube.com/watch?v=ZT6siXyIjvQ).
;      b) When (PF4) is released while in breathing mode, resume blinking at 8Hz.
;         The duty cycle can either match the most recent duty-
;         cycle or reset to 20%.
;      TIP: debugging the breathing LED algorithm and feel on the simulator is impossible.
; PortE device registers
GPIO_PORTE_DATA_R  EQU 0x400243FC
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_AFSEL_R EQU 0x40024420
GPIO_PORTE_DEN_R   EQU 0x4002451C
; PortF device registers
GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_LOCK_R  EQU 0x40025520
GPIO_PORTF_CR_R    EQU 0x40025524
GPIO_LOCK_KEY      EQU 0x4C4F434B  ; Unlocks the GPIO_CR register
SYSCTL_RCGCGPIO_R  EQU 0x400FE608

	IMPORT  TExaS_Init
	THUMB
	AREA    DATA, ALIGN=2
;global variables go here
CHECK	DCD 0 ; makes a memory location to store if the button was pressed in the last cycle
	AREA    |.text|, CODE, READONLY, ALIGN=2
	THUMB
	EXPORT  Start
Start
 ; TExaS_Init sets bus clock at 80 MHz
	BL  TExaS_Init ; voltmeter, scope on PD3
 ; Initialization goes here
	BL portstart
	MOV R5, #2
	CPSIE  I    ; TExaS voltmeter, scope runs on interrupts
loop  
; main engine goes here
	BL switches
	BL duty ;returns R3 and R4, with on and off time respectively, needs R5 in the form of 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 * [10%] duty cycle
	BL blink
	BL delay
	BL blink
	MOV R3, R4
	BL delay

	B    loop

switches
	LDR R1, =GPIO_PORTE_DATA_R
	LDR R0, [R1]				;GET DATA FROM PORT E
	MOV R2, #0x02				;MASK FOR PORT PE 1
	AND R0, R2, R0				;ERASE OTHER BITS
	LDR R1, =CHECK
	LDR R2, [R1]
	STR R0, [R1]
	CMP R2, R0				;CHECKS IF IT IS 10 - 00 =10 (WOULD MEAN THE BUTTON WAS PRESSED LAST CYCLE AND RELEASED THIS CYCLE)
	BNE SEC
	BX LR
SEC	BPL INCREASE_DUTY_CYCLE
	BX LR
INCREASE_DUTY_CYCLE	ADD R5, R5, #2 ;INCREASE DUTY CYCLE BY tw0 (=20%)
	MOV R2, #0x0A
	CMP R2, R5	;10-(R5) IF IS GREATER THAN 10 INVALID
	BMI ZERO ;IF R5 WAS GREATER THAN 10, RESET TO 0
	BX LR
ZERO	AND R5, R5, #0
	BX LR

delay ;put in R3 time delay 80=~1/16
	MOV R0, #15000 ;SET DELAY TO 1/800 OF A SECOND
wait	SUBS R0, R0, #1
	BNE wait ;if not equal branch to delay
	SUBS R3, R3, #1
	BNE delay
	BX LR

duty
	MOV R0, #16
	MUL	R3, R0, R5 ; get time on
	MOV R0, #160
	SUBS R4, R0, R3; 160-time on = time off
	BX LR
	
blink
	LDR R1, =GPIO_PORTE_DATA_R
	LDR R0, [R1]				;GET DATA FROM PORT
	MOV R2, #0x01
	EOR R0, R0, #-1				; NOT THE DATA
	AND R0, R0, R2				;SELECT ONLY PE0
	STR R0, [R1]				;WRITE THE VALUE
	BX LR
	
portstart
	LDR R1, =SYSCTL_RCGCGPIO_R
	LDR R0, [R1]
	ORR R0, R0, #0x30
	STR R0, [R1] ;STORE VAL TO ACTIVATE PORT F and E CLOCK
	NOP
	NOP
	NOP
	NOP	;Let the clock Settle
		
	LDR R1, =GPIO_PORTF_LOCK_R     ;UNLOCK PORT F 
    LDR R0, =0x4C4F434B             
    STR R0, [R1]
	
	LDR R1, =GPIO_PORTF_CR_R		;ENABLE COMMIT
	MOV R0, #0xFF
	STR R0, [R1]
	
	LDR R1, =GPIO_PORTF_DIR_R
	MOV R0, #0						;disable output
	STR R0, [R1]

	LDR R1, =GPIO_PORTE_DIR_R
	MOV R0, #0x01					;enable output on PE0
	STR R0, [R1]

	LDR R1, =GPIO_PORTF_AFSEL_R
	MOV R0, #0
	STR R0, [R1]					;DISABLE ALT FUNCTIONS

	LDR R1, =GPIO_PORTE_AFSEL_R
	MOV R0, #0
	STR R0, [R1]					;DISABLE ALT FUNCTIONS
	
	LDR R1, =GPIO_PORTF_PUR_R
	MOV R0, #0x10
	STR R0, [R1]					; EN PF0 AND PF4 PULL UP RESISTORS
	
	LDR R1, =GPIO_PORTF_DEN_R		;ENABLE DIGITAL
	MOV R0, #0xFF
	STR R0, [R1]
	
	LDR R1, =GPIO_PORTE_DEN_R 
	MOV R0, #0xFF
	STR R0, [R1]					;ENABLE DIGITAL
	
	BX	LR

	ALIGN      ; make sure the end of this section is aligned
	END        ; end of file
