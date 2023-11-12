.global __start

__start:
        lui     x5,%hi(data)
        addi    x5,x5,%lo(data)
        lw      x6,0(x5)
        li      x7,0
L1:
        addi    x7,x7,1
        blt     x7,x6,L1
        sw      x7,4(x5)
epilogue:
        j epilogue
data:
        .word   7
        .word   0
