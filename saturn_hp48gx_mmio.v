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

module saturn_hp48gx_mmio (
    i_clk,
    i_clk_en,
    i_reset,
    i_phase,
    i_phases,
    i_cycle_ctr,
    i_debug_cycle,

    i_bus_clk_en,
    i_bus_is_data,
    o_bus_nibble_out,
    i_bus_nibble_in,
    i_bus_daisy,
    o_bus_daisy,
    o_bus_active,

    o_menu_height,
    o_rom_mode
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_clk_en;
input  wire [0:0]  i_reset;
input  wire [1:0]  i_phase;
input  wire [3:0]  i_phases;
input  wire [31:0] i_cycle_ctr;
input  wire [0:0]  i_debug_cycle;

/**************************************************************************************************
 *
 * bus I/O
 *
 *************************************************************************************************/

input  wire [0:0] i_bus_clk_en;
input  wire [0:0] i_bus_is_data;
output reg  [3:0] o_bus_nibble_out;
input  wire [3:0] i_bus_nibble_in;
input  wire [0:0] i_bus_daisy;
output wire [0:0] o_bus_daisy;
output wire [0:0] o_bus_active;

/**************************************************************************************************
 *
 * I/O registers
 *
 *************************************************************************************************/

output reg  [5:0]  o_menu_height;   // 0x28 bits 0-3 | 0x29 bits 0-1 
output reg  [0:0]  o_rom_mode;      // 0x29 bit 3

/**************************************************************************************************
 *
 * address handling
 *
 *************************************************************************************************/
 
`define MMIO_BITS 6
reg  [3:0]  ioram_data[0:(2** `MMIO_BITS) - 1];

reg  [3:0]  last_cmd;
reg  [2:0]  addr_pos_ctr;
reg  [19:0] local_pc;
reg  [19:0] local_dp;
reg  [0:0]  pc_active; 
reg  [0:0]  dp_active; 

reg  [0:0]  configured;
reg  [19:0] base_addr;

initial begin
    last_cmd         = 4'b0;
    addr_pos_ctr     = 3'b0;
    local_pc         = 20'b0;
    local_dp         = 20'b0;
    pc_active        = 1'b0;
    dp_active        = 1'b0;
    configured       = 1'b0;
    base_addr        = 20'b0;
end

/* 
 * testing for read
 */

wire [0:0] do_pc_read = (last_cmd == `BUSCMD_PC_READ);
wire [0:0] do_dp_read = (last_cmd == `BUSCMD_DP_READ);
wire [0:0] do_read    = do_pc_read || do_dp_read;

/*
 * testing for write
 */

wire [0:0] do_pc_write = (last_cmd == `BUSCMD_PC_WRITE);
wire [0:0] do_dp_write = (last_cmd == `BUSCMD_DP_WRITE);
wire [0:0] do_write    = do_pc_write || do_dp_write;


/*
 * accessing the ioram
 */

assign o_bus_daisy = configured;

wire [0:0]  use_pc = do_pc_read || do_pc_write;
wire [0:0]  use_dp = do_dp_read || do_dp_write;

