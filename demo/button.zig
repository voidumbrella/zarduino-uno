//! Detects button inputs.
//! Reads button presses from PORTD2 (Pin 2 on the Arduino board),
//! and toggles the LED connected to PORTD3 (Pin 3).
const uno = @import("arduino-uno");
const PORTD = uno.atmega328p.registers.PORTD;
const USART0 = uno.atmega328p.registers.USART0;

pub const panic = uno.panicHang;

/// Computes the quotient and remainder of two 8 bit integers.
/// Apparently I need to manually define this because zig can't use avr-libc.
/// Shamelessly taken from http://www.rjhcoding.com/avr-asm-8bit-division.php
///
/// See:
///     https://gcc.gnu.org/wiki/avr-gcc#Exceptions_to_the_Calling_Convention
///
/// In:
///     r24 (dividend)
///     r22 (divisor)
/// Out:
///     r24 (quotient)
///     r25 (remainder)
/// Clobbers:
///     r23
export fn __udivmodqi4() callconv(.Naked) void {
    asm volatile (
        \\  sub r25, r25   ; clear remainder and carry
        \\  ldi r23, 9     ; loop counter (looping over each bit)
        \\.L1:
        \\  rol r24        ; left shift dividend into carry
        \\  dec r23        ; decrement loop counter
        \\  brne .L2       ; if loop counter is zero
        \\  ret
        \\.L2:
        \\  rol r25        ; left shift carry into remainder
        \\  sub r25, r22   ; remainder -= divisor
        \\  brcc .L3       ; if result negative
        \\  add r25, r22   ;    restore remainder
        \\  clc            ;    clear carry to be shifted into result
        \\  rjmp .L1
        \\.L3:             ; else
        \\  sec            ;    set carry to be shifted into result
        \\  rjmp .L1
        ::: "r23");
}

fn delayMs(ms: u16) void {
    var count: u16 = ms;
    while (count > 0) : (count -= 1) {
        var loop: u16 = 0x0A52;
        while (loop > 0) : (loop -= 1) {
            asm volatile ("nop");
        }
    }
}

pub fn writeByte(c: u8) void {
    // Wait until transmitter is ready.
    while (USART0.UCSR0A.read().UDRE0 == 0) {}
    USART0.UDR0.* = c;
}

pub fn write(buf: []const u8) void {
    for (buf) |c| writeByte(c);
    // Wait until transmitter is done.
    while (USART0.UCSR0A.read().TXC0 == 0) {}
}

pub fn main() void {
    // Set baud rate.
    USART0.UBRR0.modify(
        uno.usart.baudToUbrr(uno.CPU_FREQ, 115200, .asynch),
    );
    // Enable USART transmitter.
    USART0.UCSR0B.modify(.{ .TXEN0 = 1 });
    // Default is 8 bits per character which is what we want.
    // No need to touch any other settings.

    // Set input/output pins.
    PORTD.DDRD.* &= ~@as(u8, 1 << 2);
    PORTD.DDRD.* |= 1 << 3;

    var count: u8 = 0;
    var pressed = PORTD.PIND.* & (1 << 2) != 0;
    while (true) {
        delayMs(50);
        var state_changed = pressed != (PORTD.PIND.* & (1 << 2) != 0);
        if (state_changed) {
            if (!pressed) {
                // Toggle LED
                PORTD.PORTD.* ^= 1 << 3;
            } else {
                // Turn off LED
                PORTD.PORTD.* ^= 1 << 3;

                count += 1;
                write("Button was pressed ");
                var digits = count;

                const msd = digits / 100;
                if (msd > 0) writeByte('0' + msd);
                digits -= msd * 100;

                const nsd = digits / 10;
                if (nsd > 0) writeByte('0' + nsd);
                digits -= nsd * 10;

                const lsd = digits;
                writeByte('0' + lsd);
                write(" times.\r\n");
            }
            pressed = !pressed;
        }
    }
}
