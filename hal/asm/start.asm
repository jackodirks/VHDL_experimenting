.global __start
__start:
        lui $2,%hi(array)
        addiu $2, $2,%lo(array)
        lw $10,0x0($2)
        lw $11,0x4($2)
        add $12, $10, $11
        sw $12,0x8($2)
        j __start
array:
    .word 1
    .word 2
    .word 0
