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

module saturn_serial (
    i_clk,

    i_char_to_send,
    i_char_valid,

    o_serial_tx,

    o_serial_busy
);

input  wire [0:0]  i_clk;

input  wire [7:0]  i_char_to_send;
input  wire [0:0]  i_char_valid;

output wire [0:0]  o_serial_tx;

output wire [0:0]  o_serial_busy;

/*
 *
 */

reg  [10:0]  clocking_reg;
reg  [9:0]  data_reg;

`ifdef SIM
`define BIT_DELAY_START 13'h0
`define BIT_DELAY_TEST  0
`else
/* 9600 */
// `define BIT_DELAY_START 13'h54D
//`define BIT_DELAY_TEST  12

/* 115200 */
`define BIT_DELAY_START 13'h27
`define BIT_DELAY_TEST  8

`endif

reg  [12:0] bit_delay;

initial begin
    bit_delay    = `BIT_DELAY_START;
    clocking_reg = {11{1'b1}};
    data_reg     = {10{1'b1}};
end

assign o_serial_busy = !clocking_reg[0];
assign o_serial_tx   = data_reg[0];

always @(posedge i_clk) begin
    bit_delay    <= bit_delay + 13'd1;

    // $display("%0d", bit_delay);
    if (i_char_valid && !o_serial_busy) begin
        // $write("%c", i_char_to_send);
        // $display("serial storing char %c", i_char_to_send);
        clocking_reg <= 11'b0;
        data_reg     <= { 1'b1, i_char_to_send, 1'b0 };
        bit_delay    <= `BIT_DELAY_START;
    end

    if (o_serial_busy && bit_delay[`BIT_DELAY_TEST]) begin
        // $display("%b %b %b", o_serial_tx, data_reg, clocking_reg);
        clocking_reg <= { 1'b1, clocking_reg[10:1] };
        data_reg     <= { 1'b1, data_reg[9:1]     };
        bit_delay    <= `BIT_DELAY_START;
    end
end

endmodule