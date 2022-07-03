//! Sample code that writes transmits through USART.
//! It generates random printable ASCII characters.
const uno = @import("arduino-uno");
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

    write("\r\nhere comes another chinese earthquake\r\n");

    // xorshift rng
    var x: u32 = 65535;
    while (true) {
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
        // Specify printable ASCII values.
        const ch = @truncate(u8, x) % 0x5e + 0x21;
        writeByte(@truncate(u8, ch));
    }
}
