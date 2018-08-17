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

all: $(WORKFILE)

run: $(TARGET)

timedRun: BENCHFLAGS += --stop-time=$(MAXRUNTIME)
timedRun: $(TARGET)

$(WORKDIR) :
	@mkdir -p $@

$(WORKFILE) : $(SRC) | $(WORKDIR)
	$(GHDL) $(INCLUDEFLAGS) $?
	$(GHDL) $(BUILDFLAGS) $(TESTBENCH)

$(TARGET) : $(WORKFILE)
	$(GHDL) $(RUNFLAGS) $(TESTBENCH) $(BENCHFLAGS)

view: $(TARGET)
	$(VIEWER) $(TARGET) &>/dev/null &

clean:
	$(GHDL) --remove --workdir=$(WORKDIR) --std=$(STD)

distclean :
	rm -rf $(WORKDIR)
	rm *.o
	rm $(TESTBENCH)
