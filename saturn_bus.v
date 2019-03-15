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

module saturn_bus (
    i_clk,
    i_clk_en,
    i_reset,
    o_halt,
    o_phase,
    o_cycle_ctr,
    o_instr_decoded,
    o_debug_cycle,
    o_char_to_send,
    o_char_counter,
    o_char_valid,
    o_char_send,
    i_serial_busy
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_clk_en;
input  wire [0:0]  i_reset;
output wire [0:0]  o_halt;
output wire [1:0]  o_phase;
output wire [31:0] o_cycle_ctr;

output wire [0:0]  o_instr_decoded;
output wire [0:0]  o_debug_cycle;
assign o_debug_cycle = dbg_debug_cycle;

output wire [7:0]  o_char_to_send;
output wire [9:0]  o_char_counter;
output wire [0:0]  o_char_valid;
output wire [0:0]  o_char_send;
input  wire [0:0]  i_serial_busy;

assign o_phase = phase;
assign o_cycle_ctr = cycle_ctr;

/**************************************************************************************************
 *
 * this is the main firmware rom module
 * this module is always active, there is no configuration.
 *
 *************************************************************************************************/

saturn_hp48gx_rom hp48gx_rom (
    .i_clk              (i_clk),
    .i_clk_en           (i_clk_en),
    .i_reset            (i_reset),
`ifdef SIM
    .i_phase            (phase),
    .i_cycle_ctr        (cycle_ctr),
`endif
    .i_phase_0          (phases[0]),
    .i_debug_cycle      (dbg_debug_cycle),

    .i_bus_clk_en       (bus_clk_en),
    .i_bus_is_data      (ctrl_bus_is_data),
    .o_bus_nibble_out   (rom_bus_nibble_out),
    .i_bus_nibble_in    (ctrl_bus_nibble_out)
);

wire [3:0] rom_bus_nibble_out;

/**************************************************************************************************
 *
 * this is the sysram module
 *
 *************************************************************************************************/

saturn_hp48gx_sysram hp48gx_sysram (
    .i_clk              (i_clk),
    .i_clk_en           (i_clk_en),
    .i_reset            (i_reset),
`ifdef SIM
    .i_phase            (phase),
//    .i_phases           (phases),
    .i_cycle_ctr        (cycle_ctr),
`endif
    .i_phase_0          (phases[0]),
    .i_debug_cycle      (dbg_debug_cycle),

    .i_bus_clk_en       (bus_clk_en),
    .i_bus_is_data      (ctrl_bus_is_data),
    .o_bus_nibble_out   (sysram_bus_nibble_out),
    .i_bus_nibble_in    (ctrl_bus_nibble_out),
    .i_bus_daisy        (mmio_daisy_out),
    .o_bus_daisy        (sysram_daisy_out),
    .o_bus_active       (sysram_active)
);

wire [3:0] sysram_bus_nibble_out;
// Verilator lint_off UNUSED
wire [0:0] sysram_daisy_out;
// Verilator lint_on UNUSED
wire [0:0] sysram_active;

/**************************************************************************************************
 *
 * this is the io-ram module
 * this module only takes one configuration parameter, size is fixed
 *
 *************************************************************************************************/

saturn_hp48gx_mmio hp48gx_mmio (
    .i_clk              (i_clk),
    .i_clk_en           (i_clk_en),
    .i_reset            (i_reset),
`ifdef SIM
    .i_phase            (phase),
    .i_cycle_ctr        (cycle_ctr),
`endif
    .i_phase_0          (phases[0]),
    .i_debug_cycle      (dbg_debug_cycle),

    .i_bus_clk_en       (bus_clk_en),
    .i_bus_is_data      (ctrl_bus_is_data),
    .o_bus_nibble_out   (mmio_bus_nibble_out),
    .i_bus_nibble_in    (ctrl_bus_nibble_out),
    .i_bus_daisy        (1'b1),
    .o_bus_daisy        (mmio_daisy_out),
    .o_bus_active       (mmio_active)
);

wire [3:0] mmio_bus_nibble_out;
wire [0:0] mmio_daisy_out;
wire [0:0] mmio_active;

/**************************************************************************************************
 *
 * the main processor is hidden behind this bus controller device
 * 
 *
 *************************************************************************************************/

saturn_bus_controller bus_controller (
    .i_clk              (i_clk),
    .i_clk_en           (i_clk_en),
    .i_reset            (i_reset),
    .i_phases           (phases),
    .i_phase            (phase),
    .i_cycle_ctr        (cycle_ctr),

    .o_bus_clk_en       (ctrl_bus_clk_en),
    .o_bus_is_data      (ctrl_bus_is_data),
    .o_bus_nibble_out   (ctrl_bus_nibble_out),
    .i_bus_nibble_in    (ctrl_bus_nibble_in),

    // more ports should show up to allow for output to the serial port of debug information

    .o_debug_cycle      (dbg_debug_cycle),
    .o_instr_decoded    (o_instr_decoded),
    .o_char_to_send     (o_char_to_send),
    .o_char_counter     (o_char_counter),
    .o_char_valid       (o_char_valid),
    .o_char_send        (o_char_send),
    .i_serial_busy      (i_serial_busy),
    .o_halt             (ctrl_halt)
);

wire [0:0] ctrl_bus_clk_en;
wire [0:0] ctrl_bus_is_data;
wire [3:0] ctrl_bus_nibble_out;
reg  [3:0] ctrl_bus_nibble_in;

wire [0:0] dbg_debug_cycle;
wire [0:0] ctrl_halt;

/**************************************************************************************************
 *
 * priority logic for the bus
 * 
 *
 *************************************************************************************************/

reg  [0:0]  bus_halt;
reg  [3:0]  phases;
reg  [1:0]  phase;
reg  [31:0] cycle_ctr;

wire [0:0]  bus_clk_en = i_clk_en && ctrl_bus_clk_en;

initial begin
    bus_halt  = 1'b0;
    phases    = 4'b1;
    cycle_ctr = 32'd0;
end

assign o_halt = bus_halt || ctrl_halt;

/* handles modules priority 
 * goes through all modules
 * if the module is active, this is the one giving out it's data
 * the last active module wins
 */
always @(*) begin
    ctrl_bus_nibble_in = rom_bus_nibble_out;
    if (sysram_active) ctrl_bus_nibble_in = sysram_bus_nibble_out;
    if (mmio_active) ctrl_bus_nibble_in = mmio_bus_nibble_out;
end

always @(*) begin
    phase = 2'd0;
    if (phases[1]) phase = 2'd1;
    if (phases[2]) phase = 2'd2;
    if (phases[3]) phase = 2'd3;
end

always @(posedge i_clk) begin
    /* if we're not debugging, advance phase on each clock */
    if (!dbg_debug_cycle && i_clk_en) begin
        phases <= {phases[2:0], phases[3]};
        /* using phases[3] here becase it will be phase_0 on the next step, 
         * so we get to a new cycle on the first phase...
         */
        cycle_ctr <= cycle_ctr + {31'b0, phases[3]};
    end 

`ifdef SIM
    if (cycle_ctr == 285) begin
        bus_halt <= 1'b1;
        $display("BUS      %0d: [%d] enough cycles for now", phase, cycle_ctr);
    end
`endif

    if (i_reset) begin
        bus_halt  <= 1'b0;
        phases    <= 4'b1;
        cycle_ctr <= 32'd0;
    end
end

endmodule