;
; AssemblerApplication3.asm
;
; Created: 03/11/2017 16:31:37
; Author : nmt115
;


	.DEVICE ATmega128
	.include "m128def.inc"


;""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
jmp Init		                 ; jmp is 2 word instruction to set correct vector 
; INTERUPT:
.org		$003c			; UART0 RX Complete Handler
rjmp save_data_start352	; Vector Addresses are 2 words apart; UART Receive  Vector 			;18					
.org		$0080			; start address well above interrupt table


;""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
.include "action4include.asm"
init: ; system init routine

;renaming pins
.equ	UART_TxPort = PORTD    ;set port D aS OUTPUT FOR TRANSMIT
.equ	UART_TxDDR  = DDRD				;DIRECTION REGISTER


;Locationsin SRAM that are used in the programme
;.equ	savedregister=0x0200      ;Address in SRAM, where the new database will be stored
.equ	compare_address = 0x0300
.equ	savedregister=0x0320      ;Address in SRAM, where the new database will be stored
.equ	testregister= 0x0340           ;used for interrupt
.equ	testregister1= 0x0360
.equ    testregister2 = 0x0380
.equ    testregister3 = 0x03A0      ;not in use 
.equ    testregister4 = 0x03C0
.equ    testregister5 = 0x03E0
.equ    testregister6 = 0x0400
.equ    testregister7 = 0x0420
.equ    testregister8 = 0x0440 
.equ	testregister9 = 0x0460 

.def	buffer = R23			

;  Speed setting  
.equ	FREQ = 8000000   
.equ	BAUD 		 =  57600  
;*****       Etc       *****
.equ	stop_bits 	       = 1     ;STOPS READING
; hand-picked for easier auto-baud calculations (no division)
.equ	cycles_per_bit 	   = 12 ;without delays + 4*nop
.equ	const_delay_cycles = 9	;rjmp + ret + 2*nop
.dseg
DELAY_VALUE: .byte 1        ;assign memory for clock speed value
.cseg
;***** Precalculations *****
;pure cycles necessary per bit
.equ	q = FREQ / BAUD			;relates clock speed to transmission
;delay cycles
.equ	w = (q - cycles_per_bit - 2*const_delay_cycles)/2
;delay value	
.equ	r = w / 3						;divison by 3 of d, definition

;preprocessor check for baud rate
.if     r <= 0
	.error "high baud rate"		
.elif    r > 255 
	.error "low baud rate"
.endif

; ************************* MEMORY ERRASER *********************
; it is crucial for the operaiton of device to start with clear memory where
;data is stored as responce from the finger print scanner

;this erases memory from 0x0300 to 0x0900, with 01
eraser:
	ldi XH, high(compare_address)
	ldi XL, low(compare_address)
loop:
	push r20
	ldi r20, $01
	st X+, r20
	cpi XH, $09
	brne loop
	pop r20

;######################### PORT SET UPS #################################

; ******* Port B Setup Code ****  

		ldi r16, $FF		; will set to outputs so i cab use Leds for debugging
		out DDRB , r16		; Port B Direction Register
		ldi r16, 00		; Who cares what is it....
		out PORTB, r16		; Port B value


		ldi r16, $0F		; Stack Pointer Setup
		out SPH,r16			; Stack Pointer High Byte 
		ldi r16, $FF		; Stack Pointer Setup 
		out SPL,r16			; Stack Pointer Low Byte 

; ******* RAMPZ Setup Code ****  lower memory page arithmetic
		ldi  r16, $00		; 1 = EPLM acts on upper 64K
		out RAMPZ, r16		; 0 = EPLM acts on lower 64K


		; ******* Sleep Mode And SRAM  *******
		;			; tell it we want read and write activity on RE WR
		ldi r16, $C0		; Idle Mode - SE bit in MCUCR not set
		out MCUCR, r16		; External SRAM Enable Wait State Enabled
   
		; ******* Comparator Setup Code ****  
		ldi r16,$80		; Comparator Disabled, Input Capture Disabled 
		out ACSR, r16		; Comparator Settings


