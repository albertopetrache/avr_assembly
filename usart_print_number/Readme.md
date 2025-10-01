 ## Overview

This program demonstrates how to read a 32-bit number stored in Flash memory, convert it into an ASCII decimal string, and transmit it over USART (serial communication). A static message is also sent from Flash to indicate the number being printed.

The program is written in AVR Assembly.

## Features

- Initializes the stack pointer (SP) for SRAM usage.
- Sets up USART for serial transmission at a baud rate corresponding to `F_CPU = 14.7456 MHz`.
- Converts a 32-bit number stored in Flash memory to a null-terminated ASCII string in SRAM.
- Sends strings stored in both Flash and SRAM over USART.
- Uses 32-bit division by 10 implemented bitwise to extract each decimal digit.

## Registers & Memory

- **Z register (`ZH:ZL`)** – points to data in Flash memory.
- **X register (`XH:XL`)** – points to buffer in SRAM for storing converted ASCII string.
- **r23:r20** – hold the 32-bit number during conversion.
- **r16** – holds temporary remainder and character to send via USART.
- **SRAM buffer** – stores the ASCII string representation of the number.
- **Flash** – contains the static message (`msg`) and the number variable (`var`).

## Notes

- Assumes external crystal oscillator for accurate USART baud rate. CKSEL fuse bits must be configured accordingly.
- The program runs on ATmega1284P, but can be adapted to other AVR MCUs with sufficient Flash and SRAM.
- This program demonstrates low-level bit manipulation, number conversion, and serial communication in AVR assembly.
