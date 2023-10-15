.global __start
__start:
        lui $4,%hi(array)
        addiu $4, $4,%lo(array)
        lw $5, 0($4)
        addiu $6, $0, 0
L1:
        addiu $5, $5, -1
        addiu $6, $6, 1
        bgez $5, L1
        sw $6, 4($4)
epilogue:
        j epilogue
array:
    .word 4
    .word 0
