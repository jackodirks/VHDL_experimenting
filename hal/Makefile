AS:=mips-elf-as
GCC:=mips-elf-gcc
LD:=mips-elf-ld
OBJCOPY:=mips-elf-objcopy
ASMDIR:=asm/
SRCDIR:=src/
ODIR=obj/
OFILES := $(patsubst %.asm,%.asm.o,$(wildcard $(ASMDIR)*.asm))
OFILES += $(patsubst %.c,%.c.o,$(wildcard $(SRCDIR)*.c))
OFILES := $(patsubst $(ASMDIR)%,$(ODIR)%,$(OFILES))
OFILES := $(patsubst $(SRCDIR)%,$(ODIR)%,$(OFILES))
TARGET:=final
TARGETBIN:=final.bin
TARGETTXT:=final.txt
LDFLAGS :=

.PHONY: all release clean

all: release
release: $(TARGETTXT)

$(ODIR):
	mkdir -p $(@)

$(ODIR)%.asm.o: $(ASMDIR)%.asm | $(ODIR)
	$(AS) -EL -mips32 $< -o $@

$(ODIR)%.c.o: $(SRCDIR)%.c | $(ODIR)
	$(GCC) -EL -mips32 -O3 -c $< -o $@

$(TARGET): $(OFILES)
	$(LD) -EL -o $@ $^ $(LDFLAGS) -Tlinker_script.ld

$(TARGETBIN): $(TARGET)
	$(OBJCOPY) -j .text -j .data -j .bss -O binary $^ $@

$(TARGETTXT): $(TARGETBIN)
	od --address-radix=n --output-duplicates --width=4 --format=x4 $^ | tr -d ' ' > $@

clean:
	rm -rf $(ODIR) $(TARGET) $(TARGETBIN) $(TARGETTXT)
