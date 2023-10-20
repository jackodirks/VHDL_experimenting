This is a mips32 revision 5 processor without a floating point coprocessor. Moreover, this processor does not support load-linked/store conditional, and has no MMU, so no support for paging.

# List of supported instructions, including their development progress
| Instruction | Implementation complete |
|-------------|-------------------------|
| ADD         | X                       |
| ADDI        | X                       |
| ADDIU       | X                       |
| ADDU        | X                       |
| AND         | X                       |
| ANDI        | X                       |
| BEQ         | X                       |
| BEQL        | X                       |
| BGEZ        | X                       |
| BGEZAL      | X                       |
| BGEZALL     | X                       |
| BGEZL       | X                       |
| BGTZ        | X                       |
| BGTZL       | X                       |
| BLEZ        | X                       |
| BLEZL       | X                       |
| BLTZ        | X                       |
| BLTZAL      |                         |
| BLTZALL     |                         |
| BLTZL       |                         |
| BNE         | X                       |
| BNEL        |                         |
| CLO         |                         |
| CLZ         |                         |
| DIV         |                         |
| DIVU        |                         |
| EXT         |                         |
| INS         |                         |
| J           | X                       |
| JAL         | X                       |
| JALR        |                         |
| JALR.HB     |                         |
| JR          | X                       |
| JR.HB       |                         |
| LB          | X                       |
| LBU         | X                       |
| LHU         | X                       |
| LUI         | X                       |
| LWL         | X                       |
| LWR         | X                       |
| MADD        |                         |
| MADDU       |                         |
| MFC0        | X                       |
| MFHI        |                         |
| MFLO        |                         |
| MOVZ        |                         |
| MSUB        |                         |
| MSUBU       |                         |
| MTC0        | X                       |
| MTHI        |                         |
| MTLO        |                         |
| MUL         |                         |
| MULT        |                         |
| MULTU       |                         |
| NOR         | X                       |
| OR          | X                       |
| ORI         |                         |
| ROTR        |                         |
| ROTRV       |                         |
| SB          | X                       |
| SEB         |                         |
| SEH         |                         |
| SH          |                         |
| SLL         | X                       |
| SLLV        |                         |
| SLT         | X                       |
| SLTI        |                         |
| SLTIU       |                         |
| SLTU        | X                       |
| SRA         |                         |
| SRAV        |                         |
| SRL         | X                       |
| SRLV        |                         |
| SUB         | X                       |
| SUBU        | X                       |
| SW          | X                       |
| SWL         | X                       |
| SWR         | X                       |
| WSBH        |                         |
| XOR         |                         |
| XORI        |                         |

# List of supported pseudoinstructions
| Pseudoinstruction | Actual instruction   |
|-------------------|----------------------|
| B <offset>        | BEQ r0, r0, <offset> |
| BAL <offset>      | BGEZAL r0, <offset>  |
| EZB               | SLL r0, r0, 3        |
| NOP               | SLL r0, r0, 3        |
| SSNOP             | SLL r0, r0, 1        |

# List of unsupported floating point instructions (Coprocessor 1)
- ABS.fmt
- ADD.fmt
- ALNV.PS
- BC1F
- BC1FL
- BC1T
- BC1TL
- C.cond.fmt
- CEIL.L.fmt
- CEIL.W.fmt
- CFC1
- CTC1
- CVT.D.fmt
- CVT.L.fmt
- CVT.PS.S
- CVT.S.fmt
- CVT.S.PL
- CVT.S.PU
- CVT.W.fmt
- DIV.fmt
- FLOOR.L.fmt
- FLOOR.W.fmt
- LDC1
- LDC2
- LDXC1
- LUXC1
- LWC1
- MADD.fmt
- MFC1
- MFHC1
- MOV.fmt
- MOVF
- MOVF.fmt
- MOVT
- MOVT.fmt
- MVZ.fmt
- MSUB.fmt
- MTC1
- MTHC1
- MUL.fmt
- NEG.fmt
- NMADD.fmt
- NMSUB.fmt
- PLL.PS
- PLU.PS
- PUL.PS
- PUU.PS
- RECIP.fmt
- ROUND.L.fmt
- ROUND.W.fmt
- RSQRT.fmt
- SDC1
- SDXC1
- SQRT.fmt
- SUB.fmt
- SUXC1
- SWC1
- SWXC1
- TRUNC.L.fmt
- TRUNC.W.fmt

# List of unsupported Coprocessor 2 instructions
- BC2F
- BC2FL
- BC2T
- BC2TL
- CFC2
- COP2
- CTC2
- LWC2
- MFC2
- MFHC2
- MTC2
- MTHC2
- SDC2
- SWC2

# List of other unsupported instructions

| Instruction | Note                                   |
|-------------|----------------------------------------|
| BREAK       | No debug support for now               |
| CACHE       | No Cache manipulation                  |
| CACHEE      | No MMU/virtualization                  |
| DERET       | No debug support for now               |
| DI          | No interrupt support for now           |
| EI          | No interrupt support for now           |
| ERET        | No interrupt support for now           |
| ERETNC      | No interrupt support for now           |
| JALX        | No microMIPS32 or MIPS16e              |
| LBE         | No MMU/virtualization                  |
| LBUE        | No MMU/virtualization                  |
| LHE         | No MMU/virtualization                  |
| LHUE        | No MMU/virtualization                  |
| LL          | No multithreading support for now      |
| LLE         | No MMU/virtualization                  |
| LWE         | No MMU/virtualization                  |
| LWLE        | No MMU/virtualization                  |
| LWRE        | No MMU/virtualization                  |
| MFHC0       | Coprocessor 0 has 32 bit registers     |
| MTHC0       | Coprocessor 0 has 32 bit registers     |
| PAUSE       | No multithreading support for now      |
| PREF        | No prefetch support                    |
| PREFE       | No MMU/virtualization                  |
| PREFX       | No prefetch support                    |
| RDHWR       | No privileged/unprivileged mode        |
| RDPGPR      | No shadow set for now                  |
| SBE         | No MMU/virtualization                  |
| SC          | No multithreading support for now      |
| SCE         | No MMU/virtualization                  |
| SDBBP       | No debug support for now               |
| SHE         | No MMU/virtualization                  |
| SWE         | No MMU/virtualization                  |
| SWLE        | No MMU/virtualization                  |
| SWRE        | No MMU/virtualization                  |
| SYNC        | No MMU/virtualization                  |
| SYNCI       | No write-back cache for now            |
| SYSCALL     | No execption support for now           |
| TEQ         | No exception support for now           |
| TEQI        | No exception support for now           |
| TGE         | No exception support for now           |
| TGEI        | No exception support for now           |
| TGEIU       | No exception support for now           |
| TGEU        | No exception support for now           |
| TLBINV      | No TLB                                 |
| TLBINVF     | No TLB                                 |
| TLBP        | No TLB                                 |
| TLBR        | No TLB                                 |
| TLBWI       | No TLB                                 |
| TLBWR       | No TLB                                 |
| TLT         | No exception support for now           |
| TLTI        | No exception support for now           |
| TLTIU       | No exception support for now           |
| TLTU        | No exception support for now           |
| TNE         | No exception support for now           |
| TNEI        | No exception support for now           |
| WAIT        | No exception/interrupt support for now |
| WRPGPR      | No shadow set for now                  |
