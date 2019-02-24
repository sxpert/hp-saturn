
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

`ifndef _SATURN_ALU_PC
`define _SATURN_ALU_PC

`default_nettype none //


module saturn_alu_pc (
  i_clk,
  i_reset,
  i_stalled,
  i_just_reset,
  i_alu_active,
  i_cycle_ctr,
  i_phase,
  i_phase_0,
  i_phase_2,
  i_phase_3,

  i_alu_initializing,
  i_v_dest_counter_ptr,

  o_bus_address,
  o_bus_load_pc,
  i_bus_nibble_in,

  i_alu_stall_dec,
  i_ins_rtn,
  i_ins_test_go,
  i_push,
  i_pop,

  i_mode_jmp,
  i_carry,

  i_op_jump,
  i_op_jmp_rel_2,
  i_op_jmp_rel_3,
  i_op_jmp_rel_4,
  i_op_jmp_abs_5,

  o_do_apply_jump,

`ifdef SIM
  o_pc,
  o_rstk_ptr,
  o_rstk_0,
  o_rstk_1,
  o_rstk_2,
  o_rstk_3,
  o_rstk_4,
  o_rstk_5,
  o_rstk_6,
  o_rstk_7
`else
  o_pc
`endif
);

input wire  [0:0]  i_clk;
input wire  [0:0]  i_reset;
input wire  [0:0]  i_stalled;
input wire  [0:0]  i_just_reset;
input wire  [0:0]  i_alu_active;
input wire  [31:0] i_cycle_ctr;
input wire  [1:0]  i_phase;
input wire  [0:0]  i_phase_0;
input wire  [0:0]  i_phase_2;
input wire  [0:0]  i_phase_3;

input wire  [0:0]  i_alu_initializing;
input wire  [2:0]  i_v_dest_counter_ptr;

output reg  [19:0] o_bus_address;
output reg  [0:0]  o_bus_load_pc;
input  wire [3:0]  i_bus_nibble_in;

input wire  [0:0]  i_alu_stall_dec;
input wire  [0:0]  i_ins_rtn;
input wire  [0:0]  i_ins_test_go;
input wire  [0:0]  i_push;
input wire  [0:0]  i_pop;

input wire  [0:0]  i_mode_jmp;
input wire  [0:0]  i_carry;

input wire  [0:0]  i_op_jump;
input wire  [0:0]  i_op_jmp_rel_2;
input wire  [0:0]  i_op_jmp_rel_3;
input wire  [0:0]  i_op_jmp_rel_4;
input wire  [0:0]  i_op_jmp_abs_5;

output wire [0:0]  o_do_apply_jump;

output wire [19:0] o_pc;
`ifdef SIM
output wire [2:0]  o_rstk_ptr;
output wire [19:0] o_rstk_0;
output wire [19:0] o_rstk_1;
output wire [19:0] o_rstk_2;
output wire [19:0] o_rstk_3;
output wire [19:0] o_rstk_4;
output wire [19:0] o_rstk_5;
output wire [19:0] o_rstk_6;
output wire [19:0] o_rstk_7;
`endif

/* module 5:
 * manages all that is linked with the program counter
 */

/* main PC and RSTK registers */

reg  [2:0]       rstk_ptr;
reg  [19:0]      PC;
reg  [19:0]      RSTK[0:7];

assign o_pc    = PC;
`ifdef SIM
assign o_rstk_ptr = rstk_ptr;
assign o_rstk_0   = RSTK[0];
assign o_rstk_1   = RSTK[1];
assign o_rstk_2   = RSTK[2];
assign o_rstk_3   = RSTK[3];
assign o_rstk_4   = RSTK[4];
assign o_rstk_5   = RSTK[5];
assign o_rstk_6   = RSTK[6];
assign o_rstk_7   = RSTK[7];
`endif

