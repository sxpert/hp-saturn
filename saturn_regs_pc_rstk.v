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

    o_current_pc

);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_clk_en;
input  wire [0:0]  i_reset;
input  wire [3:0]  i_phases;
input  wire [1:0]  i_phase;
input  wire [31:0] i_cycle_ctr;

input  wire [0:0]  i_bus_busy;

input  wire [3:0]  i_nibble;

output wire [19:0] o_current_pc;

/**************************************************************************************************
 *
 * pc and rstk handling module
 *
 *************************************************************************************************/

/*
 * local variables
 */

reg  [0:0]  just_reset;

reg  [19:0] PC;

assign o_current_pc = PC;

initial begin
    just_reset  = 1'b1;
    PC          = 20'h00000;
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
    end

    if (i_reset) begin
        just_reset  <= 1'b1;
        PC          <= 20'h00000;
    end
end

endmodule