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

module saturn_debugger (
    i_clk,
    i_reset,
    i_phases,
    i_phase,
    i_cycle_ctr,

    o_debug_cycle,

    /* interface from the control unit */
    i_alu_reg_dest,
    i_alu_reg_src_1,
    i_alu_reg_src_2,
    i_alu_imm_value,
    i_alu_opcode,

    i_instr_type,
    i_instr_decoded
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_reset;
input  wire [3:0]  i_phases;
input  wire [1:0]  i_phase;
input  wire [31:0] i_cycle_ctr;

output reg  [0:0]  o_debug_cycle;

/* inteface from the control unit */
input  wire [4:0] i_alu_reg_dest;
input  wire [4:0] i_alu_reg_src_1;
input  wire [4:0] i_alu_reg_src_2;
input  wire [3:0] i_alu_imm_value;
input  wire [4:0] i_alu_opcode;

input  wire [3:0] i_instr_type;
input  wire [0:0] i_instr_decoded;

/**************************************************************************************************
 *
 * debugger process registers
 *
 *************************************************************************************************/

reg [3:0] counter;

initial begin
    o_debug_cycle = 1'b0;
end

/**************************************************************************************************
 *
 * debugger process 
 *
 *************************************************************************************************/

always @(posedge i_clk) begin

    if (i_phases[3] && i_instr_decoded) begin
        $display("DEBUGGER %0d: [%d] start debugger cycle", i_phase, i_cycle_ctr);
        o_debug_cycle <= 1'b1;
        counter <= 3'b0;
    end

    if (o_debug_cycle) begin
        $display("DEBUGGER %0d: [%d] debugger %0d", i_phase, i_cycle_ctr, counter);
        counter <= counter + 1;
        if (counter == 15) begin
            $display("DEBUGGER %0d: [%d] end debugger cycle", i_phase, i_cycle_ctr);
            o_debug_cycle <= 1'b0;
        end
    end

    if (i_reset) begin
        o_debug_cycle <= 1'b0;
    end

end

endmodule

