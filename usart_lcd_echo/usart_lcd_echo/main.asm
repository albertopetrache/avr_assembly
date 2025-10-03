; =============================
; LCD & control pin definitions
.equ LCD_PORT = PORTA
.equ LCD_DDR  = DDRA
.equ RS       = PA0       ; Register Select pin
.equ EN       = PA1       ; Enable pin

; General purpose registers
.def U         = r18
.def L         = r19
.def cursor_cnt= r22       ; Current cursor position on current line (0..15)
.def line      = r23       ; Current line: 0 = line 1, 1 = line 2
.def line1_len = r24       ; Number of characters written on line 1

; =============================
.org 0x0000
    rjmp START             ; Reset vector

.org 0x100
; =============================
msg: .db "Enter a string: ",0,0       ; Initial message to send via USART
comenzi_lcd: .db 0x02,0x28,0x0C,0x06,0x01,0x00  ; LCD initialization commands

; =============================
START:
    ; Initialize stack pointer
    ldi r16, high(RAMEND)
    out SPH,r16
    ldi r16, low(RAMEND)
    out SPL,r16

    ; Initialize LCD and USART
    rcall init_LCD
    rcall usart_init
    sei                        ; Enable global interrupts

    ; Initialize cursor state
    ldi cursor_cnt,0
    ldi line,0
    ldi line1_len,0
    ldi r16,0x80               ; DDRAM address of start of line 1
    rcall lcd_send_cmd_direct

    ; Send initial message via USART
    ldi ZL, low(msg*2)
    ldi ZH, high(msg*2)
    rcall usart_send_flash

main_loop:
    rjmp main_loop             ; Main loop does nothing, all handled in ISR

; =============================
init_LCD:
    ldi r16,0xFF
    out LCD_DDR,r16            ; Set LCD port as output
    rcall delay
    ldi ZL, low(comenzi_lcd*2)
    ldi ZH, high(comenzi_lcd*2)
    rcall send_commands
    ret

send_commands:
    lpm r16,Z+
    tst r16
    breq send_commands_done
    rcall lcd_send_cmd
    rjmp send_commands
send_commands_done:
    ret

; =============================
lcd_send_cmd:
    push r16
    rcall lcd_send
    pop r16
    ret

; Send a character to LCD (increment cursor)
lcd_send_data:
    cpi cursor_cnt,16
    brsh ignore_char           ; Ignore if line full

    push r16
    sbi LCD_PORT,RS            ; Set RS=1 for data
    rcall lcd_send
    cbi LCD_PORT,RS
    pop r16

    inc cursor_cnt
    
    ; Update line 1 length if writing on line 1
    cpi line,0
    brne ignore_char
    mov line1_len,cursor_cnt
ignore_char:
    ret

; Send character without incrementing cursor
lcd_send_data_no_inc:
    push r16
    sbi LCD_PORT,RS
    rcall lcd_send
    cbi LCD_PORT,RS
    pop r16
    ret

; Send data/command to LCD (4-bit mode)
lcd_send:
    mov U,r16
    andi U,0xF0
    mov L,r16
    swap L
    andi L,0xF0

    ; Send upper nibble
    in r17,LCD_PORT
    andi r17,0x0F
    or r17,U
    out LCD_PORT,r17
    sbi LCD_PORT,EN
    rcall delay
    cbi LCD_PORT,EN

    ; Send lower nibble
    in r17,LCD_PORT
    andi r17,0x0F
    or r17,L
    out LCD_PORT,r17
    sbi LCD_PORT,EN
    rcall delay
    cbi LCD_PORT,EN

    rcall delay
    ret

; =============================
usart_init:
    ldi r16,7
    sts UBRR0L,r16             ; Set baud rate low byte
    ldi r16,0
    sts UBRR0H,r16             ; Set baud rate high byte
    ldi r16,(1<<TXEN0)|(1<<RXEN0)|(1<<RXCIE0)
    sts UCSR0B,r16             ; Enable TX, RX, RX interrupt
    ldi r16,(1<<UCSZ00)|(1<<UCSZ01)
    sts UCSR0C,r16             ; 8-bit data
    ret

usart_send_char:
wait_udre:
    lds r17,UCSR0A
    sbrs r17,UDRE0
    rjmp wait_udre
    sts UDR0,r16
    ret

usart_send_flash:
    lpm r16,Z+
    tst r16
    breq done_flash
    rcall usart_send_char
    rjmp usart_send_flash
done_flash:
    ret

; =============================
delay:
    ldi r16,20
delay_loop1:
    ldi r17,150
delay_loop2:
    dec r17
    brne delay_loop2
    dec r16
    brne delay_loop1
    ret

; =============================
.org 0x0028
usart_rx_isr:
    lds r16,UDR0

    ; Check for backspace
    cpi r16,0x08
    breq handle_backspace

    ; Check for Enter
    cpi r16,0x0D
    breq enter_pressed

    ; Normal character input
    rcall lcd_send_data    
    reti

; =============================
handle_backspace:
    ; If cursor is not at start of line
    cpi cursor_cnt,0
    breq check_previous_line
    
    ; Delete current character
    dec cursor_cnt
    
    ; Move cursor left
    ldi r16,0x10
    rcall lcd_send_cmd_direct

    ; Overwrite with space
    ldi r16,' '
    rcall lcd_send_data_no_inc

    ; Move cursor left again
    ldi r16,0x10
    rcall lcd_send_cmd_direct
    
    ; Update line 1 length if needed
    cpi line,0
    brne backspace_done
    mov line1_len,cursor_cnt
    
backspace_done:
    reti

; Move to previous line if on line 2
check_previous_line:
    cpi line,1
    brne ignore_backspace       ; Stop if already on line 1

    ; Switch to line 1
    ldi line,0
    mov cursor_cnt,line1_len
    
    ; Position cursor correctly on last character of line 1
    ldi r16,0x80
    add r16,line1_len
    rcall lcd_send_cmd_direct
    reti

ignore_backspace:
    reti

; =============================
enter_pressed:
    cpi line,0
    brne enter_on_line2
    
    ; Enter pressed on line 1: save length and move to line 2
    mov line1_len,cursor_cnt
    ldi r16,0xC0
    rcall lcd_send_cmd_direct
    ldi cursor_cnt,0
    ldi line,1
    reti

enter_on_line2:
    ; Enter pressed on line 2: return to line 1
    ldi r16,0x80
    rcall lcd_send_cmd_direct
    ldi cursor_cnt,0
    ldi line,0
    reti

; =============================
lcd_send_cmd_direct:
    push r16
    cbi LCD_PORT,RS           ; RS=0 for command
    rcall lcd_send
    sbi LCD_PORT,RS           ; Restore RS=1 for data
    pop r16
    ret
