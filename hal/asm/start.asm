.global __start

__start:
        lui $4,%hi(array)
        addiu $4, $4,%lo(array)
        lw $5, 0($4)
        rotr $5, $5, 12
        sw $5, 4($4)
epilogue:
        j epilogue
array:
    .word 0x0a0b0c0d
    .word 0