wire [19:0] above_addr = base_addr + (2 ** `MMIO_BITS);

wire [0:0]  active    = ((pc_active && use_pc) || (dp_active && use_dp)) && configured;
assign o_bus_active  = active;

wire [19:0] pointer = use_pc?local_pc:local_dp;
wire [19:0] access_pointer = pointer - base_addr;

wire [`MMIO_BITS-1:0] address = access_pointer[`MMIO_BITS-1:0];


wire [0:0]  gen_active = i_clk_en && !i_debug_cycle && i_phases[0] && (do_read || do_write);
wire [0:0]  can_read   = i_bus_clk_en && i_clk_en && i_bus_is_data && do_read && active;
wire [0:0]  can_write  = i_bus_clk_en && i_clk_en && i_bus_is_data && do_write && active;

/*
 * reading and writing to I/O registers
 */

/* 
 * generate the active signals 
 * these comparisons incur important delays
 */
always @(posedge i_clk) begin
    if (gen_active) begin
        // $display("MMIO-GX  %0d: [%d] use_pc %b | use_dp %b | local_pc %5h | local_dp %5h | base %5h | above %5h | conf %b", i_phase, i_cycle_ctr,
        //          use_pc, use_dp, local_pc, local_dp, base_addr, above_addr, configured);
        pc_active <= use_pc && (local_pc >= base_addr) && (local_pc < above_addr) && configured;
        dp_active <= use_dp && (local_dp >= base_addr) && (local_dp < above_addr) && configured;
    end

    if (i_reset) begin
        pc_active        <= 1'b0;
        dp_active        <= 1'b0;
    end
end

always @(posedge i_clk) begin
    if (can_read)
        o_bus_nibble_out <= ioram_data[address];
end

reg [0:0] junk_bit_0;

always @(posedge i_clk) begin
    if (can_write) begin
        case (address)
            6'h28: o_menu_height[3:0] <= i_bus_nibble_in;
            6'h29: {o_rom_mode, junk_bit_0, o_menu_height[5:4]} <= i_bus_nibble_in;
            default: 
                begin
`ifdef SIM
                    $display("MMIO-GX  %0d: [%d] addr %h not handled", i_phase, i_cycle_ctr, pointer);
`endif
                end
        endcase
        ioram_data[address] <= i_bus_nibble_in;
    end
end

`ifdef SIM
wire [3:0]  imm_nibble = ioram_data[address];
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
                        addr_pos_ctr <= addr_pos_ctr + 3'd1;
                    end
                `BUSCMD_LOAD_DP:
                    begin
                        local_dp[addr_pos_ctr*4+:4] <= i_bus_nibble_in;
                        addr_pos_ctr <= addr_pos_ctr + 3'd1;
                    end
                `BUSCMD_CONFIGURE:
                    if (i_bus_daisy && !configured) begin
                        base_addr[addr_pos_ctr*4+:4] <= i_bus_nibble_in;
                        addr_pos_ctr <= addr_pos_ctr + 3'd1;
                    end
                default: begin end
            endcase

            /* auto switch to pc read / dp read */
            if (addr_pos_ctr == 4) begin
                case (last_cmd)
                    `BUSCMD_LOAD_PC:   last_cmd <= `BUSCMD_PC_READ;
                    `BUSCMD_LOAD_DP:   last_cmd <= `BUSCMD_DP_READ;
                    `BUSCMD_CONFIGURE: 
                        begin
                            // set above_addr
                            configured <= 1'b1;
                        end
                    default: begin end
                endcase
            end

`ifdef SIM            
            $write("MMIO-GX  %0d: [%d] ", i_phase, i_cycle_ctr);
            case (last_cmd)
                `BUSCMD_PC_READ:   
                    begin
                        $write("PC_READ ");
                        if (configured) 
                            begin
                                if (can_read) $write("<= mmio[%5h]: %h", local_pc, imm_nibble);
                                else $write("inactive");
                            end
                        else $write("(ignore)");
                    end 
                `BUSCMD_DP_READ:   
                    begin
                        $write("DP_READ ");
                        if (configured) 
                            begin   
                                if (can_read) $write("<= mmio[%5h]: %h", local_dp, imm_nibble);
                                else $write("(inactive)");
                            end
                        else $write("(ignore)");
                    end
                `BUSCMD_DP_WRITE:
                    begin
                        $write("DP_WRITE ");
                        if (configured) 
                            begin
                                if (can_write) $write("mmio[%5h] <= %h", local_dp, i_bus_nibble_in);
                                else $write("(inactive %h)", i_bus_nibble_in);
                            end
                        else $write("(ignore)");
                    end
                `BUSCMD_LOAD_PC:   $write("LOAD_PC - pc %5h, %h pos %0d", local_pc, i_bus_nibble_in, addr_pos_ctr);
                `BUSCMD_LOAD_DP:   $write("LOAD_DP - dp %5h, %h pos %0d", local_dp, i_bus_nibble_in, addr_pos_ctr);
                `BUSCMD_CONFIGURE: 
                    begin
                        if (!configured) $write("CONFIGURE - base_addr %5h, %h pos %0d", base_addr, i_bus_nibble_in, addr_pos_ctr);
                        else $write("CONFIGURE - already done, ignore");
                    end
                `BUSCMD_RESET:     $write("RESET");
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
            
            if (i_bus_nibble_in == `BUSCMD_CONFIGURE)
                addr_pos_ctr <= 3'd0;
            
            if (i_bus_nibble_in == `BUSCMD_RESET)
                begin
                    base_addr  <= 20'b0;
                    configured <= 1'b0;
                end

`ifdef SIM        
            $write("MMIO-GX  %0d: [%d] ", i_phase, i_cycle_ctr);    
            case (i_bus_nibble_in)
                `BUSCMD_PC_READ:   $write("PC_READ");
                `BUSCMD_DP_READ:   $write("DP_READ");
                `BUSCMD_DP_WRITE:  $write("DP_WRITE");
                `BUSCMD_LOAD_PC:   $write("LOAD_PC");
                `BUSCMD_LOAD_DP:   $write("LOAD_DP");
                `BUSCMD_CONFIGURE: $write("CONFIGURE");
                `BUSCMD_RESET:     $write("RESET base_addr to %5h and unconfigure", 20'h0);
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
        configured       <= 1'b0;
        base_addr        <= 20'b0;
    end
end

// Verilator lint_off UNUSED
wire [(20 -`MMIO_BITS):0] unused;
assign unused = { junk_bit_0, access_pointer[19:`MMIO_BITS] };
// Verilator lint_on UNUSED 

endmodule