;######################### USART SET UP ################################
		ldi r16, (1<<RXEN1)|(1<<RXCIE1)   ;enables interrupt
		sts UCSR1B,r16
; Set frame format: 8data, 2stop bit
		ldi r16, (1<<USBS1)|(3<<UCSZ10)
		sts UCSR1C,r16
		push r16
		push r17
		ldi r16, $08
		ldi r17, $00
		sts UBRR1H, r17
		sts UBRR1L, r16
		pop r17
		pop r16

ldi YH, high(testregister)
	ldi YL, low(testregister)
	sei
	
;######################################################################
rjmp main



;____________________ DATABASE OF MESSAGES AND COMMANDS TO THE SCANNER___________
ReadSysPara:
.db $EF,$01,$FF,$FF,$FF,$FF,$01,$00,$03,$0f, $00, $13
;========================== Admin Settings ========================== 
TempleteNum:
.db $EF,$01,$FF,$FF,$FF,$FF,$01,$00,$03,$1d, $00, $21    ;no of templates
DeleteChar:
.db $EF,$01,$FF,$FF,$FF,$FF,$01,$00,$07,$0C, $00, $00, $00, $0F, $00, $23    ;no of templates
;=====================================================================

genimg:
.db $EF,$01,$FF,$FF,$FF,$FF,$01,$00,$03,$01, $00, $05,$08,$00

img2tBuff1:
.db $EF,$01,$FF,$FF,$FF,$FF,$01,$00,$04,$02,$1,$00,$08,$0

img2tBuff2:
.db $EF,$01,$FF,$FF,$FF,$FF,$01,$00,$04,$02,$2,$00,$09,$0

regmodel:
.db $EF,$01,$FF,$FF,$FF,$FF,$01,$00,$03,$05,$00,$09    

Store4:
.db $EF,$01,$FF,$FF,$FF,$FF,$01,$00,$06,$06,$01, $00 ;send this

PreciseMatch:
.db $EF,$01,$FF,$FF,$FF,$FF,$01,$00,$03,$03, $00, $07,$08,$00  ;matches character files

Search:
.db $EF,$01,$FF,$FF,$FF,$FF,$01,$00,$08,$04, $01, $00,$00 ,$00, $46, $00, $54, $00

search2:
.db $EF,$01,$FF,$FF,$FF,$FF,$01,$00,$08,$04,$01   ;used in Admin page, varies location for search




;&&&&&&&&&&&&&&&&&&&&&&&&&&&&Compare DATABASE&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

compare_database:

.db $EF, $01, $FF, $FF, $FF, $FF, $07,$00, $05, $00, $00, $0A  ;;Used in datbase_to_SRAM

compare_database2:
.db $EF, $01, $FF, $FF, $FF, $FF, $07,$00, $07, $00, $00, $0A  ;;Used in datbase_to_SRAM4

;������������������������ LCD DATABASE ������������������������������������������������

Match:
.db ' ','M', 'a', 't' ,'c', 'h'       

Different:
.db ' ', 'D','i','f','f','e','r','e','n','t'

Tomas:
.db "  Tomas"

Nelson:
.db "  Nelson"

George:
.db "  George"

Welcome:
.db " Welcome! Press Pins 0 to 3 to start."

Welcomemessage1:
.db " 0. Compare.         2. Search database. 1. Locate.          3. Admin settings. "

Welcomemessage2:
.db " 4. Store finger.    6. Full templates.  5. Delete.          7. Return.         "

ready:
.db "  Enter ID number: "


ID_recognised:
.db "  Access granted.  "


;������������������������������������������������������������������

;****************************************************
;**********************CODE HERE*********************
;****************************************************

;****************************************************
;*****                 SEND BYTE                *****
;****************************************************
; This sends one byte using SW UART
UART_send_byte:	
	ldi		r24, 9 + stop_bits ;CHECK IF CORRECRT, 7 + stop_bits
	com		buffer	
	sec		

