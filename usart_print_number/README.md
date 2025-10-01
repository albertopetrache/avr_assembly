# usart_print_number.asm

**Author:** Alberto  
**Date:** 10/1/2025  
**Microcontroller:** ATmega1284P  

## Overview

This program demonstrates how to read a 32-bit number stored in Flash memory, convert it into an ASCII decimal string, and transmit it over USART (serial communication). A static message is also sent from Flash to indicate the number being printed.

The program is written in AVR Assembly.

## Features

- Initializes the stack pointer (SP) for SRAM usage.
- Sets up USART for serial transmission at a baud rate corresponding to `F_CPU = 14.7456 MHz`.
- Converts a 32-bit number stored in Flash memory to a null-terminated ASCII string in SRAM.
- Sends strings stored in both Flash and SRAM over USART.
- Uses 32-bit division by 10 implemented bitwise to extract each decimal digit.
- Simulated in Proteus to verify functionality.  

## Registers & Memory

- **Z register (`ZH:ZL`)** – points to data in Flash memory.
- **X register (`XH:XL`)** – points to buffer in SRAM for storing converted ASCII string.
- **r23:r20** – hold the 32-bit number during conversion.
- **r16** – holds temporary remainder and character to send via USART.
- **SRAM buffer** – stores the ASCII string representation of the number.
- **Flash** – contains the static message (`msg`) and the number variable (`var`).

## Number Conversion Process

1. **Load the 32-bit number from Flash**: The program uses the `lpm` instruction to read each byte of the number from Flash memory into registers `r20` (LSB) to `r23` (MSB).

2. **Divide the number by 10 repeatedly**: A custom 32-bit division routine (`divmod10_32`) shifts the number left bit by bit while building a remainder. This implements the standard long division algorithm at the bit level.

3. **Extract decimal digits**: After each division, the remainder corresponds to the next decimal digit of the number. This remainder is converted to its ASCII representation by adding `'0'` (0x30) and stored sequentially in SRAM.

4. **Build a null-terminated string**: The digits are stored in SRAM, and a null byte (`0x00`) is added at the end to mark the string termination for later USART transmission.

5. **Send the number via USART**: The program reads the ASCII characters from SRAM in reverse order (to account for the digit extraction order) and sends them one by one over the serial port.

## Proteus Simulation

Below is an example of the simulation setup in Proteus:

<img width="852" height="632" alt="image" src="https://github.com/user-attachments/assets/ea301b0a-7f29-4f70-874d-a8dd1475d8fe" />


## Notes

- Assumes external crystal oscillator for accurate USART baud rate. CKSEL fuse bits must be configured accordingly.
- The program runs on ATmega1284P, but can be adapted to other AVR MCUs with sufficient Flash and SRAM.
- This program demonstrates low-level bit manipulation, number conversion, and serial communication in AVR assembly.
