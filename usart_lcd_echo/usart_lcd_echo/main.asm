; =============================
; LCD interface with ATmega
; 4-bit communication mode
; Sends initialization commands and a string to LCD
; =============================

.equ LCD_PORT = PORTA     ; LCD data & control lines connected to PORTA
.equ LCD_DDR  = DDRA      ; Data Direction Register for LCD port
.equ RS       = PA0       ; Register Select pin (0 = command, 1 = data)
.equ EN       = PA1       ; Enable pin

.def U    = r18           ; Upper nibble temporary storage
.def L    = r19           ; Lower nibble temporary storage
.def temp = r20           ; Temporary register for RS handling


.org 0x0000
    rjmp START            ; Reset vector ? jump to program start

.org 0x100
msg: .db "Enter a string: ", 0, 0     ; String to display on LCD (null-terminated)
comenzi_lcd: .db 0x02, 0x28, 0x0C, 0x06, 0x01, 0x00 ; LCD init commands (end with 0x00)

; =============================
; Program entry point
; =============================
START:
    ; Initialize stack pointer
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

    ; Initialize LCD
    rcall init_LCD
	; Initialize USART
	rcall usart_init
	sei    

	;send string USART
	ldi ZL, low(msg*2)
	ldi ZH, high(msg*2)
	rcall usart_send_flash

hlt:
    rjmp hlt              ; Infinite loop

; =============================
; LCD Initialization
; =============================
init_LCD:
    ldi r16, 0xFF
    out LCD_DDR, r16      ; Set all PORTA pins as output
    
    rcall delay           ; Initial delay after power-up
    
    ldi ZL, low(comenzi_lcd*2)  ; Point to LCD commands in Flash
    ldi ZH, high(comenzi_lcd*2)
    rcall send_commands
    ret

; =============================
; Send initialization commands from Flash
; =============================
send_commands:
    lpm r16, Z+           ; Load next command
    tst r16               ; Check if command = 0 (end of list)
    breq send_commands_done
    clr temp              ; temp = 0 ? RS = 0 (command mode)
    rcall lcd_send
    rjmp send_commands
send_commands_done:
    ret

; =============================
; Send string characters from Flash
; =============================
send_string:
    lpm r16, Z+           ; Load next character
    tst r16               ; Check for null terminator
    breq send_string_done
    ldi temp, (1<<RS)     ; temp = RS bit set ? data mode
    rcall lcd_send
    rjmp send_string
send_string_done:
    ret

; =============================
; Unified routine to send data/commands to LCD
; Input:
;   r16 = byte (command or character)
;   temp = 0 for command, (1<<RS) for data
; =============================
lcd_send:
    push temp             ; Save RS setting
    
    ; Split into nibbles
    mov U, r16
    andi U, 0xF0          ; Upper nibble in U
    mov L, r16
    swap L                ; Move lower nibble into upper 4 bits
    andi L, 0xF0
    
    ; ----- Send upper nibble -----
    in r17, LCD_PORT      ; Read current port state
    andi r17, 0x0F        ; Clear upper nibble
    or r17, U             ; Merge with upper nibble
    pop temp              ; Restore RS
    or r17, temp          ; Apply RS setting
    out LCD_PORT, r17
    
    sbi LCD_PORT, EN      ; Pulse Enable high
    rcall delay
    cbi LCD_PORT, EN      ; Pulse Enable low
    
    ; ----- Send lower nibble -----
    push temp             ; Save RS again
    in r17, LCD_PORT
    andi r17, 0x0F
    or r17, L             ; Merge with lower nibble
    pop temp
    or r17, temp
    out LCD_PORT, r17
    
    sbi LCD_PORT, EN      ; Pulse Enable high
    rcall delay
    cbi LCD_PORT, EN      ; Pulse Enable low
    
    rcall delay           ; Extra delay for LCD processing
    ret



usart_init:
	ldi r16, 7
	sts UBRR0L, r16
	ldi r16, 0
	sts UBRR0H, r16

	ldi r16, (1<<TXEN0) | (1<<RXEN0) | (1<<RXCIE0)
	sts UCSR0B, r16
	ldi r16, (1<<UCSZ00) | (1<<UCSZ01)
	sts UCSR0C, r16
	ret

usart_send_char:
	;avem caracterul in r16
wait_udre:
	lds r17, UCSR0A
	sbrs r17, UDRE0
	rjmp wait_udre

	sts UDR0, r16
	ret

usart_send_flash:
	lpm r16, Z+
	tst r16
	breq done_flash
	rcall usart_send_char
	rjmp usart_send_flash
done_flash:
	ret


; =============================
; Simple software delay
; Adjust values for ~timing
; =============================
delay:
    ldi r16, 20
delay_loop1:
    ldi r17, 150
delay_loop2:
    dec r17
    brne delay_loop2
    dec r16
    brne delay_loop1
    ret

.org 0x0028
usart_rx_isr:
	lds r16, UDR0         ; ia caracterul primit
	ldi temp, (1<<RS)     ; RS=1 ? Data mode (scriem caracter pe LCD)
	rcall lcd_send

	; op?ional: retrimite caracterul înapoi pe serial (echo)
	rcall usart_send_char

	reti