; 12 cycles here (without delays)
uart_send_next_bit:	
	brcc	uart_send_1
	cbi		UART_TxPort, 3
	rjmp	uart_wait

uart_send_1:	
	sbi		UART_TxPort, 3
	nop

uart_wait:	
	rcall 	UART_delay	
	rcall 	UART_delay

	nop	nop nop nop
	lsr		buffer
	dec		r24		
	brne	uart_send_next_bit
					
	sbi		UART_TxPort, 3
ret		
		
;****************************************************
;*****                 GET BYTE                 *****
;****************************************************
; SW UART to get one byte - not used in the latest vesrion of code
UART_get_byte:	
	ldi 	r24, 9

uart_wait_for_start:	
	sbic 	PIND, 2	;pin in PIND
	rjmp 	uart_wait_for_start
	;synchronize for 0.5 bit length
	rcall 	UART_delay	

; 10 cycles here (without delays)
uart_get_bit:	
	rcall 	UART_delay	
	rcall 	UART_delay		

	clc			
	sbic 	PIND, 2	;2 is a pin where out data will appear bit by bit
	sec			
	
	nop	nop nop nop
	dec 	r24		
	breq 	uart_bit_done	
				
	ror 	buffer		
	rjmp 	uart_get_bit	

uart_bit_done:	
	ret

;****************************************************
;*****                UART DELAY                *****
;****************************************************
; 3*b + const_delay_cycles
UART_delay:	
	lds		r16, DELAY_VALUE
UART_delay1:	
	dec		r16
	brne	UART_delay1
	nop
	;pop r16
	ret

uart_init: ; initiation of SW UART
	in		r16, UART_TxDDR
	ori		r16, (1<<3)  ;set pin 3 as ouput
	out		UART_TxDDR, r16
	sbi		UART_TxPort, 3
	
	in		r16, DDRD          
	andi	r16, ~(1<<2 | 1<<RxCIE0)  ;set pin 2 as input
	out		DDRD, r16
	
	ldi		r16, r   ;really important sets baud rate
	sts		DELAY_VALUE, r16
	ret

	ldi r16, $01
	ret




;**************************  MAIN ***************************************
;***********************************************************************
;******************************************************************
;******************************************************************
;******************************************************************
;******************************************************************
;******************************************************************

main: ;!!!!!!!!!!!!RUNS ONCE HERE - THis is basically init2 which runs just once
    rcall Idisp
	rcall uart_init
	rcall CLRDIS
	rcall beepon
    ;rcall beepon

	rcall Welcome2 ; first welcoming message
	rcall bigdel
	rcall bigdel
	rcall bigdel
	rcall CLRDIS
	
LDI r25, $02 ; start dsavinbg 03 -> this points to starting address in scanner


main2: ; this is the main loop -> menu 1 with normal user functions
	rcall clear750 ;clears SRAM location used for tests
	rcall Welcome3
	rcall waitforbuttonpress
	rcall CLRDIS
	rjmp main2
;rcall compare_basic2   

;******************************************************************
;******************************************************************
;******************************************************************
;******************************************************************


clear750: ; clears SRAM locaiton used for tests
	push r16
	ldi r16, 0
	sts 0x0750, r16
	pop r16
	ret
;GGGGGGGGGGGGGGGGGGGGGGG Welcome Messages GGGGGGGGGGGGGGGGGGGGGGGGG
; the logic of the messages is to load SRAM address of the welcome message to Z and
;then start displaying one by one characted in LCD routines => Mess1More2
	
Welcome2:
	 LDI ZH, HIGH(2*Welcome)
     LDI ZL, LOW(2*Welcome)
     LDI r18, 37  ;number of characters or bytes
rcall Mess1More22
  ret

Welcome3:
	rcall clrdis
	 LDI ZH, HIGH(2*Welcomemessage1)
     LDI ZL, LOW(2*Welcomemessage1)
     LDI r18, 80 ;number of characters or bytes
rcall Mess1More22
rcall bigdel
  ret

Welcome5:
	rcall clrdis
	 LDI ZH, HIGH(2*Welcomemessage2)
     LDI ZL, LOW(2*Welcomemessage2)
     LDI r18, 80 ;number of characters or bytes
