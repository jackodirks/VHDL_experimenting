include mk/flags.mk
include mk/compilers.mk
include mk/emptyvars.mk
include mk/predefined.mk

TESTBENCHFILE := tb_main.vhd
TESTBENCH := tb_main
SRC += $(TESTBENCHFILE)
WORKFILE = $(WORKDIR)$(WORKNAMEPREFIX)-$(WORKNAMESUFFIX)
TARGET = $(WORKDIR)$(TESTBENCH).ghw

TOP := ./
DIRS := $(shell ls -d */)
DIRS := $(DIRS:=rules.mk)

-include $(DIRS)

.PHONY: all clean run simulate pre-build distclean timedRun

.DELETE_ON_ERROR:

all: pre-build
all: $(WORKFILE)

run: pre-build
run: $(TARGET)

timedRun: pre-build
timedRun: BENCHFLAGS += --stop-time=$(MAXRUNTIME)
timedRun: $(TARGET)

pre-build:
	@mkdir -p $(WORKDIR)

$(WORKFILE) : $(SRC)
	$(GHDL) $(INCLUDEFLAGS) $^
	$(GHDL) $(BUILDFLAGS) $(TESTBENCH)

$(TARGET) : $(WORKFILE)
	$(GHDL) $(RUNFLAGS) $(TESTBENCH) $(BENCHFLAGS)

simulate: run
	$(VIEUWER) $(TARGET)

clean:
	$(GHDL) $(CLEANFLAGS)

distclean :
	rm -rf $(WORKDIR)
