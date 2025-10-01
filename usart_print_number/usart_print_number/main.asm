;
; usart_print_number.asm
;
; Created: 10/1/2025 3:59:25 PM
; Author : Alberto
;


.org 0x0000
    rjmp start          ; Reset vector ? jump to start of program


; =========================
; Data Segment (SRAM)
; =========================
.dseg
buffer: .byte 20        ; Reserve 20 bytes in SRAM for converted number


; =========================
; Code Segment (Flash / Program Memory)
; =========================
.cseg
.org 0x100
msg: .db "The number is: ", 0   ; Null-terminated string stored in Flash
var: .dd 98234                  ; 32-bit constant stored in Flash


; =========================
; Program Start
; =========================
start:
    ; Initialize the stack pointer (SP) to top of SRAM
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

    ; Initialize USART (serial communication)
    rcall usart_init

    ; --- Print message from Flash ---
    ldi ZL, low(msg*2)      ; Z register points to "msg" (program memory uses word addressing ? *2)
    ldi ZH, high(msg*2)
    rcall usart_send_flash  ; Send string over USART

    ; --- Load number from Flash ---
    ldi ZL, low(var*2)      ; Z points to "var"
    ldi ZH, high(var*2)

    ldi XL, low(buffer)     ; X points to buffer in SRAM
    ldi XH, high(buffer)
    rcall add_in_buffer     ; Convert number ? ASCII string into buffer

    ; --- Send converted number from SRAM ---
    rcall usart_send_sram

hlt:
    rjmp hlt                ; Infinite loop (program ends here)


; =========================
; Convert number from Flash to ASCII decimal string
; Input: Z points to 32-bit number in Flash
; Output: ASCII string stored in SRAM at X
; =========================
add_in_buffer:
    ; Load 32-bit value from Flash into r23:r20
    lpm r20, Z+             ; Byte0 ? LSB
    lpm r21, Z+
    lpm r22, Z+
    lpm r23, Z+             ; Byte3 ? MSB

conv_loop:
    rcall divmod10_32       ; Divide number by 10, remainder in r16
    subi r16, -'0'          ; Convert remainder to ASCII ('0'..'9')
    st X+, r16              ; Store digit in buffer

    ; Check if quotient is zero ? continue if not
    tst r20
    brne conv_loop
    tst r21
    brne conv_loop
    tst r22
    brne conv_loop
    tst r23
    brne conv_loop

    ; Null-terminate string
    ldi r16, 0
    st X, r16
    ret


; =========================
; 32-bit Division by 10
; Input: r23:r20 = 32-bit value
; Output: quotient in r23:r20, remainder in r16
; =========================
divmod10_32:
    clr r24                 ; Temporary remainder
    clr r16                 ; Final remainder
    ldi r25, 32             ; Number of bits to process

div_loop:
    ; Shift 32-bit value left, building remainder in r24
    lsl r20
    rol r21
    rol r22
    rol r23
    rol r24

    ; If remainder >= 10, subtract 10 and set LSB of quotient
    cpi r24, 10
    brlo no_sub
    subi r24, 10
    ori r20, 1
no_sub:
    dec r25
    brne div_loop

    mov r16, r24            ; Store final remainder in r16
    ret


; =========================
; USART Initialization
; Baud rate: UBRR0 = 7 ? works for F_CPU = 14.7456 MHz
; Note: This value assumes an external crystal oscillator. If using external quartz, CKSEL fuse bits must be configured.
; =========================
usart_init:
    ldi r16, 7               ; UBRR0 low byte ? sets baud rate for 14.7456 MHz
    sts UBRR0L, r16
    ldi r16, 0               ; UBRR0 high byte
    sts UBRR0H, r16

    ; Enable receiver (RX) and transmitter (TX)
    ldi r16, (1<<RXEN0) | (1<<TXEN0)
    sts UCSR0B, r16

    ; Set frame format: 8 data bits, 1 stop bit
    ldi r16, (1<<UCSZ00) | (1<<UCSZ01)
    sts UCSR0C, r16
    ret



; =========================
; Send one character via USART
; Input: r16 = character
; =========================
usart_send_char:
wait_udre:
    lds r17, UCSR0A
    sbrs r17, UDRE0         ; Wait until transmit buffer empty
    rjmp wait_udre
    sts UDR0, r16           ; Send character
    ret


; =========================
; Send null-terminated string from Flash
; Input: Z points to string in Flash
; =========================
usart_send_flash:
    lpm r16, Z+             ; Load char from Flash
    tst r16
    breq done_flash         ; If zero ? end of string
    rcall usart_send_char
    rjmp usart_send_flash
done_flash:
    ret


; =========================
; Send null-terminated string from SRAM
; Input: X points to string in SRAM
; =========================
usart_send_sram:
    ld r16, -X              ; Load char (walking backwards!)
    tst r16
    breq done_sram
    rcall usart_send_char
    rjmp usart_send_sram
done_sram:
    ret

