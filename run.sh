#!/bin/bash
#
# licence: GPLv3 or later
# 
# verilator -Wall -I. --top-module saturn_core -cc saturn-core.v hp48_bus.v hp48_io_ram.v hp48_rom.v bus_commands.v
# VERILATOR_STATUS=$?
# if [ "VERILATOR_STATUS" != "0" ]
# then
#     echo "verilator fail"
#     #exit
# fi
#iverilog -v -Wall -DSIM -o mask_gen_tb mask_gen.v
iverilog -v -g2005-sv -gassertions -Wall -DSIM -o rom_tb saturn_core.v
IVERILOG_STATUS=$?
#./mask_gen_tb
echo "--------------------------------------------------------------------"
echo "IVERILOG_STATUS ${IVERILOG_STATUS}"
echo "--------------------------------------------------------------------"
if [ "${IVERILOG_STATUS}" = "0" ] 
then
    ./rom_tb
fi
#vvp mask_gen_tb -lxt2
#gtkwave output.vcd