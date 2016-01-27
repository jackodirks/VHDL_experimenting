UARTDIR := $(TOP)$(notdir $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))/
SRC +=$(wildcard $(UARTDIR)*.vhd)
