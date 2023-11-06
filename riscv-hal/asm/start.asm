.global __start

__start:
        nop
        lui     a0,%hi(array_int32)
        addi    a0,a0,%lo(array_int32)
        li      a1,11
        call    bubbleSort_int32
epilogue:
        j epilogue
array_size:
        .word   11
