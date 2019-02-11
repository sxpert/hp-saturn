/******************************************************************************
 * Dx
 * register manipulation field A
 *
 */ 


`include "decstates.v"

`DEC_DX: begin
    field <= `T_FIELD_A;
    alu_first <= 0;
    alu_last  <= 4;

    case (nb_in[3:2])
    2'b00: begin
        alu_op <= `ALU_OP_ZERO;
        alu_reg_dest <= reg_ABCD;
    end
    2'b01: begin
        alu_op <= `ALU_OP_COPY;
        alu_reg_dest <= reg_ABCD;
        alu_reg_src1 <= reg_BCAC;
    end
    2'b10: begin
        alu_op <= `ALU_OP_COPY;
        alu_reg_dest <= reg_BCAC;
        alu_reg_src1 <= reg_ABCD;
    end
    2'b11: begin
        alu_op <= `ALU_OP_EXCH;
        alu_reg_dest <= reg_ABAC;
        alu_reg_src1 <= reg_BCCD;
    end
    endcase
    next_cycle <= `BUSCMD_NOP;
    decstate <= `DEC_ALU_INIT;
    alu_return <= `DEC_START;
end
