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

/*
 * debugger
 *
 */

wire [19:0] new_pc;
assign new_pc = i_pc + 1;

wire run_debugger;
assign run_debugger =  !i_reset && i_en_dbg && !i_stalled && !i_bus_load_pc && !next_nibble;

wire is_short_transfer;
assign is_short_transfer = (o_field_last == 3) && 
                           ((o_reg_dest[4:1] == 4'b0010) || (o_reg_src1[4:1] == 4'b0010));

wire p_is_dest;
wire is_load_imm;
wire is_d0_eq;
wire is_d1_eq;
wire is_p_eq;
wire is_la_hex; 
wire is_lc_hex; 
wire disp_nb_nibbles;
wire is_alu_op;
assign p_is_dest       = (o_reg_dest == `ALU_REG_P);
assign is_load_imm     =   ((o_alu_op == `ALU_OP_COPY)     || 
                            (o_alu_op == `ALU_OP_RST_BIT)  ||
                            (o_alu_op == `ALU_OP_SET_BIT)  ||
                            (o_alu_op == `ALU_OP_JMP_REL2) ||
                            (o_alu_op == `ALU_OP_JMP_REL3) ||
                            (o_alu_op == `ALU_OP_JMP_REL4) ||
                            (o_alu_op == `ALU_OP_JMP_ABS5))
                         && (o_reg_src1 == `ALU_REG_IMM);
assign is_d0_eq        = is_load_imm && (o_reg_dest == `ALU_REG_D0);
assign is_d1_eq        = is_load_imm && (o_reg_dest == `ALU_REG_D1);
assign is_p_eq         = is_load_imm && p_is_dest;
assign is_la_hex       = is_load_imm && (o_reg_dest == `ALU_REG_A);
assign is_lc_hex       = is_load_imm && (o_reg_dest == `ALU_REG_C);
assign disp_nb_nibbles = is_d0_eq || is_d1_eq;
assign is_alu_op       = o_ins_alu_op && 
                         !( o_ins_config );

reg [4:0]  nibble_pos;

always @(posedge i_clk) begin
  if (run_debugger) begin
    /*
     * this whole thing is a large print statement
     * THIS PART IS NEVER GENERATED
     */
    `ifdef SIM
    if (o_ins_decoded) begin
      $write("DBG[%5d]: ", inst_counter);
      $write("%5h ", o_ins_addr);

      // $write("[%2d] ", o_dbg_nb_nbls);

      for(nibble_pos=0; nibble_pos!=o_dbg_nb_nbls; nibble_pos=nibble_pos+1)
        $write("%h", o_dbg_nibbles[nibble_pos*4+:4]);
      for(nibble_pos=o_dbg_nb_nbls; nibble_pos!=22; nibble_pos=nibble_pos+1)
        $write(" ");

      // display decoded instruction
      if (o_ins_rtn) begin
        $write("RT%s", o_en_intr?"I":"N");
        if (o_alu_op == `ALU_OP_TEST_GO) $write("YES");
        if (o_set_xm) $write("SXM");
        if (o_set_carry) $write("%sC", o_carry_val?"S":"C");
        $write("\t");
      end
      if (o_ins_set_mode) begin
        $write("SET%s", o_mode_dec?"DEC":"HEX");
      end
      if (o_ins_reset) begin
        $write("RESET\t");
      end
      if (o_ins_config) 
        $write("CONFIG\t");

      if (is_alu_op) begin

        case (o_alu_op)
          `ALU_OP_TEST_EQ,
          `ALU_OP_TEST_NEQ: $write("?");
        endcase

        // reg dest...
        case (o_alu_op)
          `ALU_OP_CLR_MASK:
            case (o_reg_dest)
              `ALU_REG_HST:
                case (o_imm_value)
                  4'h1: $write("XM=0");
                  4'h2: $write("SB=0");
                  4'h4: $write("SR=0");
                  4'h8: $write("MP=0");
                  default: begin  
                    $write("CLRHST");
                    if (o_imm_value != 4'hF) $write("\t%1h", o_imm_value);
                  end
                endcase
              default:         $write("[VLR_MASK dest:%0d]", o_reg_dest);
            endcase 
          `ALU_OP_JMP_REL2,
          `ALU_OP_JMP_REL3,
          `ALU_OP_JMP_REL4,
          `ALU_OP_JMP_ABS5,
          `ALU_OP_TEST_EQ,
          `ALU_OP_TEST_NEQ: begin end 
          default:
            case (o_reg_dest)
            `ALU_REG_A:      $write("A");
            `ALU_REG_B:      $write("B");
            `ALU_REG_C:    
              if (is_lc_hex) $write("LCHEX");
              else $write("C");
            `ALU_REG_D:      $write("D");
            `ALU_REG_D0:     $write("D0");
            `ALU_REG_D1:     $write("D1");
            `ALU_REG_RSTK:   $write("RSTK");
            `ALU_REG_R0:     $write("R0");
            `ALU_REG_R1:     $write("R1");
            `ALU_REG_R2:     $write("R2");
            `ALU_REG_R3:     $write("R3");
            `ALU_REG_R4:     $write("R4");
            `ALU_REG_DAT0:   $write("DAT0");
            `ALU_REG_DAT1:   $write("DAT1");
            `ALU_REG_ST:     if (o_alu_op!=`ALU_OP_ZERO) $write("ST");
            `ALU_REG_P:      $write("P");
            default:         $write("[dest:%0d]", o_reg_dest);
            endcase
        endcase

        // operation 1
        case (o_alu_op)
        `ALU_OP_ZERO:     if (o_reg_dest==`ALU_REG_ST) 
                            $write("CLRST"); 
                          else $write("=0");
        `ALU_OP_COPY,
        `ALU_OP_AND,
        `ALU_OP_OR,
        `ALU_OP_RST_BIT,
        `ALU_OP_SET_BIT,
        `ALU_OP_INC,
        `ALU_OP_DEC,
        `ALU_OP_ADD,
        `ALU_OP_SUB:
          if (!is_lc_hex) 
            $write("=");
        `ALU_OP_2CMPL:    $write("=-");
        `ALU_OP_JMP_REL2: begin
          $write("%s",(o_mem_load[7:0] == 0)?"RTN":"GO");
          if (!o_carry_val) $write("N");
          $write("C");
        end
        `ALU_OP_JMP_REL3:  $write("%s", o_push?"GOSUB":"GOTO"); 
        `ALU_OP_JMP_REL4:  $write("%s", o_push?"GOSUBL":"GOLONG");
        `ALU_OP_JMP_ABS5:  $write("%s", o_push?"GOSBVL":"GOVLNG");
        `ALU_OP_EXCH,
        `ALU_OP_TEST_EQ,
        `ALU_OP_TEST_NEQ,
        `ALU_OP_CLR_MASK: begin end
        default: $write("[op:%0d]", o_alu_op);
        endcase
 
        // src1
        case (o_alu_op)
        `ALU_OP_COPY,
        `ALU_OP_AND,
        `ALU_OP_OR,
        `ALU_OP_2CMPL,
        `ALU_OP_INC,
        `ALU_OP_DEC,
        `ALU_OP_ADD,
        `ALU_OP_SUB,
        `ALU_OP_TEST_EQ,
        `ALU_OP_TEST_NEQ:
          case (o_reg_src1)
          `ALU_REG_A:    $write("A");
          `ALU_REG_B:    $write("B");
          `ALU_REG_C:    $write("C");
          `ALU_REG_D:    $write("D");
          `ALU_REG_D0:   $write("D0");
          `ALU_REG_D1:   $write("D1");
          `ALU_REG_RSTK: $write("RSTK");
          `ALU_REG_R0:   $write("R0");
          `ALU_REG_R1:   $write("R1");
          `ALU_REG_R2:   $write("R2");
          `ALU_REG_R3:   $write("R3");
          `ALU_REG_R4:   $write("R4");
          `ALU_REG_DAT0: $write("DAT0");
          `ALU_REG_DAT1: $write("DAT1");
          `ALU_REG_ST:   $write("ST");
          `ALU_REG_P:    $write("P");
          `ALU_REG_IMM: 
            if (disp_nb_nibbles) $write("(%0d)", o_mem_pos);
          `ALU_REG_ZERO: $write("0");
          default: $write("[src1:%0d]", o_reg_src1);
          endcase
        `ALU_OP_RST_BIT: $write("0");
        `ALU_OP_SET_BIT: $write("1");
        endcase
        // if ((o_alu_op == `ALU_OP_COPY) && is_short_transfer) 
        //   $write("S");


        // operation 2
        case (o_alu_op)
        `ALU_OP_AND,
        `ALU_OP_OR,
        `ALU_OP_ADD,
        `ALU_OP_SUB:
          case (o_alu_op)
          `ALU_OP_AND: $write("&");
          `ALU_OP_OR:  $write("!");
          `ALU_OP_ADD:  $write("+");
          `ALU_OP_SUB:  $write("-");
          default: $write("[op:%0d]", o_alu_op);
          endcase
        `ALU_OP_TEST_EQ: $write("=");
        `ALU_OP_TEST_NEQ: $write("#");
        default: begin end
        endcase
          
        // source 2
        case (o_alu_op)
        `ALU_OP_ZERO,
        `ALU_OP_COPY: begin end
        `ALU_OP_EXCH,
        `ALU_OP_ADD,
        `ALU_OP_TEST_EQ,
        `ALU_OP_TEST_NEQ:
          case (o_reg_src2)
          `ALU_REG_A:    $write("A");
          `ALU_REG_B:    $write("B");
          `ALU_REG_C:    $write("C");
          `ALU_REG_D:    $write("D");
          `ALU_REG_D0:   $write("D0");
          `ALU_REG_D1:   $write("D1");
          `ALU_REG_RSTK: $write("RSTK");
          `ALU_REG_IMM:  $write("\t%0d", o_imm_value+1);
          default:       $write("[src2:%0d]", o_reg_src2);
          endcase
        `ALU_OP_INC:  $write("+1");
        `ALU_OP_DEC:  $write("-1");
        endcase

        if (o_alu_op == `ALU_OP_EXCH)
          $write("%s", is_short_transfer?"XS":"EX");
        
        // if (!((o_reg_dest == `ALU_REG_RSTK) || (o_reg_src1 == `ALU_REG_RSTK) ||
        //       (o_reg_dest == `ALU_REG_ST)   || (o_reg_src1 == `ALU_REG_ST  ) ||
        //       (o_reg_dest == `ALU_REG_P)    || (o_reg_src1 == `ALU_REG_P   ))) begin
        $write("\t");
        if (o_field_valid) begin
          
          $write("[FT%d]", o_fields_table);
          if (o_fields_table != `FT_TABLE_value)
            case (o_field)
            `FT_FIELD_P:  $write("P");
            `FT_FIELD_WP: $write("WP");
            `FT_FIELD_XS: $write("XS");
            `FT_FIELD_X:  $write("X");
            `FT_FIELD_S:  $write("S");
            `FT_FIELD_M:  $write("M");
            `FT_FIELD_B:  $write("B");
            `FT_FIELD_W:  $write("W");
            `FT_FIELD_A:  $write("A");
            endcase
          else $write("%0d", o_field_last+1);
        end 
        else begin
          // $write("@%b@", is_load_imm);
          if (is_load_imm) begin
            if (is_p_eq) $write("%0d", o_imm_value);
            else
              for(nibble_pos=(o_mem_pos - 1); nibble_pos!=31; nibble_pos=nibble_pos-1)
                $write("%h", o_mem_load[nibble_pos*4+:4]);
          end
          else 
            case (o_reg_dest)
            `ALU_REG_P,
            `ALU_REG_ST,
            `ALU_REG_HST: begin end
            `ALU_REG_C:  
              if (o_reg_src1 == `ALU_REG_P)
                $write("%0d", o_field_start);
            default: $write("[%h:%h]", o_field_start, o_field_last);
            endcase
        end
      end
      $write("\t(%0d cycles)", inst_cycles);
      if (o_unimplemented)
        $write("\t%C[1,31mUNIMPLEMENTED%C[0m", 27, 27);
      $write("\n");
    end
    // $display("new [%5h]--------------------------------------------------------------------", new_pc);  
    `endif
  end
end
