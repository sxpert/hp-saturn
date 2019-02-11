/******************************************************************************
 * 3n[xxxxxx]	LC (n) [xxxxxx]
 *
 *
 */ 

`include "decstates.v"
`include "fields.v"

`DEC_LC: begin
    alu_first <= P;
    alu_last <= (P + nb_in) & 4'hF;
    alu_reg_src1 <= `ALU_REG_M;
    alu_reg_dest <= `ALU_REG_C;
    alu_op <= `ALU_OP_COPY;

    decstate <= `DEC_ALU_INIT;
    alu_return <= `DEC_START;
end
