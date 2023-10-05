.global __start
__start:
    lui $4,%hi(source)
    addiu $4, $4,%lo(source)
    lui $5,%hi(dest)
    addiu $5, $5,%lo(dest)
    lw $2, 0($4)
    swl $2, 4($5)
    swr $2, 1($5)
epilogue:
    j epilogue

dest:
    .byte   254
    .4byte  0
source:
    .word 0xFFFFFFFF
