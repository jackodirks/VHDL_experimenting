.global __start

__start:
        lui $4,%hi(array)
        addiu $4, $4,%lo(array)
        lui $5,%hi(L1)
        addiu $5, $5,%lo(L1)
        jalr $6, $5
        addiu $7, $0, 15
        sw $7, 4($4)
epilogue:
        j epilogue
L1:
        addiu $7, $0, 14
        sw $7, 0($4)
        jr $6
array:
    .word 0
    .word 0
