;* AsmFile1.asm
;*
;*  Created: 14/11/2017 15:41:18
;*   Authors: Nelson Talukder and Tomas Jirman
 ;Includes All action routines



;11111111111111111111111 Action 1 1111111111111111111111111111111111111111111
;Compares 2 presented fingerprints to see if they match, useful for testing 
;if a fake works
action1:
	rcall DATABASE_TO_SRAM			;Load required comparison Database inot 0x0300
	rcall Print1					;Routine to Load a fingerprint,1 into each buffer
									;Also converts to Character file
	ldi YH, high(testregister5)		;Point to the SRAM location to save confirmation
	ldi YL, low(testregister5)
	rcall send_precisematch			;Compare character files in Buffer1 and Buffer2
	rcall Bigdel
	rcall compare_basic2			;Output on LCD and Buzzer the result of Matching
	ret 



;33333333333333333333333 Action 2 3333333333333333333333333333333333333333333
;Compares a given Fingerprint to a memoory location selected by the user 

action2:				
	rcall DATABASE_TO_SRAM4			;Load the Search compare database into 0x0300
	rcall print1					;Collect FIngerprint to be compared
	
	ldi YH, high(testregister4)		;3C0   
	ldi YL, low(testregister4)
	rcall send_regmodel				;converts CHaracter files in Buffers- 
									;-to searchable template
	rcall BigDEL
	rcall DEL15ms					

get_input:							
	rcall ready2					;Loadscreen to ask for memory location to check-
	rcall waitforbuttonpress2		;-Polling, waiting for the result
	rcall convert_to_position		;Get a hex number of position from 8-bit signal
	push r18
	push r21
	push r22
	lds r21,  0x0808                ;Save ID in SRAM, needed for  instruction-
	mov r22,r21						;-code for Command Package (CP)
	lsl r22
	subi r22,$F2
	sts 0x0809, r22					;Store Checksum, for CP
	sts 0x03EB, r21					;Store Hex number
	rcall binary_to_decimal 

	pop r22
	pop r21
	pop r18

	ldi YH, high(testregister5)		;3E0
	ldi YL, low(testregister5)
	rcall send_search2				;Tailored Search Function to search only 1 location
	rcall BigDEL
	rcall compare_basic2			
	rcall BigDEL
	ret


send_search2:						;Search Function modified by this Routine-
	push r25						;Breaks up the CP into parts
	push r19
	push r23
	ldi r23, 0
	ldi r19, 2
	ldi r18, 11
	LDI ZH, HIGH(search2*2)			;Sends standard first 8 bytes
	LDI ZL, LOW(search2*2)
	rcall Mess1Out
	lds r25, 0x0808					;R25 has the ID ($xx) of the memory location
repeat:								 
	mov buffer,r23					;send $00 $xx twice
	rcall UART_send_byte			;Send $00 (Byte 9), to indicate Buffer1
	rcall UART_delay			  
	mov buffer,r25					
	rcall UART_send_byte			;Send ID (= first memory location to be searched)
	rcall UART_delay	
	dec r19
	brne repeat						;Send ID (= Last memory location to be searched)
norrepeat:							
	mov buffer,r23
	rcall UART_send_byte			;Send $00 $xx (Checksum)
	lds r25, 0x0809					;Send correcttl calculated value
	mov buffer,r25
	rcall UART_send_byte			;Second byte of checksum
	rcall UART_delay				  
	pop r23 
	pop r19
	pop r25
	ret


convert_to_position:				;Convert KEypad Signal to position (0-15)
									;r21 signal from Keypad
	push r23
	Push r24
	push r21
	;column
	sbrs r21,0						;Standard, Check each bit in signal
	ldi r23,$0						;Depending on Column, add (0,1 ,2 3)to base-
	sbrs r21,1						;-values given by rows (e.g. 0, 4, 8 or 12)
	ldi r23,$1						
	sbrs r21,2
	ldi r23,$2
	sbrs r21,3
	ldi r23,$3

	;row
	sbrs r21,4
	ldi r24,$0
	sbrs r21,5
	ldi r24,$4
	sbrs r21,6
	ldi r24,$8
	sbrs r21,7
	ldi r24,$C

	;add
	add r23,r24						
	mov r21,r23						
	sts 0x808, r21					;R21 is the hex position between $00-$0F-
	pop r21							;Saved to give ID for CP
	pop r23
	pop r24
	ret

waitforbuttonpress2:
	ldi r21, $00					;high 4-bit
	ldi r18, $00

									; set keayboard out in 									
	ldi r16, $F0					; load r16 with 0-3 input
	out DDRE , r16					; Direction register
	ldi r16, $0F					; 4-7 output
	out PORTE, r16		
	rcall DEL49ms
	in r21, PINE					;getting value from pinE	
	
	                    
									;inverse the pin output input
	ldi r16, $0F					; load r16 with 4-7 input, reverse input and ouput
	out DDRE , r16					; Direction register
	ldi r16, $F0					; 0-3 output
	out PORTE, r16		 
	rcall DEL49ms
	in r18, PINE					;getting value from pinE, red PINE again


									;R21 is the result of reading the key
	add r21, r18					;add 2 results
	
	cpi r21, $FF
	breq waitforbuttonpress2		;leaves waiting for button, if value input is not $FF
	ret




