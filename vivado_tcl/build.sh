#!/bin/bash
BASEDIR="${HOME}/opt/Xilinx/Vivado/2023.1"
source ${BASEDIR}/settings64.sh
${BASEDIR}/bin/vivado -mode tcl -source build.tcl -nolog -nojournal -notrace
