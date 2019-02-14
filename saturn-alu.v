`ifndef _SATURN_ALU
`define _SATURN_ALU

`include "def-alu.v"

`define ALU_DEBUG

module saturn_alu (
    i_clk,
    i_reset,
    i_en_alu_dump,
	i_en_alu_prep,
	i_en_alu_calc,
    i_en_alu_init,
	i_en_alu_save,

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

input   wire        i_ins_alu_op;

output  wire [3:0]  o_reg_p;
output  wire [19:0] o_pc;

assign o_reg_p = P;
assign o_pc    = PC;

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

reg  [2:0]       rstk_ptr;
reg  [19:0]      RSTK[0:7];


initial begin
  // alu internal control bits
  alu_run         = 0;
  alu_done        = 0;
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

wire do_reg_dump;
wire do_alu_init;
wire do_alu_prep;
wire do_alu_calc;
wire do_alu_save;
wire do_alu_shpc;
wire do_alu_pc;

assign do_reg_dump = (!i_reset) && i_en_alu_dump && i_ins_decoded && !o_alu_stall_dec;
assign do_alu_init = (!i_reset) && i_en_alu_init && i_ins_alu_op && !alu_run; 
assign do_alu_prep = (!i_reset) && i_en_alu_prep && alu_run;
assign do_alu_calc = (!i_reset) && i_en_alu_calc && alu_run;
assign do_alu_save = (!i_reset) && i_en_alu_save && alu_run;
assign do_alu_shpc = (!i_reset) && i_en_alu_dump;
assign do_alu_pc   = (!i_reset) && i_en_alu_save;

reg        alu_run;
reg        alu_done;
wire       test_finish;
wire [3:0] f_next;

assign test_finish = f_start == f_last;
assign f_next      = (f_start + 1) & 4'hF;

// the decoder may request the ALU to not stall it


assign o_alu_stall_dec = alu_run && (!i_alu_no_stall || test_finish);

reg [4:0] alu_op;
reg [4:0] reg_dest;
reg [4:0] reg_src1;
reg [4:0] reg_src2;
reg [3:0] f_start;
reg [3:0] f_last;

reg [3:0] p_src1;
reg [3:0] p_src2;
reg       p_carry;
reg [3:0] c_res1;
reg [3:0] c_res2;
reg       c_carry;


/*
 * dump all registers 
 * this only reads things...
 *
 */ 

always @(posedge i_clk) begin
  if (do_reg_dump) begin
    $display("ALU_DUMP 0: run %b | done %b ", alu_run, alu_done);
    `ifdef SIM
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
    `endif
  end
end


always @(posedge i_clk) begin
  // this happens in phase 3, right after the instruction decoder (in phase 2) is finished
  if (do_alu_init) begin
    $display({"ALU_INIT 3: run %b | done %b | stall %b | op %d | s %h | l %h ",
              "| ialu %b | dest %d | src1 %d | src2 %d"},
             alu_run, alu_done, o_alu_stall_dec, i_alu_op,i_field_start, i_field_last,  
             i_ins_alu_op, i_reg_dest, i_reg_src1, i_reg_src2);
    alu_op   <= i_alu_op;
    reg_dest <= i_reg_dest;
    reg_src1 <= i_reg_src1;
    reg_src2 <= i_reg_src2;
    f_start  <= i_field_start;
    f_last   <= i_field_last;
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
    alu_done <= test_finish; 
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
    `ifdef ALU_DEBUG
    $display("ALU_PREP 1: run %b | done %b | stall %b | op %d | s %h | l %h", 
             alu_run, alu_done, o_alu_stall_dec, alu_op, f_start, f_last);
    `endif
    

    // setup value for src1

    case (alu_op)
    `ALU_OP_ZERO: begin end // no source required
    `ALU_OP_COPY,
    `ALU_OP_JMP_REL3:
      case (reg_src1)
      `ALU_REG_A:   p_src1 <= A [f_start*4+:4];
      `ALU_REG_B:   p_src1 <= B [f_start*4+:4];
      `ALU_REG_C:   p_src1 <= C [f_start*4+:4];
      `ALU_REG_D:   p_src1 <= D [f_start*4+:4];
      `ALU_REG_D0:  p_src1 <= D0[f_start*4+:4];
      `ALU_REG_D1:  p_src1 <= D1[f_start*4+:4];
      `ALU_REG_P:   p_src1 <= P;
      `ALU_REG_IMM: p_src1 <= i_imm_value;
      endcase
    endcase

    // setup p_carry

  end
end

always @(posedge i_clk) begin
  if (do_alu_calc) begin
    `ifdef ALU_DEBUG
    $display("ALU_CALC 2: run %b | done %b | stall %b | op %d | s %h | l %h | src1 %h | src2 %h | p_carry %b", 
             alu_run, alu_done, o_alu_stall_dec, alu_op, f_start, f_last, p_src1, p_src2, p_carry);
    `endif

    case (alu_op)
    `ALU_OP_ZERO: c_res1 <= 0;
    `ALU_OP_COPY: c_res1 <= p_src1;
    endcase
  end
end

always @(posedge i_clk) begin
  if (do_alu_save) begin
    `ifdef ALU_DEBUG
    $display({"ALU_SAVE 3: run %b | done %b | stall %b | op %d | s %h | l %h |",
             " res1 %h | res2 %h | c_carry %b"}, 
             alu_run, alu_done, o_alu_stall_dec, alu_op, 
             f_start, f_last, c_res1, c_res2, c_carry);
    `endif

    case (alu_op)
    `ALU_OP_ZERO,
    `ALU_OP_COPY:
      case (reg_dest)
      `ALU_REG_C:  C [f_start*4+:4] <= c_res1;
      `ALU_REG_D0: D0[f_start*4+:4] <= c_res1;
      `ALU_REG_D1: D1[f_start*4+:4] <= c_res1;
      `ALU_REG_P:  P <= c_res1;
      endcase
    endcase 

  end
end

wire [19:0] next_pc;
assign next_pc = PC + 1;
always @(posedge i_clk) begin
  if (i_reset)
    PC <= ~0;

  if (do_alu_shpc) begin
    // if (!o_alu_stall_dec)
    //   $display("ALU_SHPC 0: pc %5h", PC);
    if (o_alu_stall_dec)
      $display("ALU_SHPC 0: STALL");
  end

  if (do_alu_pc) begin
    // if (!o_alu_stall_dec)
    //   $display("ALU_PC   3: nx %5h", next_pc);
    if (!o_alu_stall_dec)
      PC <= next_pc;
  end
end

endmodule
