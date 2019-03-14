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
iverilog -v -Wall -DSIM -o z_saturn_test.iv -s saturn_top \
    saturn_top.v saturn_serial.v \
    saturn_bus.v saturn_hp48gx_rom.v saturn_hp48gx_mmio.v \
    saturn_bus_controller.v saturn_debugger.v \
    saturn_control_unit.v saturn_inst_decoder.v\
    saturn_regs_pc_rstk.v #saturn_alu_module.v
IVERILOG_STATUS=$?
#./mask_gen_tb
echo "--------------------------------------------------------------------"
echo "IVERILOG_STATUS ${IVERILOG_STATUS}"
echo "--------------------------------------------------------------------"
if [ "${IVERILOG_STATUS}" = "0" ] 
then
    ./z_saturn_test.iv
fi
#vvp mask_gen_tb -lxt2
#gtkwave output.vcd
