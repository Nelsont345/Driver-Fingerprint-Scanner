

^^^^^^^^^^^^^^^^^^^^^^^ Initialisation ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	ldi r16, (1<<RXEN1)|(1<<RXCIE1)		;enable receive, enables interrupt
	sts UCSR1B,r16 						;control and status reigster for USART1, 
;										 dealing with recepetion
	ldi r16, (1<<USBS1)|(3<<UCSZ10)   	;Set frame format: 8data, 2stop bit
	sts UCSR1C,r16						;control and status register for Byte
;										 size
	push r16							;Set BAUD rate
	push r17
	ldi r16, $08												
	ldi r17, $00	
	sts UBRR1H, r17						;register for frequency
	sts UBRR1L, r16	
	pop r17
	pop r16
	
	sei									;enable interrupts


^^^^^^^^^^^^^^^^^^^^^^^ Called Interrupt ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

save_data_start352:
	push r17
	lds r17, UDR1
	st Y+, r17 							; store bit received 
	pop r17								;to UART to memomry location
	reti								;return from interrupt
