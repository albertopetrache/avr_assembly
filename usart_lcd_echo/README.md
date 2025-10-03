# AVR LCD & USART Text Input Project

This project implements a **text input system** using an AVR microcontroller, a **16x2 LCD** (driven in 4-bit mode), and **USART serial communication**.  
The system allows the user to type text from a PC terminal (via UART), display it live on the LCD, and supports **line wrapping**, **Enter for line switching**, and **Backspace** for deletion (with proper cursor and memory management).  
All input handling is interrupt-driven via the **USART RX ISR**.

---

## Features

- LCD 16x2 in 4-bit mode (D4–D7 for data, RS/EN for control).
- USART serial input (characters sent from PC appear on LCD).
- Supports two lines of text input.
- Backspace handling:
  - Deletes the last character on the current line.
  - Moves back to the previous line if the cursor is at the start of line 2.
- Enter handling:
  - Moves from line 1 to line 2.
  - Pressing Enter again on line 2 jumps back to line 1.
- Tracks cursor position in software (`cursor_cnt`) to avoid LCD misalignment.
- Stores line length for line 1 (`line1_len`) to restore the cursor after line switches.

---

## How It Works

### Startup
- Initializes stack pointer, LCD, and USART.
- Sends an initial string (`"Enter a string: "`) over UART.
- Positions LCD cursor at the start of line 1.

### LCD Handling
- Commands and data are sent nibble-wise (4-bit interface).
- Cursor position and line state are tracked in registers.
- Functions:
  - `lcd_send_cmd` – send LCD commands.
  - `lcd_send_data` – send characters (increments cursor).
  - `lcd_send_data_no_inc` – overwrite without cursor move (used in backspace).
  - `lcd_send_cmd_direct` – position cursor explicitly.

### USART Handling
- Configured for 8-bit data, RX/TX enabled, RX interrupt enabled.
- ISR (`usart_rx_isr`) handles incoming characters:
  - Normal chars → displayed on LCD.
  - Backspace (0x08) → deletes character, updates cursor/line.
  - Enter (0x0D) → switches line.

---

## USART RX ISR Logic

- Normal char:  
  Calls `lcd_send_data`, increments cursor, stores length if on line 1.  

- Backspace:  
  - If not at column 0 → move cursor left, overwrite with space, move back.  
  - If at start of line 2 → switch back to line 1 and restore cursor to `line1_len`.  

- Enter:  
  - On line 1 → save current length, move to line 2 (0xC0).  
  - On line 2 → reset cursor to start of line 1 (0x80).  

---

## Hardware Connections

| LCD Pin | AVR Pin |
|---------|---------|
| RS      | PA0     |
| EN      | PA1     |
| D4      | PA4     |
| D5      | PA5     |
| D6      | PA6     |
| D7      | PA7     |
| RW      | GND     |

- USART:  
  - TXD0 ↔ PC RX (USB-Serial adapter).  
  - RXD0 ↔ PC TX.  
- VCC/GND connected for LCD + MCU.  
- Potentiometer for LCD contrast.

---

## Hardware Schematic

![LCD & USART schematic](https://github.com/user-attachments/assets/7ce8ed14-79b5-4143-bb22-4c29f21102df)

---

## Registers & Variables

- **U (r18), L (r19):** Nibble registers for LCD transfers.  
- **cursor_cnt (r22):** Current cursor position on the active line (0–15).  
- **line (r23):** Current line (0 = line 1, 1 = line 2).  
- **line1_len (r24):** Length of text entered on line 1 (used when jumping back).  

---

## Usage

1. Assemble the code (e.g., with `avra` or `avr-gcc -mmcu=atmegaXX`).
2. Flash the hex file to the AVR MCU.
3. Connect LCD and serial interface as described.
4. Open a serial terminal (baud rate set in `usart_init`, e.g. 9600).
5. Start typing:
   - Characters appear on LCD.
   - Enter → switch lines.
   - Backspace → delete characters, including across lines.

---

## Notes

- LCD commands respect timing via `delay` subroutine.
- System is interrupt-driven, so the main loop is empty (`rjmp main_loop`).
- RW is grounded (write-only mode) for simplicity.
- Cursor handling is done in software, not via LCD auto-increment alone, to enable proper backspace and line switching.