// assign goyes_off = {{12{i_imm_value[3]}}, i_imm_value, jump_off[3:0]};
// assign goyes_pc  = jump_bse + goyes_off;
// // rtnyes is already handled by i_ins_test_go
// assign is_rtn_rel2    = (alu_op == `ALU_OP_JMP_REL2) && (goyes_off == 0);
// assign is_jmp_rel2    = (alu_op == `ALU_OP_JMP_REL2) && !(goyes_off == 0); 
// assign jmp_carry_test = (i_test_carry && (CARRY == i_carry_val));
// assign exec_rtn_rel2  = is_rtn_rel2 && jmp_carry_test && alu_done;
// // assign set_jmp_rel2   = is_jmp_rel2 && jmp_carry_test && alu_finish;
// assign exec_jmp_rel2  = is_jmp_rel2 && jmp_carry_test && alu_done;

/* jump values generator */

reg [2:0]  jump_offset_counter;
reg [19:0] jump_base;
reg [15:0] jump_offset;
reg [19:0] new_jump_offset;
reg [0:0]  jump_start;
reg [0:0]  jump_done;

wire [0:0] jump_relative;
assign jump_relative = i_op_jmp_rel_2 || i_op_jmp_rel_3 || i_op_jmp_rel_4;

// wire [0:0] do_set_jump_base;
wire [0:0] do_pre_calc_jump;
wire [0:0] do_calc_jump;

// assign do_set_jump_base = start_in_jmp_mode && !jump_done && jump_start; 
assign do_pre_calc_jump = !i_stalled && i_op_jump && i_phase_2 && !jump_done;
assign do_calc_jump     = i_mode_jmp && i_phase_3 && !jump_done;
assign o_do_apply_jump  = i_mode_jmp && i_phase_3 &&  jump_done;

wire [19:0] jump_pc;
assign jump_pc = jump_relative?(jump_base+new_jump_offset):new_jump_offset;

/* pc update generator */

reg  [19:0] pc_plus_1;
reg  [2:0]  rstk_ptr_plus_1;
reg  [2:0]  rstk_ptr_minus_1;
wire [19:0] next_pc;
wire [0:0]  update_pc;
wire [0:0]  reload_pc;
wire [0:0]  pop_pc;
wire [0:0]  push_pc;
wire [0:0]  pc_lines_cleanup;


assign next_pc   = (jump_done)?jump_pc:pc_plus_1;
assign update_pc = (!i_reset && i_just_reset) || i_alu_active && i_phase_3 && (!i_alu_stall_dec) /* || exec_unc_jmp || exec_jmp_rel2 */;

assign pop_pc    = i_alu_active && i_phase_3 && i_pop && i_ins_rtn && ((!i_ins_test_go) || (i_ins_test_go && i_carry));
assign push_pc   = i_alu_active && i_push && o_do_apply_jump;
assign reload_pc = (!i_reset && i_just_reset) || o_do_apply_jump || pop_pc;

assign pc_lines_cleanup = i_alu_active && i_phase_0;

