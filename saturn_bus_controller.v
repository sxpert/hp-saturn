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

module saturn_bus_controller (
    i_clk,
    i_reset,
    i_phases,
    i_phase,
    i_cycle_ctr,

    o_bus_clk_en,
    o_bus_is_data,
    o_bus_nibble_out,
    i_bus_nibble_in,

    o_debug_cycle,
    o_halt
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_reset;
input  wire [3:0]  i_phases;
input  wire [1:0]  i_phase;
input  wire [31:0] i_cycle_ctr;

output reg  [0:0]  o_bus_clk_en;
output reg  [0:0]  o_bus_is_data;
output reg  [3:0]  o_bus_nibble_out;
input  wire [3:0]  i_bus_nibble_in;

output wire [0:0]  o_debug_cycle;
output wire [0:0]  o_halt;



reg [0:0] bus_error;
initial bus_error = 0;

// this should come from the debugger
assign o_debug_cycle = 1'b0;
assign o_halt = bus_error;

always @(posedge i_clk) begin
    if (!o_debug_cycle) begin
        
    end

    if (i_reset) begin
        bus_error <= 1'b0;
    end
end

endmodule