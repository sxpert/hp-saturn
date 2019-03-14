#!/bin/bash
#
# licence: GPLv3 or later
# 
verilator -Wall -I. --top-module saturn_top -cc \
    saturn_top.v saturn_serial.v \
    saturn_bus.v saturn_hp48gx_rom.v \
    saturn_bus_controller.v saturn_debugger.v \
    saturn_control_unit.v saturn_inst_decoder.v\
    saturn_regs_pc_rstk.v saturn_alu_module.v

