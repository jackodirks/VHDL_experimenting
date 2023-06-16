SRCDIR=src/
CXXFILES=$(wildcard $(SRCDIR)*.cpp)
INC= -Iinc/
LIBDIR=
CXXFLAGS:=-std=gnu++20 -Wshadow=local -Wall -Wfatal-errors
CPPFLAGS:=$(INC) -MMD -MP
LDFLAGS:=
ODIR=obj/
DEBUGODIR=$(ODIR)debug/
RELEASEODIR=$(ODIR)release/
DEBUG_OFILES = $(patsubst $(SRCDIR)%,$(DEBUGODIR)%,$(patsubst %.cpp,%.cpp.o,$(CXXFILES)))
RELEASE_OFILES = $(patsubst $(SRCDIR)%,$(RELEASEODIR)%,$(patsubst %.cpp,%.cpp.o,$(CXXFILES)))
ALL_OFILES = $(DEBUG_OFILES) $(RELEASE_OFILES)
RELEASE_TARGET := final
DEBUG_TARGET := final_debug
WERROR_CONFIG := -Werror -Wno-error=unused-variable

.DEFAULT_GOAL := release

.PHONY: all clean debug release

all: release debug

release: CXXFLAGS += -O2 $(WERROR_CONFIG)
release: $(RELEASE_TARGET)

debug: CXXFLAGS += -Og -ggdb
debug: CPPFLAGS += -DDEBUG
debug: $(DEBUG_TARGET)

-include $(DEBUG_OFILES:%.o=%.d)
-include $(RELEASE_OFILES:%.o=%.d)

$(ALL_OFILES) : Makefile

$(RELEASEODIR) $(DEBUGODIR) :
	mkdir -p $@

$(DEBUGODIR)%.cpp.o: $(SRCDIR)%.cpp | $(DEBUGODIR)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

$(RELEASEODIR)%.cpp.o: $(SRCDIR)%.cpp | $(RELEASEODIR)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

$(DEBUG_TARGET): $(DEBUG_OFILES)
	$(CXX) -o $@ $^ $(LDFLAGS)

$(RELEASE_TARGET): $(RELEASE_OFILES)
	$(CXX) -o $@ $^ $(LDFLAGS)

clean:
	rm -rf $(ODIR)
	rm -f $(RELEASE_TARGET)
	rm -f $(DEBUG_TARGET)
