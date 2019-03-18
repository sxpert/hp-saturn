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

module saturn_hp48gx_sysram (
    i_clk,
    i_clk_en,
    i_reset,
`ifdef SIM
    i_phase,
//    i_phases,
    i_cycle_ctr,
`endif
    i_phase_0,
    i_debug_cycle,

    i_bus_clk_en,
    i_bus_is_data,
    o_bus_nibble_out,
    i_bus_nibble_in,
    i_bus_daisy,
    o_bus_daisy,
    o_bus_active
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_clk_en;
input  wire [0:0]  i_reset;
`ifdef SIM
input  wire [1:0]  i_phase;
//input  wire [3:0]  i_phases;
input  wire [31:0] i_cycle_ctr;
`endif
input  wire [0:0]  i_phase_0;
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
 * address handling
 *
 *************************************************************************************************/
 
`define SYSRAM_BITS 18
reg  [3:0]  sysram_data[0:(2** `SYSRAM_BITS) - 1];

reg  [3:0]  last_cmd;
reg  [2:0]  addr_pos_ctr;
reg  [19:0] local_pc;
reg  [19:0] local_dp;
reg  [0:0]  pc_active; 
reg  [0:0]  dp_active; 
reg  [3:0]  read_nibble;
reg  [0:0]  exec_write;
reg  [3:0]  write_nibble;
reg  [`SYSRAM_BITS-1:0]  write_addr;

reg  [0:0]  base_conf;
reg  [0:0]  length_conf;
reg  [19:0] base_addr;
reg  [19:0] length;

initial begin
    last_cmd         = 4'b0;
    addr_pos_ctr     = 3'b0;
    local_pc         = 20'b0;
    local_dp         = 20'b0;
    pc_active        = 1'b0;
    dp_active        = 1'b0;
    read_nibble      = 4'b0;
    exec_write       = 1'b0;
    write_nibble     = 4'b0;
    write_addr       = {`SYSRAM_BITS{1'b0}};
    base_conf        = 1'b0;
    length_conf      = 1'b0;
    base_addr        = 20'b0;
    length           = 20'b0;

`ifdef SIM
    /* initialize ram to random crap, just like in the fpga */
    for(local_pc = (2**`SYSRAM_BITS)-1; local_pc != 20'hFFFFF; local_pc = local_pc - 20'h1)
        sysram_data[local_pc] = $urandom%15;