rcall Mess1More22
rcall bigdel
ret

READY2:
	rcall clrdis
	 LDI ZH, HIGH(2*ready)
     LDI ZL, LOW(2*ready)
     LDI r18, 19 ;number of characters or bytes
rcall Mess1More22
rcall bigdel
ret


message_ID_recognised:
	rcall clrdis
	 LDI ZH, HIGH(2*ID_recognised)
     LDI ZL, LOW(2*ID_recognised)
     LDI r18, 19 ;number of characters or bytes
rcall Mess1More22
rcall bigdel
ret

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  Beginning OF RETURN    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  Beginning OF RETURN    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


 ;*********************************COMPARING2**************************************

; in this routine we are going to compare 2 sram databases
; this is crucial routine for decitions about fullfillment of conditions and sucesses 
; of finger print detections
compare_basic2:

push r17
push r20
push r21
push r18
ldi r18,  0  ;counter
rcall Comp1Out2Z
rcall Comp1Out2Y
rjmp Comp1More2


Comp1Out2Z:	;the one we compare to

			  LDI ZH, HIGH(compare_address)    ;address for comparison 
              LDI ZL, LOW(compare_address)
			  ret
Comp1Out2Y:
              ldi YL, low(testregister5)           ;saved output from MAtch
			  ldi YH, high(testregister5) 
			  ret
  
			   
Comp1More2:

			ld r20, Z+
			ld r17, Y+

			inc r18

			cp r20, r17 ; compare the two X, Z
			brne statefalse2 ;go to false message if not equal

			


			cpi r18, 10 ; compare when end the cycle		 ;chnaged to 8 for matching	
			brne Comp1More2

Comp1End2:     

	push r22
	ldi r22, $03
	;out portB, r22
	rcall matching
	rcall beepon
	;rcall bigdel
    rcall megadel
    rcall CLRDIS
	pop r22
	rcall bigdel2
			pop r18
			pop r21
			pop r20
			pop r17
			ret

statefalse2:
	push r22
	ldi r22, $0F
	;out portB, r22
	pop r22
	rcall differently
	rcall megadel
	rcall beepon
	rcall bigdel2
	rcall beepon
	rcall bigdel2
	rcall beepon
	pop r18
	pop r21
	pop r20
	pop r17
	rjmp main2



;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  END OF RETURN    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  END OF RETURN    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&  SENDING PACKAGES &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
; the sending of packages works that the address to PM is stored in Z and then routine sends
; the message to thescanner using UART protocol

send_ReadSysPara:
              
				ldi r18, 12
			  LDI ZH, HIGH(ReadSysPara*2)
              LDI ZL, LOW(ReadSysPara*2)
			  rcall Mess1Out
			  ret

send_TempleteNum:
              
				ldi r18, 12
			  LDI ZH, HIGH(TempleteNum*2)
              LDI ZL, LOW(TempleteNum*2)
			  rcall Mess1Out
			  ret

send_DeleteChar:
              
				ldi r18, 16
			  LDI ZH, HIGH(DeleteChar*2)
              LDI ZL, LOW(DeleteChar*2)
			  rcall Mess1Out
			  ret


send_genimg:
              
				ldi r18, 12
			  LDI ZH, HIGH(genimg*2)
              LDI ZL, LOW(genimg*2)
			  rcall Mess1Out
			  ret
send_img2tBuff1:
             
			ldi r18,13
			  LDI ZH, HIGH(img2tBuff1*2)
              LDI ZL, LOW(img2tBuff1*2)
			  rcall Mess1Out
			  ret

send_img2tBuff2:
             
			ldi r18,13
			  LDI ZH, HIGH(img2tBuff2*2)
              LDI ZL, LOW(img2tBuff2*2)
			  rcall Mess1Out
			  ret

send_regmodel:
             
			ldi r18,12
			  LDI ZH, HIGH(regmodel*2)
              LDI ZL, LOW(regmodel*2)
			  rcall Mess1Out
			  ret

