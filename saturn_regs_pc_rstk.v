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

module saturn_regs_pc_rstk (
    i_clk,
    i_clk_en,
    i_reset,
    i_phases,
    i_phase,
    i_cycle_ctr,

    i_bus_busy,

    i_nibble,
    i_jump_instr,
    i_jump_length,

    o_current_pc,
    o_reload_pc
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_clk_en;
input  wire [0:0]  i_reset;
input  wire [3:0]  i_phases;
input  wire [1:0]  i_phase;
input  wire [31:0] i_cycle_ctr;

input  wire [0:0]  i_bus_busy;

input  wire [3:0]  i_nibble;
input  wire [0:0]  i_jump_instr;
input  wire [2:0]  i_jump_length;

output wire [19:0] o_current_pc;
output reg  [0:0]  o_reload_pc;

/**************************************************************************************************
 *
 * pc and rstk handling module
 *
 *************************************************************************************************/

wire [0:0]  do_jump_instr = !just_reset && i_jump_instr;

/*
 * local variables
 */

reg  [0:0]  just_reset;
reg  [0:0]  jump_decode;
reg  [0:0]  jump_exec;
reg  [2:0]  jump_counter;
reg  [19:0] jump_base;
reg  [19:0] jump_offset;

wire [0:0]  jump_rel2 = i_jump_instr && (i_jump_length == 3'd1);
wire [0:0]  jump_rel3 = i_jump_instr && (i_jump_length == 3'd2);
wire [0:0]  jump_rel4 = i_jump_instr && (i_jump_length == 3'd3);
wire [0:0]  jump_abs5 = i_jump_instr && (i_jump_length == 3'd4);
wire [0:0]  jump_relative = jump_rel2 || jump_rel3 || jump_rel4;

reg  [19:0] jump_next_offset;

always @(*) begin
    case (jump_counter)
        3'd0: jump_next_offset = { {16{1'b0}}, i_nibble};
        3'd1: jump_next_offset = { {12{jump_rel2?i_nibble[3]:1'b0}} , i_nibble, jump_offset[ 3:0]};
        3'd2: jump_next_offset = { { 8{jump_rel3?i_nibble[3]:1'b0}} , i_nibble, jump_offset[ 7:0]};
        3'd3: jump_next_offset = { { 4{jump_rel4?i_nibble[3]:1'b0}} , i_nibble, jump_offset[11:0]};
        3'd4: jump_next_offset = { i_nibble, jump_offset[15:0]};
        default: jump_next_offset = 20'h00000;
    endcase
end


reg  [19:0] PC;

assign o_current_pc = PC;

initial begin
    o_reload_pc  = 1'b0;
    just_reset   = 1'b1;
    jump_decode  = 1'b0;
    jump_exec    = 1'b0;
    jump_counter = 3'd0;
    PC           = 20'h00000;
end

/*
 * the process
 */

always @(posedge i_clk) begin
  
    /*
     * only do something when nothing is busy doing some other tasks
     * either talking to the bus, or debugging something
     */

    // if (!i_debug_cycle)
    //     $display("PC_RSTK  %0d: [%d] !i_bus_busy %b", i_phase, i_cycle_ctr, !i_bus_busy);

    if (i_clk_en && !i_bus_busy) begin

        if (i_phases[3] && just_reset) begin
            $display("PC_RSTK  %0d: [%d] exit from reset mode", i_phase, i_cycle_ctr);
            just_reset <= 1'b0;
        end

        if (i_phases[1] && !just_reset) begin
            $display("PC_RSTK  %0d: [%d] inc_pc %5h => %5h", i_phase, i_cycle_ctr, PC, PC + 20'h00001);
            PC <= PC + 20'h00001;
        end

        /* 
         * jump instruction calculations
         */ 

        /* start the jump instruction */
        if (i_phases[3] && do_jump_instr && !jump_decode && !jump_exec) begin
            $display("PC_RSTK  %0d: [%d] start decode jump %0d | jump_base %5h", i_phase, i_cycle_ctr, i_jump_length, PC);
            jump_counter <= 3'd0;
            jump_base    <= PC;
            jump_decode  <= 1'b1;
        end

        /* one step of the calculation (one nibble of data came in) */
        if (i_phases[2] && do_jump_instr && jump_decode) begin
            $display("PC_RSTK  %0d: [%d] decode jump %0d/%0d %h %5h", i_phase, i_cycle_ctr, i_jump_length, jump_counter, i_nibble, jump_next_offset);
            jump_offset  <= jump_next_offset;
            jump_counter <= jump_counter + 3'd1;
            if (jump_counter == i_jump_length) begin
                jump_decode <= 1'b0;
                jump_exec   <= 1'b1;
                o_reload_pc <= 1'b1;
            end
        end

        /* all done, apply to PC */
        if (i_phases[3] && do_jump_instr && jump_exec) begin
            $display("PC_RSTK  %0d: [%d] execute jump %0d ", i_phase, i_cycle_ctr, i_jump_length);
            PC          <= jump_relative ? jump_offset + jump_base : jump_offset;
            jump_exec   <= 1'b0;
            o_reload_pc <= 1'b0;
        end

    end

    if (i_reset) begin
        o_reload_pc  <= 1'b0;
        just_reset   <= 1'b1;
        jump_decode  <= 1'b0;
        jump_exec    <= 1'b0;
        jump_counter <= 3'd0;
        PC           <= 20'h00000;
    end
end

endmodule