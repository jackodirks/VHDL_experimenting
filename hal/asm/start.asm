.global __start
__start:
        lui $2,%hi(array)
        addiu $2, $2,%lo(array)
        li $3, 4
        li $10, 0
L1:
        addiu $10, $10, 1
        bne $3, $10, L1
        sw $10,0x0($2)
        jal func
        j __start
func:
        sll $10, $10, 1
        sw $10,0x4($2)
        jr $31
array:
    .word 0
    .word 0
