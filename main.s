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

	AREA    |.text|, CODE, READONLY, ALIGN=2
	THUMB
	EXPORT  Start
Start
 ; TExaS_Init sets bus clock at 80 MHz
	BL  TExaS_Init ; voltmeter, scope on PD3
 ; Initialization goes here
	BL portstart
	CPSIE  I    ; TExaS voltmeter, scope runs on interrupts
loop  
; main engine goes here

	B    loop

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
	
	LDR R1, =GPIO_PORTF_AMSEL_R
	MOV R0, #0
	STR R0, [R1]					;DISABLE ANALOG
	
	LDR R1, =GPIO_PORTF_PCTL_R      ;ALL PORT F TO NORMAL GPIO
	MOV R0, #0
	STR R0, [R1]
	
	LDR R1, =GPIO_PORTF_DIR_R
	MOV R0, #6						;SET BITS HIGH FOR PORTS 2,1 TO ENABLE OUTPUT
	STR R0, [R1]
	
	LDR R1, =GPIO_PORTF_AFSEL_R
	MOV R0, #0
	STR R0, [R1]					;DISABLE ALT FUNCTIONS
	
	LDR R1, =GPIO_PORTE_AFSEL_R
	MOV R0, #0
	STR R0, [R1]					;DISABLE ALT FUNCTIONS
	
	LDR R1, =GPIO_PORTF_PUR_R
	MOV R0, #0x11
	STR R0, [R1]					; EN PF0 AND PF4 PULL UP RESISTORS
	
	LDR R1, =GPIO_PORTF_DEN_R		;ENABLE DIGITAL
	MOV R0, #0xFF
	STR R0, [R1]
	
	LDR R1, =GPIO_PORTE_DEN_R 
	MOV R0, #0xFF
	STR R0, [R1]					;ENABLE DIGITAL
	
	BX	LR


//testttttt
	ALIGN      ; make sure the end of this section is aligned
	END        ; end of file

