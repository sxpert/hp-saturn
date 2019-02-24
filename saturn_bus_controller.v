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

module saturn_bus_controller (
    i_clk,
    i_reset,

    o_bus_reset,
    o_bus_clk_en,
    o_bus_is_data,
    o_bus_nibble_out,
    i_bus_nibble_in,

    o_halt
);

input  wire [0:0] i_clk;
input  wire [0:0] i_reset;

output reg  [0:0] o_bus_reset;
output reg  [0:0] o_bus_clk_en;
output reg  [0:0] o_bus_is_data;
output reg  [3:0] o_bus_nibble_out;
input  wire [3:0] i_bus_nibble_in;

output wire [0:0] o_halt;



reg [0:0] bus_error;
initial bus_error = 0;

assign o_halt = bus_error;




endmodule