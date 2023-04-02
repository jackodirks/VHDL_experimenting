AS:=mipsel-linux-gnu-as
LD:=mipsel-linux-gnu-ld
OBJCOPY:=mipsel-linux-gnu-objcopy
ASMDIR:=asm/
ODIR=obj/
OFILES := $(patsubst %.asm,%.asm.o,$(wildcard $(ASMDIR)*.asm))
OFILES := $(patsubst $(ASMDIR)%,$(ODIR)%,$(OFILES))
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
	$(AS) -mips2 $< -o $@ 

$(TARGET): $(OFILES) 
	$(LD) -o $@ $^ $(LDFLAGS) -Tlinker_script.ld

$(TARGETBIN): $(TARGET)
	$(OBJCOPY) -j .text -j .data -j .bss -O binary $^ $@

$(TARGETTXT): $(TARGETBIN)
	od --address-radix=n --output-duplicates --width=4 --format=x4 $^ | tr -d ' ' > $@

clean:
	rm -rf $(ODIR) $(TARGET) $(TARGETBIN) $(TARGETTXT)
