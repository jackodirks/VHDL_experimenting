INCLUDEFLAGS = -i --work=$(WORKNAMEPREFIX) --std=$(STD) --workdir=$(WORKDIR)
BUILDFLAGS = -m --work=$(WORKNAMEPREFIX) --std=$(STD) --workdir=$(WORKDIR)
RUNFLAGS = -r --work=$(WORKNAMEPREFIX) --std=$(STD) --workdir=$(WORKDIR)
VIEWFLAGS = --stdout
CLEANFLAGS = --remove --workdir=$(WORKDIR)