always @(posedge i_clk) begin

  /*
   * initializes default values
   */
  if (i_reset) begin
    PC                  <= ~0;
    o_bus_load_pc       <= 0;
    rstk_ptr            <= 0;
    jump_offset_counter <= 0;
    jump_base           <= 0;
    jump_offset         <= 0;
    jump_done           <= 0;
  end

  /* on every clock, we update 
   * pc + 1
   * rstk_ptr - 1
   * rstk_ptr + 1
   */
  pc_plus_1        <= PC + 20'd1;
  rstk_ptr_minus_1 <= rstk_ptr - 3'd1;
  rstk_ptr_plus_1  <= rstk_ptr + 3'd1;

  /*
   * Similarly to the data registers,
   * initializes the RSTK while the PC is first loaded
   *
   */
  if (i_alu_initializing)
    RSTK[i_v_dest_counter_ptr] <= 0;

  /** 
   * handles jumps
   *
   */

  /* nibble was read in phase 1
   * in phase 2, we precalculate all values for a jump
   */
  if (do_pre_calc_jump) begin
    $display("ALU_PC   %0d: [%d] pre_calc_jump %0d %h", i_phase, i_cycle_ctr, jump_offset_counter, i_bus_nibble_in);
    case (jump_offset_counter)
      0: begin
        new_jump_offset <= {{16{i_bus_nibble_in[3] && jump_relative}}, i_bus_nibble_in};
        jump_start <= 1'b1;
        jump_base <= PC;
      end
      1: begin
        new_jump_offset <= {{12{i_bus_nibble_in[3] && jump_relative}}, i_bus_nibble_in, jump_offset[ 3:0]};
        if (i_op_jmp_rel_2) jump_done <= 1'b1;
      end
      2: begin
        new_jump_offset <= {{ 8{i_bus_nibble_in[3] && jump_relative}}, i_bus_nibble_in, jump_offset[ 7:0]};
        if (i_op_jmp_rel_3) jump_done <= 1'b1;
      end
      3: begin
        new_jump_offset <= {{ 4{i_bus_nibble_in[3] && jump_relative}}, i_bus_nibble_in, jump_offset[11:0]};
        if (i_op_jmp_rel_4) jump_done <= 1'b1;
      end
      4: begin
        new_jump_offset <= {i_bus_nibble_in, jump_offset[15:0]};
        if (i_op_jmp_abs_5) jump_done <= 1'b1;
      end
      default: begin end
    endcase
  end

  /*
   * in phase 3, we either update the counter
   */
  if (do_calc_jump) begin
    $display("ALU_PC   %0d: [%d] calc jump     %0d | nibble %h | rel %b | base %h | offset %h | jump_pc %h", 
             i_phase, i_cycle_ctr, jump_offset_counter, i_bus_nibble_in, jump_relative, jump_base, new_jump_offset, jump_pc);
    jump_offset <= new_jump_offset[15:0];
    jump_offset_counter <= jump_offset_counter + 3'b1;
  end

  /*
   * or apply the jump 
   */
  if (o_do_apply_jump) begin
    $display("ALU_PC   %0d: [%d] apply jump    %0d | nibble %h | rel %b | base %h | offset %h | jump_pc %h",
             i_phase, i_cycle_ctr, jump_offset_counter, i_bus_nibble_in, jump_relative, jump_base, new_jump_offset, jump_pc);
    jump_offset_counter <= 3'b0;
    new_jump_offset <= 20'b0;
    jump_start <= 1'b0;
    jump_done <= 1'b0;
  end

  /**
   *
   * Update the PC.
   * Request the new PC be loaded to the other modules through 
   * the bus if necessary 
   *
   */

  if (update_pc) begin
    // $display("ALU_PC   %0d: [%d] update pc to %h", phase, i_cycle_ctr, next_pc);
    PC <= pop_pc ? RSTK[rstk_ptr_minus_1] : next_pc;
  end


  if (push_pc) begin
    $display("ALU_PC   %0d: [%d] PUSH PC %5h to RSTK[%0d]", i_phase, i_cycle_ctr, pc_plus_1, rstk_ptr);
    RSTK[rstk_ptr] <= pc_plus_1;
    rstk_ptr       <= rstk_ptr_plus_1;
  end
  
    // $display("pop %b && rtn %b && ((!go %b) || (go %b && c %b))", 
            // i_pop, i_ins_rtn, !i_ins_test_go, i_ins_test_go, c_carry);
  if (pop_pc) begin
    $display("ALU_PC   %0d: [%d] POP RSTK[%0d] to PC %5h", i_phase, i_cycle_ctr, rstk_ptr_minus_1, RSTK[rstk_ptr_minus_1]);
    rstk_ptr <= rstk_ptr_minus_1;
    RSTK[rstk_ptr_minus_1] <= 20'b0;
  end

  if (reload_pc) begin
    $display("ALU_PC   %0d: [%d] $$$$ RELOADING PC to %h $$$$", 
             i_phase, i_cycle_ctr, (pop_pc ? RSTK[rstk_ptr_minus_1] : next_pc));
    o_bus_address <= pop_pc ? RSTK[rstk_ptr_minus_1] : next_pc;
    o_bus_load_pc <= 1'b1;
  end

  if (pc_lines_cleanup && o_bus_load_pc)
    o_bus_load_pc <= 1'b0;

end

endmodule

`endif
