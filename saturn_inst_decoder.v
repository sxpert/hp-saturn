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

module saturn_inst_decoder (
    i_clk,
    i_reset,
    i_phases,
    i_phase,
    i_cycle_ctr,
    i_debug_cycle,

    i_bus_busy,

    i_nibble
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_reset;
input  wire [3:0]  i_phases;
input  wire [1:0]  i_phase;
input  wire [31:0] i_cycle_ctr;
input  wire [0:0]  i_debug_cycle;

input  wire [0:0]  i_bus_busy;

input  wire [3:0]  i_nibble;

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
 * main process
 */

always @(posedge i_clk) begin

    
    /*
     * only do something when nothing is busy doing some other tasks
     * either talking to the bus, or debugging something
     */

    if (!i_debug_cycle && !i_bus_busy) begin
 
        if (i_phases[2]) begin
            $display("DECODER  %0d: [%d] decoding", i_phase, i_cycle_ctr);
            
        end

        if (i_phases[3]) begin
            $display("DECODER  %0d: [%d] decoder cleanup", i_phase, i_cycle_ctr);
        end

    end


    if (i_reset) begin
        /* stuff that needs reset */
    end

end


endmodule
