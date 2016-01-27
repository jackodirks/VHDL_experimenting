#!/bin/bash
mkdir -p work
ghdl --remove --workdir=work
ghdl -i --work=work --std=93c --workdir=work *.vhd
ghdl -m --work=work --std=93c --workdir=work tb_main
ghdl -r --work=work --std=93c --workdir=work tb_main --vcd=work/tb_main.vcd
gtkwave work/tb_main.vcd
