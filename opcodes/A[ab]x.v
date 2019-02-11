
/******************************************************************************
 * A[ab]x
 * 
 * lots of things there
 *
 */ 


`include "decstates.v"
`include "fields.v"

`DEC_Axx_EXEC: begin
    if (!field_table[0]) begin
        // math ops
        if (nb_in[3:2] != 2'b11) 
            alu_op <= `ALU_OP_ADD;
        else alu_op <= `ALU_OP_DEC;
        case (nb_in[3:2])
        2'b00: begin
            alu_reg_dest <= reg_ABCD;
            alu_reg_src1 <= reg_ABCD;
            alu_reg_src2 <= reg_BCAC;
        end
        2'b01: begin
            alu_reg_dest <= reg_ABCD;
            alu_reg_src1 <= reg_ABCD;
            alu_reg_src2 <= reg_ABCD;
        end
        2'b10: begin
            alu_reg_dest <= reg_BCAC;
            alu_reg_src1 <= reg_BCAC;
            alu_reg_src2 <= reg_ABCD;
        end
        2'b11: begin
            alu_reg_dest <= reg_ABCD;
            alu_reg_src1 <= reg_ABCD;
        end
        endcase
    end else begin
        // copy and exchange ops
        case (nb_in[3:2])
        2'b00: begin
            alu_reg_dest <= reg_ABCD;
            alu_op <= `ALU_OP_ZERO;
        end
        2'b01: begin
            alu_reg_dest <= reg_ABCD;
            alu_reg_src1 <= reg_BCAC;
            alu_op <= `ALU_OP_COPY;
        end
        2'b10: begin
            alu_reg_dest <= reg_BCAC;
            alu_reg_src1 <= reg_ABCD;
            alu_op <= `ALU_OP_COPY;
        end
        2'b11: begin
            alu_reg_dest <= reg_ABAC;
            alu_reg_src1 <= reg_BCCD;
            alu_op <= `ALU_OP_EXCH;
        end
        endcase
    end
    // alu_debug <= 1;
    next_cycle <= `BUSCMD_NOP;
    decstate <= `DEC_ALU_INIT;
    alu_return <= `DEC_START;

`ifdef SIM
    $write("%5h ", inst_start_PC);
    if (!nb_in[3]) 
        case (nb_in[1:0])
        2'b00: $write("A=%s",(!nb_in[2])?"0":"B");
        2'b01: $write("B=%s",(!nb_in[2])?"0":"C");
        2'b10: $write("C=%s",(!nb_in[2])?"0":"A");
        2'b11: $write("D=%s",(!nb_in[2])?"0":"C");
        endcase
    else begin
        $write("NOT HANDLED");
    end
    $write("\t");
    case (field)
    `T_FIELD_P:  $display("P");
    `T_FIELD_WP: $display("WP");
    `T_FIELD_XS: $display("XS");
    `T_FIELD_X:  $display("X");
    `T_FIELD_S:  $display("S");
    `T_FIELD_M:  $display("M");
    `T_FIELD_B:  $display("B");
    `T_FIELD_W:  $display("W");
    endcase
`endif
end