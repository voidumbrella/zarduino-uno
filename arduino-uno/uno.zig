pub const atmega328p = @import("atmega328p.zig");
pub const usart = @import("usart.zig");

pub const CPU_FREQ = 16000000;

comptime {
    asm (
        \\.vectors:
        \\  jmp _start                  ; Reset
        \\  jmp _unhandled_interrupt    ; External interrupt request 0
        \\  jmp _unhandled_interrupt    ; External interrupt request 1
        \\  jmp _unhandled_interrupt    ; TODO: fill me out
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
        \\  jmp _unhandled_interrupt    ;
    );
}

export fn _unhandled_interrupt() callconv(.Naked) noreturn {
    @panic("unhandled interrupt");
}

/// Reset vector
export fn _start() callconv(.Naked) noreturn {
    asm volatile (
        \\  ;;; Copy .data section from flash to RAM.
        \\  ; load data source address to Z register
        \\  ldi r30, lo8(__load_start)
        \\  ldi r31, hi8(__load_start)
        \\  ; load data destination start address to X register
        \\  ldi r26, lo8(__sdata)
        \\  ldi r27, hi8(__sdata)
        \\  ; load data destination end address
        \\  ldi r24, lo8(__edata)
        \\  ldi r25, hi8(__edata)
        \\
        \\.L_data_loop:
        \\  cp r26, r24
        \\  cpc r27, r25 ; check if reached end of section
        \\  breq .L_data_loop_end
        \\  lpm r18, Z+  ; read from address pointed by Z and...
        \\  st X+, r18   ; ... and write to address pointed by X
        \\  rjmp .L_data_loop
        \\.L_data_loop_end:
        \\
        \\  ;;; Zero oub .bss section.
        \\  ; load bss start address to X register
        \\  ldi r26, lo8(__sbss)
        \\  ldi r27, hi8(__sbss)
        \\  ; load bss end address
        \\  ldi r24, lo8(__ebss)
        \\  ldi r25, hi8(__ebss)
        \\  clr r16
        \\
        \\.L_bss_loop:
        \\  cp r26, r24
        \\  cpc r27, r25 ; check if reached end of section
        \\  breq .L_bss_loop_end
        \\  st X+, r16
        \\  rjmp .L_bss_loop
        \\.L_bss_loop_end:
        \\
        \\ ;;; Initialize stack pointer to the top of SRAM
        \\ ldi r24, 0x08
        \\ out 0x3E, r24
        \\ ldi r24, 0xFF
        \\ out 0x3D, r24
        \\
        \\main:
        ::: "memory", "r16", "r24", "r25", "r26", "r27", "r30", "r31");

    @import("root").main();
    while (true) {
        asm volatile (
            \\ sleep
        );
    }
}

/// Panic handler that just enters an infinite loop.
pub fn panicHang(_: []const u8, _: ?*@import("std").builtin.StackTrace) noreturn {
    @setCold(true);
    while (true) {}
}
