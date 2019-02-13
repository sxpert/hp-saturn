`ifndef _SATURN_ALU
`define _SATURN_ALU

`include "def-alu.v"

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
    i_reg_dest,
    i_reg_src1,
    i_reg_src2,

    i_ins_alu_op,

    o_reg_p,
    i_pc
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
input   wire [4:0]  i_reg_dest;
input   wire [4:0]  i_reg_src1;
input   wire [4:0]  i_reg_src2;

input   wire        i_ins_alu_op;

output  wire [3:0]  o_reg_p;
input   wire [19:0] i_pc;

assign o_reg_p = P;

wire [19:0]      PC;
assign PC = i_pc + 1;

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

assign do_reg_dump = (!i_reset) && i_en_alu_dump && i_ins_decoded && !o_alu_stall_dec;
assign do_alu_init = (!i_reset) && i_en_alu_init && i_ins_alu_op && !alu_run; 
assign do_alu_prep = (!i_reset) && i_en_alu_prep;
assign do_alu_calc = (!i_reset) && i_en_alu_calc;
assign do_alu_save = (!i_reset) && i_en_alu_save;

reg       alu_run;
reg       alu_done;

assign o_alu_stall_dec = alu_run;

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
    $display({"ALU_INIT 3: run %b | done %b | stall %b | i_alu %b |",
              " op %d | dest %d | src1 %d | src2 %d | start %h | end %h"},
             alu_run, alu_done, o_alu_stall_dec, i_ins_alu_op, i_alu_op, 
             i_reg_dest, i_reg_src1, i_reg_src2, i_field_start, i_field_last);
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
  if (do_alu_prep && alu_run) alu_done <= 0;
  if (do_alu_calc && alu_run && (f_start == f_last)) alu_done <= 1; 
  if (do_alu_save && alu_done) begin
    alu_run <= 0;
    alu_done <= 0;
  end
end



always @(posedge i_clk) begin
  if (do_alu_prep && alu_run) begin
    `ifdef SIM
    $display("ALU_PREP 1: run %b | done %b | stall %b | op %b | alu_op %h | f_start %h | f_last %h", 
             alu_run, alu_done, o_alu_stall_dec, alu_op, i_alu_op, f_start, f_last);
    `endif
    

    // setup value for src1

    case (alu_op)
    `ALU_OP_ZERO: begin end // no source required
    `ALU_OP_COPY:
      case (reg_src1)
      `ALU_REG_P:   p_src1 <= P;
      `ALU_REG_IMM: p_src1 <= i_imm_value;
      endcase
    endcase

    // setup p_carry

  end
end

always @(posedge i_clk) begin
  if (do_alu_calc) begin
    $display("ALU_CALC 2: run %b | done %b | stall %b | op %d | src1 %h | src2 %h | p_carry %b", 
             alu_run, alu_done, o_alu_stall_dec, alu_op, p_src1, p_src2, p_carry);

    case (alu_op)
    `ALU_OP_ZERO: c_res1 <= 0;
    `ALU_OP_COPY: c_res1 <= p_src1;
    endcase
  end
end

always @(posedge i_clk) begin
  if (do_alu_save) begin
    $display("ALU_SAVE 3: run %b | done %b | stall %b | op %b | res1 %h | res2 %h | c_carry %b", 
             alu_run, alu_done, o_alu_stall_dec, alu_op, c_res1, c_res2, c_carry);

    case (alu_op)
    `ALU_OP_ZERO,
    `ALU_OP_COPY:
      case (reg_dest)
      `ALU_REG_P: P <= c_res1;
      endcase
    endcase 

  end
  
end

endmodule
