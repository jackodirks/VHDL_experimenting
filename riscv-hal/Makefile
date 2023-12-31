AS:=riscv32-none-elf-as
GCC:=riscv32-none-elf-gcc
LD:=riscv32-none-elf-ld
OBJCOPY:=riscv32-none-elf-objcopy
ASMDIR:=asm/
SRCDIR:=src/
ODIR=obj/
OFILES := $(patsubst %.asm,%.asm.o,$(wildcard $(ASMDIR)*.asm))
OFILES += $(patsubst %.c,%.c.o,$(wildcard $(SRCDIR)*.c))
OFILES += $(patsubst %.c,%.c.o,$(wildcard $(SRCDIR)*.c))
OFILES := $(patsubst $(ASMDIR)%,$(ODIR)%,$(OFILES))
OFILES := $(patsubst $(SRCDIR)%,$(ODIR)%,$(OFILES))
TARGET:=final
TARGETBIN:=final.bin
TARGETTXT:=final.txt
LDFLAGS := -Wl,--gc-sections -nodefaultlibs -lc -lgcc
CFLAGS := -Wall -Wextra
ARCHFLAGS := -march=rv32i -mabi=ilp32
.PHONY: all release clean

all: release
release: $(TARGETTXT)

$(ODIR):
	mkdir -p $(@)

$(ODIR)%.asm.o: $(ASMDIR)%.asm | $(ODIR)
	$(AS) $(ARCHFLAGS) $< -o $@

$(ODIR)%.c.o: $(SRCDIR)%.c | $(ODIR)
	$(GCC) $(CFLAGS) $(ARCHFLAGS) -Iinc -mbranch-cost=2 -O3 -c $< -o $@

$(TARGET): $(OFILES)
	$(GCC) -o $@ $^ $(LDFLAGS) -Tlinker_script.ld $(ARCHFLAGS)

$(TARGETBIN): $(TARGET)
	$(OBJCOPY) -j .text -j .data -j .bss -O binary $^ $@

$(TARGETTXT): $(TARGETBIN)
	od --address-radix=n --output-duplicates --width=4 --format=x4 $^ | tr -d ' ' > $@

clean:
	rm -rf $(ODIR) $(TARGET) $(TARGETBIN) $(TARGETTXT)
