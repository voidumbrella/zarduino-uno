//! Sample code that makes the built-in LED blink.
const uno = @import("arduino-uno");
const PORTB = uno.atmega328p.registers.PORTB;

pub const panic = uno.panicHang;

fn delayMs(ms: u16) void {
    var count: u16 = ms;
    while (count > 0) : (count -= 1) {
        var loop: u16 = 0x0A52;
        while (loop > 0) : (loop -= 1) {
            asm volatile ("nop");
        }
    }
}

pub fn main() void {
    PORTB.DDRB.* |= 1 << 5;
    while (true) {
        PORTB.PORTB.* ^= 1 << 5;
        delayMs(1000);
    }
}
