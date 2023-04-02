MEMORY
{
    SRAM (rwx) : ORIGIN = 0x100000, LENGTH = 0x60000
}

SECTIONS
{
    .text :
    {
        *(.text)
    } > SRAM

    .data : 
    {
        *(.data)
    } > SRAM

    .bss : 
    {
        *(.data)
    } > SRAM
}
