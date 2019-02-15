
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
    i_en_alu_dump,
	  i_en_alu_prep,
	  i_en_alu_calc,
    i_en_alu_init,
	  i_en_alu_save,

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
    i_ins_set_mode,
    i_ins_rtn,

    i_mode_dec,
    i_set_xm,
    i_set_carry,
    i_carry_val,

    o_reg_p,
    o_pc
);

input   wire [0:0]  i_clk;
input   wire [0:0]  i_reset;
input   wire [0:0]  i_en_alu_dump;
input   wire [0:0]  i_en_alu_prep;
input   wire [0:0]  i_en_alu_calc;
input   wire [0:0]  i_en_alu_init;
input   wire [0:0]  i_en_alu_save;

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
input   wire [0:0]  i_ins_set_mode; 
input   wire [0:0]  i_ins_rtn;

input   wire [0:0]  i_mode_dec;
input   wire [0:0]  i_set_xm;
input   wire [0:0]  i_set_carry;
input   wire [0:0]  i_carry_val;

output  wire [3:0]  o_reg_p;
output  wire [19:0] o_pc;

assign o_reg_p = P;
assign o_pc    = PC;

/* internal registers */

/* copy of arguments */
reg [4:0] alu_op;
reg [4:0] reg_dest;
reg [4:0] reg_src1;
reg [4:0] reg_src2;
reg [3:0] f_start;
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

reg  [63:0]      A;
reg  [63:0]      B;
reg  [63:0]      C;
reg  [63:0]      D;

reg  [63:0]      R0;
reg  [63:0]      R1;
reg  [63:0]      R2;
reg  [63:0]      R3;
reg  [63:0]      R4;

reg  [0:0]       CARRY;
reg  [0:0]       DEC;
reg  [3:0]       P;
reg  [3:0]       HST;
reg  [15:0]      ST;

reg  [19:0]      RSTK[0:7];


initial begin
  // alu internal control bits
  alu_op          = 0;
  reg_dest        = 0;
  reg_src1        = 0;
  reg_src2        = 0;
  f_start         = 0;
  f_last          = 0;

  alu_run         = 0;
  alu_done        = 0;

  p_src1          = 0;
  p_src2          = 0;
  p_carry         = 0;
  c_res1          = 0;
  c_res2          = 0;
  c_carry         = 0;
  is_zero         = 0;
//   o_alu_stall_dec = 0;
  // processor registers
  PC              = 0;

  D0              = 0;
  D1              = 0;

  A               = 0;
  B               = 0;
  C               = 0;
  D               = 0;
  
  R0              = 0;
  R1              = 0;
  R2              = 0;
  R3              = 0;
  R4              = 0;

  CARRY           = 0;
  DEC             = 0;
  P               = 0;
  HST             = 0;
  ST              = 0;

  rstk_ptr        = 0;
  RSTK[0]         = 0;
  RSTK[1]         = 0;
  RSTK[2]         = 0;
  RSTK[3]         = 0;
  RSTK[4]         = 0;
  RSTK[5]         = 0;
  RSTK[6]         = 0;
  RSTK[7]         = 0;
end

`ifdef SIM
wire do_reg_dump;
wire do_alu_shpc;
assign do_reg_dump = (!i_reset) && i_en_alu_dump && i_ins_decoded && !o_alu_stall_dec;
assign do_alu_shpc = (!i_reset) && i_en_alu_dump;
`endif

wire do_alu_init;
wire do_alu_prep;
wire do_alu_calc;
wire do_alu_save;
wire do_alu_pc;
wire do_alu_mode;

assign do_alu_init = !i_reset && i_en_alu_init && i_ins_alu_op && !alu_run; 
assign do_alu_prep = !i_reset && i_en_alu_prep && alu_run;
assign do_alu_calc = !i_reset && i_en_alu_calc && alu_run;
assign do_alu_save = !i_reset && i_en_alu_save && alu_run;
assign do_alu_pc   = !i_reset && i_en_alu_save;
assign do_alu_mode = !i_reset && i_en_alu_save && i_ins_set_mode;

// the decoder may request the ALU to not stall it

assign o_alu_stall_dec = alu_run && (!i_alu_no_stall || alu_finish);

wire       alu_start;
wire       alu_finish;
wire [3:0] f_next;

assign alu_start  = f_start == 0;
assign alu_finish = f_start == f_last;
assign f_next     = (f_start + 1) & 4'hF;

/*
 * test things on alu_op
 */

