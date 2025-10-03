# LCD & USART Text Input Project

This project demonstrates a simple text input system using an AVR microcontroller with a 16x2 LCD and USART communication. The program allows typing characters via a serial terminal, displaying them on the LCD, handling **Enter** for line changes, and **Backspace** for deleting characters correctly.

---

## Features

- 16x2 LCD interfaced in **4-bit mode**
- USART input/output for serial communication
- Supports **two lines** of text input
- Correct cursor tracking across lines
- Proper **Backspace handling**:
  - Deletes characters on the current line
  - Moves to the previous line if the cursor is at the start of line 2
- Handles **Enter** key:
  - Moves from line 1 to line 2
  - Loops back to line 1 after line 2

---

## Hardware Connections

| LCD Pin | AVR Pin  |
|---------|----------|
| RS      | PA0      |
| EN      | PA1      |
| D4      | PORTA4   |
| D5      | PORTA5   |
| D6      | PORTA6   |
| D7      | PORTA7   |

> Note: Make sure to connect RW to GND for write-only mode.

**Additional:**

- USART TX/RX pins connected to a serial terminal.
- VCC/GND properly connected to power the LCD and AVR.

<img width="1131" height="818" alt="image" src="https://github.com/user-attachments/assets/7ce8ed14-79b5-4143-bb22-4c29f21102df" />

> Replace `schematic.png` with your actual schematic image.

---

## Registers and Variables

- **U (r18), L (r19):** Temporary registers for LCD nibbles
- **cursor_cnt (r22):** Current cursor position on the active line (0..15)
- **line (r23):** Active line (0 = line 1, 1 = line 2)
- **line1_len (r24):** Number of characters written on line 1 (used for backspace)

---

## Usage

1. Compile the assembly code using AVR tools (e.g., `avr-gcc`/`avra`).
2. Program the microcontroller.
3. Open a serial terminal at the configured baud rate (set in `usart_init`).
4. Type characters:
   - Characters appear on the LCD.
   - Press **Enter** to move to the next line.
   - Press **Backspace** to delete characters (including moving from line 2 to line 1 when needed).

---

## Notes

- LCD commands are sent in **4-bit mode**.
- The code manages cursor and line lengths to avoid misalignment during backspacing.
- Delays are used to satisfy LCD timing requirements.
