/*
 * Alu module
 * calculations are in here
 */

`include "fields.v"

`DEC_ALU_INIT, `DEC_ALU_CONT: begin
`ifdef SIM
    if (alu_debug) begin
        $display("------------------------ z_alu_phase_3 - Store results -------------------------");
        $display("SRC1 %h | SRC2 %h | RES1 %h | RES2 %h | RC %b | DEST %h | TMP %h | CARRY %b", 
                 alu_src1, alu_src2, alu_res1, alu_res2, alu_res_carry,
                 alu_reg_dest, alu_tmp, alu_carry);
    end
`endif

    /*
     * put the result in destination register
     */
    case (alu_op)
    // cases where the result is useful
    `ALU_OP_ZERO,
    `ALU_OP_COPY,
    `ALU_OP_2CMPL,
    `ALU_OP_1CMPL,
    `ALU_OP_INC: begin
        case (alu_reg_dest)
        `ALU_REG_A: A[alu_first*4+:4] <= alu_res1;
        `ALU_REG_B: B[alu_first*4+:4] <= alu_res1;
        `ALU_REG_C: C[alu_first*4+:4] <= alu_res1;
        `ALU_REG_D: D[alu_first*4+:4] <= alu_res1;
        endcase   
        alu_first <= (alu_first + 1) & 4'hF;
    end
    // cases where there's no result
    `ALU_OP_TEST_EQ,
    `ALU_OP_TEST_NEQ: begin
        alu_first <= (alu_first + 1) & 4'hF;
    end
    default: begin
`ifdef SIM
        $display("ALU: operation not implemented");
        decode_error <= 1;
`endif
    end
    endcase
    /*
     * handle carry TODO: check if there are operations that don't touch carry
     */
    case (alu_op)
    // cases where carry is to be changed
    `ALU_OP_2CMPL,
    `ALU_OP_1CMPL,
    `ALU_OP_INC,
    `ALU_OP_TEST_EQ,
    `ALU_OP_TEST_NEQ: begin
        Carry <= alu_res_carry;
    end
    endcase


    if (alu_last == alu_first) begin
        // the alu is done
        next_cycle <= alu_next_cycle;
        decstate <= alu_return;
        alu_requested_halt <= alu_p1_halt | alu_p2_halt | alu_halt ;
    end else decstate <= `DEC_ALU_CONT;

end