send_Store4: ; this one has to split the message and add variable (register) poitning
			; to the variable memory address in the device -> to prevent overwriting 
			; THis adds fingerpritn to the database of the scanner
			ldi r18,12
			  LDI ZH, HIGH(2*Store4)
              LDI ZL, LOW(2*Store4)
			  rcall Mess1Out
			  sts 0x0952, r25
			  ; now fine for 12
			  ; send vaRIBKLE LOFCATION
			  mov buffer,r25
			  rcall UART_send_byte
			rcall UART_delay
			  ;send r 25
			  

			  push r25
			  ldi r25, 00
			  mov buffer,r25
			  rcall UART_send_byte
			rcall UART_delay
			  pop r25

			  push r21 ;contains the sum
			  mov r21,r25
			  sts 0x0954, r21 ; thid ks chwedfksium
			  subi r21,$F2					;add 14 to 
			  sts 0x0954, r21 ; thid ks chwedfksium   ;cnaged to 9
			  mov buffer,r21
			  rcall UART_send_byte
			;rcall UART_delay
				sts 0x0956, r21						  
			  pop r21
			  ;out portb, r25
			  inc r25
			  rcall bigdel
			  ret


send_PreciseMatch:
             
			ldi r18,12
			  LDI ZH, HIGH(PreciseMatch*2)
              LDI ZL, LOW(PreciseMatch*2)
			  rcall Mess1Out
			  ret

send_Search:
             
			ldi r18, $11
			  LDI ZH, HIGH(Search*2)
              LDI ZL, LOW(Search*2)
			  rcall Mess1Out
			  ret

;*************************************SEND BYTE BY BYTE, Transmission ****************************************
;this routine sends byte by byte given message 
Mess1Out:
			push r17	  
              ;LD r18, r22;number of characters or bytes ; this displays the number of r18 
			  ; to send command 13  ;varies betwen 12 and 13

Mess1More:
              LPM 
              MOV r17, r0
              mov buffer,r17
			  rcall UART_send_byte
			rcall UART_delay
			
			  
			  DEC r18
			  cpi r18, $0
			  breq Mess1End
			  ADIW ZL, $01
			  rjmp Mess1More
			  ; if r18>0 then retrurn to mess1more
Mess1End:     
			pop r17
			ret

;*************************************** LCD ROutines
;*******************************************************************************
;This Routine is copied from lectures:
 
;Display Initialization routine
;
; Since we cannot rely that that Power Supply will have on power up
; the required by Hitachi Specs.....we do the initialization 'by hand'.
; Follow Blindly the White-Red Book of Hitachi.
; Hitachi Liquid Crystal Disply LCD Initialization Sequence.
;
Idisp:		
		RCALL DEL15ms                ; wait 15ms for things to relax after power up           
		ldi r16,    $30	         ; Hitachi says do it...
		sts   $8000,r16                      ; so i do it....
		RCALL DEL4P1ms             ; Hitachi says wait 4.1 msec
		sts   $8000,r16	         ; and again I do what I'm told
		rcall Del49ms
		sts   $8000,r16	         ; here we go again folks
		rcall busylcd		
		ldi r16, $3F	         ; Function Set : 2 lines + 5x7 Font
		sts  $8000,r16
		rcall busylcd
		ldi r16,  $08	         ;display off
		sts  $8000, r16
		rcall busylcd		
		ldi r16,  $01	         ;display on
		sts  $8000,  r16
		rcall busylcd
		ldi r16, $38	        ;function set
		sts  $8000, r16
		rcall busylcd
		ldi r16, $0E	        ;display on
		sts  $8000, r16
		rcall busylcd
		ldi r16, $06                           ;entry mode set increment no shift
		sts  $8000,  r16
		rcall busylcd
		clr r16
		ret
;
;**********************************************************************************
; This clears the display so we can start all over again
; given in lectures:
CLRDIS:
		ldi r16,$01	; Clear Display send cursor 
		sts $8000,r16   ; to the most left position
		;rcall busylcd
		ret
