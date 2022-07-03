//! Reads analog input from pin A5, and uses it to control
//! digital output.
const std = @import("std");
const uno = @import("arduino-uno");
const regs = uno.atmega328p.registers;

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
    // Set baud rate.
    regs.USART0.UBRR0.modify(
        uno.usart.baudToUbrr(uno.CPU_FREQ, 115200, .asynch),
    );
    // Enable USART transmitter.
    regs.USART0.UCSR0B.modify(.{ .TXEN0 = 1 });
    // Default is 8 bits per character which is what we want.
    // No need to touch any other settings.

    const ADC = regs.ADC;
    ADC.ADMUX.modify(.{
        // Read from ADC5.
        .MUX = 0x5,
        // Use AVcc for high voltage reference.
        .REFS = 0x1,
    });
    ADC.ADCSRA.modify(.{
        // Enable ADC.
        .ADEN = 1,
        // Start the conversion.
        .ADSC = 1,
        // According to the datasheet, 50 kHz ~ 200 kHz
        // is needed for maximum resolution. The CPU
        // frequency is 16 MHz, so we choose a prescaler
        // of 128 (0x7) for an ADC frequency of 125 kHz.
        .ADPS = 0x7,
    });

    const PORTD = regs.PORTD;
    PORTD.DDRD.* = 1 << 2;

    while (true) {
        // Ensure ADC is ready to be read.
        while (ADC.ADCSRA.read().ADSC == 1) {}
        const voltage = @as(u16, ADC.ADC.read());
        delayMs(voltage / 10);
        PORTD.PORTD.* ^= 1 << 2;

        // Restart ADSC.
        ADC.ADCSRA.modify(.{ .ADSC = 1 });
    }
}
