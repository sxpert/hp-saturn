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

`ifdef SIM
`define ROMBITS 20
`else
`define ROMBITS 19
`endif

module saturn_hp48gx_rom (
    i_clk,
    i_clk_en,
    i_reset,
`ifdef SIM
    i_phase,
    i_cycle_ctr,
`endif
    i_phase_0,
    i_debug_cycle,
    i_bus_clk_en,
    i_bus_is_data,
    o_bus_nibble_out,
    i_bus_nibble_in
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_clk_en;
input  wire [0:0]  i_reset;
`ifdef SIM
input  wire [1:0]  i_phase;
input  wire [31:0] i_cycle_ctr;
`endif
input  wire [0:0]  i_phase_0;
input  wire [0:0]  i_debug_cycle;

input  wire [0:0]  i_bus_clk_en;
input  wire [0:0]  i_bus_is_data;
output reg  [3:0]  o_bus_nibble_out;
input  wire [3:0]  i_bus_nibble_in;

reg  [3:0]  rom_data[0:(2**`ROMBITS)-1];
initial $readmemh("rom-gx-r.hex", rom_data, 0, (2**`ROMBITS)-1);

reg  [3:0]  last_cmd;
reg  [2:0]  addr_pos_ctr;
reg  [19:0] local_pc;
reg  [19:0] local_dp;
reg  [3:0]  read_nibble;
 
initial begin
    last_cmd         = 4'b0;
    addr_pos_ctr     = 3'b0;
    local_pc         = 20'b0;
    local_dp         = 20'b0;
end

/*
 * reading the rom
 */

wire [0:0] do_pc_read = (last_cmd == `BUSCMD_PC_READ);
wire [0:0] do_dp_read = (last_cmd == `BUSCMD_DP_READ);
wire [0:0] do_read    = do_pc_read || do_dp_read;
/* pre-read happens on phase 0 */
wire [0:0] pre_read   = i_clk_en && i_phase_0 && !i_debug_cycle && do_read;
/* this happes on phase 1 */
wire [0:0] can_read   = i_bus_clk_en && i_bus_is_data && do_read;

wire [19:0] access_pointer = do_pc_read?local_pc:local_dp;
`ifndef SIM
/* Verilator lint_off UNUSED */
wire [19:`ROMBITS-1] access_pointer_unused = access_pointer[19:`ROMBITS-1];
/* Verilator lint_on UNUSED */
`endif

wire [`ROMBITS-1:0] address = access_pointer[`ROMBITS-1:0];

always @(posedge i_clk) begin
    if (pre_read) begin
`ifdef SIM
        $display("ROM-GX-R %0d: [%d] pre_read %h <= rom[%5h]", i_phase, i_cycle_ctr, rom_data[address], address);
`endif
        read_nibble <= rom_data[address];
    end       
end

always @(posedge i_clk) begin
    if (can_read) begin
`ifdef SIM
        $display("ROM-GX-R %0d: [%d] can_read %h <= rom[%5h]", i_phase, i_cycle_ctr, read_nibble, address);
`endif
        o_bus_nibble_out <= read_nibble;
    end
end

`ifdef SIM
wire [3:0]  imm_nibble = rom_data[address];
`endif

/*
 * general case
 */

always @(posedge i_clk) begin
    if (i_bus_clk_en && i_clk_en) begin
        if (i_bus_is_data) begin
            /* do things with the bits...*/
            case (last_cmd)
                `BUSCMD_PC_READ:
                    begin
                        // o_bus_nibble_out <= rom_data[local_pc[`ROMBITS-1:0]];
                        local_pc <= local_pc + 1;
                    end
                `BUSCMD_DP_READ:
                    begin
                        // o_bus_nibble_out <= rom_data[local_dp[`ROMBITS-1:0]];
                        local_dp <= local_dp + 1;
                    end
                `BUSCMD_PC_WRITE: local_pc <= local_pc + 1;
                `BUSCMD_DP_WRITE: local_dp <= local_dp + 1;
                `BUSCMD_LOAD_PC: 
                    begin
                        local_pc[addr_pos_ctr*4+:4] <= i_bus_nibble_in;
                        addr_pos_ctr <= addr_pos_ctr + 1;
                    end
                `BUSCMD_LOAD_DP:
                    begin
                        local_dp[addr_pos_ctr*4+:4] <= i_bus_nibble_in;
                        addr_pos_ctr <= addr_pos_ctr + 1;
                    end
                default: begin end
            endcase

            /* auto switch to pc read / dp read */
            if (addr_pos_ctr == 4) begin
                case (last_cmd)
                    `BUSCMD_LOAD_PC: last_cmd <= `BUSCMD_PC_READ;
                    `BUSCMD_LOAD_DP: last_cmd <= `BUSCMD_DP_READ;
                    default: begin end
                endcase
            end

`ifdef SIM            
            $write("ROM-GX-R %0d: [%d] ", i_phase, i_cycle_ctr);
            case (last_cmd)
                `BUSCMD_PC_READ:   $write("PC_READ <= rom[%5h]: %h", local_pc, imm_nibble);
                `BUSCMD_DP_READ:   $write("DP_READ <= rom[%5h]: %h", local_dp, imm_nibble);
                `BUSCMD_DP_WRITE:  $write("DP_WRITE (we can't write to rom)");
                `BUSCMD_LOAD_PC:   $write("LOAD_PC - pc %5h, %h pos %0d", local_pc, i_bus_nibble_in, addr_pos_ctr);
                `BUSCMD_LOAD_DP:   $write("LOAD_DP - dp %5h, %h pos %0d", local_dp, i_bus_nibble_in, addr_pos_ctr);
                `BUSCMD_CONFIGURE: $write("CONFIGURE - rom is not configurable");
                default: $write("last_command %h nibble %h - UNHANDLED", last_cmd, i_bus_nibble_in);
            endcase
            if (addr_pos_ctr == 4) begin
                case (last_cmd)
                    `BUSCMD_LOAD_PC: $write(" auto switch to PC_READ");
                    `BUSCMD_LOAD_DP: $write(" auto switch to DP_READ");
                    default: begin end
                endcase
            end 
            $write("\n");
`endif
        end else begin
            last_cmd <= i_bus_nibble_in;
            if ((i_bus_nibble_in == `BUSCMD_LOAD_PC) || (i_bus_nibble_in == `BUSCMD_LOAD_DP))
                addr_pos_ctr <= 0;
`ifdef SIM        
            $write("ROM-GX-R %0d: [%d] ", i_phase, i_cycle_ctr);    
            case (i_bus_nibble_in)
                `BUSCMD_PC_READ:   $write("PC_READ");
                `BUSCMD_LOAD_PC:   $write("LOAD_PC");
                `BUSCMD_LOAD_DP:   $write("LOAD_DP");
                `BUSCMD_CONFIGURE: $write("CONFIGURE");
                `BUSCMD_RESET:     $write("RESET");
                default: begin end
            endcase
            $write("\n");
`endif
        end
    end

    if (i_reset) begin
        last_cmd         <= 4'b0;
        addr_pos_ctr     <= 3'b0;
        local_pc         <= 20'b0;
        local_dp         <= 20'b0;
    end
end

endmodule
