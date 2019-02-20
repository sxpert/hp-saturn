
/*
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

`ifndef _SATURN_ALU
`define _SATURN_ALU

`include "def-alu.v"

`ifdef SIM
// `define ALU_DEBUG_DBG
`endif

`define ALU_DEBUG       1'b0
`define ALU_DEBUG_DUMP  1'b1     
`define ALU_DEBUG_JUMP  1'b0
`define ALU_DEBUG_PC    1'b0  

module saturn_alu (
    i_clk,
    i_reset,
    i_clk_ph,
    i_cycle_ctr,
    i_en_alu_dump,
	  i_en_alu_prep,
	  i_en_alu_calc,
    i_en_alu_init,
	  i_en_alu_save,
    i_stalled,

    o_bus_address,
    o_bus_xfr_cnt,
    o_bus_pc_read,
    o_bus_dp_read,
    o_bus_dp_write,
    o_bus_load_pc,
    o_bus_load_dp,
    o_bus_config,
    i_bus_nibble_in,
    o_bus_nibble_out,

    i_push,
    i_pop,
    i_alu_debug,

    o_alu_stall_dec,
    i_ins_decoded,

    i_field_start,
    i_field_last,
    i_imm_value,

    i_alu_op,
    i_alu_no_stall,
    i_reg_dest,
    i_reg_src1,
    i_reg_src2,

    i_ins_alu_op,
    i_ins_test_go,
    i_ins_set_mode,
    i_ins_rtn,
    i_ins_config,
    i_ins_mem_xfr,
    i_xfr_dir_out,
    i_ins_unconfig,

    i_mode_dec,
    i_set_xm,
    i_set_carry,
    i_test_carry,
    i_carry_val,

    o_reg_p,
    o_pc
);

input   wire [0:0]  i_clk;
input   wire [0:0]  i_reset;
input   wire [1:0]  i_clk_ph;
input   wire [31:0] i_cycle_ctr;
input   wire [0:0]  i_en_alu_dump;
input   wire [0:0]  i_en_alu_prep;
input   wire [0:0]  i_en_alu_calc;
input   wire [0:0]  i_en_alu_init;
input   wire [0:0]  i_en_alu_save;
input   wire [0:0]  i_stalled;

output  reg  [19:0] o_bus_address;
output  reg  [3:0]  o_bus_xfr_cnt;
output  reg  [0:0]  o_bus_pc_read;
output  reg  [0:0]  o_bus_dp_read;
output  reg  [0:0]  o_bus_dp_write;
output  reg  [0:0]  o_bus_load_pc;
output  reg  [0:0]  o_bus_load_dp;
output  reg  [0:0]  o_bus_config;
input   wire [3:0]  i_bus_nibble_in;
output  reg  [3:0]  o_bus_nibble_out;

input   wire [0:0]  i_push;
input   wire [0:0]  i_pop;
input   wire [0:0]  i_alu_debug;

wire alu_debug;
wire alu_debug_dump;
wire alu_debug_jump;
wire alu_debug_pc;
assign alu_debug      = `ALU_DEBUG      || i_alu_debug;
assign alu_debug_dump = `ALU_DEBUG_DUMP || i_alu_debug;
assign alu_debug_jump = `ALU_DEBUG_JUMP || i_alu_debug;
assign alu_debug_pc   = `ALU_DEBUG_PC   || i_alu_debug;

output  wire [0:0]  o_alu_stall_dec;
input   wire [0:0]  i_ins_decoded;

input   wire [3:0]  i_field_start;
input   wire [3:0]  i_field_last;
input   wire [3:0]  i_imm_value;

input   wire [4:0]  i_alu_op;
input   wire [0:0]  i_alu_no_stall;
input   wire [4:0]  i_reg_dest;
input   wire [4:0]  i_reg_src1;
input   wire [4:0]  i_reg_src2;

input   wire [0:0]  i_ins_alu_op;
input   wire [0:0]  i_ins_test_go;
input   wire [0:0]  i_ins_set_mode; 
input   wire [0:0]  i_ins_rtn;
input   wire [0:0]  i_ins_config;
input   wire [0:0]  i_ins_mem_xfr;
input   wire [0:0]  i_xfr_dir_out;
input   wire [0:0]  i_ins_unconfig;

input   wire [0:0]  i_mode_dec;
input   wire [0:0]  i_set_xm;
input   wire [0:0]  i_set_carry;
input   wire [0:0]  i_test_carry;
input   wire [0:0]  i_carry_val;

output  wire [3:0]  o_reg_p;
output  wire [19:0] o_pc;

assign o_reg_p = P;
assign o_pc    = PC;

/* internal registers */
wire [1:0] phase;
assign phase = i_clk_ph + 3;

/* copy of arguments */
reg [4:0] alu_op;
reg [4:0] reg_dest;
reg [4:0] reg_src1;
reg [4:0] reg_src2;
reg [3:0] f_first;
reg [3:0] f_cur;
reg [3:0] f_last;

/* internal pointers */

reg [3:0] p_src1;
reg [3:0] p_src2;
reg [0:0] p_carry;
reg [3:0] c_res1;
reg [3:0] c_res2;
reg [0:0] c_carry;
reg [0:0] is_zero;

/* alu status */

reg        alu_run;
reg        alu_done;
reg        alu_go_test;

/*
 * next PC in case of jump 
 */
