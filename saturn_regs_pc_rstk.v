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

module saturn_regs_pc_rstk (
    i_clk,
    i_clk_en,
    i_reset,
    i_phases,
    i_phase,
    i_cycle_ctr,

    i_bus_busy,
    i_alu_busy,
    i_exec_unit_busy,

    i_nibble,
    i_jump_instr,
    i_jump_length,
    i_block_0x,
    i_push_pc,
    i_rtn_instr,

    o_current_pc,
    o_reload_pc,

    /* debugger access */
    i_dbg_rstk_ptr,
    o_dbg_rstk_val,
    o_reg_rstk_ptr
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_clk_en;
input  wire [0:0]  i_reset;
input  wire [3:0]  i_phases;
input  wire [1:0]  i_phase;
input  wire [31:0] i_cycle_ctr;

input  wire [0:0]  i_bus_busy;
input  wire [0:0]  i_alu_busy;
input  wire [0:0]  i_exec_unit_busy;

input  wire [3:0]  i_nibble;
input  wire [0:0]  i_jump_instr;
input  wire [2:0]  i_jump_length;
input  wire [0:0]  i_block_0x;
input  wire [0:0]  i_push_pc;
input  wire [0:0]  i_rtn_instr;
 
output wire [19:0] o_current_pc;
output reg  [0:0]  o_reload_pc;

input  wire [2:0]  i_dbg_rstk_ptr;
output wire [19:0] o_dbg_rstk_val;
output wire [2:0]  o_reg_rstk_ptr;

assign o_dbg_rstk_val = reg_RSTK[i_dbg_rstk_ptr];
assign o_reg_rstk_ptr     = reg_rstk_ptr;

/**************************************************************************************************
 *
 * pc and rstk handling module
 *
 *************************************************************************************************/

wire [0:0]  do_jump_instr = !just_reset && i_jump_instr;

/*
 * local variables
 */

reg  [0:0]  just_reset;
reg  [2:0]  init_counter;
reg  [0:0]  jump_decode;
reg  [0:0]  jump_exec;
reg  [2:0]  jump_counter;
reg  [19:0] jump_base;
reg  [19:0] jump_offset;
reg  [19:0] jump_rel_addr;

wire [0:0]  jump_rel2 = i_jump_instr && (i_jump_length == 3'd1);
wire [0:0]  jump_rel3 = i_jump_instr && (i_jump_length == 3'd2);
wire [0:0]  jump_rel4 = i_jump_instr && (i_jump_length == 3'd3);
wire [0:0]  jump_abs5 = i_jump_instr && (i_jump_length == 3'd4);
wire [0:0]  jump_relative = jump_rel2 || jump_rel3 || jump_rel4;

/* this appears to be SLOW */
wire [0:0]  is_rtn = i_phases[2] && i_block_0x && !i_nibble[3] && !i_nibble[2];

reg  [19:0] jump_next_offset;

always @(*) begin
    case (jump_counter)
        3'd0: jump_next_offset = { {16{1'b0}}, i_nibble};
        3'd1: jump_next_offset = { {12{jump_rel2?i_nibble[3]:1'b0}} , i_nibble, jump_offset[ 3:0]};
        3'd2: jump_next_offset = { { 8{jump_rel3?i_nibble[3]:1'b0}} , i_nibble, jump_offset[ 7:0]};
        3'd3: jump_next_offset = { { 4{jump_rel4?i_nibble[3]:1'b0}} , i_nibble, jump_offset[11:0]};
        3'd4: jump_next_offset = { i_nibble, jump_offset[15:0]};
        default: jump_next_offset = 20'h00000;
    endcase
end


reg  [19:0] reg_PC;
reg  [2:0]  reg_rstk_ptr;
reg  [19:0] reg_RSTK[0:7];

reg  [2:0]  rstk_ptr_to_push_at;
reg  [19:0] addr_to_return_to;
reg  [2:0]  rstk_ptr_after_pop;

assign o_current_pc = reg_PC;

initial begin
    o_reload_pc  = 1'b0;
    just_reset   = 1'b1;
    init_counter = 3'd0;
    jump_decode  = 1'b0;
    jump_exec    = 1'b0;
    jump_counter = 3'd0;
    reg_PC       = 20'h00000;
    reg_rstk_ptr = 3'd7;

    addr_to_return_to   = 20'b0;
    rstk_ptr_after_pop  = 3'd0;
    rstk_ptr_to_push_at = 3'd0;
    jump_rel_addr       = 20'b0;
end

/*
 * the process
 */

always @(posedge i_clk) begin

    /* initialize RSTK */
    if (just_reset || (init_counter != 0)) begin