`endif

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

wire [0:0] configured = length_conf && base_conf;
assign o_bus_daisy = configured;

wire [0:0]  use_pc = do_pc_read || do_pc_write;
wire [0:0]  use_dp = do_dp_read || do_dp_write;

wire [19:0] above_addr = base_addr + length;

wire [0:0]  active    = ((pc_active && use_pc) || (dp_active && use_dp)) && configured;
assign o_bus_active  = active;

wire [19:0] pointer = use_pc?local_pc:local_dp;
wire [19:0] access_pointer = pointer - base_addr;

wire [`SYSRAM_BITS-1:0] address = access_pointer[`SYSRAM_BITS-1:0];


wire [0:0]  gen_active = i_clk_en && !i_debug_cycle && i_phase_0 && (do_read || do_write);
wire [0:0]  pre_read   = i_clk_en && i_phase_0 && !i_debug_cycle && do_read & active;
wire [0:0]  can_read   = i_bus_clk_en && i_bus_is_data && do_read && active;
wire [0:0]  can_write  = i_bus_clk_en && i_bus_is_data && do_write && active;

/**************************************************************************************************
 *
 * reading and writing to system ram
 *
 *************************************************************************************************/

/**************************************************************************************************
 *
 * generate the active signals 
 * these comparisons incur important delays, so they're done on a clock cycle
 *
 *************************************************************************************************/

always @(posedge i_clk) begin
    if (gen_active) begin
        pc_active <= (local_pc >= base_addr) && (local_pc < above_addr);
        dp_active <= (local_dp >= base_addr) && (local_dp < above_addr);
    end

    if (i_reset) begin
        pc_active        <= 1'b0;
        dp_active        <= 1'b0;
    end
end

/**************************************************************************************************
 *
 * read from the system ram in a pipelined fashion
 *
 *************************************************************************************************/

always @(posedge i_clk) begin
    if (pre_read) begin
`ifdef SIM
        $display("RAM-GX   %0d: [%d] pre_read %h <= sysram[%5h]", i_phase, i_cycle_ctr, sysram_data[address], address);
`endif
        read_nibble <= sysram_data[address];
    end       
end

always @(posedge i_clk) begin
    if (can_read) begin
`ifdef SIM
        $display("RAM-GX   %0d: [%d] do_read %h <= sysram[%5h]", i_phase, i_cycle_ctr, read_nibble, address);
`endif
        o_bus_nibble_out <= read_nibble;
    end
end

/**************************************************************************************************
 *
 * write to the system ram, this is pipelined so gain some speed
 *
 *************************************************************************************************/

always @(posedge i_clk) begin
    if (can_write) begin
`ifdef SIM
        $display("RAM-GX   %0d: [%d] pre_write sysram[%5h] <= %h", i_phase, i_cycle_ctr, address, i_bus_nibble_in);
`endif
        write_nibble <= i_bus_nibble_in;
        write_addr   <= address;
        exec_write   <= 1'b1;
    end
    if (exec_write)
        exec_write   <= 1'b0;
end

always @(posedge i_clk) begin
    if (exec_write) begin
`ifdef SIM
        $display("RAM-GX   %0d: [%d] do_write sysram[%5h] <= %h", i_phase, i_cycle_ctr, write_addr, write_nibble);
`endif
        sysram_data[write_addr] <= write_nibble;
    end
end 

/**************************************************************************************************
 *
 * generate length and base address for configure
 *
 *************************************************************************************************/

`ifdef SIM
wire [3:0]  imm_nibble = sysram_data[address];
`endif

/* generate length */
reg [19:0] new_length;

always @(*) begin
    case (addr_pos_ctr)
        3'd0:    new_length = { 16'b0, i_bus_nibble_in };
        3'd1:    new_length = { 12'b0, i_bus_nibble_in, length[ 3:0] };
        3'd2:    new_length = {  8'b0, i_bus_nibble_in, length[ 7:0] };
        3'd3:    new_length = {  4'b0, i_bus_nibble_in, length[11:0] };
        3'd4:    new_length = {        i_bus_nibble_in, length[15:0] };
        default: new_length = 20'b0;
    endcase
end

/* generate length */
reg [19:0] new_base_addr;

always @(*) begin
    case (addr_pos_ctr)
        3'd0:    new_base_addr = { 16'b0, i_bus_nibble_in };
        3'd1:    new_base_addr = { 12'b0, i_bus_nibble_in, base_addr[ 3:0] };
        3'd2:    new_base_addr = {  8'b0, i_bus_nibble_in, base_addr[ 7:0] };
        3'd3:    new_base_addr = {  4'b0, i_bus_nibble_in, base_addr[11:0] };
        3'd4:    new_base_addr = {        i_bus_nibble_in, base_addr[15:0] };
        default: new_base_addr = 20'b0;
    endcase
end

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
                    if (i_bus_daisy) begin
                        if (!length_conf && !base_conf) length    <= new_length;
                        if (length_conf  && !base_conf) base_addr <= new_base_addr;
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
                            if (!length_conf && !base_conf) 
                                begin   
                                    length_conf <= 1'b1;
                                    length      <= ~new_length + 20'b1;
`ifdef SIM
                                    $display("RAM-GX   %0d: [%d] configure length %5h => %5h", i_phase, i_cycle_ctr, new_length, ~new_length + 20'b1);
`endif
                                end
                            if (length_conf  && !base_conf) 
                                begin
                                    base_conf <= 1'b1;
`ifdef SIM
                                    $display("RAM-GX   %0d: [%d] configure base_addr %5h", i_phase, i_cycle_ctr, new_base_addr);
`endif
                                end
                        end
                    default: begin end
                endcase
            end

`ifdef SIM            
            $write("RAM-GX   %0d: [%d] ", i_phase, i_cycle_ctr);
            case (last_cmd)
                `BUSCMD_PC_READ:   
                    begin
                        $write("PC_READ ");
                        if (configured) 
                            begin
                                if (active) $write("<= sysram[%5h]: %h", local_pc, imm_nibble);
                                else $write("inactive");
                            end
                        else $write("(unconfigured)");
                    end 
                `BUSCMD_DP_READ:   
                    begin
                        $write("DP_READ ");
                        if (configured) 
                            begin   
                                if (active) $write("<= sysram[%5h]: %h", local_dp, imm_nibble);
                                else $write("(inactive)");
                            end
                        else $write("(unconfigured)");
                    end
                `BUSCMD_DP_WRITE:
                    begin
                        $write("DP_WRITE ");
                        if (configured) 
                            begin
                                if (active) $write("sysram[%5h] <= %h", local_dp, i_bus_nibble_in);
                                else $write("(inactive %h)", i_bus_nibble_in);
                            end
                        else $write("(ignore)");
                    end
                `BUSCMD_LOAD_PC:   $write("LOAD_PC - pc %5h, %h pos %0d", local_pc, i_bus_nibble_in, addr_pos_ctr);
                `BUSCMD_LOAD_DP:   $write("LOAD_DP - dp %5h, %h pos %0d", local_dp, i_bus_nibble_in, addr_pos_ctr);
                `BUSCMD_CONFIGURE: 
                    begin
                        $write("CONFIGURE - ");
                        if (!configured) 
                            begin
                                if (!length_conf) $write("length %5h", new_length);
                                else $write("base_addr %5h", new_base_addr);
                                $write(", %h pos %0d", i_bus_nibble_in, addr_pos_ctr);
                            end
                        else $write("already done, ignore");
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
                    base_addr   <= 20'b0;
                    base_conf   <= 1'b0;
                    length      <= 20'b0;
                    length_conf <= 1'b0;
                end

`ifdef SIM        
            $write("RAM-GX   %0d: [%d] ", i_phase, i_cycle_ctr);    
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
        pc_active        <= 1'b0;
        dp_active        <= 1'b0;
        read_nibble      <= 4'b0;
        write_nibble     <= 4'b0;
        base_conf        <= 1'b0;
        length_conf      <= 1'b0;
        base_addr        <= 20'b0;
        length           <= 20'b0;
    end
end

// Verilator lint_off UNUSED
wire [(19 -`SYSRAM_BITS):0] unused = { access_pointer[19:`SYSRAM_BITS] };
// Verilator lint_on UNUSED 

endmodule