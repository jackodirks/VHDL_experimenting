.global __start
__start:
        lui $4,%hi(array)
        addiu $4, $4,%lo(array)
        li $5, 11
        jal bubbleSort
epilogue:
        j epilogue
