.global __start

__start:
        lui $4,%hi(array)
        addiu $4, $4,%lo(array)
        lw $5, 0($4)
        bgezal $5, L2
        li $6, 14
        sw $6, 4($4)
epilogue:
        j epilogue
L2:
        jr $31
array:
    .word 1
    .word 0
