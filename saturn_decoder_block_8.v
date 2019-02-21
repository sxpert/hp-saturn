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

`ifndef _SATURN_DECODER_BLOCK_8
`define _SATURN_DECODER_BLOCK_8

`include "def-alu.v"
`include "def-fields.v"
`include "saturn_decoder_block_vars.v"

  if (do_block_8x) begin
`ifdef SIM
    $display("block_8x %h | op %d", i_nibble, o_alu_op);
`endif
    case (i_nibble)
      4'h0:       // 
        block_80x  <= 1;
      4'h1:
        block_81x  <= 1;
      4'h2: 
        block_82x  <= 1;
      4'h4, 4'h5: // ST=[01] n
      begin 
        o_alu_op       <= i_nibble[0]?`ALU_OP_SET_BIT:`ALU_OP_RST_BIT;
        block_sr_bit   <= 1;
        `ifdef SIM
        o_unimplemented <= 0;
        `endif
      end
      4'hA: block_8Ax <= 1;
      4'hC, 4'hD, 
      4'hE, 4'hF: // GOLONG, GOVLNG, GOSUBL, GOSBVL
      begin
        o_alu_no_stall <= 1;
        o_alu_op       <= i_nibble[0]?`ALU_OP_JMP_ABS5:`ALU_OP_JMP_REL4;
        // is it a gosub ?
        o_push         <= i_nibble[1];
        o_alu_debug    <= i_nibble[1];
        mem_load_max   <= i_nibble[0]?4:3;
        o_mem_pos      <= 0;
        block_jmp      <= 1;
        // debug for cases not tested
        o_alu_debug    <= !i_nibble[0];  
        `ifdef SIM
        o_unimplemented <= 0;
        `endif   
      end
      default: begin
`ifdef SIM
        $display("block_8x %h error", i_nibble);
`endif
        o_dec_error    <= 1;
      end
    endcase
    block_8x           <= 0;
  end

  if (do_block_80x) begin
`ifdef SIM
    $display("block_80x %h | op %d", i_nibble, o_alu_op);
`endif
    case (i_nibble)
      4'h5: begin // CONFIG
        o_ins_alu_op  <= 1;
        o_alu_op      <= `ALU_OP_COPY;
        next_nibble   <= 0;
        o_ins_decoded <= 1;
        o_ins_config  <= 1;
        `ifdef SIM
        o_unimplemented <= 0;
        `endif
      end
      4'hA: begin // RESET
        o_ins_reset   <= 1;
        next_nibble   <= 0;
        o_ins_decoded <= 1;
      end
      4'hC: block_80Cx <= 1;
      default: begin
`ifdef SIM
        $display("block_80x %h error", i_nibble);
`endif
        o_dec_error    <= 1;
      end
    endcase
    block_80x          <= 0;
  end

  if (do_block_80Cx) begin
    o_ins_alu_op   <= 1;
    o_alu_op       <= `ALU_OP_COPY;
    next_nibble    <= 0;
    o_ins_decoded  <= 1;
    block_80Cx     <= 0;
  end

  if (do_block_81x) begin
    $display("block_81x %h", i_nibble);
    case (i_nibble)
    4'hA: begin
      block_81Ax <= 1;
      o_fields_table <= `FT_TABLE_f;
      go_fields_table <= 1;
    end
    default: o_dec_error <= 1;
    endcase
    block_81x <= 0;
  end

  if (do_block_81Ax) begin
    $display("block_81Ax %h", i_nibble);
    go_fields_table <= 0;
    block_81Afx <= 1;
    block_81Ax <= 0;
  end

  if (do_block_81Afx) begin
    $display("block_81Afx %h | f %0d | s %h | l %h | 0 %b | 1 %b | 2 %b", 
             i_nibble, o_field, o_field_start, o_field_last,
             i_nibble == 0, i_nibble==1, i_nibble==2);
    block_81Af0x <= i_nibble == 0;
    block_81Af1x <= i_nibble == 1;
    block_81Af2x <= i_nibble == 2;
    block_81Afx <= 0;
  end

  if (do_block_81Af0x || do_block_81Af1x) begin
    $display("block_81Af[01]x %h", i_nibble);
    o_ins_alu_op <= 1;
    o_alu_op <= `ALU_OP_COPY;
    next_nibble <= 0;
    o_ins_decoded <= 1;
    block_81Af0x <= 0;
    block_81Af1x <= 0;
  end

  if (do_block_81Af2x) begin
    $display("block_81Af2x %h", i_nibble);
    o_ins_alu_op <= 1;
    o_alu_op <= `ALU_OP_EXCH;
    next_nibble <= 0;
    o_ins_decoded <= 1;
    block_81Af2x <= 0;
  end

  // 821 XM=0
  // 822 SB=0
  // 824 SR=0
  // 828 MP=0
  // 82F CLRHST
  // 82x CLRHST     x
  if (do_block_82x) begin
    o_ins_alu_op    <= 1;
    o_alu_op        <= `ALU_OP_CLR_MASK;
    o_imm_value     <= i_nibble;
    next_nibble     <= 0;
    o_ins_decoded   <= 1;
    `ifdef SIM
    o_unimplemented <= 0;
    `endif
    block_82x       <= 0;
  end

  if (do_block_8Ax) begin
    o_fields_table <= `FT_TABLE_f;
    o_ins_alu_op <= 1;
    o_alu_op <= i_nibble[2]?`ALU_OP_TEST_NEQ:`ALU_OP_TEST_EQ;
   // o_alu_debug <= 1;
    o_mem_pos <= 0;
    mem_load_max <= 1;
    o_ins_decoded <= 1;
    next_nibble <= 0;
    block_jump_test <= 1;
    
    // lauch the ALU into test_go mode
    o_ins_test_go    <= 1;
    block_8Ax <= 0;
  end

`endif