.global __start

__start:
        lui $4,%hi(array)
        addiu $4, $4,%lo(array)
        addiu $5, $0, 14
        addiu $6, $0, 15
        movz $5, $6, $4
        sw $5, 0($4)
        movz $6, $5, $0
        sw $6, 4($4)
epilogue:
        j epilogue
array:
    .word 0
    .word 0
