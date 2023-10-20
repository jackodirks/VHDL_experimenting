.global __start

__start:
        lui $4,%hi(array)
        addiu $4, $4,%lo(array)
        lw $5, 0($4)
        bgtz $5, epilogue
        lw $5, 4($4)
        bgtz $5, epilogue
        li $6, 14
        sw $6, 12($4)
        lw $5, 8($4)
        bgtz $5, L2
        j epilogue
L2:
        li $6, 14
        sw $6, 16($4)
epilogue:
        j epilogue
array:
    .word -1
    .word 0
    .word 1
    .word 0
    .word 0
