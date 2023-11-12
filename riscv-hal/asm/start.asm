.global __start

__start:
        lui     x5,%hi(data)
        addi    x5,x5,%lo(data)
        lw      x6,0(x5)
        addi    x6,x6,7
        sw      x6,4(x5)
epilogue:
        j epilogue
data:
        .word   7
        .word   0
