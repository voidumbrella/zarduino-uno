//! Universal Synchronous and Asynchronous Serial Receiver and Transmitter
//!
//! # Baud rate
//!     The baud rate is set by the UBRR registers 12-bit number, given by
//!         UBRR = f_OSC / (D*BAUD) - 1
//!     where
//!         f_OSC is the system oscillator clock frequency in Hz,
//!         BAUD is the baud rate in bps (bits per second),
//!         and D is the baud rate divisor depending on the mode,
//!     * asynchronous mode: D = 16
//!     * asynchronous double speed mode: D = 8
//!     * synchronous master mode: D = 2
//!
//! # Frame formats
//!     A frame is one character of data bits with synchronization bits
//!     (and an optional parity bit). It consists of:
//!     * 1 start bit, always low,
//!     * 5 to 9 data bits (see UCSZ02:0 bits in UCSR0B register),
//!     * 0 or 1 parity bits (see UPM01:0 bits in UCSR0C register), and
//!     * 1 or 2 stop bits, always high (see USBS0 bit in UCSR0C register),
//!     * followed by high bits for an idle communication line.
//!
//! # Parity Bit
//!     The parity bit is calculated by XORing all data bits.
//!     If odd parity is used, this bit is then inverted.

const atmega328p = @import("atmega328p.zig");
const regs = @import("atmega328p.zig").registers;
const USART0 = regs.USART0;

pub const UsartMode = enum {
    asynch,
    asynch_double,
    synch,
};

/// Calculates what needs to be writen to the UBRR register for the given baud rate.
pub fn baudToUbrr(comptime f_osc: comptime_int, comptime baud_rate: comptime_int, comptime mode: UsartMode) u12 {
    const denom = switch (mode) {
        .asynch => 16 * baud_rate,
        .asynch_double => 8 * baud_rate,
        .synch => 2 * baud_rate,
    };
    return (f_osc + denom / 2) / denom - 1;
}
