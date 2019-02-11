/******************************************************************************
 * 1X
 *
 *
 */ 

`include "decstates.v"

`DEC_1X: begin
    case (nb_in)
    4'h3: decstate <= `DEC_13X;
    4'h4: decstate <= `DEC_14X;
    4'h5: decstate <= `DEC_15X;
    4'h6, 4'h7, 4'h8, 4'hC: begin
        alu_reg_dest <= reg_D0D1;
        alu_reg_src1 <= reg_D0D1;
        alu_reg_src2 <= `ALU_REG_CST;
        alu_op <= nb_in[3]?`ALU_OP_SUB_CST:`ALU_OP_ADD_CST;
        decstate <= `DEC_PTR_MATH;
    end
    4'h9: decstate <= `DEC_D0_EQ_2N;
    4'hA: decstate <= `DEC_D0_EQ_4N;
    4'hB: decstate <= `DEC_D0_EQ_5N;
    4'hD: decstate <= `DEC_D1_EQ_2N;
    4'hE: decstate <= `DEC_D1_EQ_4N;
    4'hF: decstate <= `DEC_D1_EQ_5N;
    default: begin 
        $display("ERROR : DEC_1X %h", nb_in);
        decode_error <= 1;    
    end
    endcase
end