;444444444444444444444444  Action 3 4444444444444444444444444444444444444444
;general database search for match
action3:   
	rcall clrdis
	rcall DATABASE_TO_SRAM4			;Load the Search compare database into 0x0300


	rcall print1					;Collect FIngerprint to be compared
	
	ldi YH, high(testregister4)		;3C0   
	ldi YL, low(testregister4)
	rcall send_regmodel				;converts CHaracter files in Buffers- 
									;-to searchable template
	rcall BigDEL
	rcall DEL15ms					

	
	ldi YH, high(testregister5)		;3E0
	ldi YL, low(testregister5)
	rcall send_search				;General Search of Entire Database
	rcall BigDEL
	rcall compare_basic2			;Output on LCD and Buzzer the result
	rcall comparepeople				;Check to See if a name is attached to the ID
	rcall BigDEL
	rcall clrdis
	rcall send_This_is_ID			;LCD output of ID/ memory location
	rcall Password
	rcall bigdel
finalaction3: 
	ret


/*
recordspecific:						;Give Someone a unique address above th 0-15 
	push r25						;Set value for Storage function
	ldi r25, 62						;Call Storage Function
	rcall action4 
	pop r25
*/

comparepeople:						;Check for address to see if it has a name
	push r16
	lds r16, 0x03EB
	cpi r16, 60
	breq SayTomas
	cpi r16, 61
	breq SayNelson
	pop r16
	ret

SayTomas:							;Load 'Tomas' to LCD
	rcall clrdis
	LDI ZH, HIGH(2*Tomas)
    LDI ZL, LOW(2*Tomas)
    LDI r18, 7						;number of characters or bytes
	rcall Mess1More22				
	rcall password
	rcall bigdel
	rjmp finalaction3

SayNelson:							;Load 'Nelson' to LCD
	rcall clrdis
	LDI ZH, HIGH(2*Nelson)
    LDI ZL, LOW(2*Nelson)
    LDI r18, 8 
	rcall Mess1More22
	rcall password
	rcall bigdel
	rjmp finalaction3


Password:							;Load SRAM with value if verified as Admin
	push r16
	ldi r16, 22						;Checks later to see if 0x0750 = 0 for- 
	sts 0x0750, r16					;admin access
	pop r16
	ret
	

This_is_ID:							;Indicates to the User their ID will be displayed
	.db " This is the ID: "
send_This_is_ID:	
	rcall clrdis
	LDI ZH, HIGH(2*This_is_ID)
    LDI ZL, LOW(2*This_is_ID)
    LDI r18, 16						;number of characters or bytes
	rcall Mess1More22
	rcall binary_to_decimal			;COnvert Hex address to Decimal for LCD Screen
	rcall bigdel
	rcall clrdis
	ret

 ;^^^^^^^^^^^^^^^^^^^^^^^^^^Binary to decimal subroutine  ^^^^^^^^^^^^^^^^^^^^^^^^^^
 ;Capable of convertng any binary number between 0 and 15 to decimal

 binary_to_decimal:					
	push r16
	push r23
	lds r16, 0x03EB					;Load the Hex value from SRAM
	cpi r16, 10						
	brge greaterthan10
seconddigit:						;Converts the remainder to Hex by getting ascii-
	subi r16, $D0					;-value which is Hex value + $30
	rcall del49ms 
	sts $C000, r16					;displays remainder as decimal
	rcall bigdel
	pop r16
	pop r23
	ret

greaterthan10:						;Dsplays a 1 if Hex value is greater than 10
	ldi r23, $31
	sts $C000, r23
	subi r16, $0A					;get remainder
	rjmp seconddigit

;22222222222222222222222 Action 4 2222222222222222222222222222222222222222222
;Adds new fingerprint to database
action4:   
	rcall print1					;Collect Fingerprint to be compared
	ldi YH, high(testregister2)		;380    
	ldi YL, low(testregister2)
	rcall send_regmodel				;converts CHaracter files in Buffers- 
									;-to searchable template;
	rcall BigDEL

	ldi YH, high(testregister3)		;3A0   
	ldi YL, low(testregister3)
	rcall send_Store4       		;Stores the fingerprint in the next location
	rcall BigDEL

	ret


Print1:
	ldi YH, high(testregister9) 	;Generate image
	ldi YL, low(testregister9)        
	rcall send_genimg		   
	rcall BigDEL

	ldi YH, high(testregister)		;360
	ldi YL, low(testregister) 
	rcall send_img2tBuff1  			;Convert to Character file, put in Buffer 1
	rcall BigDEL    

	ldi YH, high(testregister9) 
	ldi YL, low(testregister9)
	rcall send_genimg		   
	rcall BigDEL

	ldi YH, high(testregister1)		;380
	ldi YL, low(testregister1) 
	rcall send_img2tBuff2 			;Convert to Character file, put in Buffer 2
	rcall BigDEL	
	ret

;~~~~~~~~~~~~~~~~~~~ Action 5 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;deletes database, memory 1-15 addresses
action5:
	ldi YH, high(testregister9) 	;3E0 ;Point to location to save acknolegement package
	ldi YL, low(testregister9)		;This meant the USART interrupt	knew where to store 
	rcall send_DeleteChar			;Deletes values between ID values 0 and 15
	ldi r25, 2						;Reload the place from where to start counting the ID
	rcall bigdel
	ret


;@@@@@@@@@@@@@@@@@@@@@@@@@@ Action 6 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@	
;returns number of existing stored fingerprints in the memory of scanner
action6:
	ldi YH, high(testregister6)		;400
	ldi YL, low(testregister6)
	rcall send_TempleteNum			;Gets the number of stored fingerprints
	rcall bigdel
	push r16
	
	lds r16, 0x040B
	sts 0x03EB, r16
	rcall binary_to_decimal			;Display the number
	rcall bigdel
	rcall clrdis
	pop r16
	ret
	