reg  [19:0]      jump_bse;
reg  [19:0]      jump_off;
wire [19:0]      jump_pc;
assign jump_pc = (alu_op == `ALU_OP_JMP_ABS5)?jump_off:(jump_bse + jump_off); 

reg  [2:0]       rstk_ptr;

/* public registers */

reg  [19:0]      PC;

reg  [19:0]      D0;
reg  [19:0]      D1;

//reg  [63:0]      A;
reg  [3:0]       A[0:15];
reg  [3:0]       B[0:15];
reg  [3:0]       C[0:15];
reg  [3:0]       D[0:15];

reg  [3:0]      R0[0:15];
reg  [3:0]      R1[0:15];
reg  [3:0]      R2[0:15];
reg  [3:0]      R3[0:15];
reg  [3:0]      R4[0:15];

reg  [0:0]       CARRY;
reg  [0:0]       DEC;
reg  [3:0]       P;
reg  [3:0]       HST;
reg  [15:0]      ST;

reg  [19:0]      RSTK[0:7];


initial begin
end

/*
 * can the alu function ?
 */
wire alu_active;

assign alu_active = !i_reset && !i_stalled;

/*
 * simulation only states, when alu is active
 */
`ifdef SIM
wire do_reg_dump;
wire do_alu_shpc;
assign do_reg_dump = alu_active && i_en_alu_dump && !o_bus_load_pc &&
                     i_ins_decoded && !o_alu_stall_dec;
assign do_alu_shpc = alu_active && i_en_alu_dump;
`endif

wire do_busclean;
wire do_alu_init;
wire do_alu_prep;
wire do_alu_calc;
wire do_alu_save;
wire do_alu_pc;
wire do_alu_mode;

assign do_busclean = alu_active && i_en_alu_dump;
assign do_alu_init = alu_active && i_en_alu_init && i_ins_alu_op && !alu_run && 
                     !write_done && !do_exec_p_eq && !o_bus_config; 
assign do_alu_prep = alu_active && i_en_alu_prep && alu_run;
assign do_alu_calc = alu_active && i_en_alu_calc && alu_run;
assign do_alu_save = alu_active && i_en_alu_save && alu_run;
assign do_alu_pc   = alu_active && i_en_alu_save;
assign do_alu_mode = alu_active && i_en_alu_save && i_ins_set_mode;

wire do_go_init;
wire do_go_prep;
wire do_go_calc;

assign do_go_init  = alu_active && i_en_alu_save && i_ins_test_go;
assign do_go_prep  = alu_active && i_en_alu_prep && i_ins_test_go;

// now for the fine tuning ;-)

// save one cycle on P= n!
wire   is_alu_op_copy;
wire   is_reg_dest_p;
wire   is_reg_src1_imm;
wire   do_exec_p_eq;

assign is_alu_op_copy  = (i_alu_op == `ALU_OP_COPY);
assign is_reg_dest_p   = (i_reg_dest == `ALU_REG_P);
assign is_reg_src1_imm = (i_reg_src1 == `ALU_REG_IMM);
assign do_exec_p_eq    = alu_active && i_en_alu_save && i_ins_alu_op && is_alu_op_copy && is_reg_dest_p && is_reg_src1_imm;

initial begin
  // $monitor({"ALU - ph %0d | ",
  //           "i_reset %b | i_stalled %b | nostll %b | ",
  //           "init %b | act %b | run %b | done %b | fin %b | ",
  //           "idump %b | oblpc %b | idec %b | bconf %b | stdec %b "}, 
  //          phase,
  //          i_reset, i_stalled, i_alu_no_stall,
  //          do_alu_init, alu_active, alu_run, alu_done, alu_finish,
  //          i_en_alu_dump, o_bus_load_pc, i_ins_decoded, o_bus_config, o_alu_stall_dec);

end

// the decoder may request the ALU to not stall it

wire bus_commands;
assign bus_commands = o_bus_config || o_bus_dp_write ;

assign o_alu_stall_dec = alu_initializing || 
                         (alu_run && (!i_alu_no_stall || alu_finish || i_ins_mem_xfr)) || 
                         i_stalled || bus_commands;


wire       alu_start;
wire       alu_finish;
wire [3:0] f_next;

assign alu_start  = f_cur == f_first;
assign alu_finish = f_cur == f_last;
assign f_next     = (f_cur + 1) & 4'hF;

/*
 * test things on alu_op
 */

