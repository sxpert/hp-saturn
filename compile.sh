#!/bin/bash
#
# licence: GPLv3 or later
#


#yosys -p "synth_ecp5 -top saturn_core -json saturn_core.json" saturn_core.v
yosys make_saturn.ESP5.ys
YOSYS_STATUS=$?
echo "--------------------------------------------------------------------"
echo "YOSYS_STATUS ${YOSYS_STATUS}"
echo "--------------------------------------------------------------------"

time nextpnr-ecp5 --85k --speed 6 --freq 50 --lpf ulx3s_v20.lpf --textcfg z_saturn_test.config --json z_saturn_test.json

echo "--------------------------------------------------------------------"
echo "Running ecppack"
echo "--------------------------------------------------------------------"
time ecppack z_saturn_test.config z_saturn_test.bit