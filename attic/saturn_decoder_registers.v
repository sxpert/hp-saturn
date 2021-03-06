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

`ifndef _SATURN_DECODER_REGISTERS
`define _SATURN_DECODER_REGISTERS

`include "def-alu.v"

/******************************************************************************
*
* set registers from instruction nibble
*
*****************************************************************************/

wire [4:0]		reg_ABCD;
wire [4:0]		reg_BCAC;
wire [4:0]		reg_ABAC;
wire [4:0]		reg_BCCD;
wire [4:0]		reg_D0D1;
wire [4:0]		reg_DAT0DAT1;
wire [4:0]    reg_A_C;

assign reg_ABCD     = { 3'b000,   i_nibble[1:0]};
assign reg_BCAC     = { 3'b000,   i_nibble[0], !(i_nibble[1] ||   i_nibble[0])};
assign reg_ABAC     = { 3'b000,   i_nibble[1] && i_nibble[0],   (!i_nibble[1]) && i_nibble[0]};
assign reg_BCCD     = { 3'b000,   i_nibble[1] || i_nibble[0],  !( i_nibble[1]  ^  i_nibble[0])};
// assign reg_D0D1 = { 4'b0010, (i_nibble[0] && i_nibble[1]) || (i_nibble[2]  && i_nibble[3])};
assign reg_D0D1     = { 4'b0010,  i_nibble[0]};
assign reg_DAT0DAT1 = { 4'b1000,  i_nibble[0]};
assign reg_A_C      = { 3'b000,   i_nibble[2],   1'b0};

always @(posedge i_clk) begin

  if (i_reset) begin
    o_reg_dest        <= `ALU_REG_NOPE;
    o_reg_src1        <= `ALU_REG_NOPE;
    o_reg_src2        <= `ALU_REG_NOPE;
    inval_opcode_regs <= 0;
  end

  if (do_on_first_nibble) begin
    // reset values on instruction decode start
    case (i_nibble)
    4'h3: begin
      o_reg_dest        <= `ALU_REG_C;
      o_reg_src1        <= `ALU_REG_IMM;
      o_reg_src2        <= `ALU_REG_NOPE;
    end
    4'h4, 4'h5, 4'h6, 4'h7: begin
      o_reg_dest        <= `ALU_REG_NOPE;
      o_reg_src1        <= `ALU_REG_IMM;
      o_reg_src2        <= `ALU_REG_NOPE;
    end
    default: begin
      o_reg_dest        <= `ALU_REG_NOPE;
      o_reg_src1        <= `ALU_REG_NOPE;
      o_reg_src2        <= `ALU_REG_NOPE;
    end
    endcase
    inval_opcode_regs <= 0;
  end


  /************************************************************************
  *
  * set registers for specific instructions
  *
  ************************************************************************/

  if (do_block_0x) begin
    o_reg_src2 <= `ALU_REG_NOPE;
    case (i_nibble)
    4'h6: begin
      o_reg_dest <= `ALU_REG_RSTK;
      o_reg_src1 <= `ALU_REG_C;
    end
    4'h7: begin
      o_reg_dest <= `ALU_REG_C;
      o_reg_src1 <= `ALU_REG_RSTK;
    end
    4'h8: begin
      o_reg_dest <= `ALU_REG_ST;
      o_reg_src1 <= `ALU_REG_NOPE;
    end
    4'h9, 4'hB: begin
      o_reg_dest <= `ALU_REG_C;
      o_reg_src1 <= `ALU_REG_ST;
    end
    4'hA: begin
      o_reg_dest <= `ALU_REG_ST;
      o_reg_src1 <= `ALU_REG_C;
    end
    4'hC, 4'hD: begin
      o_reg_dest <= `ALU_REG_P;
      o_reg_src1 <= `ALU_REG_P;
    end
    default: begin
      // inval_opcode_regs <= 1;
    end
    endcase
  end 

  if (do_block_0Efx && !in_fields_table) begin
    o_reg_dest <= i_nibble[2]?reg_BCAC:reg_ABCD;
    o_reg_src1 <= i_nibble[2]?reg_BCAC:reg_ABCD;
    o_reg_src2 <= i_nibble[2]?reg_ABCD:reg_BCAC;
  end   

  if (do_block_1x) begin
    o_reg_src2 <= `ALU_REG_NOPE;
    case (i_nibble)
      4'h6, 4'h8: begin
        o_reg_dest <= `ALU_REG_D0;
        o_reg_src1 <= `ALU_REG_D0; 
      end
      4'h7, 4'hC: begin
        o_reg_dest <= `ALU_REG_D1;
        o_reg_src1 <= `ALU_REG_D1; 
      end
      4'h9, 4'hA, 4'hB: begin
        o_reg_dest <= `ALU_REG_D0;
        o_reg_src1 <= `ALU_REG_IMM;
      end
      4'hD, 4'hE, 4'hF: begin
        o_reg_dest <= `ALU_REG_D1;
        o_reg_src1 <= `ALU_REG_IMM;
      end
    default: begin end
    endcase
  end

  if (do_block_save_to_R_W) begin
    o_reg_dest <= {2'b01,  i_nibble[2:0]};
    o_reg_src1 <= {3'b000, i_nibble[3]?2'b10:2'b00};
    o_reg_src2 <= `ALU_REG_NOPE;
  end
  
  if (do_block_rest_from_R_W || do_block_exch_with_R_W) begin
    o_reg_dest <= {3'b000, i_nibble[3]?2'b10:2'b00};
    o_reg_src1 <= {2'b01,  i_nibble[2:0]};
    o_reg_src2 <= `ALU_REG_NOPE;
  end

  if (do_block_13x) begin
    o_reg_dest <= i_nibble[1]?reg_A_C:reg_D0D1;
    o_reg_src1 <= i_nibble[2]?`ALU_REG_C:`ALU_REG_A;
    o_reg_src2 <= i_nibble[1]?reg_D0D1:0;
  end

  if (do_block_14x_15xx) begin
    o_reg_dest <= i_nibble[1]?reg_A_C:reg_DAT0DAT1;
    o_reg_src1 <= i_nibble[1]?reg_DAT0DAT1:reg_A_C;
    o_reg_src2 <= i_nibble[0]?`ALU_REG_D1:`ALU_REG_D0;
  end

  if (do_block_pointer_arith_const) begin
    o_reg_dest <= `ALU_REG_NOPE;
    o_reg_dest <= `ALU_REG_NOPE;
    o_reg_src2 <= `ALU_REG_IMM;
  end

  if (do_block_2x) begin
    o_reg_dest <= `ALU_REG_P;
    o_reg_src1 <= `ALU_REG_IMM;
    o_reg_src2 <= `ALU_REG_NOPE;
  end

  if (do_block_8x) begin
    o_reg_src2 <= `ALU_REG_NOPE;
    case (i_nibble)
      4'h4, 4'h5, 4'h6, 4'h7: begin
        o_reg_dest        <= `ALU_REG_ST;
        o_reg_src1        <= `ALU_REG_IMM;
      end
      4'hC, 4'hD, 4'hE, 4'hF: begin
        o_reg_dest        <= `ALU_REG_NOPE;
        o_reg_src1        <= `ALU_REG_IMM;
      end
    endcase
  end

  if (do_block_80x) begin
    case (i_nibble)
      4'h5: begin
        o_reg_dest        <= `ALU_REG_ADDR;
        o_reg_src1        <= `ALU_REG_C;
        o_reg_src2        <= `ALU_REG_NOPE;
      end
      4'hC: begin
        o_reg_dest        <= `ALU_REG_C;
        o_reg_src1        <= `ALU_REG_P;
        o_reg_src2        <= `ALU_REG_NOPE;
      end
    endcase
  end

  if (do_block_81Af0x) begin
    o_reg_dest        <= { 2'b01, i_nibble[2:0]};
    o_reg_src1        <= i_nibble[3]?`ALU_REG_C:`ALU_REG_A;
    o_reg_src2        <= `ALU_REG_NOPE;
  end

  if (do_block_81Af1x) begin
    o_reg_dest        <= i_nibble[3]?`ALU_REG_C:`ALU_REG_A;
    o_reg_src1        <= { 2'b01, i_nibble[2:0]};
    o_reg_src2        <= `ALU_REG_NOPE;
  end

  if (do_block_81Af2x) begin
    o_reg_dest        <= i_nibble[3]?`ALU_REG_C:`ALU_REG_A;
    o_reg_src1        <= i_nibble[3]?`ALU_REG_C:`ALU_REG_A;
    o_reg_src2        <= { 2'b01, i_nibble[2:0]};
  end

  if (do_block_82x) begin
    o_reg_dest        <= `ALU_REG_HST;
    o_reg_src1        <= `ALU_REG_IMM;
    o_reg_src2        <= `ALU_REG_NOPE;
  end

  if (do_block_84x_85x) begin
    o_reg_dest        <= `ALU_REG_ST;
    o_reg_src1        <= `ALU_REG_IMM;
    o_reg_src2        <= `ALU_REG_NOPE;
  end

  if (do_block_8Ax) begin
    o_reg_dest <= 0;
    o_reg_src1 <= i_nibble[3]?reg_ABCD:reg_BCAC;
    o_reg_src2 <= i_nibble[3]?`ALU_REG_ZERO:reg_ABCD;
  end

  if (do_block_Abx || do_block_Dx) begin
    o_reg_src2      <= `ALU_REG_NOPE;
    case ({i_nibble[3],i_nibble[2]})
      2'b00: begin
        o_reg_dest      <= reg_ABCD;
        o_reg_src1      <= `ALU_REG_ZERO;
      end
      2'b01: begin
        o_reg_dest      <= reg_ABCD;
        o_reg_src1      <= reg_BCAC;
      end
      2'b10: begin
        o_reg_dest      <= reg_BCAC;
        o_reg_src1      <= reg_ABCD;
      end
      2'b11: begin // exch
        o_reg_dest      <= reg_ABAC;
        o_reg_src1      <= reg_ABAC;
        o_reg_src2      <= reg_BCCD;
      end
    endcase
  end

  if (do_block_Bax) begin
    case ({i_nibble[3],i_nibble[2]})
      2'b00: begin
        o_reg_dest <= reg_ABCD;
        o_reg_src1 <= reg_ABCD;
        o_reg_src2 <= reg_BCAC;
      end
      2'b01: begin
        o_reg_dest <= reg_ABCD;
        o_reg_src1 <= reg_ABCD;
        o_reg_src2 <= `ALU_REG_NOPE;
      end
      2'b10: begin
        o_reg_dest <= reg_BCAC;
        o_reg_src1 <= reg_BCAC;
        o_reg_src2 <= reg_ABCD;
      end
      2'b11: begin
        o_reg_dest <= reg_ABCD;
        o_reg_src1 <= reg_BCAC;
        o_reg_src2 <= reg_ABCD;
      end
    endcase
  end

  if (do_block_Bbx) begin
    o_reg_dest <= reg_ABCD;
    o_reg_src1 <= reg_ABCD;
    o_reg_src2 <= `ALU_REG_NOPE;
  end

  if (do_block_Cx) begin
    case ({i_nibble[3],i_nibble[2]})
    2'b00: begin
      o_reg_dest      <= reg_ABCD;
      o_reg_src1      <= reg_ABCD;
      o_reg_src2      <= reg_BCAC;
    end
    2'b01: begin
      o_reg_dest      <= reg_ABCD;
      o_reg_src1      <= reg_ABCD;
      o_reg_src2      <= reg_ABCD;
    end
    2'b10: begin
      o_reg_dest      <= reg_BCAC;
      o_reg_src1      <= reg_BCAC;
      o_reg_src2      <= reg_ABCD;
    end
    2'b11: begin // reg = reg - 1
      o_reg_dest      <= reg_ABCD;
      o_reg_src1      <= reg_ABCD;
      o_reg_src2      <= `ALU_REG_NOPE;
    end
    endcase
  end

  if (do_block_Fx) begin
    o_reg_src2 <= `ALU_REG_NOPE;
    case (i_nibble)
      4'h8, 4'h9, 4'hA, 4'hB: begin
        o_reg_dest        <= reg_ABCD;
        o_reg_src1        <= reg_ABCD;
      end
    endcase
    o_reg_src2        <= 0;     
  end

end

`endif