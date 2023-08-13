#!/bin/bash
BASEDIR="/home/jacko/opt/Xilinx/Vivado/2023.1"
source ${BASEDIR}/settings64.sh
${BASEDIR}/bin/vivado -mode tcl -source upload.tcl -log /tmp/executeTcl.log -journal /tmp/executeTcl.jou