;**********************************************************************************
; A routine the probes the display BUSY bit
; given in lectures
   
busylcd:     
	;push r23   
	lds r23, $8000   ;access 
	sbrc r23, 7      ;check busy bit  7
	rjmp busylcd
	;rcall BigDEL3
	;pop r23

	ret              ;return if clear

;**********************************************************************************

Matching:

              LDI ZH, HIGH(2*match)
              LDI ZL, LOW(2*match)
              LDI r18, 6 ;number of characters or bytes
Mess1More22:
              LPM 
              MOV r17, r0
              sts $C000, r17
              rcall busylcd
              DEC r18
              BREQ Mess1End22
              ADIW ZL, $01
              ;OUT PORTB, ZL
              RJMP Mess1More22
Mess1End22:     ret
;             

differently:
              LDI ZH, HIGH(2*different)
              LDI ZL, LOW(2*different)
              LDI r18, 10 ;number of characters or bytes
rcall Mess1More22
ret



;
;********************   DELAY ROUTINES ********************************************
BigDEL2:
             rcall Del49ms
             rcall Del49ms
             rcall Del49ms
             rcall Del49ms
             rcall Del49ms
			 rcall Del49ms
             rcall Del49ms
             rcall Del49ms
             rcall Del49ms
             rcall Del49ms
			 rcall Del49ms
             rcall Del49ms
             rcall Del49ms
             rcall Del49ms
             rcall Del49ms
			 rcall Del49ms
             rcall Del49ms
             rcall Del49ms
             ret

BigDEL:
             rcall BigDEL2
				rcall BigDEL2
             ret

BigDEL3:
             rcall Del49ms
             rcall Del49ms
             rcall Del49ms
             rcall Del49ms
             rcall Del49ms
             ret

megadel:
	rcall BigDEL2
	rcall BigDEL2
	rcall BigDEL2
	rcall BigDEL2
	rcall BigDEL2	
	ret

DEL15ms:

            LDI XH, HIGH(19997)
            LDI XL, LOW (19997)
COUNT:  
            SBIW XL, 1
            BRNE COUNT
            RET
;
DEL4P1ms:
            LDI XH, HIGH(5464)
            LDI XL, LOW (5464)
COUNT1:
            SBIW XL, 1
            BRNE COUNT1
            RET 
;
DEL100mus:
            LDI XH, HIGH(131)
            LDI XL, LOW (131)
COUNT2:
            SBIW XL, 1
            BRNE COUNT2
            RET 
;
DEL49ms:
            LDI XH, HIGH(65535)
            LDI XL, LOW (65535)
COUNT3:
            SBIW XL, 1
            BRNE COUNT3
            RET 




;%%%%%%%%%%%%%%%%%%%%%%%%%%%%    Interrupt   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




save_data_start352:

push r17
lds r17, UDR1
st Y+, r17 ; store bit received to UART to memomry location
pop r17
;cpi YL, $61
;breq end
;sbrc YL, 4
;jmp end
reti

end:
	cli
	ret

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  Calling Actions  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ WAIT FOR  BUTTION PRESS AND MOVE SOMWEHRE ~~~~~~~~~~~

waitforbuttonpress:
rcall waitforbuttonpresscycle
rcall FirstScreen
ret
waitforbuttonpresscycle:
	
    ;ldi r21,$00
	in r21, PIND

	;out portb, r21
	cpi r21, $FF
	breq waitforbuttonpresscycle
	rcall clrdis
	ret

waitforbuttonpress2:
	ldi r21, $00   ;high 4-bit
	ldi r18, $00


	; set keayboard out in 
	; this sets port  4-7 as outputs and porte 0-3 imputs
	ldi r16, $F0		; load r16 with 0-3 input
	out DDRE , r16		; Direction register
	ldi r16, $0F		; 4-7 output
	out PORTE, r16		; 
	rcall DEL49ms
	in r21, PINE ;getting value from pinE	
	
	                    
	;inverse the pin output input
	ldi r16, $0F		; load r16 with 0-3 input, reverse input and ouput
	out DDRE , r16		; Direction register
	ldi r16, $F0		; 4-7 output
	out PORTE, r16		; 
	rcall DEL49ms
	in r18, PINE ;getting value from pinE, red PINE again


	;push r21 ~~~~~~~~~~~~~~~~~~ R21 is the result of reading the key
	add r21, r18 ;add 2 results
	
	cpi r21, $FF
	breq waitforbuttonpress2    ;leaves waiting for button, if value input is not $FF
	ret

