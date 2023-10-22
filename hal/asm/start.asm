.global __start

__start:
        lui $4,%hi(array)
        addiu $4, $4,%lo(array)
        lw $5, 0($4)
        lw $6, 4($4)
        ext $7, $5, 16, 8
        ins $6, $7, 8, 8
        sw $6, 8($4)
epilogue:
        j epilogue
array:
    .word 0x1a2b3c4d
    .word 0xffffffff
    .word 0
