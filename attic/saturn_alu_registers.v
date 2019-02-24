
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

`default_nettype none //

`include "def-alu.v"

`ifndef _SATURN_ALU_REGISTERS
`define _SATURN_ALU_REGISTERS


module saturn_alu_registers (
    i_clk,
    i_reset,
    i_stalled,
    i_phase,
    i_phase_3,
    i_cycle_ctr,
    i_alu_initializing,
    i_ins_decoded,

    i_src_ptr,
    i_src_1,
    o_src_1_nbl,
    o_src_1_valid,
    i_src_2,
    o_src_2_nbl,
    o_src_2_valid,

    i_dest_ptr,
    i_dest_1,
    i_dest_1_nbl,
    i_dest_2,
    i_dest_2_nbl

`ifdef SIM
    ,
    i_dbg_src,
    i_dbg_ptr,
    o_dbg_nbl
`endif
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_reset;
input  wire [0:0]  i_stalled;
input  wire [1:0]  i_phase;
input  wire [0:0]  i_phase_3;
input  wire [31:0] i_cycle_ctr;
input  wire [0:0]  i_alu_initializing;
input  wire [0:0]  i_ins_decoded;

input  wire [3:0]  i_src_ptr;
input  wire [4:0]  i_src_1;
output reg  [3:0]  o_src_1_nbl;
output reg  [0:0]  o_src_1_valid;
input  wire [4:0]  i_src_2;
output reg  [3:0]  o_src_2_nbl;
output reg  [0:0]  o_src_2_valid;

input  wire [3:0]  i_dest_ptr;
input  wire [4:0]  i_dest_1;
input  wire [3:0]  i_dest_1_nbl;
input  wire [4:0]  i_dest_2;
input  wire [3:0]  i_dest_2_nbl;

`ifdef SIM
input  wire [4:0]  i_dbg_src;
input  wire [3:0]  i_dbg_ptr;
output reg  [3:0]  o_dbg_nbl;
`endif

wire [0:0] reg_store_ev;
assign reg_store_ev = !i_reset && !i_alu_initializing && !i_stalled && i_ins_decoded && i_phase_3;

/* public registers */

reg  [3:0]       D0[0:4];
reg  [3:0]       D1[0:4];

reg  [3:0]       A[0:15];
reg  [3:0]       B[0:15];
reg  [3:0]       C[0:15];
reg  [3:0]       D[0:15];

reg  [3:0]      R0[0:15];
reg  [3:0]      R1[0:15];
reg  [3:0]      R2[0:15];
reg  [3:0]      R3[0:15];
reg  [3:0]      R4[0:15];


`ifdef SIM
always @(i_src_ptr, i_src_1, i_src_2, i_dbg_src, i_dbg_ptr) begin
`else
always @(i_src_ptr, i_src_1, i_src_2) begin
`endif
  o_src_1_nbl   = 4'b0000;
  o_src_1_valid = 1'b1;
  o_src_2_nbl   = 4'b0000;
  o_src_2_valid = 1'b1;

  case (i_src_1)
    `ALU_REG_A:  o_src_1_nbl = A [i_src_ptr];
    `ALU_REG_B:  o_src_1_nbl = B [i_src_ptr];
    `ALU_REG_C:  o_src_1_nbl = C [i_src_ptr];
    `ALU_REG_D:  o_src_1_nbl = D [i_src_ptr];
    `ALU_REG_D0: o_src_1_nbl = D0[i_src_ptr[2:0]];
    `ALU_REG_D1: o_src_1_nbl = D1[i_src_ptr[2:0]];
    `ALU_REG_R0: o_src_1_nbl = R0[i_src_ptr];
    `ALU_REG_R1: o_src_1_nbl = R1[i_src_ptr];
    `ALU_REG_R2: o_src_1_nbl = R2[i_src_ptr];
    `ALU_REG_R3: o_src_1_nbl = R3[i_src_ptr];
    `ALU_REG_R4: o_src_1_nbl = R4[i_src_ptr];
    default: o_src_1_valid = 1'b0;
  endcase

  case (i_src_2)
    `ALU_REG_A:  o_src_2_nbl = A [i_src_ptr];
    `ALU_REG_B:  o_src_2_nbl = B [i_src_ptr];
    `ALU_REG_C:  o_src_2_nbl = C [i_src_ptr];
    `ALU_REG_D:  o_src_2_nbl = D [i_src_ptr];
    `ALU_REG_D0: o_src_2_nbl = D0[i_src_ptr[2:0]];
    `ALU_REG_D1: o_src_2_nbl = D1[i_src_ptr[2:0]];
    `ALU_REG_R0: o_src_2_nbl = R0[i_src_ptr];
    `ALU_REG_R1: o_src_2_nbl = R1[i_src_ptr];
    `ALU_REG_R2: o_src_2_nbl = R2[i_src_ptr];
    `ALU_REG_R3: o_src_2_nbl = R3[i_src_ptr];
    `ALU_REG_R4: o_src_2_nbl = R4[i_src_ptr];
    default: o_src_2_valid = 1'b0;
  endcase

`ifdef SIM
  case (i_dbg_src)
    `ALU_REG_A:  o_dbg_nbl = A [i_dbg_ptr];
    `ALU_REG_B:  o_dbg_nbl = B [i_dbg_ptr];
    `ALU_REG_C:  o_dbg_nbl = C [i_dbg_ptr];
    `ALU_REG_D:  o_dbg_nbl = D [i_dbg_ptr];
    `ALU_REG_D0: o_dbg_nbl = D0[i_dbg_ptr[2:0]];
    `ALU_REG_D1: o_dbg_nbl = D1[i_dbg_ptr[2:0]];
    `ALU_REG_R0: o_dbg_nbl = R0[i_dbg_ptr];
    `ALU_REG_R1: o_dbg_nbl = R1[i_dbg_ptr];
    `ALU_REG_R2: o_dbg_nbl = R2[i_dbg_ptr];
    `ALU_REG_R3: o_dbg_nbl = R3[i_dbg_ptr];
    `ALU_REG_R4: o_dbg_nbl = R4[i_dbg_ptr];
    default: o_dbg_nbl = 1'bx;  
  endcase
`endif

end

wire [0:0] dest_1_valid;

assign dest_1_valid = (i_dest_1 == `ALU_REG_A) ||
                      (i_dest_1 == `ALU_REG_B) ||
                      (i_dest_1 == `ALU_REG_C) ||
                      (i_dest_1 == `ALU_REG_D) ||
                      (i_dest_1 == `ALU_REG_D0) ||
                      (i_dest_1 == `ALU_REG_D1) ||
                      (i_dest_1 == `ALU_REG_R0) ||
                      (i_dest_1 == `ALU_REG_R1) ||
                      (i_dest_1 == `ALU_REG_R2) ||
                      (i_dest_1 == `ALU_REG_R3) ||
                      (i_dest_1 == `ALU_REG_R4);

always @(posedge i_clk) begin

  if (!i_reset && i_alu_initializing) begin
    A [i_dest_ptr]      <= 0;
    B [i_dest_ptr]      <= 0;
    C [i_dest_ptr]      <= 0;
    D [i_dest_ptr]      <= 0;
    D0[i_dest_ptr[2:0]] <= 0;
    D1[i_dest_ptr[2:0]] <= 0;
    R0[i_dest_ptr]      <= 0;
    R1[i_dest_ptr]      <= 0;
    R2[i_dest_ptr]      <= 0;
    R3[i_dest_ptr]      <= 0;
    R4[i_dest_ptr]      <= 0;
  end

  // $display({"REGS     %0d: [%d] !i_reset %b | !i_alu_initializing %b | i_ins_decoded %b | i_phase_3 %b | store_ev %b |",
  //           " dest_1_valid %b | i_dest_1 %d | i_dest_ptr %h | i_dest_1_nbl %h"}, 
  //           i_phase, i_cycle_ctr,
  //           !i_reset, !i_alu_initializing, i_ins_decoded, i_phase_3, reg_store_ev, 
  //           dest_1_valid, i_dest_1, i_dest_ptr, i_dest_1_nbl);


  /* registers store their new value on phase 3 */
  if (reg_store_ev && dest_1_valid) begin
    $write("REGS     %0d: [%d] ", i_phase, i_cycle_ctr);
    case (i_dest_1) 
      `ALU_REG_A: begin 
        $display("A[%0d] <= %h", i_dest_ptr, i_dest_1_nbl); 
        A[i_dest_ptr] <= i_dest_1_nbl;
      end
      `ALU_REG_C: begin
        $display("C[%0d] <= %h", i_dest_ptr, i_dest_1_nbl); 
        C[i_dest_ptr] <= i_dest_1_nbl; 
      end
      default: begin end
    endcase
  end
end

endmodule

`endif