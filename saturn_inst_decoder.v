/*
    (c) Raphaël Jacquot 2019
    
		This file is part of hp_saturn.

    hp_saturn is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    any later version.

    hp_saturn is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <https://www.gnu.org/licenses/>.

 */

`default_nettype none

`include "saturn_def_alu.v"

module saturn_inst_decoder (
    i_clk,
    i_reset,
    i_phases,
    i_phase,
    i_cycle_ctr,
    i_debug_cycle,

    i_bus_busy,

    i_nibble,
    i_reg_p,
    i_current_pc,

    o_alu_reg_dest,
    o_alu_reg_src_1,
    o_alu_reg_src_2,
    o_alu_imm_value,
    o_alu_opcode,

    o_instr_type,
    o_instr_decoded,
    o_instr_execute,

    /* debugger interface */
    o_dbg_inst_addr
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_reset;
input  wire [3:0]  i_phases;
input  wire [1:0]  i_phase;
input  wire [31:0] i_cycle_ctr;
input  wire [0:0]  i_debug_cycle;

input  wire [0:0]  i_bus_busy;

input  wire [3:0]  i_nibble;
input  wire [3:0]  i_reg_p;
input  wire [19:0] i_current_pc;

output reg  [4:0]  o_alu_reg_dest;
output reg  [4:0]  o_alu_reg_src_1;
output reg  [4:0]  o_alu_reg_src_2;
output reg  [3:0]  o_alu_imm_value;
output reg  [4:0]  o_alu_opcode;

output reg  [3:0]  o_instr_type;
/* instruction is fully decoded */
output reg  [0:0]  o_instr_decoded;
/* instruction is sufficiently decoded to start execution */
output reg  [0:0]  o_instr_execute;

/*
 * debugger interface
 */
/* address of the last instruction */
output reg  [19:0] o_dbg_inst_addr;

/**************************************************************************************************
 *
 * sub-modules go here
 *
 *************************************************************************************************/




/**************************************************************************************************
 *
 * the decoder module
 *
 *************************************************************************************************/

/*
 * process state variables
 */

reg [0:0] just_reset;
reg [0:0] decode_started;

/*
 * decoder block variables
 */

reg [0:0] block_2x;

/*
 * initialization
 */

initial begin
    o_alu_reg_dest  = `ALU_REG_NONE;
    o_alu_reg_src_1 = `ALU_REG_NONE;
    o_alu_reg_src_2 = `ALU_REG_NONE;
    o_alu_imm_value = 4'b0;
    o_alu_opcode    = `ALU_OP_NOP;

    o_instr_type    = 4'd15;
    o_instr_decoded = 1'b0;
    o_instr_execute = 1'b0;

    /* debugger interface */
    o_dbg_inst_addr = 20'b0;

    /* internal registers */
    just_reset      = 1'b1;
    decode_started  = 1'b0;

    block_2x        = 1'b0;
end

/****************************
 *
 * main process
 *
 */

always @(posedge i_clk) begin
  
    /*
     * only do something when nothing is busy doing some other tasks
     * either talking to the bus, or debugging something
     */

    if (!i_debug_cycle && i_bus_busy && i_phases[2] && just_reset) begin
        // $display("DECODER  %0d: [%d] dump registers right after reset", i_phase, i_cycle_ctr);
        just_reset      <= 1'b0;
        o_instr_decoded <= 1'b1;
    end

    if (!i_debug_cycle && !i_bus_busy) begin
 
        if (i_phases[1] && !decode_started) begin
            $display("DECODER  %0d: [%d] store current PC as instruction start %5h", i_phase, i_cycle_ctr, i_current_pc);
        end

        if (i_phases[2] && !decode_started) begin
            $display("DECODER  %0d: [%d] start instruction decoding %h", i_phase, i_cycle_ctr, i_nibble);

            decode_started <= 1'b1;
            case (i_nibble)
                4'h2: block_2x <= 1'b1;
            endcase
        end

        if (i_phases[2] && decode_started) begin
            $display("DECODER  %0d: [%d] decoding %h", i_phase, i_cycle_ctr, i_nibble);

            if (block_2x) begin
                $display("DECODER  %0d: [%d] P= %h", i_phase, i_cycle_ctr, i_nibble);
                o_alu_reg_dest  <= `ALU_REG_P;
                o_alu_reg_src_1 <= `ALU_REG_IMM;
                o_alu_reg_src_2 <= `ALU_REG_NONE;
                o_alu_imm_value <= i_nibble;
                o_alu_opcode    <= `ALU_OP_COPY;
                o_instr_type    <= `INSTR_TYPE_ALU;
                o_instr_decoded <= 1'b1;
                o_instr_execute <= 1'b1;
                block_2x        <= 1'b0;
                decode_started  <= 1'b0;
            end

        end

        if (i_phases[3]) begin
            // $display("DECODER  %0d: [%d] decoder cleanup", i_phase, i_cycle_ctr);
            o_instr_decoded <= 1'b0;
            o_instr_execute <= 1'b0;
        end

    end


    if (i_reset) begin
        /* stuff that needs reset */
        o_alu_reg_dest  <= `ALU_REG_NONE;
        o_alu_reg_src_1 <= `ALU_REG_NONE;
        o_alu_reg_src_2 <= `ALU_REG_NONE;
        o_alu_imm_value <= 4'b0;
        o_alu_opcode    <= `ALU_OP_NOP;

        o_instr_type    <= 4'd15;
        o_instr_decoded <= 1'b0;
        o_instr_execute <= 1'b0;

        /* debugger interface */
        o_dbg_inst_addr <= 20'b0;

        /* internal registers */
        just_reset      <= 1'b1;
        decode_started  <= 1'b0;

        block_2x        <= 1'b0;
    end

end


endmodule
