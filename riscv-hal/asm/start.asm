.global __start

__start:
        lui     x1,%hi(data)
        addi    x1,x1,%lo(data)
        li      x2,11
        sw      x2,0(x1)
epilogue:
        j epilogue
data:
        .word   0
