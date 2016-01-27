SSDIR := $(TOP)$(notdir $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))/
SRC +=$(wildcard $(SSDIR)*.vhd)
