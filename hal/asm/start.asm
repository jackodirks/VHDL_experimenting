.global __start
__start:
    lui $4,%hi(source)
    addiu $4, $4,%lo(source)
    lui $5,%hi(dest)
    addiu $5, $5,%lo(dest)
    lwl $2, 4($4)
    lwr $2, 1($4)
    sw  $2, 0($5)    
epilogue:
    j epilogue

source:
    .byte   1
    .4byte  32
dest:
    .word 0
