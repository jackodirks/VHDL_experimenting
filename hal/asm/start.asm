.global __start
__start:
        lui $4,%hi(array_int32)
        addiu $4, $4,%lo(array_int32)
        li $5, 11
        jal bubbleSort_int32
        lui $4,%hi(array_int16)
        addiu $4, $4,%lo(array_int16)
        li $5, 11
        jal bubbleSort_int16
        lui $4,%hi(array_int8)
        addiu $4, $4,%lo(array_int8)
        li $5, 11
        jal bubbleSort_int8
epilogue:
        j epilogue