FirstScreen:
	;here have list of conditions
	cpi r21,$7F ; pin 1
	breq action1call ; ACTION 1
	
	cpi r21, $BF ; PIN2
	breq action2call ; ACTION 2
	
	cpi r21, $DF ; PIN3
	breq action3call ;Action 3

	cpi r21, $EF ; PIN4
	breq SecondScreen ;Action 4

	ret

SecondScreen:
	rcall verification
correct:
	rcall Welcome5
	rcall waitforbuttonpresscycle
	;here have list of conditions
	cpi r21,$7F ; pin 1
	breq action4call ; ACTION 1
	
	cpi r21, $BF ; PIN2
	breq action5call ; ACTION 2
	
	cpi r21, $DF ; PIN3
	breq action6call ;Action 3

	cpi r21, $EF ; PIN4
	breq action7call ;Action 4
	rjmp main2


actions:

action1call:
	rcall action1
	rjmp main2
action2call:
	rcall action2
	rjmp main2
action3call:
	rcall action3
	rjmp main2
action4call:
	rcall action4    ;included
	rjmp main2

action5call:
	rcall action5
	rjmp main2

action6call:
	rcall action6
	rjmp main2

action7call:
	rjmp main2

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       Verification        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
Verification:
	rcall action3
	lds r16, 0x0750 
	cpi r16, 22
	breq continue
	rjmp main2
	ret

continue:
	rcall message_ID_recognised
	rcall clear750
	rcall bigdel
	rjmp correct




;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^DATABASE TO SRAM  MATCH   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

DATABASE_TO_SRAM: ;saves to 0x0300
push r20

makingZalocation:
ldi ZH, HIGH(compare_database*2)  ;leave as 16 bit
    ldi ZL, LOW(compare_database*2)

rcall step_by_step_LOADING	
pop r20
ret 

;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^DATABASE TO SRAM SEARCH ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


 DATABASE_TO_SRAM4: ;saves to 0x0300
push r20

makingZalocation4:
	ldi ZH, HIGH(compare_database2*2)  ;leave as 16 bit
    ldi ZL, LOW(compare_database2*2)

rcall step_by_step_LOADING	
pop r20 
ret
	
;<<<<<<<<<<<<<<<<<<<<<<<<<<<< Subroutine for databases >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
step_by_step_LOADING	: ; this stores given message from  PM (Z) to the  SRAM location (X)
ldi r20, 12  ;counter
ldi XH, high(compare_address) ;create 16 bit address? ;0x0300
ldi XL, low(compare_address)  ;Leave as 8 bit

program_to_memory:
	lpm 
	;mov r19, r0 ;r19 cointans byte by byte
	ADIW ZL, $01
	dec r20
	
	;now you have data in r19 and you want to store it
	
	st X+, r0            ;don't need sts, if using X

	;end if counted
	cpi r20, $0
	brne program_to_memory
	ret

;???????????????????????????? Alarm    ??????????????????????????????????????????????
;rings once for correct finger
;rings three times fro incorrect figner, defined within Statefalse, subroutine

beepon: ; turns on beep alarm - sound generator
/*
	ldi r16, $FF		; load r16 with 0-3 input
	out DDRB , r16		; Direction register
	ldi r16, $00		; 4-7 output
	out PORTB, r16		
*/
	ldi r17, $FF
	out portB, r17
	rcall del49ms
	rcall del49ms
		rcall del49ms
	rcall del49ms
		rcall del49ms
	rcall del49ms
	ldi r17, $00
	out portB, r17
	;rcall del49ms
    ret