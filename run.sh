#!/bin/bash
mkdir -p simu
ghdl --remove --workdir=simu
ghdl -a --workdir=simu main_file.vhd
ghdl -a --workdir=simu tb_main.vhd
ghdl -e --workdir=simu tb_main
ghdl -r --workdir=simu tb_main
