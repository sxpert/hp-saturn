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

module saturn_bus (
    i_clk,
    i_reset,
    o_halt
);

input  wire [0:0] i_clk;
input  wire [0:0] i_reset;
output wire [0:0] o_halt;

/**************************************************************************************************
 *
 * this is the main firmware rom module
 * this module is always active, there is no configuration.
 *
 *************************************************************************************************/

saturn_hp48gx_rom hp48gx_rom (
    .i_clk              (i_clk),
    .i_reset            (i_reset),

    .i_bus_reset        (ctrl_bus_reset),
    .i_bus_clk_en       (ctrl_bus_clk_en),
    .i_bus_is_data      (ctrl_bus_is_data),
    .o_bus_nibble_out   (rom_bus_nibble_out),
    .i_bus_nibble_in    (ctrl_bus_nibble_out)
);

wire [3:0] rom_bus_nibble_out;

/**************************************************************************************************
 *
 * the main processor is hidden behind this bus controller device
 * 
 *
 *************************************************************************************************/

saturn_bus_controller bus_controller (
    .i_clk              (i_clk),
    .i_reset            (i_reset),

    .o_bus_reset        (ctrl_bus_reset),
    .o_bus_clk_en       (ctrl_bus_clk_en),
    .o_bus_is_data      (ctrl_bus_is_data),
    .o_bus_nibble_out   (ctrl_bus_nibble_out),
    .i_bus_nibble_in    (ctrl_bus_nibble_in),

    // more ports should show up to allow for output to the serial port of debug information

    .o_halt             (ctrl_halt)
);

wire [0:0] ctrl_bus_reset;
wire [0:0] ctrl_bus_clk_en;
wire [0:0] ctrl_bus_is_data;
wire [3:0] ctrl_bus_nibble_out;
reg  [3:0] ctrl_bus_nibble_in;

wire [0:0] ctrl_halt;

/**************************************************************************************************
 *
 * priority logic for the bus
 * 
 *
 *************************************************************************************************/

reg bus_halt;
initial bus_halt = 0;

assign o_halt = bus_halt || ctrl_halt;

/* handles modules priority 
 * goes through all modules
 * if the module is active, this is the one giving out it's data
 * the last active module wins
 */
always @(*) begin
    ctrl_bus_nibble_in = rom_bus_nibble_out;
end


endmodule