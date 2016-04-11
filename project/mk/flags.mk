TIMESEED := $(shell date +%s)
INCLUDEFLAGS = -i --work=$(WORKNAMEPREFIX) --std=$(STD) --workdir=$(WORKDIR)
BUILDFLAGS = -m --work=$(WORKNAMEPREFIX) --std=$(STD) --workdir=$(WORKDIR) -gSEED=$(TIMESEED)
RUNFLAGS = -r --work=$(WORKNAMEPREFIX) --std=$(STD) --workdir=$(WORKDIR) -gSEED=$(TIMESEED)
VIEWFLAGS = --stdout
CLEANFLAGS = --remove --workdir=$(WORKDIR)
