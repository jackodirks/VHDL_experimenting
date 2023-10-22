.global __start

__start:
        lui $4,%hi(array)
        addiu $4, $4,%lo(array)
        lw $5, 0($4)
        clo $6, $5 
        sw $6, 8($4)
        lw $5, 4($4)
        clz $6, $5 
        sw $6, 12($4)
epilogue:
        j epilogue
array:
    .word 0xff800000
    .word 0x0010000f
    .word 0
    .word 0