`ifdef SIM
        $display("PC_RSTK  %0d: [%d] initializing RSTK[%0d]", i_phase, i_cycle_ctr, init_counter);
`endif
        reg_RSTK[init_counter] <= 20'h00000;
        init_counter <= init_counter + 3'd1;
        if (init_counter == 3'd7) begin
`ifdef SIM
            $display("PC_RSTK  %0d: [%d] exit from reset mode", i_phase, i_cycle_ctr);
`endif
            just_reset <= 1'b0;
        end
    end

    /*
     * only do something when nothing is busy doing some other tasks
     * either talking to the bus, or debugging something
     */

    // if (!i_debug_cycle)
    //     $display("PC_RSTK  %0d: [%d] !i_bus_busy %b", i_phase, i_cycle_ctr, !i_bus_busy);

    if (i_clk_en && !i_bus_busy && !i_exec_unit_busy) begin

        // if (i_phases[3] && just_reset) begin
        //     $display("PC_RSTK  %0d: [%d] exit from reset mode", i_phase, i_cycle_ctr);
        //     just_reset <= 1'b0;
        // end

        if (i_phases[1] && !just_reset) begin
            $display("PC_RSTK  %0d: [%d] inc_pc %5h => %5h", i_phase, i_cycle_ctr, reg_PC, reg_PC + 20'h00001);
            reg_PC <= reg_PC + 20'h00001;
        end

        /* 
         * jump instruction calculations
         */ 

        /* start the jump instruction 
         * the jump base is:
         * address of first nibble of the offset when goto
         * address of nibble after the offset when gosub
         */
        if (i_phases[3] && do_jump_instr && !jump_decode) begin
`ifdef SIM
            $display("PC_RSTK  %0d: [%d] start decode jump %0d | jump_base %5h", i_phase, i_cycle_ctr, 
                     i_jump_length, i_push_pc? reg_PC + {{17{1'b0}},(i_jump_length + 3'd1)} : reg_PC);
`endif
            jump_counter <= 3'd0;
            jump_base    <= i_push_pc? reg_PC + {{17{1'b0}},(i_jump_length + 3'd1)} : reg_PC;
            jump_decode  <= 1'b1;
            rstk_ptr_to_push_at <= (reg_rstk_ptr + 3'o1) & 3'o7;
        end

        /* one step of the calculation (one nibble of data came in) */
        if (i_phases[2] && do_jump_instr && jump_decode) begin
            $display("PC_RSTK  %0d: [%d] decode jump %0d/%0d %h %5h", i_phase, i_cycle_ctr, i_jump_length, jump_counter, i_nibble, jump_next_offset);
            jump_offset  <= jump_next_offset;
            jump_counter <= jump_counter + 3'd1;
            if (jump_counter == i_jump_length) begin
                $write("PC_RSTK  %0d: [%d] execute jump(%0d) jump_base %h jump_next_offset %h", i_phase, i_cycle_ctr, i_jump_length, jump_base, jump_next_offset);
                jump_decode <= 1'b0;
                // jump_exec   <= 1'b1;
                // o_reload_pc <= 1'b1;
                reg_PC           <= jump_relative ? jump_next_offset + jump_base : jump_next_offset;
                if (i_push_pc) begin
                    $write(" ( push %5h => RSTK[%0d] )", reg_PC, reg_rstk_ptr + 3'd1);
                    reg_RSTK[(reg_rstk_ptr + 3'o1)&3'o7] <= reg_PC;
                    reg_rstk_ptr <= reg_rstk_ptr + 3'd1;
                end
                $write("\n");
            end
        end
    end

        /*
         * RTN instruction
         */
    if (i_clk_en && !i_bus_busy && !i_exec_unit_busy) begin
        /* this happens at the same time in the decoder */
        if (i_phases[1]) begin
            addr_to_return_to  <= reg_RSTK[reg_rstk_ptr];
            rstk_ptr_after_pop <= (reg_rstk_ptr - 3'o1) & 3'o7; 
        end

        if (is_rtn) begin
            /* this is an RTN */
            reg_PC                 <= addr_to_return_to;
            reg_RSTK[reg_rstk_ptr] <= 20'h00000;
            reg_rstk_ptr           <= rstk_ptr_after_pop;
`ifdef SIM
            $write("PC_RSTK  %0d: [%d] RTN", i_phase, i_cycle_ctr); 
            case (i_nibble)
                4'h0: $display("SXM");
                4'h2: $display("SC");
                4'h3: $display("CC");
                default: begin end
            endcase
            $display("PC_RSTK  %0d: [%d] execute RTN back to %5h", i_phase, i_cycle_ctr, addr_to_return_to);
`endif
        end


    end


    // if (i_phases[0] && i_clk_en) begin
    //     $write("RSTK : ptr %0d | ", reg_rstk_ptr);
    //     for (tmp_ctr = 4'd0; tmp_ctr < 4'd8; tmp_ctr = tmp_ctr + 4'd1)
    //         $write("%0d => %5h | ", tmp_ctr, reg_RSTK[tmp_ctr]);
    //     $write("\n");
    // end

    if (i_reset) begin
        o_reload_pc  <= 1'b0;
        just_reset   <= 1'b1;
        init_counter <= 3'd0;
        jump_decode  <= 1'b0;
        jump_exec    <= 1'b0;
        jump_counter <= 3'd0;
        reg_PC       <= 20'h00000;
        reg_rstk_ptr <= 3'd7;
    end
end

reg [3:0] tmp_ctr;

endmodule