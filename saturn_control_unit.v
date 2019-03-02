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

`include "saturn_def_buscmd.v" 

module saturn_control_unit (
    i_clk,
    i_reset,
    i_phases,
    i_phase,
    i_cycle_ctr,
    i_debug_cycle,

    i_bus_busy,

    o_program_data,
    o_program_address,

    o_no_read,
    i_nibble,

    o_error
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_reset;
input  wire [3:0]  i_phases;
input  wire [1:0]  i_phase;
input  wire [31:0] i_cycle_ctr;
input  wire [0:0]  i_debug_cycle;

input  wire [0:0]  i_bus_busy;

output reg  [4:0]  o_program_data;
output reg  [4:0]  o_program_address;

output reg  [0:0]  o_no_read;
input  wire [3:0]  i_nibble;

output wire [0:0]  o_error;
assign o_error = control_unit_error;

/**************************************************************************************************
 *
 * cpu modules go here
 *
 *************************************************************************************************/


/**************************************************************************************************
 *
 * the control unit
 *
 *************************************************************************************************/

reg [0:0] control_unit_error;
reg [0:0] just_reset;
reg [0:0] control_unit_ready;
reg [4:0] bus_prog_addr;

initial begin
    o_program_address  = 5'd31;
    o_program_data     = 5'd0;
    o_no_read          = 1'b0;
    control_unit_error = 1'b0;
    just_reset         = 1'b1;
    control_unit_ready = 1'b0;
    bus_prog_addr      = 5'd0;
end

always @(posedge i_clk) begin

    if (!i_debug_cycle && just_reset && i_phases[3]) begin
        /* this happend right after reset */
`ifdef SIM
        if (!i_reset)
            $display("CTRL     %0d: [%d] we are in the control unit", i_phase, i_cycle_ctr);
`endif
        just_reset        <= 1'b0;
        o_program_data    <= {1'b1, `BUSCMD_LOAD_PC };
`ifdef SIM
        $display("CTRL     %0d: [%d] pushing LOAD_PC command to pos %d", i_phase, i_cycle_ctr, bus_prog_addr);
`endif
        /* push the current program pointer out,  
         * increment the program pointer 
         */
        o_program_address <= bus_prog_addr;
        bus_prog_addr     <= bus_prog_addr + 1;
    end 

    /* loop to fill the initial PC value in the program */
    if (!i_debug_cycle && !control_unit_ready && (bus_prog_addr != 5'b0)) begin
        o_program_data    <= 5'b0;
        o_program_address <= bus_prog_addr;
        bus_prog_addr     <= bus_prog_addr + 1;
`ifdef SIM
        $write("CTRL     %0d: [%d] pushing ADDR[%0d] = 0", i_phase, i_cycle_ctr, bus_prog_addr);
`endif
        if (bus_prog_addr == 5'd5) begin
            control_unit_ready <= 1'b1;
`ifdef SIM
            $write(" done");
`endif
        end
`ifdef SIM
        $write("\n");
`endif
    end
    
    /* this happend otherwise */
    if (!i_debug_cycle && control_unit_ready && !i_bus_busy) begin
        
// `ifdef SIM
        // $display("CTRL     %0d: [%d] starting to do things", i_phase, i_cycle_ctr);
// `endif
        if (i_cycle_ctr == 10) begin
            control_unit_error <= 1'b1;
            $display("CTRL     %0d: [%d] enough cycles for now", i_phase, i_cycle_ctr);
        end

        if (i_phases[2]) begin
            $display("CTRL     %0d: [%d] interpreting %h", i_phase, i_cycle_ctr, i_nibble);
        end
    end

    if (i_reset) begin
        o_program_address  <= 5'd31;
        o_program_data     <= 5'd0;
        o_no_read          <= 1'b0;
        control_unit_error <= 1'b0;
        just_reset         <= 1'b1;
        control_unit_ready <= 1'b0;
        bus_prog_addr      <= 5'd0;
    end

end

endmodule



