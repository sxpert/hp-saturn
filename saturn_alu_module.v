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

module saturn_alu_module (
    i_clk,
    i_clk_en,
    i_reset,
    i_phases,
    i_phase,
    i_cycle_ctr,

    i_opcode,
    i_ptr_begin,
    i_ptr_end,

    i_run,
    i_done,

    i_prep_src_1_val,
    i_prep_src_2_val,
    i_prep_carry,

    i_calc_pos,
    o_calc_res_1_val,
    o_calc_res_2_val,
    o_calc_carry,
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_clk_en;
input  wire [0:0]  i_reset;
input  wire [3:0]  i_phases;
input  wire [1:0]  i_phase;
input  wire [31:0] i_cycle_ctr;

input  wire [4:0]  i_opcode;
input  wire [3:0]  i_ptr_begin;
input  wire [3:0]  i_ptr_end;

input  wire [0:0]  i_run;
input  wire [0:0]  i_done;

input  wire [3:0]  i_prep_src_1_val;
input  wire [3:0]  i_prep_src_2_val;
input  wire [0:0]  i_prep_carry;

input  wire [3:0]  i_calc_pos;
output reg  [3:0]  o_calc_res_1_val;
output reg  [3:0]  o_calc_res_2_val;
output reg  [0:0]  o_calc_carry;

always @(*) begin
    o_calc_res_1_val = 4'h0;
    o_calc_res_2_val = 4'h0;
    o_calc_carry     = 2'b0;
    if (i_clk_en && i_run && !i_done) begin
        case (i_opcode) 
            `ALU_OP_ZERO: $display("ALU      %0d: [%d] res1 <= 0", i_phase, i_cycle_ctr);
            default:      $display("ALU      %0d: [%d] invalid ALU opcode %0d", i_phase, i_cycle_ctr, i_opcode);
        endcase
    end
end

endmodule