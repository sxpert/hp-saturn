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

/**************************************************************************************************
 *
 * master control unit
 *
 *************************************************************************************************/

saturn_control_unit control_unit (
    .i_clk             (i_clk),
    .i_reset           (i_reset),
    .i_phases          (i_phases),
    .i_phase           (i_phase),
    .i_cycle_ctr       (i_cycle_ctr),
    .i_debug_cycle     (dbg_debug_cycle),
    .i_bus_busy        (bus_busy),
    .o_program_address (ctrl_unit_prog_addr),
    .o_program_data    (ctrl_unit_prog_data),

    .o_no_read         (ctrl_unit_no_read),
    .i_nibble          (i_bus_nibble_in),

    .o_error           (ctrl_unit_error)
);

wire [0:0] ctrl_unit_error;
wire [4:0] ctrl_unit_prog_addr;
wire [4:0] ctrl_unit_prog_data;
wire [0:0] ctrl_unit_no_read;

/**************************************************************************************************
 *
 * debugger module
 *
 *************************************************************************************************/

saturn_debugger debugger (
    .i_clk         (i_clk),
    .i_reset       (i_reset),
    .i_phases      (i_phases),
    .i_phase       (i_phase),
    .i_cycle_ctr   (i_cycle_ctr),
    .o_debug_cycle (dbg_debug_cycle)
);

wire [0:0] dbg_debug_cycle;
assign o_debug_cycle = dbg_debug_cycle;

/**************************************************************************************************
 *
 * the bus controller module
 *
 *************************************************************************************************/

/*
 * local registers
 */

reg [0:0] bus_error;
reg [0:0] bus_busy;

/* 
 * program list for the bus controller
 * this is used for the control unit to send the bus controller
 * the list of things that need to be done for long sequences
 */
reg [4:0] bus_prog_addr;
reg [4:0] bus_program[0:31];
reg [4:0] next_bus_prog_addr;
reg [0:0] more_to_write;

always @(*) begin
    // $write("BUSCTRL0 %0d: [%d] write prog %d : %5b\n", i_phase, i_cycle_ctr, ctrl_unit_prog_addr, ctrl_unit_prog_data);
    bus_program[ctrl_unit_prog_addr] = ctrl_unit_prog_data; 
    next_bus_prog_addr = bus_prog_addr + 5'd1;
    more_to_write = (bus_prog_addr != ctrl_unit_prog_addr);
end

/*
 * this should come from the debugger
 */

assign o_halt = bus_error || ctrl_unit_error;

initial begin
    bus_error     = 1'b0;
    bus_prog_addr = 5'd31;
    bus_busy      = 1'b1;
end

/*
 * bus chronograms
 *
 * The bus works on a 4 phase system
 *
 */

always @(posedge i_clk) begin
    if (!o_debug_cycle) begin
        case (i_phases)
            4'b0001:
                begin
                    /*
                     * in this phase, we can send a command or data from the processor
                     */
                    if (more_to_write) begin
                        $write("BUSCTRL  %0d: [%d] %0d : %5b ", i_phase, i_cycle_ctr, next_bus_prog_addr, bus_program[next_bus_prog_addr]);
                        if (bus_program[next_bus_prog_addr][4]) $write("CMD  : ");
                        else $write("DATA : ");
                        $write("%h\n", bus_program[next_bus_prog_addr][3:0]);
                        bus_prog_addr <= next_bus_prog_addr;
                        o_bus_is_data <= !bus_program[next_bus_prog_addr][4];
                        o_bus_nibble_out <= bus_program[next_bus_prog_addr][3:0];
                        o_bus_clk_en <= 1'b1;
                        bus_busy <= 1'b1;
                    end 
                    /*
                     * nothing to send, see if we can read, and do it
                     */
                    if (!more_to_write && !ctrl_unit_no_read) begin
                        // $display("BUSCTRL  %0d: [%d] setting up read", i_phase, i_cycle_ctr);
                        o_bus_clk_en <= 1'b1;
                    end
                end
            4'b0010:
                begin
                    /*
                     * this phase is reserved for reading data from the bus
                     */
                    if (o_bus_clk_en) begin
                        // $display("BUSCTRL  %0d: [%d] lowering bus clock_en", i_phase, i_cycle_ctr);
                        o_bus_clk_en <= 1'b0;
                    end
                end
            4'b0100:
                begin
                    /*
                     * this phase is when the instruction decoder does it's job
                     */
                    if (!more_to_write && bus_busy) begin
                        $display("BUSCTRL  %0d: [%d] done sending the entire program", i_phase, i_cycle_ctr);
                        bus_busy <= 1'b0;
                    end
                end
            4'b1000:
                begin
                    /*
                     * instructions that can be handled in one clock are done here, otherwise, we start the ALU
                     */
                end
            default: begin end // other states should not exist
        endcase
    end

    if (i_reset) begin
        bus_error     <= 1'b0;
        bus_prog_addr <= 5'd31;
        bus_busy      <= 1'b1;
    end
end

endmodule