wire is_alu_op_unc_jump;
assign is_alu_op_unc_jump = ((alu_op == `ALU_OP_JMP_REL3) ||
                             (alu_op == `ALU_OP_JMP_REL4) ||
                             (alu_op == `ALU_OP_JMP_ABS5) ||
                             i_ins_rtn);
wire is_alu_op_test;
assign is_alu_op_test = ((alu_op == `ALU_OP_TEST_EQ) ||
                         (alu_op == `ALU_OP_TEST_NEQ));

/*****************************************************************************
 *
 * Dump all registers at the end of each instruction's execution cycle
 *
 ****************************************************************************/

`ifdef SIM
reg [4:0] alu_dbg_ctr;
`endif

always @(posedge i_clk) begin

`ifdef SIM
//   if (i_stalled && i_en_alu_dump) 
//     $display("ALU STALLED");
`endif

`ifdef ALU_DEBUG_DBG
  $display("iad %b | AD %b | ad %b | ADD %b | add %b | ADJ %b | adj %b | ADP %b | adp %b",
           i_alu_debug, 
           `ALU_DEBUG,      i_alu_debug, 
           `ALU_DEBUG_DUMP, alu_debug_dump, 
           `ALU_DEBUG_JUMP, alu_debug_jump,
           `ALU_DEBUG_PC,   alu_debug_pc );
`endif

`ifdef SIM
  if (do_reg_dump && alu_debug_dump) begin

    $display("ALU_DUMP 0: run %b | done %b", alu_run, alu_done);
    // display registers
    $display("PC: %05h               Carry: %b h: %s rp: %h   RSTK7: %05h", 
             PC, CARRY, DEC?"DEC":"HEX", rstk_ptr, RSTK[7]);
    $display("P:  %h  HST: %b        ST:  %b   RSTK6: %5h", 
             P, HST, ST, RSTK[6]);

    $write("A:  ");
    for(alu_dbg_ctr=15;alu_dbg_ctr!=31;alu_dbg_ctr=alu_dbg_ctr-1)
      $write("%h", A[alu_dbg_ctr]);
    $write("    R0:  ");
    for(alu_dbg_ctr=15;alu_dbg_ctr!=31;alu_dbg_ctr=alu_dbg_ctr-1)
      $write("%h", R0[alu_dbg_ctr]);
    $write("   RSTK5: %5h\n", RSTK[5]);

    $write("B:  ");
    for(alu_dbg_ctr=15;alu_dbg_ctr!=31;alu_dbg_ctr=alu_dbg_ctr-1)
      $write("%h", B[alu_dbg_ctr]);
    $write("    R1:  ");
    for(alu_dbg_ctr=15;alu_dbg_ctr!=31;alu_dbg_ctr=alu_dbg_ctr-1)
      $write("%h", R1[alu_dbg_ctr]);
    $write("   RSTK4: %5h\n", RSTK[4]);

    $write("C:  ");
    for(alu_dbg_ctr=15;alu_dbg_ctr!=31;alu_dbg_ctr=alu_dbg_ctr-1)
      $write("%h", C[alu_dbg_ctr]);
    $write("    R2:  ");
    for(alu_dbg_ctr=15;alu_dbg_ctr!=31;alu_dbg_ctr=alu_dbg_ctr-1)
      $write("%h", R2[alu_dbg_ctr]);
    $write("   RSTK3: %5h\n", RSTK[3]);

    $write("D:  ");
    for(alu_dbg_ctr=15;alu_dbg_ctr!=31;alu_dbg_ctr=alu_dbg_ctr-1)
      $write("%h", D[alu_dbg_ctr]);
    $write("    R3:  ");
    for(alu_dbg_ctr=15;alu_dbg_ctr!=31;alu_dbg_ctr=alu_dbg_ctr-1)
      $write("%h", R3[alu_dbg_ctr]);
    $write("   RSTK2: %5h\n", RSTK[2]);

    $write("D0: %h  D1: %h    R4:  ", D0, D1);
    for(alu_dbg_ctr=15;alu_dbg_ctr!=31;alu_dbg_ctr=alu_dbg_ctr-1)
      $write("%h", R4[alu_dbg_ctr]);
    $write("   RSTK1: %5h\n", RSTK[1]);
    $display("         ADDR: %5h                            RSTK0: %5h", 
             o_bus_address, RSTK[0]);
  end
`endif
end

/*****************************************************************************
 *
 * Initialize the ALU, to prepare it to execute the instruction 
 *
 ****************************************************************************/

wire [0:0] is_mem_read; 
wire [0:0] is_mem_write;
wire [0:0] is_mem_xfer;
wire [4:0] mem_reg;
assign is_mem_read  = (i_reg_src1 == `ALU_REG_DAT0) || (i_reg_src1 == `ALU_REG_DAT1);
assign is_mem_write = (i_reg_dest == `ALU_REG_DAT0) || (i_reg_dest == `ALU_REG_DAT1);
assign is_mem_xfer  = is_mem_read || is_mem_write;
assign mem_reg      = is_mem_read?i_reg_src1:i_reg_dest; 

always @(posedge i_clk) begin

  if (i_reset) begin
    alu_op   <= 0;
    reg_dest <= 0;
    reg_src1 <= 0;
    reg_src2 <= 0;
    f_last   <= 0;
  end

  // this happens in phase 3, right after the instruction decoder (in phase 2) is finished
  if (do_alu_init) begin

`ifdef SIM
    if (alu_debug)
      $display({"ALU_INIT 3: run %b | done %b | stall %b | op %d | s %h | l %h ",
                "| ialu %b | dest %d | src1 %d | src2 %d | imm %h"},
               alu_run, alu_done, o_alu_stall_dec, i_alu_op,i_field_start, i_field_last,  
               i_ins_alu_op, i_reg_dest, i_reg_src1, i_reg_src2, i_imm_value);
`endif

    alu_op   <= i_alu_op;
    reg_dest <= i_reg_dest;
    reg_src1 <= i_reg_src1;
    reg_src2 <= i_reg_src2;
    f_last   <= i_field_last;

  end
end

/*
 * handles f_start, alu_run and alu_done
 */

always @(posedge i_clk) begin

  if (i_reset) begin
    alu_run  <= 0;
    alu_done <= 0;
    f_first  <= 0;
    f_cur    <= 0;
  end

  if (alu_initializing) 
    f_cur <= f_cur + 1;

  if (do_alu_init) begin
    $display("ALU %0d - -------------------------------------------------  DO_ALU_INIT", phase);
    alu_run <= 1;
    f_first <= i_field_start;
    f_cur   <= i_field_start;

    alu_go_test <= is_alu_op_test;
  end

  if (do_alu_prep) begin
    // $display("ALU_TEST 1: tf %b | nxt %h", test_finish, f_next);
    alu_done <= 0;
  end

  if (do_alu_calc) begin
    // $display("ALU_TEST 2: tf %b | nxt %h", test_finish, f_next);
    alu_done <= alu_finish; 
    // f_next  <= (f_start + 1) & 4'hF;
  end

  if (do_alu_save) begin
    // $display("ALU_TEST 3: tf %b | nxt %h", test_finish, f_next);    
    f_cur  <= f_next;
  end    

  if (do_alu_save && alu_done) begin
    alu_run <= 0;
    alu_done <= 0;
  end

end



always @(posedge i_clk) begin

  if (i_reset) begin
    p_src1   <= 0;
    p_src2   <= 0;
    p_carry  <= 0;
    jump_bse <= 0;
  end

  if (do_alu_prep) begin
    if (alu_debug) begin
      `ifdef SIM
      $display("ALU_PREP 1: run %b | done %b | stall %b | op %d | f %h | c %h | l %h | imm %h", 
               alu_run, alu_done, o_alu_stall_dec, alu_op, f_first, f_cur, f_last, i_imm_value);
      `endif
    end

    /*
     * source 1
     */
    case (alu_op)
      `ALU_OP_ZERO: begin end // no source required
      `ALU_OP_COPY,
      `ALU_OP_EXCH,
      `ALU_OP_RST_BIT,
      `ALU_OP_SET_BIT,
      `ALU_OP_2CMPL,
      `ALU_OP_DEC,
      `ALU_OP_ADD,
      `ALU_OP_TEST_EQ,
      `ALU_OP_TEST_NEQ,
      `ALU_OP_JMP_REL2,
      `ALU_OP_JMP_REL3,
      `ALU_OP_JMP_REL4,
      `ALU_OP_JMP_ABS5,
      `ALU_OP_CLR_MASK:
        case (reg_src1)
        `ALU_REG_A:    p_src1 <= A[f_cur];
        `ALU_REG_B:    p_src1 <= B[f_cur];
        `ALU_REG_C:    p_src1 <= C[f_cur];
        `ALU_REG_D:    p_src1 <= D[f_cur];
        `ALU_REG_R0:   p_src1 <= R0[f_cur];
        `ALU_REG_R1:   p_src1 <= R1[f_cur];
        `ALU_REG_R2:   p_src1 <= R2[f_cur];
        `ALU_REG_R3:   p_src1 <= R3[f_cur];
        `ALU_REG_R4:   p_src1 <= R4[f_cur];
        `ALU_REG_D0:   p_src1 <= D0[f_cur*4+:4];
        `ALU_REG_D1:   p_src1 <= D1[f_cur*4+:4];
        `ALU_REG_P:    p_src1 <= P;
        `ALU_REG_DAT0,
        `ALU_REG_DAT1: p_src1 <= i_bus_nibble_in;
        `ALU_REG_HST:  p_src1 <= HST;
        `ALU_REG_IMM:  p_src1 <= i_imm_value;
        `ALU_REG_ZERO: p_src1 <= 0;
        default: $display("#### SRC_1 UNHANDLED REGISTER %0d", reg_src1);
        endcase
      default: $display("#### SRC_1 UNHANDLED OPERATION %0d", alu_op);
    endcase


    /*
     * source 2
     */
    case (alu_op)
      `ALU_OP_ZERO,
      `ALU_OP_COPY,
      `ALU_OP_RST_BIT,
      `ALU_OP_SET_BIT,
      `ALU_OP_2CMPL,
      `ALU_OP_DEC,
      `ALU_OP_JMP_REL2,
      `ALU_OP_JMP_REL3,
      `ALU_OP_JMP_REL4,
      `ALU_OP_JMP_ABS5: begin end // no need for a 2nd operand
      `ALU_OP_EXCH, 
      `ALU_OP_ADD,
      `ALU_OP_TEST_EQ,
      `ALU_OP_TEST_NEQ,
      `ALU_OP_CLR_MASK: begin
        case (reg_src2)
        `ALU_REG_A:    p_src2 <= A[f_cur];
        `ALU_REG_B:    p_src2 <= B[f_cur];
        `ALU_REG_C:    p_src2 <= C[f_cur];
        `ALU_REG_D:    p_src2 <= D[f_cur];
        `ALU_REG_R0:   p_src2 <= R0[f_cur];
        `ALU_REG_R1:   p_src2 <= R1[f_cur];
        `ALU_REG_R2:   p_src2 <= R2[f_cur];
        `ALU_REG_R3:   p_src2 <= R3[f_cur];
        `ALU_REG_R4:   p_src2 <= R4[f_cur];
        `ALU_REG_D0:   p_src2 <= D0[f_cur*4+:4];
        `ALU_REG_D1:   p_src2 <= D1[f_cur*4+:4];
        `ALU_REG_P:    p_src2 <= P;
        `ALU_REG_HST:  p_src2 <= HST;
        `ALU_REG_IMM:  p_src2 <= i_imm_value;
        `ALU_REG_ZERO: p_src2 <= 0;
        default: $display("#### SRC_2 UNHANDLED REGISTER %0d", reg_src2);
        endcase
      end
      default: $display("#### SRC_2 UNHANDLED OPERATION %0d", alu_op);
    endcase

    // setup p_carry
    // $display("fs %h | fs=0 %b | cc %b | npc %b", f_start, (f_start == 0), c_carry, (f_start == 0)?1'b1:c_carry);
    case (alu_op)
    `ALU_OP_2CMPL:    p_carry <= alu_start?1'b1:c_carry;
    `ALU_OP_DEC:      p_carry <= alu_start?1'b0:c_carry;
    `ALU_OP_ADD:      p_carry <= alu_start?1'b0:c_carry;
    `ALU_OP_TEST_NEQ: p_carry <= alu_start?1'b0:c_carry;
    endcase

    // prepare jump base
    case (alu_op)
    `ALU_OP_JMP_REL2,
    `ALU_OP_JMP_REL3,
    `ALU_OP_JMP_REL4:
      begin
        // the address of the first digit of the offset
        if (!i_push && alu_start)
          jump_bse <= PC - 1;
        // doc says address of the next instruction, but appears to be off by 1
        if (i_push)
          jump_bse <= PC;
      end
    endcase

  end
end

always @(posedge i_clk) begin
  
  if (i_reset) begin
    c_res1   <= 0;
    c_res2   <= 0;
    c_carry  <= 0;
    is_zero  <= 0;
    jump_off <= 0;
  end

  if (do_alu_calc) begin
    `ifdef SIM
    if (alu_debug)
      $display("ALU_CALC 2: run %b | done %b | stall %b | op %d | f %h | c %h | l %h | dest %d | psrc1 %h | psrc2 %h | p_carry %b", 
               alu_run, alu_done, o_alu_stall_dec, alu_op, f_first, f_cur, f_last, reg_dest, p_src1, p_src2, p_carry);
    if (alu_debug_jump)
      $display("ALU_JUMP 2: run %b | done %b | stall %b | op %d | f %h | c %h | l %h | jbs %5h | jof %5h | jpc %5h | fin %b",
               alu_run, alu_done, o_alu_stall_dec, alu_op, f_first, f_cur, f_last, jump_bse, jump_off, jump_pc, alu_finish);
    `endif

    if(alu_start)
      case (alu_op)
        `ALU_OP_JMP_REL2,
        `ALU_OP_JMP_REL3,
        `ALU_OP_JMP_REL4,
        `ALU_OP_JMP_ABS5: jump_off <= { 16'b0, p_src1 };
      endcase

    // main case
    case (alu_op)
      `ALU_OP_ZERO: c_res1 <= 0;
      `ALU_OP_EXCH: 
        begin
            c_res1 <= p_src2;
            c_res2 <= p_src1;
          end
      `ALU_OP_COPY,
      `ALU_OP_RST_BIT,
      `ALU_OP_SET_BIT:  c_res1 <= p_src1;
      `ALU_OP_2CMPL: begin 
          c_carry <= (~p_src1 == 4'hf) && p_carry ;
          c_res1  <= ~p_src1 + {3'b000, p_carry};
          is_zero <= ((~p_src1 + {3'b000, p_carry}) == 0) && alu_start?1:is_zero;
        end
      `ALU_OP_DEC: 
        {c_carry, c_res1} <= p_src1 + 4'b1111 + {4'b0000, p_carry};
      `ALU_OP_ADD:
        {c_carry, c_res1} <= p_src1 + p_src2 + {4'b0000, p_carry};
      `ALU_OP_TEST_NEQ: 
        c_carry <= !(p_src1 == p_src2) || p_carry;
      `ALU_OP_JMP_REL2: begin end // there is no middle part
      `ALU_OP_JMP_REL3,
      `ALU_OP_JMP_REL4,
      `ALU_OP_JMP_ABS5: jump_off[f_cur*4+:4] <= p_src1;
      `ALU_OP_CLR_MASK: c_res1 <= p_src1 & ~p_src2;
      default: $display("#### CALC 2 UNHANDLED OPERATION %0d", alu_op); 
    endcase

    if (alu_finish) 
      case (alu_op)
        `ALU_OP_JMP_REL2: jump_off <= { {12{p_src1[3]}}, p_src1, jump_off[3:0]  };
        `ALU_OP_JMP_REL3: jump_off <= { {8{p_src1[3]}},  p_src1, jump_off[7:0]  };
        `ALU_OP_JMP_REL4: jump_off <= { {4{p_src1[3]}},  p_src1, jump_off[11:0] };
      endcase

    // $display("-------C- SRC1 %b %h | ~SRC1 %b %h | PC %b | RES1 %b %h | CC %b", 
    //          p_src1, p_src1, ~p_src1, ~p_src1, p_carry, 
    //          (~p_src1) + p_carry, (~p_src1) + p_carry, 
    //          (~p_src1) == 4'hf );
  end

  if (do_go_init) begin
    // $display("GO_INIT  3: imm %h", i_imm_value);
    jump_off <= { {16{1'b0}}, i_imm_value};
  end
end

/******************************************************************************
 * save alu registers after calculations
 *
 * this is the only place the registers can be updated !
 *
 *
 *
 *
 *
 *
 *****************************************************************************/

reg [0:0] alu_initializing;

always @(posedge i_clk) begin

  /*
   * Initialization of all registers
   * This happens at the same time the first LOAD_PC command goes out
   *
   */

  if (i_reset) begin
    alu_initializing <= 1;
    CARRY            <= 0;
    P                <= 0;
    D0               <= 0;
    D1               <= 0;
  end

  if (alu_initializing) begin
    A[f_cur]         <= 0;
    B[f_cur]         <= 0;
    C[f_cur]         <= 0;
    D[f_cur]         <= 0;
    R0[f_cur]        <= 0;
    R1[f_cur]        <= 0;
    R2[f_cur]        <= 0;
    R3[f_cur]        <= 0;
    R4[f_cur]        <= 0;
    ST[f_cur]        <= 0;
    HST[f_cur[1:0]]  <= 0;
    alu_initializing <= (f_cur != 15);
  end

  /*
   * 
   * Debug for some JUMP condition testing
   *
   */

  if (do_alu_save || do_go_prep) begin
    if (alu_debug_jump) begin
    `ifdef SIM
      $display({"ALU_JUMP 3: run %b | done %b | stall %b | op %d | f %h | ",
                "c %h | l %h | bse %5h | jof %5h | jpc %5h | fin %b"},
                alu_run, alu_done, o_alu_stall_dec, alu_op, f_first, f_cur, 
                f_last, jump_bse, jump_off, jump_pc, alu_finish);
    `endif
    end
  end

  /*
   *
   * Epic shortcut for P= n case
   *
   */

  if (do_exec_p_eq) begin
    P <= i_imm_value;
  end

  /*
   * normal way for the ALU to save results. 
   *
   *
   */

  if (do_alu_save) begin
    `ifdef SIM
    if (alu_debug) begin
      $display({"ALU_SAVE 3: run %b | done %b | stall %b | op %d | f %h | c %h | l %h |",
                " dest %d | cres1 %h | cres2 %h | psrc1 %h | psrc2 %h | c_carry %b"}, 
                alu_run, alu_done, o_alu_stall_dec, alu_op, 
                f_first, f_cur, f_last, reg_dest, c_res1, c_res2, p_src1, p_src2, c_carry);

    end
    `endif

    case (alu_op)
      `ALU_OP_ZERO,
      `ALU_OP_COPY,
      `ALU_OP_EXCH, // does the first assign
      `ALU_OP_2CMPL,
      `ALU_OP_DEC,
      `ALU_OP_ADD,
      `ALU_OP_CLR_MASK:
        case (reg_dest)
        `ALU_REG_A:    A[f_cur] <= c_res1;
        `ALU_REG_B:    B[f_cur] <= c_res1;
        `ALU_REG_C:    C[f_cur] <= c_res1;
        `ALU_REG_D:    D[f_cur] <= c_res1;
        `ALU_REG_R0:   R0[f_cur] <= c_res1;
        `ALU_REG_R1:   R1[f_cur] <= c_res1;
        `ALU_REG_R2:   R2[f_cur] <= c_res1;
        `ALU_REG_R3:   R3[f_cur] <= c_res1;
        `ALU_REG_R4:   R4[f_cur] <= c_res1;
        `ALU_REG_D0:   D0[f_cur*4+:4] <= c_res1;
        `ALU_REG_D1:   D1[f_cur*4+:4] <= c_res1;
        `ALU_REG_ST:   ST[f_cur*4+:4] <= c_res1;
        `ALU_REG_P:    P <= c_res1;
        `ALU_REG_DAT0,
        `ALU_REG_DAT1: o_bus_nibble_out <= c_res1;
        `ALU_REG_HST:  HST <= c_res1;
        `ALU_REG_ADDR: begin end // done down below where o_bus_addr is accessible
        default: $display("#### ALU_SAVE invalid register %0d for op %0d", reg_dest, alu_op);
        endcase
      `ALU_OP_RST_BIT,
      `ALU_OP_SET_BIT:
        case (reg_dest)
        `ALU_REG_ST: ST[c_res1] <= alu_op==`ALU_OP_SET_BIT?1:0;
        default: $display("#### ALU_SAVE invalid register %0d for op %0d", reg_dest, alu_op);
        endcase
      `ALU_OP_TEST_EQ,
      `ALU_OP_TEST_NEQ,
      `ALU_OP_JMP_REL2,
      `ALU_OP_JMP_REL3,
      `ALU_OP_JMP_REL4,
      `ALU_OP_JMP_ABS5: begin end // nothing to save, handled by PC management below      
      default: $display("#### ALU_SAVE UNHANDLED OP %0d", alu_op);
    endcase 

    /*
     * in case of exch, we need to update src2 to finish the exchange
     */
    case (alu_op)
      `ALU_OP_EXCH: // 2nd assign, with src2
          case (reg_src2)
          `ALU_REG_A:   A[f_cur] <= c_res2;
          `ALU_REG_B:   B[f_cur] <= c_res2;
          `ALU_REG_C:   C[f_cur] <= c_res2;
          `ALU_REG_D:   D[f_cur] <= c_res2;
          `ALU_REG_D0:  D0[f_cur*4+:4] <= c_res2;
          `ALU_REG_D1:  D1[f_cur*4+:4] <= c_res2;
          `ALU_REG_R0:  R0[f_cur] <= c_res2;
          `ALU_REG_R1:  R1[f_cur] <= c_res2;
          `ALU_REG_R2:  R2[f_cur] <= c_res2;
          `ALU_REG_R3:  R3[f_cur] <= c_res2;
          `ALU_REG_R4:  R4[f_cur] <= c_res2;
          // `ALU_REG_ST:  ST[f_start*4+:4] <= c_res2;
          // `ALU_REG_P:   P <=                c_res2;
          // `ALU_REG_HST: HST <=              c_res2;
        endcase    
    endcase
  end

  /*
   * update carry
   */
  if (do_alu_save) begin
    case (alu_op)
    `ALU_OP_2CMPL: CARRY <= !is_zero;
    `ALU_OP_DEC,
    `ALU_OP_ADD,
    `ALU_OP_TEST_EQ,
    `ALU_OP_TEST_NEQ: CARRY <= c_carry;
    endcase
  end

  // do whatever is requested by the RTN instruction
  if (alu_active && i_ins_rtn) begin

    if (i_set_xm)
      HST[`ALU_HST_XM] <= 1;

    if (i_set_carry)
      CARRY <= i_carry_val;

  end

end

/******************************************************************************
 *
 * facility to detect that we just came out of reset 
 *
 *****************************************************************************/

reg  [0:0]  just_reset;

always @(posedge i_clk) begin

  if (i_reset)
    just_reset     <= 1;

  if (just_reset && do_alu_pc) begin
    just_reset    <= 0;
    $display("---------------------------------------- CLEARING JUST_RESET");
  end

end

/******************************************************************************
 *
 * WRITE TO MEMORY
 *
 *
 * Request the D0 or D1 pointers to be loaded to other 
 * modules through the bus
 *
 *
 *
 *
 *****************************************************************************/

reg  [0:0]  write_done;
reg  [1:0]  extra_cycles;

wire [0:0]  read_done;
wire [0:0]  read_done_t;
wire [0:0]  setup_load_dp_read;
wire [0:0]  setup_load_dp_write;
wire [0:0]  setup_load_dp;
wire [0:0]  no_extra_cycles;
wire [1:0]  cycles_to_go;

assign read_done_t          = is_mem_read && do_alu_save && ((f_cur +1) == f_last);
assign read_done           = (phase == 3) && i_stalled && is_mem_read && !do_alu_save && (f_cur == f_last);
assign setup_load_dp_read  = do_alu_init && is_mem_read && !read_done;
assign setup_load_dp_write = do_alu_init && is_mem_write && !write_done;
assign setup_load_dp       = setup_load_dp_read || setup_load_dp_write;
assign no_extra_cycles     = (extra_cycles == 0);
assign cycles_to_go        = extra_cycles - 1;

  reg [3:0] _f;
  reg [3:0] _l;

always @(posedge i_clk) begin

  // reset stuff
  if (i_reset) begin
    // read_done      <= 0;
    write_done     <= 0;
    extra_cycles   <= 0;
    o_bus_load_dp  <= 0;
    o_bus_dp_read  <= 0;
    o_bus_dp_write <= 0;
  end

  /*
   * reading
   * note: starts immediately
   */

  if (setup_load_dp_read) begin
    o_bus_load_dp <= 1;
    o_bus_dp_read <= 1;
    $display("%0d =========================================== XFR INIT %0d %0d => %0d", 
              phase, f_first, f_last, f_last - f_first);
    o_bus_xfr_cnt <= f_last - f_first;
  end

  // $display("phase %0d | i_stalled %b | is_mem_read %b | do_alu_save %b | f_cur+1 %0d | f_last %0d | read_done %b",
  //          phase, i_stalled, is_mem_read, do_alu_save, f_cur+1, f_last, read_done);
  if (read_done_t) begin
    $display("============================================= NEW read done");
  end

  if (read_done) begin
    $display("============================================= old read_done");
    o_bus_load_dp <= 0;
    o_bus_dp_read <= 0;
  end

  /*
   * writing
   */

  // setup the order to load DP in time
  if (setup_load_dp_write) begin
    o_bus_load_dp <= 1;
  end

  // tell the bus to start the write cycle
  // this will take 1 cycle because we need to send the DP_WRITE command
  if (do_busclean && alu_run && !write_done && is_mem_write && !o_bus_dp_write)
    o_bus_dp_write      <= 1;
  
  // writing takes 2 more cycles :
  // - one used up above
  // - one used down below to restore the PC_READ command
  if (do_alu_save && alu_finish && is_mem_write && (extra_cycles == 0)) begin
    extra_cycles <= 2;
    write_done   <= 1;
  end

  // if we're on cycle the last of the extra cycles, send the PC_READ command
  // so as to allow reading the instructions streams again to the decoder
  if (i_en_alu_calc && !no_extra_cycles) begin
    extra_cycles   <= cycles_to_go;
    if (cycles_to_go == 1) begin
      o_bus_dp_write <= 0;
      o_bus_pc_read  <= 1;
    end
  end

  // once the PC_READ command has been sent, remove the stall on the decoder
  if (i_en_alu_dump && no_extra_cycles && o_bus_pc_read) begin
    o_bus_pc_read   <= 0;
    write_done      <= 0;
  end

  if (do_busclean && o_bus_load_dp)
    o_bus_load_dp       <= 0;

end

/*****************************************************************************
 *
 * config and unconfig
 *
 ****************************************************************************/

wire is_bus_config;
assign is_bus_config = (alu_op == `ALU_OP_COPY) && (reg_dest == `ALU_REG_ADDR);
wire send_config;
assign send_config =  alu_active && (phase == 1) && i_ins_alu_op && alu_run && alu_finish;
wire clean_after_config;
assign clean_after_config = alu_active && (phase == 3) && o_bus_config && !alu_run;

always @(posedge i_clk) begin
  if (i_reset) 
    o_bus_config <= 0;

  // $display("send_config %b | is_bus_cfg %b | i_ins_cfg %b", send_config, is_bus_config, i_ins_config);
  if (send_config && is_bus_config && i_ins_config) begin
    $display("ALU %0d - =========================== ALU start configure mode", phase);
    o_bus_config <= 1;
  end


  if (clean_after_config) begin
    $display("ALU %0d - --------------------------- ALU end configure mode %b", phase, i_stalled);
    o_bus_config <= 0;
  end

end

/*****************************************************************************
 *
 * Handles all changes to PC 
 *
 ****************************************************************************/

wire [19:0] next_pc;
wire [19:0] goyes_off;
wire [19:0] goyes_pc;

wire [0:0]  is_jmp_rel2;
wire [0:0]  is_rtn_rel2;
wire [0:0]  jmp_carry_test;
wire [0:0]  exec_rtn_rel2;
wire [0:0]  set_jmp_rel2;
wire [0:0]  exec_jmp_rel2;

wire [0:0]  update_pc;
wire [0:0]  set_unc_jmp;
wire [0:0]  exec_unc_jmp;
wire [0:0]  exec_unc_rtn;
wire [0:0]  pop_pc;
wire [0:0]  reload_pc;
wire [0:0]  push_pc;

 
assign goyes_off = {{12{i_imm_value[3]}}, i_imm_value, jump_off[3:0]};
assign goyes_pc  = jump_bse + goyes_off;
// rtnyes is already handled by i_ins_test_go
assign is_rtn_rel2    = (alu_op == `ALU_OP_JMP_REL2) && (goyes_off == 0);
assign is_jmp_rel2    = (alu_op == `ALU_OP_JMP_REL2) && !(goyes_off == 0); 
assign jmp_carry_test = (i_test_carry && (CARRY == i_carry_val));
assign exec_rtn_rel2  = is_rtn_rel2 && jmp_carry_test && alu_done;
assign set_jmp_rel2   = is_jmp_rel2 && jmp_carry_test && alu_finish;
assign exec_jmp_rel2  = is_jmp_rel2 && jmp_carry_test && alu_done;


assign set_unc_jmp = is_alu_op_unc_jump && alu_finish;
assign exec_unc_jmp   = is_alu_op_unc_jump && alu_done;
assign exec_unc_rtn   = i_pop && i_ins_rtn;

assign pop_pc     = i_pop && i_ins_rtn &&  
                    ((!i_ins_test_go) ||                    
                     (i_ins_test_go && CARRY));

assign next_pc   = (set_unc_jmp || set_jmp_rel2)?jump_pc:PC + 1;
assign update_pc    = !o_alu_stall_dec || exec_unc_jmp || exec_jmp_rel2 || just_reset;
assign reload_pc  = (exec_unc_jmp || pop_pc || just_reset || exec_jmp_rel2);
assign push_pc    = update_pc && i_push && alu_finish;

always @(posedge i_clk) begin

  /*
   * initializes the PC
   *
   */

  if (i_reset) begin
    PC             <= ~0;
    o_bus_load_pc  <= 0;
    rstk_ptr       <= 0;
  end

  /*
   * Similarly to the data registers,
   * initializes the RSTK while the PC is first loaded
   *
   */
  if (alu_initializing)
    RSTK[f_cur[2:0]] <= 0;


  // necessary for the write to memory above
  // otherwise we get a conflict on o_bus_address
  if (setup_load_dp) 
    case (mem_reg[0])
    0: o_bus_address <= D0;
    1: o_bus_address <= D1;
    endcase

  // this is moved here for access conflicts to o_bus_address
  if (do_alu_save && (alu_op == `ALU_OP_COPY) && (reg_dest == `ALU_REG_ADDR)) begin
    o_bus_address[f_cur*4+:4] <= c_res1;
  end

  /**
   *
   * Update the PC.
   * Request the new PC be loaded to the other modules through 
   * the bus if necessary 
   *
   */

  if (do_alu_pc) begin
    // $display("DO ALU PC");
`ifdef SIM
    if (alu_debug_pc)
      $display({"ALU_PC   3: !stl %b | nx %5h | done %b | fin %b | ",
                "uncjmp %b | ins_rtn %b | push %b | imm %h | ",
                "c_test %b | jmpr2 %b | rtn[n]c %b |",
                "j_bs %h | go_off %h | go_pc %h | update %b | PC <= %h"},
                !o_alu_stall_dec,  next_pc, alu_done, alu_finish, 
                is_alu_op_unc_jump, i_ins_rtn, i_push, i_imm_value, 
                jmp_carry_test, exec_jmp_rel2, exec_rtn_rel2,
                jump_bse, goyes_off, goyes_pc, update_pc, pop_pc ? RSTK[rstk_ptr - 1] : next_pc);
`endif

    // this may do wierd things with C=RSTK...
    if (update_pc) begin
      PC <= pop_pc ? RSTK[rstk_ptr - 1] : next_pc;
    end

    if (reload_pc) begin
      // $display("ALU_PC   3: $$$$ RELOADING PC $$$$");
      o_bus_address <= pop_pc ? RSTK[rstk_ptr-1] : next_pc;
      o_bus_load_pc <= 1;
    end

    // $display("pop %b && rtn %b && ((!go %b) || (go %b && c %b))", 
    //          i_pop, i_ins_rtn, !i_ins_test_go, i_ins_test_go, c_carry);
    if (pop_pc) begin
      $display("POP RSTK[%0d] to PC %5h", rstk_ptr-1, RSTK[rstk_ptr - 1]);
      RSTK[rstk_ptr - 1] <= 0;
      rstk_ptr <= rstk_ptr - 1;
    end

    if (push_pc) begin
      $display("PUSH PC %5h to RSTK[%0d]", PC, rstk_ptr);
      RSTK[rstk_ptr] <= PC;
      rstk_ptr       <= rstk_ptr + 1;
    end
  end

  /*
   *
   * Deactivate the load_pc or load_dp enables on the next clock
   *
   */

  if (do_busclean && o_bus_load_pc)
    o_bus_load_pc       <= 0;

end

/*****************************************************************************
 *
 * execute SETHEX and SETDEC 
 *
 ****************************************************************************/

always @(posedge i_clk) begin
  if (i_reset) 
    DEC <= 0;

  // changing calculation modes
  if (do_alu_mode) begin
    $display("SETTING MODE TO %s", i_mode_dec?"DEC":"HEX");
    DEC <= i_mode_dec;
  end
end


endmodule

`endif