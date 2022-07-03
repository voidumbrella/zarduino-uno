MEMORY
{
    flash (rx) : ORIGIN = 0, LENGTH = 32K
    ram (rw!x) : ORIGIN = 0x800100, LENGTH = 2K
}

SECTIONS
{
    .text :
    {
        KEEP (*(.vectors .vectors.*))
        *(.text .text.*)
    } > flash
    .data :
    {
        __sdata = .;
        *(.rodata*)
        *(.data*)
        __edata = .;
    } > ram AT > flash
    .bss (NOLOAD) :
    {
        __sbss = .;
        *(.bss*)
        __ebss = .;
    } > ram
    __load_start = LOADADDR(.data);
}
