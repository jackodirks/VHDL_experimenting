.global __start

__start:
        j actual_start
dont_hit:
        j dont_hit
hit:
        addiu $5, $0, 14
        sw $5, 8($4)
        jr $31
actual_start:
        addiu $31, $0, 0
        lui $4,%hi(array)
        addiu $4, $4,%lo(array)
        lw $5, 0($4)
        bltzal $5, dont_hit
        sw $31, 16($4)
        lw $5, 4($4)
        bltzall $5, hit
        addiu $5, $0, 14
        sw $5, 12($4)
epilogue:
        j epilogue
array:
    .word 10
    .word -20
    .word 0
    .word 0
    .word 0
