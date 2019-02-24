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

module saturn_hp48gx_rom (
    i_clk,
    i_reset,

    i_bus_reset,
    i_bus_clk_en,
    i_bus_is_data,
    o_bus_nibble_out,
    i_bus_nibble_in
);

input  wire [0:0] i_clk;
input  wire [0:0] i_reset;

input  wire [0:0] i_bus_reset;
input  wire [0:0] i_bus_clk_en;
input  wire [0:0] i_bus_is_data;
output reg  [3:0] o_bus_nibble_out;
input  wire [3:0] i_bus_nibble_in;

initial o_bus_nibble_out = 4'b0;


endmodule