wire is_alu_op_jump;
assign is_alu_op_jump = ((alu_op == `ALU_OP_JMP_REL3) ||
                         (alu_op == `ALU_OP_JMP_REL4) ||
                         (alu_op == `ALU_OP_JMP_ABS5) ||
                         i_ins_rtn);

/*****************************************************************************
 *
 * Dump all registers at the end of each instruction's execution cycle
 *
 ****************************************************************************/

always @(posedge i_clk) begin
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
    $display("A:  %h    R0:  %h   RSTK5: %5h", A, R0, RSTK[5]);
    $display("B:  %h    R1:  %h   RSTK4: %5h", B, R1, RSTK[4]);
    $display("C:  %h    R2:  %h   RSTK3: %5h", C, R2, RSTK[3]);
    $display("D:  %h    R3:  %h   RSTK2: %5h", D, R3, RSTK[2]);
    $display("D0: %h  D1: %h    R4:  %h   RSTK1: %5h", 
              D0, D1, R4, RSTK[1]);
    $display("                                                RSTK0: %5h", 
             RSTK[0]);
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
  // this happens in phase 3, right after the instruction decoder (in phase 2) is finished
  if (do_alu_init) begin

`ifdef SIM
    if (alu_debug)
      $display({"ALU_INIT 3: run %b | done %b | stall %b | op %d | s %h | l %h ",
                "| ialu %b | dest %d | src1 %d | src2 %d | imm %h"},
               alu_run, alu_done, o_alu_stall_dec, i_alu_op,i_field_start, i_field_last,  
               i_ins_alu_op, i_reg_dest, i_reg_src1, i_reg_src2, i_imm_value);
`endif

    jump_bse <= PC;
    alu_op   <= i_alu_op;
    reg_dest <= i_reg_dest;
    reg_src1 <= i_reg_src1;
    reg_src2 <= i_reg_src2;
    f_start  <= i_field_start;
    f_last   <= i_field_last;

    if (is_mem_xfer) begin
`ifdef SIM
      $display("ALU_XFER 3: read %b | write %b | mem_reg DAT%b",
               is_mem_read, is_mem_write, mem_reg[0]);
      $display(".------------------------------------.");
      $display("| SHOULD TELL THE BUS CONTROLLER TO  |");
      $display("| LOAD D0 OR D1 INTO MODULES' DP REG |");
      $display("`------------------------------------´");
`endif
      // DO SOMETHING TO GET THE BUS CONTROLLER TO SEND OUT 
      // THE CONTENTS OF D0 OR D1 AS THE DP 
    end
  end
end

/*
 * handles alu_done
 */

always @(posedge i_clk) begin
  if (do_alu_init) alu_run <= 1;
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
    f_start  <= f_next;
  end    
  if (do_alu_save && alu_done) begin
    alu_run <= 0;
    alu_done <= 0;
  end
end



always @(posedge i_clk) begin
  if (do_alu_prep) begin
    if (alu_debug) begin
      `ifdef SIM
      $display("ALU_PREP 1: run %b | done %b | stall %b | op %d | s %h | l %h", 
               alu_run, alu_done, o_alu_stall_dec, alu_op, f_start, f_last);
      `endif
    end

    case (alu_op)
    `ALU_OP_ZERO: begin end // no source required
    `ALU_OP_COPY,
    `ALU_OP_RST_BIT,
    `ALU_OP_SET_BIT,
    `ALU_OP_2CMPL,
    `ALU_OP_JMP_REL3,
    `ALU_OP_JMP_REL4,
    `ALU_OP_JMP_ABS5,
    `ALU_OP_CLR_MASK:
      case (reg_src1)
      `ALU_REG_A:    p_src1 <= A [f_start*4+:4];
      `ALU_REG_B:    p_src1 <= B [f_start*4+:4];
      `ALU_REG_C:    p_src1 <= C [f_start*4+:4];
      `ALU_REG_D:    p_src1 <= D [f_start*4+:4];
      `ALU_REG_D0:   p_src1 <= D0[f_start*4+:4];
      `ALU_REG_D1:   p_src1 <= D1[f_start*4+:4];
      `ALU_REG_P:    p_src1 <= P;
      `ALU_REG_HST:  p_src1 <= HST;
      `ALU_REG_IMM:  p_src1 <= i_imm_value;
      `ALU_REG_ZERO: p_src1 <= 0;
      default: $display("#### SRC_1 UNHANDLED REGISTER %0d", reg_src1);
      endcase
    default: $display("#### SRC_1 UNHANDLED OPERATION %0d", alu_op);
    endcase

    case (alu_op)
    `ALU_OP_CLR_MASK:
      case (reg_src2)
      `ALU_REG_IMM: p_src2 <= i_imm_value;
      default: $display("#### SRC_2 UNHANDLED REGISTER %0d", reg_src2);
      endcase
    `ALU_OP_ZERO: begin end // no source required
    `ALU_OP_COPY,
    `ALU_OP_RST_BIT,
    `ALU_OP_SET_BIT,
    `ALU_OP_2CMPL,
    `ALU_OP_JMP_REL3,
    `ALU_OP_JMP_REL4,
    `ALU_OP_JMP_ABS5: begin end // no need for a 2nd operand
    default: $display("#### SRC_2 UNHANDLED OPERATION %0d", alu_op);
    endcase

    // setup p_carry
    // $display("fs %h | fs=0 %b | cc %b | npc %b", f_start, (f_start == 0), c_carry, (f_start == 0)?1'b1:c_carry);
    case (alu_op)
    `ALU_OP_2CMPL: p_carry <= (f_start == 0)?1'b1:c_carry;
    endcase

  end
end

always @(posedge i_clk) begin
  if (do_alu_calc) begin
    `ifdef SIM
    if (alu_debug)
      $display("ALU_CALC 2: run %b | done %b | stall %b | op %d | s %h | l %h | dest %d | src1 %h | src2 %h | p_carry %b", 
               alu_run, alu_done, o_alu_stall_dec, alu_op, f_start, f_last, reg_dest, p_src1, p_src2, p_carry);
    if (alu_debug_jump)
      $display("ALU_JUMP 2: run %b | done %b | stall %b | op %d | s %h | l %h | jbs %5h | jof %5h | jpc %5h | fin %b",
               alu_run, alu_done, o_alu_stall_dec, alu_op, f_start, f_last, jump_bse, jump_off, jump_pc, alu_finish);
    `endif

    case (alu_op)
    `ALU_OP_JMP_REL3,
    `ALU_OP_JMP_REL4,
    `ALU_OP_JMP_ABS5: if (alu_start)
                        jump_off               <= { 16'b0, p_src1 };
    endcase

    case (alu_op)
    `ALU_OP_ZERO:       c_res1                 <= 0;
    `ALU_OP_COPY,
    `ALU_OP_RST_BIT,
    `ALU_OP_SET_BIT:    c_res1                 <= p_src1;
    `ALU_OP_2CMPL:      begin 
                        c_carry                <= (~p_src1 == 4'hf) && p_carry ;
                        c_res1                 <= ~p_src1 + p_carry;
                        is_zero                <= ((~p_src1 + p_carry) == 0) && (f_start == 0)?1:is_zero;
                        end
    `ALU_OP_JMP_REL3,
    `ALU_OP_JMP_REL4,
    `ALU_OP_JMP_ABS5:   jump_off[f_start*4+:4] <= p_src1;
    `ALU_OP_CLR_MASK:   c_res1                 <= p_src1 & ~p_src2;
    endcase

    case (alu_op)
    `ALU_OP_JMP_REL3: if (alu_finish)
                        jump_off               <= { {8{p_src1[3]}}, p_src1, jump_off[7:0] };
    `ALU_OP_JMP_REL4: if (alu_finish)
                        jump_off               <= { {4{p_src1[3]}}, p_src1, jump_off[11:0] };
    endcase

    // $display("-------C- SRC1 %b %h | ~SRC1 %b %h | PC %b | RES1 %b %h | CC %b", 
    //          p_src1, p_src1, ~p_src1, ~p_src1, p_carry, 
    //          (~p_src1) + p_carry, (~p_src1) + p_carry, 
    //          (~p_src1) == 4'hf );
  end
end

always @(posedge i_clk) begin

  if (do_alu_save) begin
    `ifdef ALU_DEBUG
    if (alu_debug)
      $display({"ALU_SAVE 3: run %b | done %b | stall %b | op %d | s %h | l %h |",
                " dest %d | res1 %h | res2 %h | c_carry %b"}, 
                alu_run, alu_done, o_alu_stall_dec, alu_op, 
                f_start, f_last, reg_dest, c_res1, c_res2, c_carry);
    if (alu_debug_jump)
      $display( "ALU_JUMP 3: run %b | done %b | stall %b | op %d | s %h | l %h | bse %5h | jof %5h | jpc %5h | fin %b",
                alu_run, alu_done, o_alu_stall_dec, alu_op, f_start, f_last, jump_bse, jump_off, jump_pc, alu_finish);
    `endif

    // $display("-------S- SRC1 %b %h | ~SRC1 %b %h | PC %b | RES1 %b %h | CC %b", 
    //          p_src1, p_src1, ~p_src1, ~p_src1, p_carry, 
    //          (~p_src1) + p_carry, (~p_src1) + p_carry, 
    //          (~p_src1) == 4'hf );

    case (alu_op)
      `ALU_OP_ZERO,
      `ALU_OP_COPY,
      `ALU_OP_2CMPL,
      `ALU_OP_CLR_MASK:
        case (reg_dest)
        `ALU_REG_A:   A [f_start*4+:4] <= c_res1;
        `ALU_REG_B:   B [f_start*4+:4] <= c_res1;
        `ALU_REG_C:   C [f_start*4+:4] <= c_res1;
        `ALU_REG_D:   D [f_start*4+:4] <= c_res1;
        `ALU_REG_D0:  D0[f_start*4+:4] <= c_res1;
        `ALU_REG_D1:  D1[f_start*4+:4] <= c_res1;
        `ALU_REG_ST:  ST[f_start*4+:4] <= c_res1;
        `ALU_REG_P:   P <=                c_res1;
        `ALU_REG_HST: HST <=              c_res1;
        endcase
      `ALU_OP_RST_BIT,
      `ALU_OP_SET_BIT:
        case (reg_dest)
        `ALU_REG_ST: ST[c_res1] <= alu_op==`ALU_OP_SET_BIT?1:0;
        default: $display("#### ALU_SAVE invalid register %0d for op %0d", reg_dest, alu_op);
        endcase
      `ALU_OP_JMP_REL3,
      `ALU_OP_JMP_REL4,
      `ALU_OP_JMP_ABS5: begin end // nothing to save, handled by PC management below      
      default: $display("#### ALU_SAVE UNHANDLED OP %0d", alu_op);
    endcase 
  end


  if (do_alu_save) begin
    case (alu_op)
    `ALU_OP_2CMPL: CARRY <= !is_zero;
    endcase
  end

  // do whatever is requested by the RTN instruction
  if (i_ins_rtn) begin

    if (i_set_xm)
      HST[`ALU_HST_XM] <= 1;

    if (i_set_carry)
      CARRY <= i_carry_val;

  end

end

/*****************************************************************************
 *
 * Handles all changes to PC 
 *
 ****************************************************************************/

wire [19:0] next_pc;
wire [0:0]  update_pc;
wire [0:0]  push_pc;

assign next_pc   = (is_alu_op_jump && alu_finish)?jump_pc:PC + 1;
assign update_pc = !o_alu_stall_dec || is_alu_op_jump;
assign push_pc   = update_pc && i_push && alu_done;

always @(posedge i_clk) begin
  if (i_reset)
    PC <= ~0;

  /*
   * some debug information
   */

`ifdef SIM
  if (do_alu_shpc && alu_debug_pc) begin
    if (!o_alu_stall_dec)
      $display("ALU_SHPC 0: pc %5h", PC);
    if (o_alu_stall_dec)
      $display("ALU_SHPC 0: STALL");
  end
`endif

  /*
   * updates the PC
   */
  if (do_alu_pc) begin
`ifdef SIM
    if (alu_debug_pc)
      $display("ALU_PC   3: !stl %b | nx %5h | jmp %b | push %b",
               !o_alu_stall_dec,  next_pc, is_alu_op_jump, i_push);
      if ((is_alu_op_jump && alu_done) || i_ins_rtn) begin
        $display(".---------------------------------.");
        $display("| SHOULD TELL THE BUS CONTROLLER  |");
        $display("| TO LOAD PC INTO MODULES' PC REG |");
        $display("`---------------------------------´");
      end
`endif
    // this may do wierd things with C=RSTK...
    if (update_pc) begin
      PC <= i_pop ? RSTK[rstk_ptr-1] : next_pc;
    end

    if (i_pop) begin
      RSTK[rstk_ptr - 1] <= 0;
      rstk_ptr <= rstk_ptr - 1;
    end

    if (push_pc) begin
      $display("PUSH PC %5h to RSTK[%0d]", PC, rstk_ptr);
      RSTK[rstk_ptr] <= PC;
      rstk_ptr       <= rstk_ptr + 1;
    end
  end
end

/*****************************************************************************
 *
 * execute SETHEX and SETDEC 
 *
 ****************************************************************************/

always @(posedge i_clk)
  // changing calculation modes
  if (do_alu_mode) begin
    $display("SETTING MODE TO %s", i_mode_dec?"DEC":"HEX");
    DEC <= i_mode_dec;
  end


endmodule

`endif