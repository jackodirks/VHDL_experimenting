.global __start
__start:
        lui $4,%hi(array)
        addiu $4, $4,%lo(array)
        lw $5, 0($4)
        andi $5, $5, 0x2f2f
        sw $5, 4($4)
epilogue:
        j epilogue
array:
    .word 0x0000f1f1
    .word 0
