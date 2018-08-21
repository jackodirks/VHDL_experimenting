TIMESEED := $(shell date +%s)
INCLUDEFLAGS = -i --work=$(WORKNAMEPREFIX) --std=$(STD) --workdir=$(WORKDIR)
BUILDFLAGS = -m --work=$(WORKNAMEPREFIX) --std=$(STD) --workdir=$(WORKDIR)
RUNFLAGS = -r --work=$(WORKNAMEPREFIX) --std=$(STD) --workdir=$(WORKDIR)
BENCHFLAGS = --wave=$@ -gSEED=$(TIMESEED)
VIEWFLAGS = --stdout
CLEANFLAGS = --remove --workdir=$(WORKDIR)
GHDL := ghdl
VIEWER := gtkwave
SRC :=
WORKDIR ?= work/
WORKNAMEPREFIX ?= work
WORKNAMESUFFIX ?= obj93.cf
STD ?= 93
MAXRUNTIME ?= 50000ns

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
